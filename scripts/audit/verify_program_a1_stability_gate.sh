#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
K8S_EVIDENCE="$ROOT_DIR/evidence/phase1/k8s_manifests_validation.json"
SANDBOX_EVIDENCE="$ROOT_DIR/evidence/phase1/sandbox_deploy_dry_run.json"
SCHEMA="$ROOT_DIR/evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json"
OUT="$ROOT_DIR/evidence/phase1/program_a1_stability_gate.json"

ROOT_DIR="$ROOT_DIR" K8S_EVIDENCE="$K8S_EVIDENCE" SANDBOX_EVIDENCE="$SANDBOX_EVIDENCE" SCHEMA="$SCHEMA" OUT="$OUT" python3 - <<'PY'
import json
import os
import subprocess
from pathlib import Path
import jsonschema
from datetime import datetime, timezone

root = Path(os.environ["ROOT_DIR"])
k8s_evidence_path = Path(os.environ["K8S_EVIDENCE"])
sandbox_path = Path(os.environ["SANDBOX_EVIDENCE"])
schema_path = Path(os.environ["SCHEMA"])
out_path = Path(os.environ["OUT"])

required_manifest_files = [
    "infra/sandbox/k8s/namespace.yaml",
    "infra/sandbox/k8s/kustomization.yaml",
    "infra/sandbox/k8s/db-migration-job.yaml",
    "infra/sandbox/k8s/executor-worker-deployment.yaml",
    "infra/sandbox/k8s/ledger-api-deployment.yaml",
]
missing_manifests = [p for p in required_manifest_files if not (root / p).exists()]

errors = []
if missing_manifests:
    errors.append(f"missing_manifest_files:{','.join(missing_manifests)}")

if not k8s_evidence_path.exists():
    errors.append("k8s_manifests_validation_missing")
else:
    k8s = json.loads(k8s_evidence_path.read_text(encoding="utf-8"))
    if not bool(k8s.get("pass")):
        errors.append("k8s_manifests_validation_not_pass")

if not schema_path.exists():
    errors.append("sandbox_schema_missing")

if not sandbox_path.exists():
    errors.append("sandbox_deploy_dry_run_missing")
else:
    sandbox = json.loads(sandbox_path.read_text(encoding="utf-8"))
    if schema_path.exists():
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        try:
            jsonschema.validate(instance=sandbox, schema=schema)
        except Exception as exc:
            errors.append(f"sandbox_schema_validation_failed:{exc}")
    if not bool(sandbox.get("pass")):
        errors.append("sandbox_deploy_dry_run_not_pass")

out = {
    "check_id": "TSK-OPS-A1-STABILITY-GATE",
    "timestamp_utc": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "git_sha": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
    "task_id": "TSK-OPS-A1-STABILITY-GATE",
    "status": "PASS" if not errors else "FAIL",
    "pass": not errors,
    "k8s_manifests_validation_present": k8s_evidence_path.exists(),
    "sandbox_deploy_dry_run_present": sandbox_path.exists(),
    "required_manifest_files_present": len(missing_manifests) == 0,
    "errors": errors,
}
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if errors:
    raise SystemExit(1)
print("Program A1 stability gate: PASS")
print(f"Evidence: {out_path}")
PY
