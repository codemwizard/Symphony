#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-TEN-003"
EVIDENCE_PATH="evidence/phase1/ten_003_tenant_onboarding_admin.json"
PROJECT="services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj"

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

export SYMPHONY_ENV="${SYMPHONY_ENV:-development}"

dotnet build "$PROJECT" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-tenant-onboarding-admin >/dev/null

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH"
import json
import sys
from pathlib import Path

task_id, path = sys.argv[1:]
p = Path(path)
if not p.exists():
    raise SystemExit(f"missing_evidence:{p}")

payload = json.loads(p.read_text(encoding="utf-8"))
if payload.get("task_id") != task_id:
    raise SystemExit(f"task_id_mismatch:{payload.get('task_id')}")

if str(payload.get("status", "")).upper() != "PASS" and payload.get("pass") is not True:
    raise SystemExit("tenant_onboarding_admin_evidence_not_pass")

required_true = (
    payload.get("tenant_created"),
    payload.get("outbox_event_emitted"),
    payload.get("idempotency_confirmed"),
    payload.get("non_admin_rejected"),
)
if not all(bool(x) for x in required_true):
    raise SystemExit("tenant_onboarding_admin_assertions_failed")

print(f"Evidence written: {p}")
PY
