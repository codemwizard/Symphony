#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-ADP-001"
EVIDENCE_PATH="evidence/phase1/adp_001_adapter_contract_tests.json"
PROJECT="services/executor-worker/dotnet/src/ExecutorWorker/ExecutorWorker.csproj"

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
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-adapter-contract >/dev/null

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
    raise SystemExit("adapter_contract_tests_not_pass")

details = payload.get("details") or {}
methods = details.get("methods") or []
if methods != ["submit", "query_status", "cancel"]:
    raise SystemExit("adapter_methods_mismatch")

tests = details.get("contract_tests") or []
if not tests:
    raise SystemExit("adapter_contract_tests_missing")

print(f"Evidence written: {p}")
PY
