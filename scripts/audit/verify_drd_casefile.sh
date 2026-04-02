#!/usr/bin/env bash
# verify_drd_casefile.sh
# TARGET: scripts/audit/verify_drd_casefile.sh
#
# PURPOSE:
#   Verifies that an active DRD lockout has a matching remediation casefile
#   with a documented root cause. Used in two modes:
#
#   Default (no args):
#     Checks whether the current lockout has a valid casefile. Exits 0 if
#     no lockout is active or if the casefile is valid. Exits 1 if the
#     lockout is active but no valid casefile is found.
#
#   --clear:
#     Performs a controlled lockout reset. Verifies the casefile first, then
#     logs the reset to .toolchain/pre_ci_debug/clear_log.jsonl before
#     deleting the lockout file. Refuses to clear without a valid casefile.
#
# EXIT CODES:
#   0  -- no lockout active, or lockout active with valid casefile (verify mode)
#   0  -- cleared successfully (--clear mode)
#   1  -- lockout active, no matching casefile found (verify mode)
#   1  -- casefile invalid, refusing to clear (--clear mode)
#   2  -- usage error
#
# USAGE:
#   bash scripts/audit/verify_drd_casefile.sh
#   bash scripts/audit/verify_drd_casefile.sh --clear
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

MODE="verify"
if [[ "${1:-}" == "--clear" ]]; then
  MODE="clear"
elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: $0 [--clear]"
  echo "  (no args)  Verify lockout has a matching casefile with documented root cause."
  echo "  --clear    Verify then clear the lockout with audit log entry."
  exit 0
elif [[ -n "${1:-}" ]]; then
  echo "ERROR: unknown argument: $1" >&2
  echo "Usage: $0 [--clear]" >&2
  exit 2
fi

DRD_LOCKOUT_FILE="$ROOT/.toolchain/pre_ci_debug/drd_lockout.env"
CLEAR_LOG="$ROOT/.toolchain/pre_ci_debug/clear_log.jsonl"
CASEFILE_GLOB="docs/plans"

# ── No lockout active ─────────────────────────────────────────────────────────
if [[ ! -f "$DRD_LOCKOUT_FILE" ]]; then
  echo "No DRD lockout is active."
  if [[ "$MODE" == "clear" ]]; then
    echo "Nothing to clear."
  fi
  exit 0
fi

# ── Load lockout state ────────────────────────────────────────────────────────
# shellcheck disable=SC1090
source "$DRD_LOCKOUT_FILE"

LOCKED_SIG="${DRD_LOCKED_SIGNATURE:-}"
LOCKED_COUNT="${DRD_LOCKED_COUNT:-?}"
LOCKED_AT="${DRD_LOCKED_AT:-unknown}"

if [[ -z "$LOCKED_SIG" ]]; then
  echo "ERROR: drd_lockout.env is missing DRD_LOCKED_SIGNATURE." >&2
  echo "  The lockout file may be malformed. Inspect: $DRD_LOCKOUT_FILE" >&2
  exit 1
fi

echo "DRD lockout active:"
echo "  Signature : $LOCKED_SIG"
echo "  Count     : $LOCKED_COUNT consecutive failures"
echo "  Locked at : $LOCKED_AT"
echo ""
echo "Searching for matching casefile under $CASEFILE_GLOB ..."

# ── Find matching casefile using yaml.safe_load ───────────────────────────────
# Falls back to regex for legacy casefiles that are not valid YAML.
CASEFILE_RESULT="$(python3 - "$CASEFILE_GLOB" "$LOCKED_SIG" <<'PY'
import os
import re
import sys
import yaml
from pathlib import Path

cases_root = Path(sys.argv[1])
required_sig = sys.argv[2]

found_path = None
found_root_cause = None
found_via = None

plan_files = sorted(cases_root.rglob("PLAN.md"))

for plan in plan_files:
    text = plan.read_text(encoding="utf-8", errors="ignore")

    sig = None
    root_cause = None

    # Primary: attempt yaml.safe_load on the full file
    try:
        data = yaml.safe_load(text)
        if isinstance(data, dict):
            sig = data.get("failure_signature", "")
            root_cause = str(data.get("root_cause", "")).strip()
            found_via = "yaml"
    except Exception:
        pass

    # Fallback: regex for legacy casefiles that are not valid YAML
    if sig is None:
        m = re.search(r"^failure_signature:\s*(.+)$", text, re.MULTILINE)
        if m:
            sig = m.group(1).strip().strip('"').strip("'")
            found_via = "regex"
        rc = re.search(r"^root_cause:\s*(.+)$", text, re.MULTILINE)
        if rc:
            root_cause = rc.group(1).strip().strip('"').strip("'")

    if not sig:
        continue

    if sig != required_sig:
        continue

    found_path = str(plan)
    found_root_cause = root_cause or ""
    break

