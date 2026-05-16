#!/usr/bin/env bash
# Verifier for TSK-P3-CLEAN-003: Add doctrine references to Phase 3 invariant register
# Acceptance criteria:
#   [ID tsk_p3_clean_003_work_01] Every invariant has at least one doctrine reference
#   [ID tsk_p3_clean_003_work_02] No invariant is promoted to implemented without evidence
#   [ID tsk_p3_clean_003_work_03] All doctrine citations resolve to existing canonical files

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTER="$ROOT/docs/PHASE3/PHASE3_INVARIANT_REGISTER.md"
EVIDENCE_DIR="$ROOT/evidence/phase3"
EVIDENCE_PATH="$EVIDENCE_DIR/tsk_p3_clean_003.json"
TASK_ID="TSK-P3-CLEAN-003"
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

# Python script to validate the markdown tables
VALIDATION_RESULT=$(python3 -c "
import re
import sys
from pathlib import Path

register_path = Path('$REGISTER')
if not register_path.exists():
    print('FAIL_FILE:PHASE3_INVARIANT_REGISTER.md missing')
    sys.exit(0)

content = register_path.read_text()
invariants = ['INV-301', 'INV-302', 'INV-303', 'INV-304', 'INV-305', 'INV-306', 'INV-307', 'INV-308', 'INV-309', 'INV-310']

issues = []

for inv in invariants:
    # Find the section for this invariant
    match = re.search(r'### ' + inv + r'.*?(?=### INV|\Z)', content, re.DOTALL)
    if not match:
        issues.append(f'{inv}_missing')
        continue
    
    section = match.group(0)
    
    # Check status
    status_match = re.search(r'\|\s*Status\s*\|\s*(.*?)\s*\|', section)
    if not status_match:
        issues.append(f'{inv}_no_status')
    elif status_match.group(1).lower() != 'roadmap':
        issues.append(f'{inv}_status_changed_{status_match.group(1)}')
        
    # Check doctrine references
    doctrine_match = re.search(r'\|\s*Governing Doctrine\s*\|\s*(.*?)\s*\|', section)
    if not doctrine_match:
        issues.append(f'{inv}_no_doctrine')
    else:
        doctrine_val = doctrine_match.group(1)
        # Extract files cited in markdown links or plain text
        # Assuming format like [NAME](docs/constitutional/...) or just docs/constitutional/...
        paths = re.findall(r'(?:\]\()?docs/constitutional/[A-Za-z0-9_.-]+', doctrine_val)
        if not paths:
            issues.append(f'{inv}_invalid_doctrine_format')
        else:
            for p in paths:
                p_clean = p.replace('](', '').replace(')', '')
                if not (Path('$ROOT') / p_clean).exists():
                    issues.append(f'{inv}_doctrine_file_missing_{p_clean}')

if not issues:
    print('PASS_ALL')
else:
    print('FAIL_ISSUES:' + ';'.join(issues))
" 2>&1)

if [[ "$VALIDATION_RESULT" == PASS_ALL* ]]; then
  add_check "doctrine_citations" "PASS" "All 10 invariants have valid doctrine citations and honest status"
else
  add_check "doctrine_citations" "FAIL" "${VALIDATION_RESULT#FAIL_ISSUES:}"
fi

# Compute observed hashes
HASH=$(sha256sum "$REGISTER" | awk '{print $1}')

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
    'observed_paths': ['docs/PHASE3/PHASE3_INVARIANT_REGISTER.md'],
    'observed_hashes': {'docs/PHASE3/PHASE3_INVARIANT_REGISTER.md': '$HASH'}
}
print(json.dumps(evidence, indent=2))
" "$CHECKS" > "$EVIDENCE_PATH"

echo "$STATUS"
if [ "$STATUS" = "FAIL" ]; then
  exit 1
fi
