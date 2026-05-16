#!/usr/bin/env bash
# Verifier for TSK-P3-CLEAN-005: Resolve non-canonical MADD/MAIN duplicate doctrine
# Acceptance criteria:
#   [ID tsk_p3_clean_005_work_01] Duplicate is archived or removed from docs/constitutional
#   [ID tsk_p3_clean_005_work_02] Duplicate is marked non-canonical / DO-NOT-INGEST
#   [ID tsk_p3_clean_005_work_03] Canonical target remains clear

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT/evidence/phase3"
EVIDENCE_PATH="$EVIDENCE_DIR/tsk_p3_clean_005.json"
TASK_ID="TSK-P3-CLEAN-005"
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

# Test 1: Check it's removed from constitutional docs
if [ -f "$ROOT/docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE-2.md" ]; then
  add_check "removed_from_constitutional" "FAIL" "Duplicate still exists in docs/constitutional/"
else
  add_check "removed_from_constitutional" "PASS" "Duplicate removed from docs/constitutional/"
fi

# Test 2: Check canonical file still exists
if [ -f "$ROOT/docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE.md" ]; then
  add_check "canonical_exists" "PASS" "Canonical MADD_MAIN_INTEGRATION_DOCTRINE.md exists"
else
  add_check "canonical_exists" "FAIL" "Canonical file missing"
fi

# Test 3: Check it was archived and marked DO-NOT-INGEST
ARCHIVED_PATH="$ROOT/docs/archive/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE-2_ARCHIVED.md"
if [ -f "$ARCHIVED_PATH" ]; then
  if grep -q "DO-NOT-INGEST" "$ARCHIVED_PATH"; then
    add_check "archived_and_marked" "PASS" "Duplicate archived and marked DO-NOT-INGEST"
  else
    add_check "archived_and_marked" "FAIL" "Archived file exists but not marked DO-NOT-INGEST"
  fi
else
  add_check "archived_and_marked" "FAIL" "Archive target missing"
fi

# We assume if the previous checks passed, it's valid.

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
    'observed_paths': ['docs/archive/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE-2_ARCHIVED.md'],
    'observed_hashes': {}
}
print(json.dumps(evidence, indent=2))
" "$CHECKS" > "$EVIDENCE_PATH"

echo "$STATUS"
if [ "$STATUS" = "FAIL" ]; then
  exit 1
fi