if found_path is None:
    print(f"NOTFOUND")
else:
    # Output as simple key=value for bash to consume
    print(f"FOUND")
    print(f"CASEFILE={found_path}")
    print(f"VIA={found_via}")
    # Root cause is on its own line; truncate newlines for single-line output
    rc_oneline = (found_root_cause or "").replace("\n", " ").strip()
    print(f"ROOT_CAUSE={rc_oneline}")
PY
)"

# ── Parse result ──────────────────────────────────────────────────────────────
STATUS="$(echo "$CASEFILE_RESULT" | head -1)"

if [[ "$STATUS" == "NOTFOUND" ]]; then
  echo "ERROR: No casefile found for signature: $LOCKED_SIG" >&2
  echo "" >&2
  echo "  Create one with:" >&2
  echo "  ${DRD_SCAFFOLD_CMD:-scripts/audit/new_remediation_casefile.sh ...}" >&2
  exit 1
fi

CASEFILE_PATH="$(echo "$CASEFILE_RESULT" | grep '^CASEFILE=' | cut -d= -f2-)"
CASEFILE_VIA="$(echo "$CASEFILE_RESULT" | grep '^VIA=' | cut -d= -f2-)"
CASEFILE_RC="$(echo "$CASEFILE_RESULT" | grep '^ROOT_CAUSE=' | cut -d= -f2-)"

echo "Casefile found: $CASEFILE_PATH"
if [[ "$CASEFILE_VIA" == "regex" ]]; then
  echo "  (Warning: parsed via regex fallback -- file is not valid YAML)"
fi

# ── Validate root cause is documented ────────────────────────────────────────
# root_cause must be non-empty and not the literal placeholder "pending"
RC_LOWER="$(echo "$CASEFILE_RC" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
if [[ -z "$CASEFILE_RC" || "$RC_LOWER" == "pending" || "$RC_LOWER" == "" ]]; then
  echo "" >&2
  echo "ERROR: Casefile found but root_cause is not documented." >&2
  echo "  File   : $CASEFILE_PATH" >&2
  echo "  Value  : '${CASEFILE_RC:-<empty>}'" >&2
  echo "" >&2
  echo "  Open the PLAN.md and fill in the root_cause field before clearing." >&2
  exit 1
fi

echo "  Root cause: $CASEFILE_RC"
echo "  Casefile is valid."

# ── Verify-only mode: done ────────────────────────────────────────────────────
if [[ "$MODE" == "verify" ]]; then
  echo ""
  echo "Lockout is active but casefile is valid."
  echo "Run with --clear to remove the lockout when ready:"
  echo "  bash scripts/audit/verify_drd_casefile.sh --clear"
  exit 0
fi

# ── Clear mode: log then delete ──────────────────────────────────────────────
mkdir -p "$(dirname "$CLEAR_LOG")"

CLEARED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"

python3 - "$CLEAR_LOG" "$LOCKED_SIG" "$LOCKED_COUNT" "$CLEARED_AT" \
           "$GIT_SHA" "$CASEFILE_PATH" "$CASEFILE_RC" <<'PY'
import json
import sys
from pathlib import Path

log_path  = Path(sys.argv[1])
sig       = sys.argv[2]
count     = sys.argv[3]
cleared   = sys.argv[4]
sha       = sys.argv[5]
casefile  = sys.argv[6]
root_cause = sys.argv[7]

entry = {
    "cleared_at": cleared,
    "git_sha": sha,
    "signature": sig,
    "nonconvergence_count": count,
    "casefile": casefile,
    "root_cause": root_cause,
}

with log_path.open("a", encoding="utf-8") as f:
    f.write(json.dumps(entry) + "\n")

print(f"Logged clear event to {log_path}")
PY

sudo "$(dirname "${BASH_SOURCE[0]}")/clear_drd_lockout_privileged.sh"

echo ""
echo "DRD lockout cleared."
echo "  Signature : $LOCKED_SIG"
echo "  Cleared at: $CLEARED_AT"
echo "  Log entry : $CLEAR_LOG"
echo ""
echo "You may now re-run scripts/dev/pre_ci.sh."
