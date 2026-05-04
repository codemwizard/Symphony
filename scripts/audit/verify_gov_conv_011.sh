#!/bin/bash

# Verification script for TSK-P2-GOV-CONV-011
# Verify Phase-2 policy authority alignment

set -euo pipefail

TASK_ID="TSK-P2-GOV-CONV-011"
EVIDENCE_PATH="evidence/phase2/gov_conv_011_phase2_policy_alignment.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize checks array
checks=()

echo "Starting verification for ${TASK_ID}..."

# Check 1: Verify prerequisite task is complete
echo "Check 1: Verify prerequisite task complete"
if [ -f "tasks/TSK-P2-GOV-CONV-010/meta.yml" ]; then
    STATUS=$(grep "^status:" "tasks/TSK-P2-GOV-CONV-010/meta.yml" | cut -d: -f2- | tr -d ' ')
    if [ "$STATUS" = "completed" ]; then
        checks+=("prerequisite_task_complete:PASS")
        echo "✓ Prerequisite task TSK-P2-GOV-CONV-010 is completed"
    else
        checks+=("prerequisite_task_complete:FAIL")
        echo "✗ Prerequisite task TSK-P2-GOV-CONV-010 not completed: $STATUS"
        exit 1
    fi
else
    checks+=("prerequisite_task_complete:FAIL")
    echo "✗ Prerequisite task TSK-P2-GOV-CONV-010 not found"
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

# Check 3: Verify apex authority reference
echo "Check 3: Verify apex authority reference"
if grep -q "AI_AGENT_OPERATION_MANUAL.md" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    checks+=("apex_authority_referenced:PASS")
    echo "✓ Apex authority referenced"
else
    checks+=("apex_authority_referenced:FAIL")
    echo "✗ Apex authority not referenced"
    exit 1
fi

# Check 4: Verify lifecycle authority reference
echo "Check 4: Verify lifecycle authority reference"
if grep -q "PHASE_LIFECYCLE.md" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    checks+=("lifecycle_authority_referenced:PASS")
    echo "✓ Lifecycle authority referenced"
else
    checks+=("lifecycle_authority_referenced:FAIL")
    echo "✗ Lifecycle authority not referenced"
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

# Check 6: Verify claim-evidence requirements
echo "Check 6: Verify claim-evidence requirements"
CLAIM_EVIDENCE_FOUND=false
if grep -q "Required Evidence for Phase-2 Delivery Claims" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md && \
   grep -q "Machine Contract Rows" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md && \
   grep -q "Verifier Output" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md && \
   grep -q "evidence/phase2/\*\*" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    CLAIM_EVIDENCE_FOUND=true
    checks+=("claim_evidence_requirements:PASS")
    echo "✓ Claim-evidence requirements present"
else
    checks+=("claim_evidence_requirements:FAIL")
    echo "✗ Claim-evidence requirements missing"
    exit 1
fi

# Check 7: Verify no prohibited readiness claims
echo "Check 7: Verify no prohibited readiness claims"
PROHIBITED_CLAIMS=0

# Check for prohibited Phase-2 readiness language (more specific patterns)
if grep -q "Phase-2 is complete\|Phase-2 is ratified\|Phase-2 is delivery-claimable\|Phase-2 is ready" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    PROHIBITED_CLAIMS=$((PROHIBITED_CLAIMS + 1))
fi

# Check for claims that Phase-2 is open or accepting work (exclude "not open")
if grep -q "Phase-2 is open\|Phase-2 is accepting\|Phase-2 is available" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    PROHIBITED_CLAIMS=$((PROHIBITED_CLAIMS + 1))
fi

if [ "$PROHIBITED_CLAIMS" -eq 0 ]; then
    checks+=("no_prohibited_claims:PASS")
    echo "✓ No prohibited readiness claims found"
else
    checks+=("no_prohibited_claims:FAIL")
    echo "✗ Found $PROHIBITED_CLAIMS prohibited readiness claims"
    exit 1
fi

# Check 8: Verify verifier reference
echo "Check 8: Verify verifier reference"
if grep -q "verify_phase2_contract.sh" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    checks+=("verifier_referenced:PASS")
    echo "✓ Verifier referenced"
else
    checks+=("verifier_referenced:FAIL")
    echo "✗ Verifier not referenced"
    exit 1
fi

# Check 9: Verify evidence path reference
echo "Check 9: Verify evidence path reference"
if grep -q "phase2_contract_status.json" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md; then
    checks+=("evidence_path_referenced:PASS")
    echo "✓ Evidence path referenced"
else
    checks+=("evidence_path_referenced:FAIL")
    echo "✗ Evidence path not referenced"
    exit 1
fi

# Check 10: Verify role boundaries don't conflict with apex authority
echo "Check 10: Verify role boundaries don't conflict with apex authority"
# Check that policy doesn't redefine agent roles from the apex manual
ROLE_REDEFINITION=$(grep -c "role.*is.*defined\|agent.*role.*means\|role.*definition.*:\|defines.*role" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md 2>/dev/null || echo "0")

# Clean up the variable to ensure it contains only digits
ROLE_REDEFINITION=${ROLE_REDEFINITION//[^0-9]/}

if [ "$ROLE_REDEFINITION" -eq 0 ]; then
    checks+=("no_role_redefinition:PASS")
    echo "✓ No role redefinition detected"
else
    checks+=("no_role_redefinition:FAIL")
    echo "✗ Role redefinition detected"
    exit 1
fi

# Check 11: Verify policy is scoped (not trying to replace apex)
echo "Check 11: Verify policy is scoped"
SCOPED_LANGUAGE=$(grep -c "Phase-2.*scoped\|scoped.*Phase-2\|Phase-2.*specific\|specific.*Phase-2" docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md || echo "0")

if [ "$SCOPED_LANGUAGE" -gt 0 ]; then
    checks+=("policy_scoped:PASS")
    echo "✓ Policy is properly scoped"
else
    checks+=("policy_scoped:FAIL")
    echo "✗ Policy not properly scoped"
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
  "policy_alignment_status": "PASS",
  "authority_references": {
    "apex_manual": "AI_AGENT_OPERATION_MANUAL.md",
    "lifecycle_policy": "PHASE_LIFECYCLE.md",
    "machine_contract": "phase2_contract.yml",
    "verifier": "verify_phase2_contract.sh",
    "evidence_path": "phase2_contract_status.json"
  },
  "prohibited_claims": {
        "count": $PROHIBITED_CLAIMS,
        "readiness_claims": 0,
        "open_claims": 0,
        "completion_claims": 0
    },
    "claim_evidence_requirements": $(if [ "$CLAIM_EVIDENCE_FOUND" -eq 1 ]; then echo "True"; else echo "False"; fi),
    "policy_scoping": {
        "scoped_language_present": True,
        "no_role_redefinition": True,
        "phase_specific": True
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
