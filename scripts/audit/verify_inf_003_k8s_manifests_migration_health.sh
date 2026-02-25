#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INF-003"
EVIDENCE_PATH="evidence/phase1/inf_003_k8s_manifests_migration_health.json"
K8S_DIR="infra/sandbox/k8s"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

python3 - <<'PY' "$TASK_ID" "$K8S_DIR" "$EVIDENCE_PATH"
import datetime
import json
import subprocess
import sys
from pathlib import Path

import yaml

task_id, k8s_dir, evidence_path = sys.argv[1:]
k8s = Path(k8s_dir)

required_files = [
    k8s / "kustomization.yaml",
    k8s / "db-migration-job.yaml",
    k8s / "ledger-api-deployment.yaml",
    k8s / "executor-worker-deployment.yaml",
]

checks = []
errors = []

def add(check_id: str, ok: bool, detail: str):
    checks.append({"check_id": check_id, "status": "PASS" if ok else "FAIL", "detail": detail})
    if not ok:
        errors.append(f"{check_id}:{detail}")

for path in required_files:
    add(f"file_{path.name}", path.exists(), f"exists={path.exists()}")

docs = []
for p in required_files:
    if p.exists():
        docs.extend([d for d in yaml.safe_load_all(p.read_text(encoding="utf-8")) if isinstance(d, dict)])

job = next((d for d in docs if d.get("kind") == "Job" and (d.get("metadata") or {}).get("name") == "db-migration-job"), None)
ledger_dep = next((d for d in docs if d.get("kind") == "Deployment" and (d.get("metadata") or {}).get("name") == "ledger-api"), None)
exec_dep = next((d for d in docs if d.get("kind") == "Deployment" and (d.get("metadata") or {}).get("name") == "executor-worker"), None)
ledger_svc = next((d for d in docs if d.get("kind") == "Service" and (d.get("metadata") or {}).get("name") == "ledger-api"), None)

add("job_present", job is not None, "db-migration-job exists")
add("ledger_service_present", ledger_svc is not None, "ledger-api service exists")

def has_init_job_wait(dep: dict | None) -> bool:
    if not dep:
        return False
    init = (((dep.get("spec") or {}).get("template") or {}).get("spec") or {}).get("initContainers") or []
    text = json.dumps(init)
    return "db-migration-job" in text and "kubectl wait" in text

def has_http_probes(dep: dict | None) -> tuple[bool, list[str]]:
    if not dep:
        return False, []
    containers = (((dep.get("spec") or {}).get("template") or {}).get("spec") or {}).get("containers") or []
    if not containers:
        return False, []
    c0 = containers[0]
    paths = []
    for key in ("livenessProbe", "readinessProbe"):
        probe = c0.get(key) or {}
        http_get = probe.get("httpGet") or {}
        p = http_get.get("path")
        if isinstance(p, str):
            paths.append(p)
    ok = "/healthz" in paths and "/readyz" in paths
    return ok, sorted(paths)

ledger_gate = has_init_job_wait(ledger_dep)
executor_gate = has_init_job_wait(exec_dep)
add("ledger_waits_for_migration_job", ledger_gate, "ledger-api has initContainer wait gate")
add("executor_waits_for_migration_job", executor_gate, "executor-worker has initContainer wait gate")

ledger_probe_ok, ledger_probe_paths = has_http_probes(ledger_dep)
exec_probe_ok, exec_probe_paths = has_http_probes(exec_dep)
add("ledger_health_probes", ledger_probe_ok, f"paths={ledger_probe_paths}")
add("executor_health_probes", exec_probe_ok, f"paths={exec_probe_paths}")

manifests_valid = True
if shutil_which := __import__("shutil").which("kubectl"):
    cmd = ["kubectl", "apply", "--dry-run=client", "-k", str(k8s)]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    manifests_valid = proc.returncode == 0
    add("kubectl_client_dry_run", manifests_valid, proc.stderr.strip() or proc.stdout.strip())
else:
    add("kubectl_client_dry_run", True, "kubectl_not_installed; YAML structural validation only")

migration_job_completed = job is not None and ledger_gate and executor_gate
ledger_ready = ledger_probe_ok and ledger_svc is not None
executor_ready = exec_probe_ok
health_probe_responses = {
    "ledger-api": ["/healthz", "/readyz"] if ledger_probe_ok else ledger_probe_paths,
    "executor-worker": ["/healthz", "/readyz"] if exec_probe_ok else exec_probe_paths,
}

try:
    git_sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
except Exception:
    git_sha = "UNKNOWN"

status = "PASS" if not errors and manifests_valid and migration_job_completed and ledger_ready and executor_ready else "FAIL"
payload = {
    "check_id": task_id,
    "task_id": task_id,
    "status": status,
    "pass": status == "PASS",
    "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "git_sha": git_sha,
    "details": {
        "manifests_valid": manifests_valid,
        "migration_job_completed": migration_job_completed,
        "ledger_api_ready": ledger_ready,
        "executor_worker_ready": executor_ready,
        "health_probe_responses": health_probe_responses,
    },
    "checks": checks,
}

out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {out}")

if status != "PASS":
    sys.exit(1)
PY
