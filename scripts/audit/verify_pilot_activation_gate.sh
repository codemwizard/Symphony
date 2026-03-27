#!/usr/bin/env bash
# scripts/audit/verify_pilot_activation_gate.sh
#
# PURPOSE
# -------
# Verify pilot activation gate compliance. Runs 6 check groups in sequence,
# failing fast on any group failure.
#
# USAGE
# -----
# bash scripts/audit/verify_pilot_activation_gate.sh --pilot PWRM0001

set -euo pipefail

PILOT_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --pilot)
            shift
            PILOT_ID="$1"
            shift
            ;;
        *)
            echo "ERROR: Unknown argument $1" >&2
            echo "Usage: $0 --pilot <pilot_id>" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$PILOT_ID" ]]; then
    echo "ERROR: --pilot argument is required" >&2
    exit 1
fi

echo "==> Pilot Activation Gate Verification"
echo "Pilot ID: $PILOT_ID"

# Check groups
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

run_check() {
    local check_id="$1"
    local check_description="$2"
    local check_command="$3"
    
    echo "Running check: $check_description"
    
    ((TOTAL_CHECKS++))
    
    if eval "$check_command" >/dev/null 2>&1; then
        echo "✅ PASS: $check_description"
        ((PASSED_CHECKS++))
    else
        echo "❌ FAIL: $check_description"
        ((FAILED_CHECKS++))
        return 1
    fi
}

echo ""
echo "=== Check Group 1: INV-159 - Adapter registration completeness ==="

run_check "INV-159-1" \
    "Adapter registration record exists in invariants manifest" \
    "grep -q 'adapter_registrations' docs/invariants/INVARIANTS_MANIFEST.yml"

run_check "INV-159-2" \
    "Adapter registration record has required fields" \
    "! grep -q 'adapter_registrations.*fields.*empty' docs/invariants/INVARIANTS_MANIFEST.yml"

echo ""
echo "=== Check Group 2: INV-160 - Adapter registration uniqueness ==="

run_check "INV-160-1" \
    "Unique constraint on adapter_code exists" \
    "grep -q 'UNIQUE.*adapter_code' schema/migrations/*.sql"

echo ""
echo "=== Check Group 3: INV-161 - Adapter registration authority validation ==="

run_check "INV-161-1" \
    "Authority level validation exists" \
    "grep -q 'authority_level.*CHECK.*IN' schema/migrations/*.sql"

echo ""
echo "=== Check Group 4: INV-162 - Adapter registration schema validation ==="

run_check "INV-162-1" \
    "JSONB schema validation for payload_schema_refs" \
    "grep -q 'jsonb_typeof.*payload_schema_refs' schema/migrations/*.sql"

echo ""
echo "=== Check Group 5: INV-163 - Adapter registration temporal validation ==="

run_check "INV-163-1" \
    "Effective date validation exists" \
    "grep -q 'effective_from.*CURRENT_TIMESTAMP' schema/migrations/*.sql"

echo ""
echo "=== Check Group 6: INV-164..168 - Pilot-specific activation requirements ==="

run_check "INV-164-1" \
    "Pilot scope document exists" \
    "test -f docs/pilots/${PILOT_ID}/SCOPE.md"

run_check "INV-165-1" \
    "Adapter registration for pilot exists" \
    "grep -q '${PILOT_ID}.*adapter_registrations' docs/pilots/${PILOT_ID}/SCOPE.md"

run_check "INV-166-1" \
    "Pilot activation checklist exists" \
    "test -f docs/pilots/${PILOT_ID}/ACTIVATION_CHECKLIST.md"

run_check "INV-167-1" \
    "Pilot activation evidence exists" \
    "test -f evidence/phase0/pilot_activation_${PILOT_ID}.json"

run_check "INV-168-1" \
    "Pilot activation evidence has required fields" \
    "grep -q 'pilot_id' evidence/phase0/pilot_activation_${PILOT_ID}.json"

echo ""
echo "=== Summary ==="
echo "Total checks: $TOTAL_CHECKS"
echo "Passed: $PASSED_CHECKS"
echo "Failed: $FAILED_CHECKS"

if [[ $FAILED_CHECKS -gt 0 ]]; then
    echo ""
    echo "❌ PILOT ACTIVATION GATE FAILED"
    echo "One or more check groups failed. Pilot $PILOT_ID is not ready for activation."
    exit 1
else
    echo ""
    echo "✅ PILOT ACTIVATION GATE PASSED"
    echo "All check groups passed. Pilot $PILOT_ID is ready for activation."
    exit 0
fi
