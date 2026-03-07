#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_PATH="evidence/phase1/tsk_p1_203__sandbox_deploy_manifests_restore_posture_verifier.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence) EVIDENCE_PATH="${2:-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$(dirname "$ROOT_DIR/$EVIDENCE_PATH")"
ROOT_DIR="$ROOT_DIR" EVIDENCE_PATH="$EVIDENCE_PATH" python3 - <<'PY'
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path

try:
    import yaml  # type: ignore
except Exception as exc:
    raise SystemExit(f"pyyaml_missing:{exc}")

root = Path(os.environ["ROOT_DIR"])
out = root / os.environ["EVIDENCE_PATH"]

required_files = {
    "kustomization": root / "infra/sandbox/k8s/kustomization.yaml",
    "migration_job": root / "infra/sandbox/k8s/db-migration-job.yaml",
    "ledger_api": root / "infra/sandbox/k8s/ledger-api-deployment.yaml",
    "executor_worker": root / "infra/sandbox/k8s/executor-worker-deployment.yaml",
    "secrets_bootstrap": root / "infra/sandbox/k8s/secrets-bootstrap.yaml",
}

errors = []
for name, p in required_files.items():
    if not p.exists():
        errors.append(f"missing_required_file:{name}:{p}")

checks = {
    "kustomization_references": False,
    "migration_job_kind": False,
    "ledger_waits_for_migration": False,
    "executor_waits_for_migration": False,
    "secrets_kind_secret": False,
}

if required_files["kustomization"].exists():
    k = yaml.safe_load(required_files["kustomization"].read_text(encoding="utf-8")) or {}
    resources = (k.get("resources") or [])
    want = {"db-migration-job.yaml", "ledger-api-deployment.yaml", "executor-worker-deployment.yaml", "secrets-bootstrap.yaml"}
    checks["kustomization_references"] = want.issubset(set(resources))
    if not checks["kustomization_references"]:
        errors.append("kustomization_missing_required_resources")

if required_files["migration_job"].exists():
    docs = [d for d in yaml.safe_load_all(required_files["migration_job"].read_text(encoding="utf-8")) if isinstance(d, dict)]
    checks["migration_job_kind"] = any(str(d.get("kind", "")) == "Job" for d in docs)
    if not checks["migration_job_kind"]:
        errors.append("db_migration_job_not_job_kind")

for dep_name, check_name in [("ledger_api", "ledger_waits_for_migration"), ("executor_worker", "executor_waits_for_migration")]:
    p = required_files[dep_name]
    if not p.exists():
        continue
    d = yaml.safe_load(p.read_text(encoding="utf-8")) or {}
    spec = (((d.get("spec") or {}).get("template") or {}).get("spec") or {})
    init = spec.get("initContainers") or []
    found = False
    for c in init:
        cmd = " ".join(c.get("command") or [])
        if "db-migration-job" in cmd:
            found = True
            break
    checks[check_name] = found
    if not found:
        errors.append(f"{dep_name}_missing_wait_for_db_migration_job")

if required_files["secrets_bootstrap"].exists():
    docs = [d for d in yaml.safe_load_all(required_files["secrets_bootstrap"].read_text(encoding="utf-8")) if isinstance(d, dict)]
    checks["secrets_kind_secret"] = any(str(d.get("kind", "")) == "Secret" for d in docs)
    if not checks["secrets_kind_secret"]:
        errors.append("secrets_bootstrap_not_secret_kind")

payload = {
    "check_id": "TSK-P1-203-VERIFY",
    "timestamp_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "git_sha": subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip(),
    "task_id": "TSK-P1-203",
    "status": "PASS" if not errors else "FAIL",
    "pass": len(errors) == 0,
    "required_files": {k: str(v.relative_to(root)) for k, v in required_files.items()},
    "checks": checks,
    "errors": errors,
}
out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
if errors:
    raise SystemExit(1)
print(f"evidence_written:{out}")
PY

python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task TSK-P1-203 --evidence "$ROOT_DIR/$EVIDENCE_PATH"
