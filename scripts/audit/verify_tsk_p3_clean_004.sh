#!/usr/bin/env bash
# Verifier for TSK-P3-CLEAN-004: Reconcile Phase 3 opening posture with execution envelope
# Acceptance criteria:
#   [ID tsk_p3_clean_004_work_01] Document the conflict
#   [ID tsk_p3_clean_004_work_02] Record resolution (RESOLVED, DEFERRED, or ESCALATED)
#   [ID tsk_p3_clean_004_work_03] Confirm envelope authority (no executable claims)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OPENING_ACT="$ROOT/docs/PHASE3/PHASE3_OPENING_ACT.md"
EVIDENCE_DIR="$ROOT/evidence/phase3"
EVIDENCE_PATH="$EVIDENCE_DIR/tsk_p3_clean_004.json"
TASK_ID="TSK-P3-CLEAN-004"
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

# Positive test 1 & 2: Conflict explicitly recorded and resolved/deferred/escalated
VALIDATION_RESULT=$(python3 -c "
import re, sys
content = open('$OPENING_ACT').read()

conflict_section = re.search(r'## Execution Envelope Conflict.*?---', content, re.DOTALL | re.IGNORECASE)
if not conflict_section:
    print('FAIL:Missing Execution Envelope Conflict section')
    sys.exit(0)

section_text = conflict_section.group(0)

has_resolution = 'RESOLVED' in section_text or 'DEFERRED' in section_text or 'ESCALATED' in section_text
if not has_resolution:
    print('FAIL:No explicit outcome (RESOLVED, DEFERRED, or ESCALATED) recorded')
    sys.exit(0)

print('PASS:Conflict explicitly documented and resolution recorded')
" 2>&1)

if [[ "$VALIDATION_RESULT" == PASS:* ]]; then
  add_check "conflict_resolution_documented" "PASS" "${VALIDATION_RESULT#PASS:}"
else
  add_check "conflict_resolution_documented" "FAIL" "${VALIDATION_RESULT#FAIL:}"
fi

# Positive test 3 / Negative test: Confirm envelope authority (no executable status claims)
ENVELOPE_AUTHORITY_CHECK=$(python3 -c "
import re, sys
content = open('$OPENING_ACT').read()

conflict_section = re.search(r'## Execution Envelope Conflict.*?---', content, re.DOTALL | re.IGNORECASE)
if conflict_section:
    section_text = conflict_section.group(0)
    if 'PHASE_EXECUTION_ENVELOPE.md' not in section_text:
        print('FAIL:Conflict section missing reference to PHASE_EXECUTION_ENVELOPE.md')
        sys.exit(0)

# The document MUST NOT contain 'admitted into planning and execution' anymore
if 'admitted into planning and execution' in content:
    print('FAIL:Document contains banned phrase \"admitted into planning and execution\"')
    sys.exit(0)

print('PASS:Envelope authority confirmed and execution-ready claims removed')
" 2>&1)

if [[ "$ENVELOPE_AUTHORITY_CHECK" == PASS:* ]]; then
  add_check "envelope_authority" "PASS" "${ENVELOPE_AUTHORITY_CHECK#PASS:}"
else
  add_check "envelope_authority" "FAIL" "${ENVELOPE_AUTHORITY_CHECK#FAIL:}"
fi

# Compute observed hashes
HASH=$(sha256sum "$OPENING_ACT" | awk '{print $1}')

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
    'observed_paths': ['docs/PHASE3/PHASE3_OPENING_ACT.md'],
    'observed_hashes': {'docs/PHASE3/PHASE3_OPENING_ACT.md': '$HASH'}
}
print(json.dumps(evidence, indent=2))
" "$CHECKS" > "$EVIDENCE_PATH"

echo "$STATUS"
if [ "$STATUS" = "FAIL" ]; then
  exit 1
fi
