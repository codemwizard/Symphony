#!/bin/bash

# Verification script for TSK-P2-GOV-CONV-007
# Wire Phase-2 contract verifier into local and CI paths

set -euo pipefail

TASK_ID="TSK-P2-GOV-CONV-007"
EVIDENCE_PATH="evidence/phase2/gov_conv_007_phase2_contract_wiring.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize checks array
checks=()

echo "Starting verification for ${TASK_ID}..."

# Check 1: Verify prerequisite task is complete
echo "Check 1: Verify prerequisite task complete"
if [ -f "tasks/TSK-P2-GOV-CONV-006/meta.yml" ]; then
    STATUS=$(grep "^status:" "tasks/TSK-P2-GOV-CONV-006/meta.yml" | cut -d: -f2- | tr -d ' ')
    if [ "$STATUS" = "completed" ]; then
        checks+=("prerequisite_task_complete:PASS")
        echo "✓ Prerequisite task TSK-P2-GOV-CONV-006 is completed"
    else
        checks+=("prerequisite_task_complete:FAIL")
        echo "✗ Prerequisite task TSK-P2-GOV-CONV-006 not completed: $STATUS"
        exit 1
    fi
else
    checks+=("prerequisite_task_complete:FAIL")
    echo "✗ Prerequisite task TSK-P2-GOV-CONV-006 not found"
    exit 1
fi

# Check 2: Verify canonical verifier exists
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

# Check 3: Verify local pre-CI wiring
echo "Check 3: Verify local pre-CI wiring"
if grep -q "RUN_PHASE2_GATES" scripts/dev/pre_ci.sh; then
    if grep -q "verify_phase2_contract.sh" scripts/dev/pre_ci.sh; then
        checks+=("local_pre_ci_wiring:PASS")
        echo "✓ Local pre-CI script has RUN_PHASE2_GATES wiring"
    else
        checks+=("local_pre_ci_wiring:FAIL")
        echo "✗ Local pre-CI script missing verify_phase2_contract.sh call"
        exit 1
    fi
else
    checks+=("local_pre_ci_wiring:FAIL")
    echo "✗ Local pre-CI script missing RUN_PHASE2_GATES"
    exit 1
fi

# Check 4: Verify CI wiring
echo "Check 4: Verify CI wiring"
if grep -q "RUN_PHASE2_GATES=1" .github/workflows/invariants.yml; then
    if grep -q "verify_phase2_contract.sh" .github/workflows/invariants.yml; then
        checks+=("ci_wiring:PASS")
        echo "✓ CI workflow has RUN_PHASE2_GATES=1 wiring"
    else
        checks+=("ci_wiring:FAIL")
        echo "✗ CI workflow missing verify_phase2_contract.sh call"
        exit 1
    fi
else
    checks+=("ci_wiring:FAIL")
    echo "✗ CI workflow missing RUN_PHASE2_GATES=1"
    exit 1
fi

# Check 5: Verify fail-closed behavior (not advisory-only)
echo "Check 5: Verify fail-closed behavior"
LOCAL_FAIL_CLOSED=$(grep -A 5 "RUN_PHASE2_GATES=1" scripts/dev/pre_ci.sh | grep -c "exit 1" || echo "0")
CI_FAIL_CLOSED=$(grep -A 5 "RUN_PHASE2_GATES=1" .github/workflows/invariants.yml | grep -c "exit 1" || echo "0")

if [ "$LOCAL_FAIL_CLOSED" -gt 0 ] && [ "$CI_FAIL_CLOSED" -gt 0 ]; then
    checks+=("fail_closed_behavior:PASS")
    echo "✓ Both local and CI wiring have fail-closed behavior"
else
    checks+=("fail_closed_behavior:FAIL")
    echo "✗ Missing fail-closed behavior (local: $LOCAL_FAIL_CLOSED, CI: $CI_FAIL_CLOSED)"
    exit 1
fi

# Check 6: Test local wiring functionality
echo "Check 6: Test local wiring functionality"
# Test just the Phase-2 contract verification part
if RUN_PHASE2_GATES=1 bash scripts/audit/verify_phase2_contract.sh > /tmp/test_phase2_contract.json 2>&1; then
    checks+=("local_wiring_test:PASS")
    echo "✓ Local wiring test passed"
    rm -f /tmp/test_phase2_contract.json
else
    checks+=("local_wiring_test:FAIL")
    echo "✗ Local wiring test failed"
    rm -f /tmp/test_phase2_contract.json
    exit 1
fi

# Check 7: Verify evidence path consistency
echo "Check 7: Verify evidence path consistency"
LOCAL_EVIDENCE_PATH=$(grep -A 3 "RUN_PHASE2_GATES=1" scripts/dev/pre_ci.sh | grep "phase2_contract_status.json" | head -1 | grep -o "evidence/phase2/[^>]*" || echo "")
CI_EVIDENCE_PATH=$(grep -A 3 "RUN_PHASE2_GATES=1" .github/workflows/invariants.yml | grep "phase2_contract_status.json" | head -1 | grep -o "evidence/phase2/[^>]*" || echo "")

if [ "$LOCAL_EVIDENCE_PATH" = "$CI_EVIDENCE_PATH" ] && [ -n "$LOCAL_EVIDENCE_PATH" ]; then
    checks+=("evidence_path_consistency:PASS")
    echo "✓ Evidence paths are consistent: $LOCAL_EVIDENCE_PATH"
else
    checks+=("evidence_path_consistency:FAIL")
    echo "✗ Evidence path mismatch (local: $LOCAL_EVIDENCE_PATH, CI: $CI_EVIDENCE_PATH)"
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
  "local_wiring": {
    "script": "scripts/dev/pre_ci.sh",
    "has_run_phase2_gates": true,
    "has_verifier_call": true,
    "fail_closed": true,
    "test_passed": true
  },
  "ci_wiring": {
    "workflow": ".github/workflows/invariants.yml",
    "has_run_phase2_gates": true,
    "has_verifier_call": true,
    "fail_closed": true
  },
  "evidence_path": "$LOCAL_EVIDENCE_PATH",
  "canonical_verifier": "scripts/audit/verify_phase2_contract.sh",
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
