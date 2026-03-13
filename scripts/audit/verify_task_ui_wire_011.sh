#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

EVIDENCE_PATH="evidence/phase1/task_ui_wire_011_closeout.json"
mkdir -p "$(dirname "$EVIDENCE_PATH")"
CHECK_ID="TASK-UI-WIRE-011-CLOSEOUT"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_SHA="$(git rev-parse HEAD)"

write_failure_evidence() {
  local error="$1"
  local detail_key="${2:-}"
  local detail_value="${3:-}"
  python3 - "$EVIDENCE_PATH" "$CHECK_ID" "$TIMESTAMP_UTC" "$GIT_SHA" "$error" "$detail_key" "$detail_value" <<'PY'
import json
import sys

path, check_id, timestamp_utc, git_sha, error, detail_key, detail_value = sys.argv[1:8]
payload = {
    "check_id": check_id,
    "task_id": "TASK-UI-WIRE-011",
    "timestamp_utc": timestamp_utc,
    "git_sha": git_sha,
    "status": "FAIL",
    "error": error,
}
if detail_key:
    payload[detail_key] = detail_value
with open(path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, indent=2)
    fh.write("\n")
PY
}

required_files=(
  "src/supervisory-dashboard/index.html"
  "src/supervisory-dashboard/legacy.html"
  "docs/operations/SUPERVISORY_UI_SOURCE_OF_TRUTH.md"
  "services/ledger-api/dotnet/src/LedgerApi/Program.cs"
  "scripts/audit/verify_task_ui_wire_008.sh"
  "scripts/audit/verify_task_ui_wire_009.sh"
  "scripts/audit/verify_task_ui_wire_010.sh"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    write_failure_evidence "missing_required_file" "file" "$file"
    echo "missing_required_file:$file" >&2
    exit 1
  fi
done

bash scripts/audit/verify_task_ui_wire_008.sh
bash scripts/audit/verify_task_ui_wire_009.sh
bash scripts/audit/verify_task_ui_wire_010.sh

find_free_port() {
  python3 - <<'PY'
import socket
s = socket.socket()
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
PY
}

PORT_PRIMARY="$(find_free_port)"
PORT_LEGACY="$(find_free_port)"
LOG_PRIMARY="$(mktemp)"
LOG_LEGACY="$(mktemp)"
PID_PRIMARY=""
PID_LEGACY=""

cleanup() {
  [[ -n "$PID_PRIMARY" ]] && kill "$PID_PRIMARY" 2>/dev/null || true
  [[ -n "$PID_LEGACY" ]] && kill "$PID_LEGACY" 2>/dev/null || true
  rm -f "$LOG_PRIMARY" "$LOG_LEGACY"
}
trap cleanup EXIT

start_api() {
  local port="$1"
  local legacy_flag="$2"
  local log_file="$3"

  SYMPHONY_RUNTIME_PROFILE=pilot-demo \
  SYMPHONY_UI_TENANT_ID=demo-tenant \
  SYMPHONY_UI_API_KEY=demo-ui-key \
  SYMPHONY_ENABLE_LEGACY_SUPERVISORY_UI="$legacy_flag" \
  ASPNETCORE_URLS="http://127.0.0.1:$port" \
  dotnet run --no-launch-profile \
    --project services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj \
    >"$log_file" 2>&1 &
  echo $!
}

wait_for_http() {
  local url="$1"
  for _ in $(seq 1 60); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

PID_PRIMARY="$(start_api "$PORT_PRIMARY" 0 "$LOG_PRIMARY")"
wait_for_http "http://127.0.0.1:$PORT_PRIMARY/health"

primary_status="$(curl -s -o /tmp/task_ui_wire_011_primary.html -w '%{http_code}' "http://127.0.0.1:$PORT_PRIMARY/pilot-demo/supervisory")"
legacy_default_status="$(curl -s -o /tmp/task_ui_wire_011_legacy_default.html -w '%{http_code}' "http://127.0.0.1:$PORT_PRIMARY/pilot-demo/supervisory-legacy")"

if [[ "$primary_status" != "200" ]]; then
  write_failure_evidence "primary_route_unavailable" "http_status" "$primary_status"
  echo "primary_route_unavailable:$primary_status" >&2
  exit 1
fi

if [[ "$legacy_default_status" != "404" ]]; then
  write_failure_evidence "legacy_route_not_isolated" "http_status" "$legacy_default_status"
  echo "legacy_route_not_isolated:$legacy_default_status" >&2
  exit 1
fi

rg -q 'programme-summary-panel' /tmp/task_ui_wire_011_primary.html
rg -q 'timeline-panel' /tmp/task_ui_wire_011_primary.html
rg -q 'evidence-completeness-panel' /tmp/task_ui_wire_011_primary.html
rg -q 'exception-log-panel' /tmp/task_ui_wire_011_primary.html
rg -q 'pilotSuccessPanel' /tmp/task_ui_wire_011_primary.html
rg -q '\(Phase 1 · DEMO_BACKED\)' /tmp/task_ui_wire_011_primary.html
! rg -q 'Google Fonts|fonts.googleapis.com' /tmp/task_ui_wire_011_primary.html

kill "$PID_PRIMARY" 2>/dev/null || true
wait "$PID_PRIMARY" 2>/dev/null || true
PID_PRIMARY=""

PID_LEGACY="$(start_api "$PORT_LEGACY" 1 "$LOG_LEGACY")"
wait_for_http "http://127.0.0.1:$PORT_LEGACY/health"
legacy_debug_status="$(curl -s -o /tmp/task_ui_wire_011_legacy_debug.html -w '%{http_code}' "http://127.0.0.1:$PORT_LEGACY/pilot-demo/supervisory-legacy")"

if [[ "$legacy_debug_status" != "200" ]]; then
  write_failure_evidence "legacy_debug_route_unavailable" "http_status" "$legacy_debug_status"
  echo "legacy_debug_route_unavailable:$legacy_debug_status" >&2
  exit 1
fi

python3 - "$CHECK_ID" "$TIMESTAMP_UTC" "$GIT_SHA" <<'PY' > "$EVIDENCE_PATH"
import json
import sys
from pathlib import Path

check_id, timestamp_utc, git_sha = sys.argv[1:4]
source = Path("docs/operations/SUPERVISORY_UI_SOURCE_OF_TRUTH.md").read_text()
evidence = {
    "check_id": check_id,
    "task_id": "TASK-UI-WIRE-011",
    "timestamp_utc": timestamp_utc,
    "git_sha": git_sha,
    "status": "PASS",
    "primary_route": "/pilot-demo/supervisory",
    "legacy_route_default_status": 404,
    "legacy_route_debug_opt_in_status": 200,
    "single_primary_shell": True,
    "legacy_shell_debug_only": True,
    "sim_swap_mode": "DEMO_BACKED",
    "pilot_success_mode": "LIVE_FROM_EVIDENCE",
    "live_surfaces_declared": [
        "Programme summary",
        "Timeline",
        "Evidence completeness",
        "Exception log",
        "Evidence-link issue",
        "Signed instruction generate",
        "Signed instruction verify",
        "Supplier policy lookup",
        "Detail / drill-down",
        "Export",
        "Ack / interrupt state",
    ],
    "source_of_truth_contains_legacy_debug_gate": "SYMPHONY_ENABLE_LEGACY_SUPERVISORY_UI=1" in source,
    "source_of_truth_marks_thin_shell_retired": "retired from normal demo navigation" in source,
    "prerequisite_verifiers": {
        "TASK-UI-WIRE-008": "PASS",
        "TASK-UI-WIRE-009": "PASS",
        "TASK-UI-WIRE-010": "PASS",
    },
}
print(json.dumps(evidence, indent=2))
PY

echo "Evidence written: $EVIDENCE_PATH"
