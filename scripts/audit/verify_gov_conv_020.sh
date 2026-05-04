#!/bin/bash

# Verification script for TSK-P2-GOV-CONV-020
# Verify Phase-4 stub non-claimability only

set -euo pipefail

TASK_ID="TSK-P2-GOV-CONV-020"
EVIDENCE_PATH="evidence/phase2/gov_conv_020_phase4_verification.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize checks array
checks=()

echo "Starting verification for ${TASK_ID}..."

# Check 1: Verify Phase-4 stub non-claimability status
echo "Check 1: Verify Phase-4 stub non-claimability status"
if [ -f "docs/PHASE4/README.md" ] && [ -f "docs/PHASE4/phase4_contract.yml" ]; then
    if grep -q "non-claimable" docs/PHASE4/README.md || grep -q "non-claimable" docs/PHASE4/phase4_contract.yml; then
        checks+=("phase4_non_claimable:PASS")
        echo "✓ Phase-4 stub non-claimability status verified"
    else
        checks+=("phase4_non_claimable:FAIL")
        echo "✗ Phase-4 stub non-claimability status not found"
    fi
else
    checks+=("phase4_non_claimable:FAIL")
    echo "✗ Phase-4 stub files missing"
fi

# Check 2: Verify README.md contains explicit non-open language
echo "Check 2: Verify README.md contains explicit non-open language"
if [ -f "docs/PHASE4/README.md" ]; then
    if grep -q "NOT OPEN\|not open" docs/PHASE4/README.md; then
        checks+=("readme_non_open_language:PASS")
        echo "✓ README.md contains explicit non-open language"
    else
        checks+=("readme_non_open_language:FAIL")
        echo "✗ README.md does not contain explicit non-open language"
    fi
else
    checks+=("readme_non_open_language:FAIL")
    echo "✗ README.md missing"
fi

# Check 3: Verify phase4_contract.yml has zero implementation rows
echo "Check 3: Verify phase4_contract.yml has zero implementation rows"
if [ -f "docs/PHASE4/phase4_contract.yml" ]; then
    # Parse YAML to check for empty rows array
    if grep -A1 "rows:" docs/PHASE4/phase4_contract.yml | grep -q "\[\]"; then
        checks+=("phase4_zero_rows:PASS")
        echo "✓ phase4_contract.yml has zero implementation rows"
    else
        checks+=("phase4_zero_rows:FAIL")
        echo "✗ phase4_contract.yml does not have zero implementation rows"
    fi
else
    checks+=("phase4_zero_rows:FAIL")
    echo "✗ phase4_contract.yml missing"
fi

# Check 4: Ensure verifier rejects any premature Phase-4 opening artifacts
echo "Check 4: Verify verifier rejects premature Phase-4 opening artifacts"
# Check for any Phase-4 task files that might indicate premature opening
PHASE4_TASKS=$(find tasks/ -name "TSK-P4-*" 2>/dev/null | wc -l)
if [ "$PHASE4_TASKS" -eq 0 ]; then
    checks+=("no_premature_phase4_tasks:PASS")
    echo "✓ No premature Phase-4 tasks found"
else
    checks+=("no_premature_phase4_tasks:FAIL")
    echo "✗ Found $PHASE4_TASKS premature Phase-4 tasks"
fi

# Check 5: Verify Phase-4 directory structure is minimal (stub only)
echo "Check 5: Verify Phase-4 directory structure is minimal"
if [ -d "docs/PHASE4" ]; then
    # Count files in PHASE4 directory (should only be README.md and phase4_contract.yml)
    PHASE4_FILES=$(find docs/PHASE4 -type f | wc -l)
    if [ "$PHASE4_FILES" -eq 2 ]; then
        checks+=("phase4_minimal_structure:PASS")
        echo "✓ Phase-4 directory structure is minimal (stub only)"
    else
        checks+=("phase4_minimal_structure:FAIL")
        echo "✗ Phase-4 directory has $PHASE4_FILES files (expected 2)"
    fi
else
    checks+=("phase4_minimal_structure:FAIL")
    echo "✗ Phase-4 directory missing"
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
  "phase4_non_claimable_verified": $(if grep -q "phase4_non_claimable:PASS" <<< "${checks[*]}"; then echo "true"; else echo "false"; fi),
  "zero_rows_confirmed": $(if grep -q "phase4_zero_rows:PASS" <<< "${checks[*]}"; then echo "true"; else echo "false"; fi),
  "premature_opening_detected": $(if grep -q "no_premature_phase4_tasks:FAIL" <<< "${checks[*]}"; then echo "true"; else echo "false"; fi),
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
