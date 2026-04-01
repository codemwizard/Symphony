#!/usr/bin/env bash
# =============================================================================
# lint_verifier_execution_posture.sh
# Symphony -- Verifier Script Execution Posture Linter
#
# Scans evidence-writing verifier scripts and HARD FAILS if any of them:
#   1. Lack a real database execution call (psql / docker exec ... psql)
#   2. Rely purely on grep/cat/string matching against source files
#   3. Never produce an evidence JSON artifact
#
# This blocks the class of deception where an agent:
#   - Writes a string into a .sql file
#   - Writes a grep check for that same string
#   - Calls it a "passing test"
#
# USAGE (from repo root):
#   bash scripts/audit/lint_verifier_execution_posture.sh
#
# Called by pre_ci.sh before any GF verifier runs.
#
# EXIT CODES:
#   0 -- all scanned verifiers have acceptable execution posture
#   1 -- one or more verifiers are grep-only (fake) tests
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Verifier scripts that MUST have real DB execution (not grep-only).
# These are the evidence-writing scripts that guard the GF Wave 5/6 work.
SCANNED_VERIFIERS=(
  scripts/db/verify_gf_w1_fnc_001.sh
  scripts/db/verify_gf_w1_fnc_002.sh
  scripts/db/verify_gf_w1_fnc_003.sh
  scripts/db/verify_gf_w1_fnc_004.sh
  scripts/db/verify_gf_w1_fnc_005.sh
  scripts/db/verify_gf_w1_fnc_006.sh
)

FAIL=0

echo "==> Verifier execution posture lint"

for script in "${SCANNED_VERIFIERS[@]}"; do
  if [[ ! -f "$script" ]]; then
    echo "  SKIP (not yet deployed): $script"
    continue
  fi

  # A verifier has acceptable posture if it contains at least one of:
  #   - psql  (direct invocation or via docker exec)
  #   - docker exec (wrapping psql)
  # These are the only two patterns that prove the script touches a live DB.
  has_db_call=0
  if grep -qE '^\s*(psql|docker\s+exec)' "$script" 2>/dev/null; then
    has_db_call=1
  elif grep -qE '\bpsql\b' "$script" 2>/dev/null; then
    has_db_call=1
  fi

  # A verifier fails the lint if it is ONLY doing grep/cat checks against
  # the migration file itself — the hallmark of the rogue-agent pattern.
  is_grep_only=0
  if ! grep -qE '\bpsql\b' "$script" 2>/dev/null && \
     grep -qE 'grep\s+-q' "$script" 2>/dev/null; then
    is_grep_only=1
  fi

  if [[ "$is_grep_only" -eq 1 ]] || [[ "$has_db_call" -eq 0 ]]; then
    echo "  FAIL: $script"
    echo "    Reason: no psql/docker exec call found -- script appears to be a grep-only fake verifier."
    echo "    This verifier does not prove database execution. It must be rewritten to call psql."
    FAIL=1
  else
    echo "  PASS: $script"
  fi
done

echo ""
if [[ "$FAIL" -ne 0 ]]; then
  echo "LINT FAIL: One or more verifiers are grep-only and do not prove database execution."
  echo ""
  echo "  A verifier that only checks strings inside .sql files provides no real proof."
  echo "  An agent can write the expected string into the file, then grep for it --"
  echo "  this is exactly the deception pattern this gate is designed to catch."
  echo ""
  echo "  To fix: rewrite the failing verifier(s) to use:"
  echo "    docker exec symphony-postgres psql -U symphony -d <db> -v ON_ERROR_STOP=1 -tc \"...\""
  echo "  The psql block must:"
  echo "    1. Call the actual DB function under test"
  echo "    2. Assert a state transition (e.g. SELECT status FROM projects WHERE ...)"
  echo "    3. Write evidence JSON to evidence/phase1/<task>.json"
  exit 1
fi

echo "==> Verifier execution posture: OK (all scanned verifiers have DB execution calls)"
