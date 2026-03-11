#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-002"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_002_sms_secure_link.json}"
PROJECT="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj"

dotnet build "$PROJECT" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-evidence-link-issuance >/dev/null

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json
import sys
from pathlib import Path

task_id, evidence_path = sys.argv[1:]
p = Path(evidence_path)
if not p.exists():
    raise SystemExit(f"missing_evidence:{p}")

payload = json.loads(p.read_text(encoding="utf-8"))
if payload.get("task_id") != task_id:
    raise SystemExit(f"task_id_mismatch:{payload.get('task_id')}")
if str(payload.get("status", "")).upper() != "PASS" and payload.get("pass") is not True:
    raise SystemExit("secure_link_evidence_not_pass")

details = payload.get("details") or {}
if details.get("sms_dispatch_seam") != "SIMULATED_DISPATCHED":
    raise SystemExit("sms_dispatch_seam_missing")

tests = details.get("tests") or []
required = {
    "issue_secure_link",
    "submit_with_valid_token",
    "submit_with_tampered_token_rejected",
    "submit_with_expired_token_rejected",
}
status = {row.get("name"): row.get("status") for row in tests}
for name in required:
    if status.get(name) != "PASS":
        raise SystemExit(f"test_failed:{name}:{status.get(name)}")

print(f"Evidence written: {p}")
PY

