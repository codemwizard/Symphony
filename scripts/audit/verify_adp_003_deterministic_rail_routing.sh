#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-ADP-003"
EVIDENCE_PATH="evidence/phase1/adp_003_deterministic_rail_routing.json"
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
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-deterministic-rail-routing >/dev/null

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
    raise SystemExit("deterministic_rail_routing_evidence_not_pass")

details = payload.get("details") or {}
routing_table = details.get("routing_table") or {}
tested_rail_types = details.get("tested_rail_types") or []
unknown_ok = details.get("unknown_type_exception_confirmed") is True

if not routing_table:
    raise SystemExit("routing_table_missing")
if set(tested_rail_types) != set(routing_table.keys()):
    raise SystemExit("tested_rail_types_mismatch")
if not details.get("deterministic_routing_confirmed"):
    raise SystemExit("deterministic_routing_not_confirmed")
if not unknown_ok:
    raise SystemExit("unknown_type_fail_closed_not_confirmed")

checks = details.get("checks") or []
if not checks:
    raise SystemExit("routing_checks_missing")

print(f"Evidence written: {p}")
PY
