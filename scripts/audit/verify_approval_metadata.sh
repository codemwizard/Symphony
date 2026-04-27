#!/usr/bin/env bash
set -euo pipefail

# --- PRE_CI_CONTEXT_GUARD ---
if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---

MODE="stage-a"
BRANCH=""
PR=""
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode=*)
      MODE="${1#*=}"
      shift
      ;;
    --branch=*)
      BRANCH="${1#*=}"
      shift
      ;;
    --pr=*)
      PR="${1#*=}"
      shift
      ;;
    *)
      echo "ERROR: Unknown argument $1"
      exit 1
      ;;
  esac
done

if [[ "$MODE" == "stage-a" && -z "$BRANCH" ]]; then
  echo "ERROR: --branch is required for stage-a mode"
  exit 1
fi

if [[ "$MODE" == "stage-b" && -z "$PR" ]]; then
  echo "ERROR: --pr is required for stage-b mode"
  exit 1
fi

# Find the approval file
SEARCH_PATTERN=""
if [[ "$MODE" == "stage-a" ]]; then
  SEARCH_PATTERN="BRANCH-${BRANCH}.approval.json"
else
  SEARCH_PATTERN="PR-${PR}.approval.json"
fi

# Look in approvals/ directory, most recent first (by date directory name)
APPROVAL_FILE=$(find "$ROOT/approvals" -name "$SEARCH_PATTERN" | sort -r | head -n 1)

if [[ -z "$APPROVAL_FILE" ]]; then
  echo "ERROR: Approval metadata not found for $MODE ($SEARCH_PATTERN)"
  exit 1
fi

echo "Found approval: $APPROVAL_FILE"

# Basic validation using jq if available, otherwise simple grep
if command -v jq >/dev/null 2>&1; then
  STATUS=$(jq -r '.approval.status' "$APPROVAL_FILE")
  if [[ "$STATUS" != "APPROVED" ]]; then
    echo "ERROR: Approval status is $STATUS, expected APPROVED"
    exit 1
  fi
  echo "Approval status: $STATUS"
else
  if ! grep -q '"status": "APPROVED"' "$APPROVAL_FILE"; then
    echo "ERROR: Approval status is not APPROVED (checked via grep)"
    exit 1
  fi
  echo "Approval status: APPROVED (verified via grep)"
fi

echo "OK: Approval metadata verified for $MODE"
exit 0
