#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
TASK_EVIDENCE="$EVIDENCE_DIR/tsk_p1_025_demo_proof_pack.json"
REGULATOR_OUT="$EVIDENCE_DIR/regulator_demo_pack.json"
TIER1_OUT="$EVIDENCE_DIR/tier1_pilot_demo_pack.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export ROOT_DIR TASK_EVIDENCE REGULATOR_OUT TIER1_OUT EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

bash "$ROOT_DIR/scripts/audit/verify_phase1_demo_proof_pack.sh"

python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
task_evidence = Path(os.environ["TASK_EVIDENCE"])
regulator = Path(os.environ["REGULATOR_OUT"])
tier1 = Path(os.environ["TIER1_OUT"])

errors = []
claims = {}
for name, path in {"regulator_demo_pack": regulator, "tier1_demo_pack": tier1}.items():
    if not path.exists():
        errors.append(f"missing_evidence:{path}")
        continue
    payload = json.loads(path.read_text(encoding="utf-8"))
    if str(payload.get("status", "")).upper() != "PASS":
        errors.append(f"evidence_not_pass:{path}")
    claims[name] = len(payload.get("claims", []) or [])

status = "PASS" if not errors else "FAIL"
out = {
    "task_id": "TSK-P1-025",
    "check_id": "TSK-P1-025-DEMO-PROOF-PACK",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "pass": status == "PASS",
    "artifacts": {
        "regulator_demo_pack": str(regulator.relative_to(root)),
        "tier1_demo_pack": str(tier1.relative_to(root)),
    },
    "claim_counts": claims,
    "errors": errors,
}
task_evidence.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if errors:
    raise SystemExit(1)
print(f"TSK-P1-025 verification passed. Evidence: {task_evidence}")
PY
