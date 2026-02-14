#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/sandbox_deploy_manifest_posture.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export ROOT_DIR EVIDENCE_FILE EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

python3 <<'PY'
import json
import os
import sys
from pathlib import Path

try:
    import yaml  # type: ignore
except Exception as exc:
    print(f"pyyaml_missing:{exc}", file=sys.stderr)
    sys.exit(2)

root = Path(os.environ["ROOT_DIR"])
out = Path(os.environ["EVIDENCE_FILE"])

required = [
    root / "infra/sandbox/k8s/kustomization.yaml",
    root / "infra/sandbox/k8s/namespace.yaml",
    root / "infra/sandbox/k8s/ledger-api-deployment.yaml",
    root / "infra/sandbox/k8s/executor-worker-deployment.yaml",
    root / "infra/sandbox/k8s/secrets-bootstrap.yaml",
    root / "infra/openbao/openbao.hcl",
]

failures = []
for p in required:
    if not p.exists():
        failures.append(f"missing_required_file:{p}")


def load_yaml(path: Path):
    return yaml.safe_load(path.read_text(encoding="utf-8"))

for name in ["ledger-api-deployment.yaml", "executor-worker-deployment.yaml"]:
    p = root / "infra/sandbox/k8s" / name
    if not p.exists():
        continue
    data = load_yaml(p) or {}
    spec = ((data.get("spec") or {}).get("template") or {}).get("spec") or {}
    replicas = (data.get("spec") or {}).get("replicas", 0)
    if not isinstance(replicas, int) or replicas < 2:
        failures.append(f"replicas_below_min:{name}:{replicas}")

    tsc = spec.get("topologySpreadConstraints") or []
    if not tsc:
        failures.append(f"missing_topology_spread:{name}")

    affinity = spec.get("affinity") or {}
    anti = (affinity.get("podAntiAffinity") or {}).get("preferredDuringSchedulingIgnoredDuringExecution") or []
    if not anti:
        failures.append(f"missing_pod_anti_affinity:{name}")

    containers = spec.get("containers") or []
    if not containers:
        failures.append(f"missing_containers:{name}")
        continue

    for c in containers:
        sec = c.get("securityContext") or {}
        if sec.get("runAsNonRoot") is not True:
            failures.append(f"run_as_non_root_required:{name}:{c.get('name')}")
        if sec.get("allowPrivilegeEscalation") is not False:
            failures.append(f"allow_privilege_escalation_must_be_false:{name}:{c.get('name')}")
        env_from = c.get("envFrom") or []
        has_secret_ref = any((item.get("secretRef") or {}).get("name") == "symphony-pilot-secrets" for item in env_from)
        if not has_secret_ref:
            failures.append(f"missing_secret_ref:{name}:{c.get('name')}")

for p in (root / "infra/sandbox/k8s").glob("*.yaml"):
    text = p.read_text(encoding="utf-8")
    if "postgres://" in text or "password=" in text.lower():
        failures.append(f"inline_secret_detected:{p}")

status = "PASS" if not failures else "FAIL"
report = {
    "check_id": "PHASE1-SANDBOX-DEPLOY-MANIFEST-POSTURE",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "required_files": [str(p.relative_to(root)) for p in required],
    "verified_redundancy": status == "PASS",
    "failures": failures,
}
out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    print("❌ Sandbox deploy posture verification failed", file=sys.stderr)
    for f in failures:
        print(f" - {f}", file=sys.stderr)
    sys.exit(1)

print(f"Sandbox deploy posture verification passed. Evidence: {out}")
PY
