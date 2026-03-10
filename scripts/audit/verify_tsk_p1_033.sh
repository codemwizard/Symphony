#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
TASK_EVIDENCE="$EVIDENCE_DIR/tsk_p1_033_no_mcp_reintroduction_guard.json"
SOURCE_EVIDENCE="$EVIDENCE_DIR/no_mcp_phase1_guard.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export ROOT_DIR TASK_EVIDENCE SOURCE_EVIDENCE EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

bash "$ROOT_DIR/scripts/audit/verify_no_mcp_phase1.sh"
bash "$ROOT_DIR/scripts/audit/tests/test_no_mcp_phase1_guard.sh"

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
        errors.append("no_mcp_guard_not_pass")
    summary = {
        "forbidden_hits_count": payload.get("forbidden_hits_count"),
        "scan_root": payload.get("scan_root"),
    }
status = "PASS" if not errors else "FAIL"
out = {
    "task_id": "TSK-P1-033",
    "check_id": "TSK-P1-033-NO-MCP-REINTRODUCTION-GUARD",
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
print(f"TSK-P1-033 verification passed. Evidence: {task_evidence}")
PY
