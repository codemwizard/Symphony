#!/usr/bin/env bash
# clear_drd_lockout_privileged.sh — ENF-005 privileged lockout clear wrapper
#
# This script is the ONLY path that may delete the DRD lockout file.
# It must be invoked via sudo (see sudoers entry in ENF-005/EXEC_LOG.md).
# Calling rm on drd_lockout.env directly is a bypass and will be caught
# by verify_enf_005.sh.
#
# Usage: sudo scripts/audit/clear_drd_lockout_privileged.sh
#
# Exit 0 = cleared successfully
# Exit 1 = lockout file not present, or log write failed
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DRD_LOCKOUT_FILE="$ROOT/.toolchain/pre_ci_debug/drd_lockout.env"
CLEAR_LOG="$ROOT/.toolchain/evidence_ack/reset_log.jsonl"
CLEARED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
CALLER="${SUDO_USER:-${USER:-unknown}}"
EXECUTOR="${USER:-unknown}"

if [[ ! -f "$DRD_LOCKOUT_FILE" ]]; then
    echo "ENF-005: drd_lockout.env not present — nothing to clear." >&2
    exit 1
fi

mkdir -p "$(dirname "$CLEAR_LOG")"

python3 - <<PY
import json, os
from pathlib import Path

log_path = Path("$CLEAR_LOG")
entry = {
    "action": "drd_lockout_cleared",
    "cleared_by": "$CALLER",
    "cleared_as": "$EXECUTOR",
    "cleared_at": "$CLEARED_AT",
    "lockout_file": "$DRD_LOCKOUT_FILE",
    "method": "clear_drd_lockout_privileged.sh",
}
with log_path.open("a", encoding="utf-8") as f:
    f.write(json.dumps(entry) + "\n")
print(f"ENF-005: audit entry written to {log_path}")
PY

rm "$DRD_LOCKOUT_FILE"

echo "ENF-005: drd_lockout.env cleared."
echo "  Cleared by: $CALLER (executed as $EXECUTOR)"
echo "  Cleared at: $CLEARED_AT"
echo "  Log entry : $CLEAR_LOG"
