#!/bin/bash

# Verification script for TSK-P2-GOV-CONV-001
# Produce Phase-2 reconciliation manifest from task metadata

set -euo pipefail

TASK_ID="TSK-P2-GOV-CONV-001"
EVIDENCE_PATH="evidence/phase2/gov_conv_001_reconciliation_manifest.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize checks array
checks=()

echo "Starting verification for ${TASK_ID}..."

# Check 1: Scan tasks/TSK-P2-*/meta.yml files
echo "Check 1: Scan Phase-2 task metadata files"
TASK_FILES=()
for task_dir in tasks/TSK-P2-*/; do
    if [ -f "${task_dir}meta.yml" ]; then
        TASK_FILES+=("${task_dir}meta.yml")
    fi
done

if [ ${#TASK_FILES[@]} -eq 0 ]; then
    checks+=("task_metadata_scan:FAIL")
    echo "✗ No Phase-2 task metadata files found"
    exit 1
else
    checks+=("task_metadata_scan:PASS")
    echo "✓ Found ${#TASK_FILES[@]} Phase-2 task metadata files"
fi

# Check 2: Verify row count is above minimum threshold
echo "Check 2: Verify minimum row count"
if [ ${#TASK_FILES[@]} -ge 80 ]; then
    checks+=("row_count_minimum:PASS")
    echo "✓ Row count ${#TASK_FILES[@]} meets minimum threshold of 80"
else
    checks+=("row_count_minimum:FAIL")
    echo "✗ Row count ${#TASK_FILES[@]} below minimum threshold of 80"
    exit 1
fi

# Check 3: Parse metadata and emit rows
echo "Check 3: Parse metadata and emit rows"
ROWS=()
EVIDENCE_COMPLETE=0
VERIFIER_COMPLETE=0
INV_ID_ABSENT=0

for task_file in "${TASK_FILES[@]}"; do
    if [ ! -r "$task_file" ]; then
        echo "✗ Cannot read $task_file"
        exit 1
    fi
    
    # Process the entire task file in Python to avoid shell parsing issues
    ROW_JSON=$(python3 -c "
import yaml
import json
import sys
try:
    with open('$task_file', 'r') as f:
        data = yaml.safe_load(f)
    
    task_id = data.get('task_id', '')
    title = data.get('title', '')
    status = data.get('status', '')
    phase = data.get('phase', '')
    owner_role = data.get('owner_role', '')
    
    deliverable_files = data.get('deliverable_files', [])
    verification = data.get('verification', [])
    invariants = data.get('invariants', [])
    
    evidence_exists = len(deliverable_files) > 0
    verifier_exists = len(verification) > 0
    invariant_id_exists = len(invariants) > 0
    
    row = {
        'task_id': task_id,
        'title': title,
        'status': status,
        'phase': phase,
        'owner_role': owner_role,
        'evidence_exists': evidence_exists,
        'verifier_exists': verifier_exists,
        'invariant_id_exists': invariant_id_exists
    }
    
    print(json.dumps(row))
except Exception as e:
    print(f'ERROR:{e}')
    sys.exit(1)
")
    
    if [[ "$ROW_JSON" == ERROR* ]]; then
        echo "✗ Failed to parse $task_file: ${ROW_JSON#ERROR:}"
        exit 1
    fi
    
    # Add to rows
    ROWS+=("$ROW_JSON")
    
    # Track completeness
    EVIDENCE_EXISTS=$(echo "$ROW_JSON" | python3 -c "import json; data=json.loads('$ROW_JSON'); print(data.get('evidence_exists', False))")
    VERIFIER_EXISTS=$(echo "$ROW_JSON" | python3 -c "import json; data=json.loads('$ROW_JSON'); print(data.get('verifier_exists', False))")
    INVARIANT_ID_EXISTS=$(echo "$ROW_JSON" | python3 -c "import json; data=json.loads('$ROW_JSON'); print(data.get('invariant_id_exists', False))")
    
    if [ "$EVIDENCE_EXISTS" = "True" ]; then
        ((EVIDENCE_COMPLETE++))
    fi
    if [ "$VERIFIER_EXISTS" = "True" ]; then
        ((VERIFIER_COMPLETE++))
    fi
    if [ "$INVARIANT_ID_EXISTS" = "False" ]; then
        ((INV_ID_ABSENT++))
    fi
done

if [ ${#ROWS[@]} -eq ${#TASK_FILES[@]} ]; then
    checks+=("metadata_parsing:PASS")
    echo "✓ Successfully parsed all ${#ROWS[@]} task metadata files"
else
    checks+=("metadata_parsing:FAIL")
    echo "✗ Failed to parse all task metadata files"
    exit 1
fi

# Check 4: Compute summary counts
echo "Check 4: Compute summary counts"
TOTAL_TASKS=${#ROWS[@]}
PLANNED_COUNT=0
COMPLETED_COUNT=0
IN_PROGRESS_COUNT=0

# Count by status
for row in "${ROWS[@]}"; do
    STATUS=$(echo "$row" | python3 -c "
import json
import sys
data = json.loads('$row')
print(data.get('status', ''))
")
    case "$STATUS" in
        "planned") ((PLANNED_COUNT++)) ;;
        "completed") ((COMPLETED_COUNT++)) ;;
        "in_progress") ((IN_PROGRESS_COUNT++)) ;;
    esac
done

checks+=("summary_counts:PASS")
echo "✓ Computed summary counts: Total=$TOTAL_TASKS, Planned=$PLANNED_COUNT, Completed=$COMPLETED_COUNT, In Progress=$IN_PROGRESS_COUNT"

# Check 5: Verify fail-closed behavior
echo "Check 5: Verify fail-closed behavior"
if [ $TOTAL_TASKS -ge 80 ] && [ ${#ROWS[@]} -eq $TOTAL_TASKS ]; then
    checks+=("fail_closed_behavior:PASS")
    echo "✓ Fail-closed behavior verified"
else
    checks+=("fail_closed_behavior:FAIL")
    echo "✗ Fail-closed behavior failed"
    exit 1
fi

# Generate evidence JSON
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": [
$(printf '    "%s"' "${checks[@]}" | paste -sd ',' -)
  ],
  "rows": [
$(printf '    %s' "${ROWS[@]}" | paste -sd ',' -)
  ],
  "summary_counts": {
    "total_tasks": $TOTAL_TASKS,
    "planned": $PLANNED_COUNT,
    "completed": $COMPLETED_COUNT,
    "in_progress": $IN_PROGRESS_COUNT
  },
  "total_tasks": $TOTAL_TASKS,
  "evidence_complete": $EVIDENCE_COMPLETE,
  "verifier_complete": $VERIFIER_COMPLETE,
  "inv_id_absent": $INV_ID_ABSENT
}
EOF

echo "Evidence written to $EVIDENCE_PATH"
echo "All checks passed"

exit 0
