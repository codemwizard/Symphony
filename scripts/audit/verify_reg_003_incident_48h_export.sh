#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-REG-003"
EVIDENCE_PATH="evidence/phase1/reg_003_incident_48h_export.json"
PROJECT="services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence) EVIDENCE_PATH="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

dotnet build "$PROJECT" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-reg-incident-48h-report >/dev/null

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
for k in [
    "incident_registered",
    "status_updated_under_investigation",
    "report_generated",
    "signature_verified",
    "open_status_report_blocked",
]:
    if d.get(k) is not True:
        raise SystemExit(f"field_not_true:{k}")
print(f"Evidence written: {p}")
PY
