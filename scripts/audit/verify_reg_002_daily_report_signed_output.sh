#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-REG-002"
EVIDENCE_PATH="evidence/phase1/reg_002_daily_report_signed_output.json"
PROJECT="services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence) EVIDENCE_PATH="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

dotnet build "$PROJECT" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-reg-daily-report >/dev/null

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json,sys
from pathlib import Path

task_id, path = sys.argv[1:]
p = Path(path)
if not p.exists():
    raise SystemExit(f"missing_evidence:{p}")

d = json.loads(p.read_text(encoding="utf-8"))
if d.get("task_id") != task_id:
    raise SystemExit("task_id_mismatch")
if str(d.get("status", "")).upper() != "PASS" and d.get("pass") is not True:
    raise SystemExit("status_not_pass")
for k in ["report_generated", "signature_verified", "determinism_confirmed"]:
    if d.get(k) is not True:
        raise SystemExit(f"field_not_true:{k}")
print(f"Evidence written: {p}")
PY
