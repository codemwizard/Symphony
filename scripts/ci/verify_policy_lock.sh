#!/usr/bin/env bash
set -euo pipefail

LOCK_FILE=".policy.lock"
SUBMODULE_DIR=".policies"

test -f "$LOCK_FILE" || { echo "❌ $LOCK_FILE missing"; exit 1; }
test -d "$SUBMODULE_DIR" || { echo "❌ $SUBMODULE_DIR missing (submodule not initialized?)"; exit 1; }

# Extract commit, assuming format "commit: <hash>"
LOCKED_COMMIT="$(grep -E '^commit:' "$LOCK_FILE" | awk '{print $2}' | tr -d '[:space:]')"
test -n "$LOCKED_COMMIT" || { echo "❌ No commit found in $LOCK_FILE"; exit 1; }

ACTUAL_COMMIT="$(cd "$SUBMODULE_DIR" && git rev-parse HEAD | tr -d '[:space:]')"

if [[ "$LOCKED_COMMIT" != "$ACTUAL_COMMIT" ]]; then
  echo "❌ Policy commit mismatch"
  echo "Locked: $LOCKED_COMMIT"
  echo "Actual: $ACTUAL_COMMIT"
  echo ""
  echo "Fix: update submodule pointer + .policy.lock together via approved governance process."
  exit 1
fi

echo "✅ Policy lock verified: $LOCKED_COMMIT"
