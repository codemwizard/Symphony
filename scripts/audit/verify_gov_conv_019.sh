#!/bin/bash

# Verification script for TSK-P2-GOV-CONV-019
# Create Phase-4 non-claimable stub docs only

set -euo pipefail

TASK_ID="TSK-P2-GOV-CONV-019"
EVIDENCE_PATH="evidence/phase2/gov_conv_019_phase4_stub.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize checks array
checks=()

echo "Starting verification for ${TASK_ID}..."

# Check 1: Verify README.md exists and marks Phase-4 as not open
echo "Check 1: Verify README.md exists and marks Phase-4 as not open"
if [ -f "docs/PHASE4/README.md" ]; then
    if grep -q "not open" docs/PHASE4/README.md && grep -q "Phase-4" docs/PHASE4/README.md; then
        checks+=("phase4_readme_exists:PASS")
        echo "✓ README.md exists and marks Phase-4 as not open"
    else
        checks+=("phase4_readme_exists:FAIL")
        echo "✗ README.md exists but does not properly mark Phase-4 as not open"
    fi
else
    checks+=("phase4_readme_exists:FAIL")
    echo "✗ README.md does not exist"
fi

# Check 2: Verify phase4_contract.yml exists with zero implementation rows
echo "Check 2: Verify phase4_contract.yml exists with zero implementation rows"
if [ -f "docs/PHASE4/phase4_contract.yml" ]; then
    # Check if rows array exists and is empty
    if grep -q "rows:" docs/PHASE4/phase4_contract.yml && grep -A1 "rows:" docs/PHASE4/phase4_contract.yml | grep -q "\[\]"; then
        checks+=("phase4_contract_zero_rows:PASS")
        echo "✓ phase4_contract.yml exists with zero implementation rows"
    else
        checks+=("phase4_contract_zero_rows:FAIL")
        echo "✗ phase4_contract.yml exists but does not have zero implementation rows"
    fi
else
    checks+=("phase4_contract_zero_rows:FAIL")
    echo "✗ phase4_contract.yml does not exist"
fi

# Check 3: Verify explicit non-claimable status and future-phase placeholder
echo "Check 3: Verify explicit non-claimable status"
if [ -f "docs/PHASE4/README.md" ] && [ -f "docs/PHASE4/phase4_contract.yml" ]; then
    if grep -q "non-claimable" docs/PHASE4/README.md || grep -q "non-claimable" docs/PHASE4/phase4_contract.yml; then
        checks+=("non_claimable_status:PASS")
        echo "✓ Explicit non-claimable status found"
    else
        checks+=("non_claimable_status:FAIL")
        echo "✗ Explicit non-claimable status not found"
    fi
else
    checks+=("non_claimable_status:FAIL")
    echo "✗ Cannot verify non-claimable status - files missing"
fi

# Check 4: Verify stub prevents premature Phase-4 work initiation
echo "Check 4: Verify stub prevents premature Phase-4 work initiation"
if [ -f "docs/PHASE4/README.md" ]; then
    # Check for anti-drift language
    if grep -q "anti-drift\|prevent.*premature\|not.*available" docs/PHASE4/README.md; then
        checks+=("premature_work_prevention:PASS")
        echo "✓ Stub contains language to prevent premature Phase-4 work"
    else
        checks+=("premature_work_prevention:FAIL")
        echo "✗ Stub does not contain language to prevent premature Phase-4 work"
    fi
else
    checks+=("premature_work_prevention:FAIL")
    echo "✗ Cannot verify premature work prevention - README.md missing"
fi

# Check 5: Verify stubs are properly structured
echo "Check 5: Verify stubs are properly structured"
if [ -f "docs/PHASE4/README.md" ] && [ -f "docs/PHASE4/phase4_contract.yml" ]; then
    # Check basic structure
    if [ -s "docs/PHASE4/README.md" ] && [ -s "docs/PHASE4/phase4_contract.yml" ]; then
        checks+=("stub_structure:PASS")
        echo "✓ Stub files are properly structured"
    else
        checks+=("stub_structure:FAIL")
        echo "✗ Stub files are not properly structured"
    fi
else
    checks+=("stub_structure:FAIL")
    echo "✗ Cannot verify stub structure - files missing"
fi

# Determine overall status
failed_checks=0
for check in "${checks[@]}"; do
    if [[ "$check" == *":FAIL" ]]; then
        ((failed_checks++))
    fi
done

if [ $failed_checks -eq 0 ]; then
    status="PASS"
    echo "All checks passed"
else
    status="FAIL"
    echo "$failed_checks checks failed"
fi

# Generate evidence JSON
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "$status",
  "checks": [
$(printf '    "%s"' "${checks[@]}" | paste -sd ',' -)
  ],
  "phase4_stub_created": $(if [ $failed_checks -eq 0 ]; then echo "true"; else echo "false"; fi),
  "non_claimable_status": $(if grep -q "phase4_readme_exists:PASS" <<< "${checks[*]}" && grep -q "non_claimable_status:PASS" <<< "${checks[*]}"; then echo "true"; else echo "false"; fi),
  "zero_rows_confirmed": $(if grep -q "phase4_contract_zero_rows:PASS" <<< "${checks[*]}"; then echo "true"; else echo "false"; fi),
  "summary": {
    "total_checks": ${#checks[@]},
    "passed_checks": $((${#checks[@]} - failed_checks)),
    "failed_checks": $failed_checks
  }
}
EOF

echo "Evidence written to $EVIDENCE_PATH"

# Exit with appropriate code
if [ "$status" = "PASS" ]; then
    exit 0
else
    exit 1
fi
