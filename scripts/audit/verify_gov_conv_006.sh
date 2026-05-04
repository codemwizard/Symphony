#!/bin/bash

# Verification script for TSK-P2-GOV-CONV-006
# Create canonical Phase-2 contract verifier

set -euo pipefail

TASK_ID="TSK-P2-GOV-CONV-006"
EVIDENCE_PATH="evidence/phase2/gov_conv_006_contract_verifier.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize checks array
checks=()

echo "Starting verification for ${TASK_ID}..."

# Check 1: Verify prerequisite task is complete
echo "Check 1: Verify prerequisite task complete"
if [ -f "tasks/TSK-P2-GOV-CONV-005/meta.yml" ]; then
    STATUS=$(grep "^status:" "tasks/TSK-P2-GOV-CONV-005/meta.yml" | cut -d: -f2- | tr -d ' ')
    if [ "$STATUS" = "completed" ]; then
        checks+=("prerequisite_task_complete:PASS")
        echo "✓ Prerequisite task TSK-P2-GOV-CONV-005 is completed"
    else
        checks+=("prerequisite_task_complete:FAIL")
        echo "✗ Prerequisite task TSK-P2-GOV-CONV-005 not completed: $STATUS"
        exit 1
    fi
else
    checks+=("prerequisite_task_complete:FAIL")
    echo "✗ Prerequisite task TSK-P2-GOV-CONV-005 not found"
    exit 1
fi

# Check 2: Verify canonical verifier exists and is executable
echo "Check 2: Verify canonical verifier exists"
if [ -f "scripts/audit/verify_phase2_contract.sh" ]; then
    if [ -x "scripts/audit/verify_phase2_contract.sh" ]; then
        checks+=("canonical_verifier_exists:PASS")
        echo "✓ Canonical Phase-2 contract verifier exists and is executable"
    else
        checks+=("canonical_verifier_exists:FAIL")
        echo "✗ Canonical verifier is not executable"
        exit 1
    fi
else
    checks+=("canonical_verifier_exists:FAIL")
    echo "✗ Canonical verifier does not exist"
    exit 1
fi

# Check 3: Run canonical verifier against Phase-2 contract
echo "Check 3: Run canonical verifier"
if bash scripts/audit/verify_phase2_contract.sh > /dev/null 2>&1; then
    checks+=("canonical_verifier_passes:PASS")
    echo "✓ Canonical verifier passes on Phase-2 contract"
else
    checks+=("canonical_verifier_passes:FAIL")
    echo "✗ Canonical verifier failed on Phase-2 contract"
    exit 1
fi

# Check 4: Verify evidence file is generated
echo "Check 4: Verify evidence file generated"
if [ -f "evidence/phase2/phase2_contract_status.json" ]; then
    if python3 -c "import json; json.load(open('evidence/phase2/phase2_contract_status.json'))" 2>/dev/null; then
        checks+=("evidence_file_generated:PASS")
        echo "✓ Evidence file generated and is valid JSON"
    else
        checks+=("evidence_file_generated:FAIL")
        echo "✗ Evidence file is not valid JSON"
        exit 1
    fi
else
    checks+=("evidence_file_generated:FAIL")
    echo "✗ Evidence file not generated"
    exit 1
fi

# Check 5: Verify evidence shows no violations
echo "Check 5: Verify evidence shows no violations"
VIOLATION_COUNT=$(python3 -c "
import json
with open('evidence/phase2/phase2_contract_status.json', 'r') as f:
    evidence = json.load(f)

total_violations = 0
for violation_type, violations in evidence.get('violations', {}).items():
    total_violations += len(violations)

print(total_violations)
")

if [ "$VIOLATION_COUNT" -eq 0 ]; then
    checks+=("no_contract_violations:PASS")
    echo "✓ No contract violations found"
else
    checks+=("no_contract_violations:FAIL")
    echo "✗ Found $VIOLATION_COUNT contract violations"
    exit 1
fi

# Get contract stats
TOTAL_ROWS=$(python3 -c "
import json
with open('evidence/phase2/phase2_contract_status.json', 'r') as f:
    evidence = json.load(f)
print(evidence.get('total_rows', 0))
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
  "canonical_verifier": "scripts/audit/verify_phase2_contract.sh",
  "contract_rows": $TOTAL_ROWS,
  "violation_count": $VIOLATION_COUNT,
  "evidence_generated": "evidence/phase2/phase2_contract_status.json",
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
