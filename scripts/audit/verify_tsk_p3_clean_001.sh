#!/usr/bin/env bash
# Verifier for TSK-P3-CLEAN-001: Repair Phase 3 contract YAML parse defect
# Acceptance criteria:
#   [ID tsk_p3_clean_001_work_01] phase3_contract.yml parses as valid YAML
#   [ID tsk_p3_clean_001_work_02] P3-004 row fields are semantically intact
#   [ID tsk_p3_clean_001_work_03] No execution-claim language is present
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTRACT="$ROOT/docs/PHASE3/phase3_contract.yml"
EVIDENCE_DIR="$ROOT/evidence/phase3"
EVIDENCE_PATH="$EVIDENCE_DIR/tsk_p3_clean_001.json"
TASK_ID="TSK-P3-CLEAN-001"
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

# Check 1: YAML parse (tsk_p3_clean_001_work_01)
if python3 -c "import yaml; yaml.safe_load(open('$CONTRACT'))" 2>/dev/null; then
  add_check "yaml_parse" "PASS" "phase3_contract.yml parses as valid YAML"
else
  add_check "yaml_parse" "FAIL" "phase3_contract.yml YAML parse failed"
fi

# Check 2: P3-004 row integrity (tsk_p3_clean_001_work_02)
P3_004_CHECK=$(python3 -c "
import yaml, json
with open('$CONTRACT') as f:
    data = yaml.safe_load(f)
rows = {r['id']: r for r in data.get('rows', [])}
if 'P3-004' not in rows:
    print('MISSING')
else:
    r = rows['P3-004']
    checks = []
    if r.get('title') == 'Failure Composition Engine':
        checks.append('title_ok')
    else:
        checks.append('title_MISMATCH')
    if r.get('status') == 'planned':
        checks.append('status_ok')
    else:
        checks.append('status_MISMATCH')
    if 'INV-306' in r.get('invariants', []) and 'INV-305' in r.get('invariants', []):
        checks.append('invariants_ok')
    else:
        checks.append('invariants_MISMATCH')
    if r.get('phase_scope') == 'PHASE-3':
        checks.append('phase_scope_ok')
    else:
        checks.append('phase_scope_MISMATCH')
    result = 'PASS' if all('ok' in c for c in checks) else 'FAIL'
    print(f'{result}:{\";\".join(checks)}')
" 2>&1)

if [[ "$P3_004_CHECK" == PASS:* ]]; then
  add_check "p3_004_integrity" "PASS" "${P3_004_CHECK#PASS:}"
else
  add_check "p3_004_integrity" "FAIL" "$P3_004_CHECK"
fi

# Check 3: No execution-claim language (tsk_p3_clean_001_work_03)
BANNED_PHRASES=("executable" "implementation ready" "Phase 3 open" "Phase 3 active")
FOUND_BANNED=""
for phrase in "${BANNED_PHRASES[@]}"; do
  if grep -qi "$phrase" "$CONTRACT" 2>/dev/null; then
    FOUND_BANNED="$FOUND_BANNED;$phrase"
  fi
done

if [ -z "$FOUND_BANNED" ]; then
  add_check "no_execution_claims" "PASS" "No banned execution-claim phrases found"
else
  add_check "no_execution_claims" "FAIL" "Found banned phrases:$FOUND_BANNED"
fi

# Check 4: UTF-8 encoding
FILE_TYPE=$(file "$CONTRACT")
if echo "$FILE_TYPE" | grep -qi "utf-8\|ASCII"; then
  add_check "utf8_encoding" "PASS" "$FILE_TYPE"
else
  add_check "utf8_encoding" "FAIL" "Not UTF-8: $FILE_TYPE"
fi

# Check 5: Row count preserved
ROW_COUNT=$(python3 -c "
import yaml
with open('$CONTRACT') as f:
    data = yaml.safe_load(f)
print(len(data.get('rows', [])))
" 2>/dev/null || echo "0")

if [ "$ROW_COUNT" -eq 9 ]; then
  add_check "row_count" "PASS" "9 rows preserved"
else
  add_check "row_count" "FAIL" "Expected 9 rows, found $ROW_COUNT"
fi

# Compute observed hashes
HASH=$(sha256sum "$CONTRACT" | awk '{print $1}')

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
    'observed_paths': ['docs/PHASE3/phase3_contract.yml'],
    'observed_hashes': {'docs/PHASE3/phase3_contract.yml': '$HASH'}
}
print(json.dumps(evidence, indent=2))
" "$CHECKS" > "$EVIDENCE_PATH"

echo "$STATUS"
if [ "$STATUS" = "FAIL" ]; then
  exit 1
fi
