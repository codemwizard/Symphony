#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-TEN-001"
EVIDENCE_PATH="evidence/phase1/ten_001_ingress_tenant_context.json"
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

dotnet build "$PROJECT" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-tenant-context >/dev/null

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
if payload.get("status") != "PASS" and payload.get("pass") is not True:
    raise SystemExit("tenant_context_evidence_not_pass")

details = payload.get("details") or {}
required_true = (
    details.get("missing_tenant_rejected"),
    details.get("unknown_tenant_rejected"),
    details.get("valid_tenant_accepted"),
)
if not all(required_true):
    raise SystemExit("tenant_context_assertions_failed")

print(f"Evidence written: {p}")
PY
