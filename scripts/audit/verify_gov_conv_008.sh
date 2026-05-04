#!/bin/bash

# Verification script for TSK-P2-GOV-CONV-008
# Author Phase-2 human contract

set -euo pipefail

TASK_ID="TSK-P2-GOV-CONV-008"
EVIDENCE_PATH="evidence/phase2/gov_conv_008_phase2_human_contract.json"
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

# Check 2: Verify human contract document exists
echo "Check 2: Verify human contract document exists"
if [ -f "docs/PHASE2/PHASE2_CONTRACT.md" ]; then
    checks+=("human_contract_exists:PASS")
    echo "✓ Human contract document exists"
else
    checks+=("human_contract_exists:FAIL")
    echo "✗ Human contract document does not exist"
    exit 1
fi

# Check 3: Verify required sections exist
echo "Check 3: Verify required sections exist"
REQUIRED_SECTIONS=(
    "## Phase Identity"
    "## Capability Boundary"
    "## Non-Goals"
    "## Required Artifacts"
    "## Authority Boundary"
    "## Verification and Compliance"
    "## Governance Notes"
)

MISSING_SECTIONS=()
for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "^$section" docs/PHASE2/PHASE2_CONTRACT.md; then
        MISSING_SECTIONS+=("$section")
    fi
done

if [ ${#MISSING_SECTIONS[@]} -eq 0 ]; then
    checks+=("required_sections_present:PASS")
    echo "✓ All required sections present"
else
    checks+=("required_sections_present:FAIL")
    echo "✗ Missing sections: ${MISSING_SECTIONS[*]}"
    exit 1
fi

# Check 4: Verify authority boundary declaration
echo "Check 4: Verify authority boundary declaration"
if grep -q "phase2_contract.yml.*authoritative" docs/PHASE2/PHASE2_CONTRACT.md; then
    checks+=("authority_boundary_declared:PASS")
    echo "✓ Authority boundary declared"
else
    checks+=("authority_boundary_declared:FAIL")
    echo "✗ Authority boundary not properly declared"
    exit 1
fi

# Check 5: Verify verifier reference
echo "Check 5: Verify verifier reference"
if grep -q "verify_phase2_contract.sh" docs/PHASE2/PHASE2_CONTRACT.md; then
    checks+=("verifier_referenced:PASS")
    echo "✓ Verifier referenced"
else
    checks+=("verifier_referenced:FAIL")
    echo "✗ Verifier not referenced"
    exit 1
fi

# Check 6: Verify evidence reference
echo "Check 6: Verify evidence reference"
if grep -q "phase2_contract_status.json" docs/PHASE2/PHASE2_CONTRACT.md; then
    checks+=("evidence_referenced:PASS")
    echo "✓ Evidence file referenced"
else
    checks+=("evidence_referenced:FAIL")
    echo "✗ Evidence file not referenced"
    exit 1
fi

# Check 7: Verify invariant references
echo "Check 7: Verify invariant references"
INV_REFERENCES=$(grep -c "INV-[0-9]\+" docs/PHASE2/PHASE2_CONTRACT.md || echo "0")
if [ "$INV_REFERENCES" -ge 6 ]; then
    checks+=("invariant_references_present:PASS")
    echo "✓ Invariant references present ($INV_REFERENCES found)"
else
    checks+=("invariant_references_present:FAIL")
    echo "✗ Insufficient invariant references ($INV_REFERENCES found, need at least 6)"
    exit 1
fi

# Check 8: Verify no new claims beyond machine contract
echo "Check 8: Verify no new claims beyond machine contract"
# Look for actual new requirements, excluding the authority boundary section
NEW_CLAIMS=$(sed '/## Authority Boundary/,/##/d' docs/PHASE2/PHASE2_CONTRACT.md | grep -c "must.*provide\|shall.*implement\|required.*new\|additional.*requirement" || echo "0")
NEW_CLAIMS=${NEW_CLAIMS//[^0-9]/}  # Extract only digits
if [ "$NEW_CLAIMS" -eq 0 ]; then
    checks+=("no_new_claims:PASS")
    echo "✓ No new claims detected"
else
    checks+=("no_new_claims:FAIL")
    echo "✗ Potential new claims found ($NEW_CLAIMS)"
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
  "human_contract": {
    "file": "docs/PHASE2/PHASE2_CONTRACT.md",
    "exists": true,
    "required_sections": ${#REQUIRED_SECTIONS[@]},
    "missing_sections": ${#MISSING_SECTIONS[@]},
    "authority_boundary_declared": true,
    "verifier_referenced": true,
    "evidence_referenced": true,
    "invariant_references": $INV_REFERENCES,
    "new_claims_detected": false
  },
  "machine_contract_reference": "docs/PHASE2/phase2_contract.yml",
  "verifier_reference": "scripts/audit/verify_phase2_contract.sh",
  "evidence_reference": "evidence/phase2/phase2_contract_status.json",
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
