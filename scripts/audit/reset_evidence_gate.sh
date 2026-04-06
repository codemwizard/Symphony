#!/usr/bin/env bash
# reset_evidence_gate.sh
# TARGET: scripts/audit/reset_evidence_gate.sh
#
# PURPOSE:
#   Performs a controlled reset of the evidence ack gate for a given TASK_ID.
#   Writes an audit log entry BEFORE deleting any files so the reset is always
#   traceable. Replaces manual rm of .toolchain/evidence_ack/ files.
#
# EXIT CODES:
#   0  -- reset successful (or no state to reset)
#   1  -- TASK_ID not provided or gate files not found
#   2  -- usage error
#
# USAGE:
#   bash scripts/audit/reset_evidence_gate.sh <TASK_ID>
#   bash scripts/audit/reset_evidence_gate.sh --help
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: $0 <TASK_ID>"
  echo ""
  echo "  Resets the evidence ack gate for TASK_ID. Clears:"
  echo "    .toolchain/evidence_ack/<TASK_ID>.required"
  echo "    .toolchain/evidence_ack/<TASK_ID>.retries"
  echo ""
  echo "  Preserves (for audit):"
  echo "    .toolchain/evidence_ack/<TASK_ID>.ack.attempt_*"
  echo ""
  echo "  Writes a log entry to:"
  echo "    .toolchain/evidence_ack/reset_log.jsonl"
  exit 0
fi

TASK_ID="${1:-}"
if [[ -z "$TASK_ID" ]]; then
  echo "ERROR: TASK_ID is required." >&2
  echo "Usage: $0 <TASK_ID>" >&2
  exit 2
fi

ACK_DIR="$ROOT/.toolchain/evidence_ack"
REQUIRED="$ACK_DIR/${TASK_ID}.required"
RETRIES="$ACK_DIR/${TASK_ID}.retries"
RESET_LOG="$ACK_DIR/reset_log.jsonl"

mkdir -p "$ACK_DIR"

# Read current state for the log entry
RETRIES_COUNT=0
if [[ -f "$RETRIES" ]]; then
  RETRIES_COUNT="$(cat "$RETRIES" | tr -d '[:space:]')"
  RETRIES_COUNT="${RETRIES_COUNT:-0}"
fi

REQUIRED_EXISTS=false
[[ -f "$REQUIRED" ]] && REQUIRED_EXISTS=true

if [[ "$REQUIRED_EXISTS" == "false" && "$RETRIES_COUNT" -eq 0 ]]; then
  echo "No evidence gate state found for task: $TASK_ID"
  echo "Nothing to reset."
  exit 0
fi

RESET_AT="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
RESET_BY="${USER:-unknown}"

# Write audit log entry BEFORE deleting anything
python3 - "$RESET_LOG" "$TASK_ID" "$RETRIES_COUNT" \
           "$RESET_AT" "$GIT_SHA" "$RESET_BY" "$REQUIRED_EXISTS" <<'PY'
import json
import sys
from pathlib import Path

log_path     = Path(sys.argv[1])
task_id      = sys.argv[2]
retries      = sys.argv[3]
reset_at     = sys.argv[4]
git_sha      = sys.argv[5]
reset_by     = sys.argv[6]
req_existed  = sys.argv[7]

entry = {
    "reset_at": reset_at,
    "git_sha": git_sha,
    "reset_by": reset_by,
    "task_id": task_id,
    "retries_cleared": int(retries),
    "required_file_existed": req_existed == "true",
}

with log_path.open("a", encoding="utf-8") as f:
    f.write(json.dumps(entry) + "\n")

print(f"Audit log entry written to {log_path}")
PY

# Now delete the state files
deleted=()
if [[ -f "$REQUIRED" ]]; then
  rm "$REQUIRED"
  deleted+=("$REQUIRED")
fi
if [[ -f "$RETRIES" ]]; then
  rm "$RETRIES"
  deleted+=("$RETRIES")
fi

echo ""
echo "Evidence gate reset for task: $TASK_ID"
echo "  Retries cleared : $RETRIES_COUNT"
echo "  Files removed   : ${deleted[*]:-none}"
echo "  Log entry at    : $RESET_LOG"
echo ""
echo "Ack files preserved for audit:"
for f in "$ACK_DIR/${TASK_ID}.ack.attempt_"*; do
  [[ -f "$f" ]] && echo "  $f" || true
done
echo ""
echo "You may now re-run: scripts/agent/run_task.sh $TASK_ID"
