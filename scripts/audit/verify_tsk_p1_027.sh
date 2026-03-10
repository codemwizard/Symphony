#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
TASK_EVIDENCE="$EVIDENCE_DIR/tsk_p1_027_range_only_diff_parity.json"
SOURCE_EVIDENCE="$EVIDENCE_DIR/git_diff_semantics.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export ROOT_DIR TASK_EVIDENCE SOURCE_EVIDENCE EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

bash "$ROOT_DIR/scripts/audit/test_diff_semantics_parity.sh"
bash "$ROOT_DIR/scripts/audit/verify_diff_semantics_parity.sh"

python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
task_evidence = Path(os.environ["TASK_EVIDENCE"])
source = Path(os.environ["SOURCE_EVIDENCE"])
errors = []
summary = {}
if not source.exists():
    errors.append(f"missing_evidence:{source}")
else:
    payload = json.loads(source.read_text(encoding="utf-8"))
    if str(payload.get("status", "")).upper() != "PASS":
        errors.append("git_diff_semantics_not_pass")
    summary = {
        "diff_mode": payload.get("diff_mode"),
        "critical_scripts": len(payload.get("critical_scripts", []) or []),
        "checked_scripts": len(payload.get("checked_scripts", []) or []),
    }
status = "PASS" if not errors else "FAIL"
out = {
    "task_id": "TSK-P1-027",
    "check_id": "TSK-P1-027-RANGE-ONLY-DIFF-PARITY",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "pass": status == "PASS",
    "source_evidence": str(source.relative_to(root)),
    "summary": summary,
    "errors": errors,
}
task_evidence.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if errors:
    raise SystemExit(1)
print(f"TSK-P1-027 verification passed. Evidence: {task_evidence}")
PY
