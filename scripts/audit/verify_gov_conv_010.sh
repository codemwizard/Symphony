#!/bin/bash

# Verification script for TSK-P2-GOV-CONV-010
# Author Phase-2 agentic SDLC policy

set -euo pipefail

TASK_ID="TSK-P2-GOV-CONV-010"
EVIDENCE_PATH="evidence/phase2/gov_conv_010_phase2_policy_authoring.json"
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

# Check 2: Verify policy document exists
echo "Check 2: Verify policy document exists"
if [ -f "docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md" ]; then
    checks+=("policy_document_exists:PASS")
    echo "✓ Phase-2 policy document exists"
else
    checks+=("policy_document_exists:FAIL")
    echo "✗ Phase-2 policy document does not exist"
    exit 1
fi

# Check 3: Verify required sections exist
echo "Check 3: Verify required sections exist"
REQUIRED_SECTIONS=(
    "## Phase Scope"
    "## Authority Hierarchy"
    "## Phase-2 Claim Requirements"
    "## Phase-2 Execution Rules"
    "## Anti-Drift Measures"
    "## Phase-2 Completion Criteria"
    "## Phase-2 Limitations"
    "## Phase-2 Governance"
    "## Compliance and Audit"
)

MISSING_SECTIONS=()
for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "^$section" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
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

# Check 4: Verify authority hierarchy references
echo "Check 4: Verify authority hierarchy references"
if grep -q "AI_AGENT_OPERATION_MANUAL.md" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md && \
   grep -q "PHASE_LIFECYCLE.md" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    checks+=("authority_hierarchy_present:PASS")
    echo "✓ Authority hierarchy references present"
else
    checks+=("authority_hierarchy_present:FAIL")
    echo "✗ Authority hierarchy references missing"
    exit 1
fi

# Check 5: Verify machine contract reference
echo "Check 5: Verify machine contract reference"
if grep -q "phase2_contract.yml" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    checks+=("machine_contract_referenced:PASS")
    echo "✓ Machine contract referenced"
else
    checks+=("machine_contract_referenced:FAIL")
    echo "✗ Machine contract not referenced"
    exit 1
fi

# Check 6: Verify claim requirements defined
echo "Check 6: Verify claim requirements defined"
if grep -q "Required Evidence for Phase-2 Delivery Claims" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md && \
   grep -q "Machine Contract Rows" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md && \
   grep -q "Verifier Output" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    checks+=("claim_requirements_defined:PASS")
    echo "✓ Claim requirements defined"
else
    checks+=("claim_requirements_defined:FAIL")
    echo "✗ Claim requirements not properly defined"
    exit 1
fi

# Check 7: Verify no Phase-2 open claims
echo "Check 7: Verify no Phase-2 open claims"
OPEN_CLAIMS=$(grep -c "Phase-2 is open\|Phase-2.*available for\|available.*Phase-2\|Phase-2.*accepting\|accepting.*Phase-2" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md 2>/dev/null || echo "0")
CLOSED_CLAIMS=$(grep -c "Phase-2.*CLOSED\|Phase-2 is not open\|not open.*Phase-2" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md 2>/dev/null || echo "0")

# Clean up the variables to ensure they contain only digits
OPEN_CLAIMS=${OPEN_CLAIMS//[^0-9]/}
CLOSED_CLAIMS=${CLOSED_CLAIMS//[^0-9]/}

if [ "$OPEN_CLAIMS" -eq 0 ] && [ "$CLOSED_CLAIMS" -gt 0 ]; then
    checks+=("no_phase_open_claims:PASS")
    echo "✓ No Phase-2 open claims found"
else
    checks+=("no_phase_open_claims:FAIL")
    echo "✗ Phase-2 open claims detected (open: $OPEN_CLAIMS, closed: $CLOSED_CLAIMS)"
    exit 1
fi

# Check 8: Verify evidence requirements specified
echo "Check 8: Verify evidence requirements specified"
if grep -q "evidence/phase2/\*\*" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md && \
   grep -q "task_id.*git_sha.*timestamp_utc" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    checks+=("evidence_requirements_specified:PASS")
    echo "✓ Evidence requirements specified"
else
    checks+=("evidence_requirements_specified:FAIL")
    echo "✗ Evidence requirements not specified"
    exit 1
fi

# Check 9: Verify role boundaries defined
echo "Check 9: Verify role boundaries defined"
if grep -q "Agent Role Boundaries" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md && \
   grep -q "INVARIANTS_CURATOR\|SECURITY_GUARDIAN\|ARCHITECT\|DB_FOUNDATION" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    checks+=("role_boundaries_defined:PASS")
    echo "✓ Role boundaries defined"
else
    checks+=("role_boundaries_defined:FAIL")
    echo "✗ Role boundaries not defined"
    exit 1
fi

# Check 10: Verify anti-drift measures present
echo "Check 10: Verify anti-drift measures present"
if grep -q "Anti-Drift Measures" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md && \
   grep -q "Contract Integrity\|Evidence Integrity\|Process Integrity" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    checks+=("anti_drift_measures_present:PASS")
    echo "✓ Anti-drift measures present"
else
    checks+=("anti_drift_measures_present:FAIL")
    echo "✗ Anti-drift measures not present"
    exit 1
fi

# Generate evidence JSON using Python for proper formatting
python3 << PYTHON_EOF
import json

checks = [line.strip() for line in '''${checks[@]}'''.split() if line.strip()]

evidence = {
    "task_id": "$TASK_ID",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": "PASS",
    "checks": checks,
    "policy_document": {
        "file": "docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md",
        "exists": True,
        "required_sections": ${#REQUIRED_SECTIONS[@]},
        "missing_sections": ${#MISSING_SECTIONS[@]},
        "authority_hierarchy_present": True,
        "machine_contract_referenced": True,
        "claim_requirements_defined": True,
        "evidence_requirements_specified": True,
        "role_boundaries_defined": True,
        "anti_drift_measures_present": True
    },
    "phase_status": {
        "open_claims": $OPEN_CLAIMS,
        "closed_claims": $CLOSED_CLAIMS,
        "phase_closed": $([ "$OPEN_CLAIMS" -eq 0 ] && [ "$CLOSED_CLAIMS" -gt 0 ] && echo "True" || echo "False")
    },
    "summary": {
        "total_checks": len(checks),
        "passed_checks": len(checks),
        "failed_checks": 0
    }
}

with open("$EVIDENCE_PATH", "w") as f:
    json.dump(evidence, f, indent=2)
PYTHON_EOF

echo "Evidence written to $EVIDENCE_PATH"
echo "All checks passed"

exit 0
