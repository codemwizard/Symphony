#!/usr/bin/env bash
# Verifier for TSK-P3-CLEAN-002: Rewrite Phase 3 README planning posture
# Acceptance criteria:
#   [ID tsk_p3_clean_002_work_01] No stale external-trust-surface phrases remain
#   [ID tsk_p3_clean_002_work_02] Canonical references are present
#   [ID tsk_p3_clean_002_work_03] No execution claims
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
README="$ROOT/docs/PHASE3/README.md"
EVIDENCE_DIR="$ROOT/evidence/phase3"
EVIDENCE_PATH="$EVIDENCE_DIR/tsk_p3_clean_002.json"
TASK_ID="TSK-P3-CLEAN-002"
GIT_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
STATUS="PASS"
CHECKS="[]"

add_check() {
  local name="$1" result="$2" detail="${3:-}"
  CHECKS=$(python3 -c "
import json, sys
checks = json.loads(sys.argv[1])
checks.append({'name': sys.argv[2], 'result': sys.argv[3], 'detail': sys.argv[4]})
print(json.dumps(checks))
" "$CHECKS" "$name" "$result" "$detail")
  if [ "$result" = "FAIL" ]; then
    STATUS="FAIL"
  fi
}

# Negative tests (first)
# We test these by asserting what should NOT be there.
# [N1] Check that old external-trust-surface wording is gone
if grep -qi "external trust surface" "$README" 2>/dev/null; then
  add_check "no_stale_language" "FAIL" "Found 'external trust surface' language"
else
  add_check "no_stale_language" "PASS" "No stale language found"
fi

# [N2] Check that execution claims are not present
BANNED_PHRASES=("executable" "implementation ready" "Phase 3 open" "Phase 3 active")
FOUND_BANNED=""
for phrase in "${BANNED_PHRASES[@]}"; do
  if grep -qi "$phrase" "$README" 2>/dev/null; then
    FOUND_BANNED="$FOUND_BANNED;$phrase"
  fi
done

if [ -z "$FOUND_BANNED" ]; then
  add_check "no_execution_claims" "PASS" "No banned execution-claim phrases found"
else
  add_check "no_execution_claims" "FAIL" "Found banned phrases:$FOUND_BANNED"
fi

# Positive tests
# [P1] Check canonical references
REQUIRED_REFS=(
  "PHASE3_SOURCE_PACK.md"
  "PHASE3_CAPABILITY_BOUNDARY.md"
  "PHASE3_TASK_DAG.md"
  "PHASE3_MASTER_IMPLEMENTATION_PLAN.md"
)
MISSING_REFS=""
for ref in "${REQUIRED_REFS[@]}"; do
  if ! grep -q "$ref" "$README" 2>/dev/null; then
    MISSING_REFS="$MISSING_REFS;$ref"
  fi
done

if [ -z "$MISSING_REFS" ]; then
  add_check "canonical_references" "PASS" "All required references are present"
else
  add_check "canonical_references" "FAIL" "Missing references:$MISSING_REFS"
fi

# [P2] Planning posture statement
if grep -qi "planning posture" "$README" 2>/dev/null; then
  add_check "planning_posture" "PASS" "Planning posture language found"
else
  add_check "planning_posture" "FAIL" "Missing 'planning posture' phrase"
fi

# Compute observed hashes
HASH=$(sha256sum "$README" | awk '{print $1}')

# Emit evidence
mkdir -p "$EVIDENCE_DIR"
python3 -c "
import json, sys
evidence = {
    'task_id': '$TASK_ID',
    'git_sha': '$GIT_SHA',
    'timestamp_utc': '$TIMESTAMP',
    'status': '$STATUS',
    'checks': json.loads(sys.argv[1]),
    'observed_paths': ['docs/PHASE3/README.md'],
    'observed_hashes': {'docs/PHASE3/README.md': '$HASH'}
}
print(json.dumps(evidence, indent=2))
" "$CHECKS" > "$EVIDENCE_PATH"

echo "$STATUS"
if [ "$STATUS" = "FAIL" ]; then
  exit 1
fi
