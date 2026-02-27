#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-LED-003"
EVIDENCE_PATH="evidence/phase1/led_003_canonical_message_model.json"
PROJECT="services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj"
SCHEMA_PATH="schema/messages/canonical_instruction_v1.json"

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

[[ -f "$SCHEMA_PATH" ]] || { echo "missing_schema:$SCHEMA_PATH" >&2; exit 1; }

dotnet build "$PROJECT" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-canonical-message-model >/dev/null

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
    raise SystemExit("canonical_message_model_not_pass")

details = payload.get("details") or {}
if details.get("schema_exists") is not True:
    raise SystemExit("schema_file_missing")

cases = details.get("tests") or []
if len(cases) < 3:
    raise SystemExit("insufficient_test_cases")

status = {}
for c in cases:
    name = c.get("name", c.get("Name"))
    case_status = c.get("status", c.get("Status"))
    if name is not None:
        status[name] = case_status
required = [
    "valid_payload_accepted",
    "missing_required_field_rejected",
    "wrong_type_rejected",
]
for case in required:
    if status.get(case) != "PASS":
        raise SystemExit(f"case_failed:{case}:{status.get(case)}")

print(f"Evidence written: {p}")
PY
