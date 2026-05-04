#!/bin/bash

# Verification script for TSK-P2-GOV-CONV-005
# Rewrite Phase-2 machine contract to invariant-centric

set -euo pipefail

TASK_ID="TSK-P2-GOV-CONV-005"
EVIDENCE_PATH="evidence/phase2/gov_conv_005_phase2_contract_rewrite.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize checks array
checks=()

echo "Starting verification for ${TASK_ID}..."

# Check 1: Verify prerequisite tasks are complete
echo "Check 1: Verify prerequisite tasks are complete"
PREREQ_TASKS=("TSK-P2-GOV-CONV-002" "TSK-P2-GOV-CONV-003" "TSK-P2-GOV-CONV-004")
ALL_PREREQS_COMPLETE=true

for prereq in "${PREREQ_TASKS[@]}"; do
    if [ ! -f "tasks/$prereq/meta.yml" ]; then
        ALL_PREREQS_COMPLETE=false
        echo "✗ Prerequisite task $prereq not found"
        break
    fi
    
    STATUS=$(grep "^status:" "tasks/$prereq/meta.yml" | cut -d: -f2- | tr -d ' ')
    if [ "$STATUS" != "completed" ]; then
        ALL_PREREQS_COMPLETE=false
        echo "✗ Prerequisite task $prereq not completed: $STATUS"
        break
    fi
done

if [ "$ALL_PREREQS_COMPLETE" = true ]; then
    checks+=("prerequisite_tasks_complete:PASS")
    echo "✓ All prerequisite tasks are completed"
else
    checks+=("prerequisite_tasks_complete:FAIL")
    echo "✗ Prerequisite tasks are not complete"
    exit 1
fi

# Check 2: Verify Phase-2 contract exists and is valid YAML
echo "Check 2: Verify Phase-2 contract exists"
if [ -f "docs/PHASE2/phase2_contract.yml" ]; then
    if python3 -c "import yaml; yaml.safe_load(open('docs/PHASE2/phase2_contract.yml'))" 2>/dev/null; then
        checks+=("phase2_contract_exists:PASS")
        echo "✓ Phase-2 contract exists and is valid"
    else
        checks+=("phase2_contract_exists:FAIL")
        echo "✗ Phase-2 contract is invalid"
        exit 1
    fi
else
    checks+=("phase2_contract_exists:FAIL")
    echo "✗ Phase-2 contract does not exist"
    exit 1
fi

# Check 3: Verify no task_id-keyed rows exist
echo "Check 3: Verify no task_id-keyed rows"
TASK_ID_ROWS=$(python3 << 'PYTHON_EOF'
import yaml
import sys

try:
    with open('docs/PHASE2/phase2_contract.yml', 'r') as f:
        contract = yaml.safe_load(f)

    task_id_rows = []
    if 'rows' in contract:
        for row in contract['rows']:
            invariant_id = row.get('invariant_id', '')
            if invariant_id.startswith('TSK-P2-'):
                task_id_rows.append(invariant_id)

    print(len(task_id_rows))
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_EOF
)

if [ "$TASK_ID_ROWS" -eq 0 ]; then
    checks+=("no_task_id_rows:PASS")
    echo "✓ No task_id-keyed rows found"
else
    checks+=("no_task_id_rows:FAIL")
    echo "✗ Found $TASK_ID_ROWS task_id-keyed rows"
    exit 1
fi

# Check 4: Verify all invariant references are registered
echo "Check 4: Verify all invariant references are registered"
MISSING_INVARIANTS=$(python3 << 'PYTHON_EOF'
import yaml
import sys

try:
    # Load contract
    with open('docs/PHASE2/phase2_contract.yml', 'r') as f:
        contract = yaml.safe_load(f)

    # Load invariants manifest
    with open('docs/invariants/INVARIANTS_MANIFEST.yml', 'r') as f:
        invariants = yaml.safe_load(f)

    # Get all registered invariant IDs
    registered_ids = set()
    for inv in invariants:
        registered_ids.add(inv.get('id', ''))
        for alias in inv.get('aliases', []):
            registered_ids.add(alias)

    # Check contract rows
    missing_invariants = []
    if 'rows' in contract:
        for row in contract['rows']:
            invariant_id = row.get('invariant_id', '')
            if invariant_id and invariant_id not in registered_ids:
                missing_invariants.append(invariant_id)

    print(len(missing_invariants))
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_EOF
)

if [ "$MISSING_INVARIANTS" -eq 0 ]; then
    checks+=("all_invariants_registered:PASS")
    echo "✓ All invariant references are registered"
else
    checks+=("all_invariants_registered:FAIL")
    echo "✗ Found $MISSING_INVARIANTS missing invariant references"
    exit 1
fi

# Check 5: Verify contract row schema
echo "Check 5: Verify contract row schema"
INVALID_ROWS=$(python3 << 'PYTHON_EOF'
import yaml
import sys

try:
    with open('docs/PHASE2/phase2_contract.yml', 'r') as f:
        contract = yaml.safe_load(f)

    required_fields = ['invariant_id', 'status', 'required', 'gate_id', 'verifier', 'evidence_path']
    invalid_rows = []
    
    if 'rows' in contract:
        for i, row in enumerate(contract['rows']):
            missing_fields = []
            for field in required_fields:
                if field not in row:
                    missing_fields.append(field)
            if missing_fields:
                invalid_rows.append(f"Row {i}: missing {', '.join(missing_fields)}")

    print(len(invalid_rows))
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_EOF
)

if [ "$INVALID_ROWS" -eq 0 ]; then
    checks+=("contract_row_schema:PASS")
    echo "✓ Contract row schema is valid"
else
    checks+=("contract_row_schema:FAIL")
    echo "✗ Found $INVALID_ROWS invalid contract rows"
    exit 1
fi

# Get total rows count
TOTAL_ROWS=$(python3 -c "
import yaml
with open('docs/PHASE2/phase2_contract.yml', 'r') as f:
    contract = yaml.safe_load(f)
print(len(contract.get('rows', [])))
")

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
  "total_rows": $TOTAL_ROWS,
  "invalid_rows": $INVALID_ROWS,
  "missing_invariants": $MISSING_INVARIANTS,
  "task_id_rows_found": $TASK_ID_ROWS,
  "summary": {
    "total_checks": ${#checks[@]},
    "passed_checks": ${#checks[@]},
    "failed_checks": 0
  }
}
EOF

echo "Evidence written to $EVIDENCE_PATH"
echo "All checks passed"

exit 0
