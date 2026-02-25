#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-ADP-002"
EVIDENCE_PATH="evidence/phase1/adp_002_simulated_rail_adapter.json"
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
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-simulated-rail-adapter >/dev/null

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
    raise SystemExit("simulated_rail_adapter_evidence_not_pass")

details = payload.get("details") or {}
scenarios = details.get("scenarios_tested") or []
required = {
    "SIMULATE_SUCCESS",
    "SIMULATE_TRANSIENT_FAILURE",
    "SIMULATE_PERMANENT_FAILURE",
    "SIMULATE_CANCEL_SUCCESS",
    "SIMULATE_CANCEL_TOO_LATE",
}
if set(scenarios) != required:
    raise SystemExit("scenario_coverage_mismatch")

checks = details.get("checks") or []
if not checks:
    raise SystemExit("scenario_checks_missing")

print(f"Evidence written: {p}")
PY
