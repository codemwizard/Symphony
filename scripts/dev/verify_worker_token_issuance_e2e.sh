#!/usr/bin/env bash
set -eo pipefail

# GF-W1-UI-009: End-to-End Worker Token Issuance Verification
# Tests complete lifecycle: issuance → submission → security enforcement

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EVIDENCE_DIR="$REPO_ROOT/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/worker_token_issuance_e2e.json"

# Test configuration
TENANT_ID="ten-zambiagrn"
PROGRAM_ID="PGM-ZAMBIA-GRN-001"
INSTRUCTION_ID="CHG-2026-E2E-$(date +%s)"
WORKER_ID="worker-chunga-001"
WORKER_PHONE="+260971100001"
SUBMITTER_CLASS="WASTE_COLLECTOR"
BASE_URL="${SYMPHONY_BASE_URL:-http://localhost:5000}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Worker Token Issuance E2E Verification"
echo "========================================="
echo ""

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to report test result
report_test() {
    local test_name="$1"
    local result="$2"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        ((TESTS_FAILED++))
    fi
}

# Test 1: Token Issuance
echo "Test 1: Token Issuance"
echo "----------------------"

ISSUE_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "$BASE_URL/pilot-demo/api/evidence-links/issue" \
    -H "Content-Type: application/json" \
    -d "{
        \"tenant_id\": \"$TENANT_ID\",
        \"instruction_id\": \"$INSTRUCTION_ID\",
        \"program_id\": \"$PROGRAM_ID\",
        \"submitter_class\": \"$SUBMITTER_CLASS\",
        \"submitter_msisdn\": \"$WORKER_PHONE\",
        \"worker_id\": \"$WORKER_ID\",
        \"expires_in_seconds\": 900
    }")

HTTP_CODE=$(echo "$ISSUE_RESPONSE" | tail -n1)
ISSUE_BODY=$(echo "$ISSUE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    TOKEN=$(echo "$ISSUE_BODY" | jq -r '.token // empty')
    if [ -n "$TOKEN" ]; then
        report_test "Token issuance" "PASS"
        TOKEN_ISSUANCE_SUCCESS=true
    else
        report_test "Token issuance (no token in response)" "FAIL"
        TOKEN_ISSUANCE_SUCCESS=false
    fi
else
    report_test "Token issuance (HTTP $HTTP_CODE)" "FAIL"
    TOKEN_ISSUANCE_SUCCESS=false
fi

echo ""

# Test 2: Worker Submission with Valid Token
if [ "$TOKEN_ISSUANCE_SUCCESS" = true ]; then
    echo "Test 2: Worker Submission with Valid Token"
    echo "-------------------------------------------"
    
    SUBMIT_RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X POST "$BASE_URL/v1/evidence-links/submit" \
        -H "Authorization: Bearer $TOKEN" \
        -H "x-tenant-id: $TENANT_ID" \
        -H "x-submitter-msisdn: $WORKER_PHONE" \
        -H "Content-Type: application/json" \
        -d "{
            \"artifact_type\": \"WEIGHBRIDGE_RECORD\",
            \"artifact_ref\": \"e2e-test-$(date +%s)\",
            \"latitude\": -15.4167,
            \"longitude\": 28.2833,
            \"structured_payload\": {
                \"plastic_type\": \"PET\",
                \"gross_weight_kg\": 10.5,
                \"tare_weight_kg\": 0.1,
                \"net_weight_kg\": 10.4,
                \"collector_id\": \"$WORKER_ID\"
            }
        }")
    
    HTTP_CODE=$(echo "$SUBMIT_RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" = "202" ]; then
        report_test "Worker submission with valid token" "PASS"
        WORKER_SUBMISSION_SUCCESS=true
    else
        report_test "Worker submission (HTTP $HTTP_CODE)" "FAIL"
        WORKER_SUBMISSION_SUCCESS=false
    fi
    
    echo ""
fi

# Test 3: Token Expiry Enforcement
echo "Test 3: Token Expiry Enforcement"
echo "---------------------------------"

EXPIRY_ISSUE_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "$BASE_URL/pilot-demo/api/evidence-links/issue" \
    -H "Content-Type: application/json" \
    -d "{
        \"tenant_id\": \"$TENANT_ID\",
        \"instruction_id\": \"CHG-2026-EXPIRY-$(date +%s)\",
        \"program_id\": \"$PROGRAM_ID\",
        \"submitter_class\": \"$SUBMITTER_CLASS\",
        \"submitter_msisdn\": \"$WORKER_PHONE\",
        \"worker_id\": \"$WORKER_ID\",
        \"expires_in_seconds\": 1
    }")

HTTP_CODE=$(echo "$EXPIRY_ISSUE_RESPONSE" | tail -n1)
EXPIRY_BODY=$(echo "$EXPIRY_ISSUE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    EXPIRY_TOKEN=$(echo "$EXPIRY_BODY" | jq -r '.token // empty')
    if [ -n "$EXPIRY_TOKEN" ]; then
        # Wait for token to expire
        sleep 2
        
        EXPIRY_SUBMIT_RESPONSE=$(curl -s -w "\n%{http_code}" \
            -X POST "$BASE_URL/v1/evidence-links/submit" \
            -H "Authorization: Bearer $EXPIRY_TOKEN" \
            -H "x-tenant-id: $TENANT_ID" \
            -H "x-submitter-msisdn: $WORKER_PHONE" \
            -H "Content-Type: application/json" \
            -d "{
                \"artifact_type\": \"WEIGHBRIDGE_RECORD\",
                \"artifact_ref\": \"expiry-test-$(date +%s)\",
                \"latitude\": -15.4167,
                \"longitude\": 28.2833,
                \"structured_payload\": {
                    \"plastic_type\": \"PET\",
                    \"gross_weight_kg\": 5.0,
                    \"tare_weight_kg\": 0.1,
                    \"net_weight_kg\": 4.9,
                    \"collector_id\": \"$WORKER_ID\"
                }
            }")
        
        HTTP_CODE=$(echo "$EXPIRY_SUBMIT_RESPONSE" | tail -n1)
        
        if [ "$HTTP_CODE" = "401" ]; then
            report_test "Expired token rejected" "PASS"
            EXPIRY_ENFORCEMENT_CONFIRMED=true
        else
            report_test "Expired token rejected (HTTP $HTTP_CODE, expected 401)" "FAIL"
            EXPIRY_ENFORCEMENT_CONFIRMED=false
        fi
    else
        report_test "Expiry test (no token issued)" "FAIL"
        EXPIRY_ENFORCEMENT_CONFIRMED=false
    fi
else
    report_test "Expiry test (issuance failed)" "FAIL"
    EXPIRY_ENFORCEMENT_CONFIRMED=false
fi

echo ""

# Test 4: Single-Use Enforcement
if [ "$TOKEN_ISSUANCE_SUCCESS" = true ] && [ "$WORKER_SUBMISSION_SUCCESS" = true ]; then
    echo "Test 4: Single-Use Enforcement"
    echo "-------------------------------"
    
    # Try to reuse the token from Test 2
    REUSE_RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X POST "$BASE_URL/v1/evidence-links/submit" \
        -H "Authorization: Bearer $TOKEN" \
        -H "x-tenant-id: $TENANT_ID" \
        -H "x-submitter-msisdn: $WORKER_PHONE" \
        -H "Content-Type: application/json" \
        -d "{
            \"artifact_type\": \"WEIGHBRIDGE_RECORD\",
            \"artifact_ref\": \"reuse-test-$(date +%s)\",
            \"latitude\": -15.4167,
            \"longitude\": 28.2833,
            \"structured_payload\": {
                \"plastic_type\": \"PET\",
                \"gross_weight_kg\": 5.0,
                \"tare_weight_kg\": 0.1,
                \"net_weight_kg\": 4.9,
                \"collector_id\": \"$WORKER_ID\"
            }
        }")
    
    HTTP_CODE=$(echo "$REUSE_RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" = "409" ]; then
        report_test "Token reuse rejected" "PASS"
        SINGLE_USE_ENFORCEMENT_CONFIRMED=true
    else
        report_test "Token reuse rejected (HTTP $HTTP_CODE, expected 409)" "FAIL"
        SINGLE_USE_ENFORCEMENT_CONFIRMED=false
    fi
    
    echo ""
fi

# Test 5: GPS Validation
echo "Test 5: GPS Validation (Out of Radius)"
echo "---------------------------------------"

GPS_ISSUE_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "$BASE_URL/pilot-demo/api/evidence-links/issue" \
    -H "Content-Type: application/json" \
    -d "{
        \"tenant_id\": \"$TENANT_ID\",
        \"instruction_id\": \"CHG-2026-GPS-$(date +%s)\",
        \"program_id\": \"$PROGRAM_ID\",
        \"submitter_class\": \"$SUBMITTER_CLASS\",
        \"submitter_msisdn\": \"$WORKER_PHONE\",
        \"worker_id\": \"$WORKER_ID\",
        \"expires_in_seconds\": 900
    }")

HTTP_CODE=$(echo "$GPS_ISSUE_RESPONSE" | tail -n1)
GPS_BODY=$(echo "$GPS_ISSUE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    GPS_TOKEN=$(echo "$GPS_BODY" | jq -r '.token // empty')
    if [ -n "$GPS_TOKEN" ]; then
        # Submit with GPS coordinates far outside the 250m radius
        GPS_SUBMIT_RESPONSE=$(curl -s -w "\n%{http_code}" \
            -X POST "$BASE_URL/v1/evidence-links/submit" \
            -H "Authorization: Bearer $GPS_TOKEN" \
            -H "x-tenant-id: $TENANT_ID" \
            -H "x-submitter-msisdn: $WORKER_PHONE" \
            -H "Content-Type: application/json" \
            -d "{
                \"artifact_type\": \"WEIGHBRIDGE_RECORD\",
                \"artifact_ref\": \"gps-test-$(date +%s)\",
                \"latitude\": -15.5000,
                \"longitude\": 28.5000,
                \"structured_payload\": {
                    \"plastic_type\": \"PET\",
                    \"gross_weight_kg\": 5.0,
                    \"tare_weight_kg\": 0.1,
                    \"net_weight_kg\": 4.9,
                    \"collector_id\": \"$WORKER_ID\"
                }
            }")
        
        HTTP_CODE=$(echo "$GPS_SUBMIT_RESPONSE" | tail -n1)
        
        if [ "$HTTP_CODE" = "422" ]; then
            report_test "Out-of-radius GPS rejected" "PASS"
            GPS_VALIDATION_CONFIRMED=true
        else
            report_test "Out-of-radius GPS rejected (HTTP $HTTP_CODE, expected 422)" "FAIL"
            GPS_VALIDATION_CONFIRMED=false
        fi
    else
        report_test "GPS test (no token issued)" "FAIL"
        GPS_VALIDATION_CONFIRMED=false
    fi
else
    report_test "GPS test (issuance failed)" "FAIL"
    GPS_VALIDATION_CONFIRMED=false
fi

echo ""

# Test 6: Supervisory Reveal (optional - depends on data availability)
echo "Test 6: Supervisory Reveal"
echo "---------------------------"

REVEAL_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X GET "$BASE_URL/pilot-demo/api/supervisory/reveal?tenant_id=$TENANT_ID&program_id=$PROGRAM_ID")

HTTP_CODE=$(echo "$REVEAL_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ]; then
    report_test "Supervisory reveal endpoint accessible" "PASS"
    SUPERVISORY_REVEAL_CONFIRMED=true
else
    report_test "Supervisory reveal endpoint (HTTP $HTTP_CODE)" "FAIL"
    SUPERVISORY_REVEAL_CONFIRMED=false
fi

echo ""

# Summary
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

# Emit evidence JSON
mkdir -p "$EVIDENCE_DIR"

cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "GF-W1-UI-009",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "token_issuance_success": ${TOKEN_ISSUANCE_SUCCESS:-false},
  "worker_submission_success": ${WORKER_SUBMISSION_SUCCESS:-false},
  "supervisory_reveal_confirmed": ${SUPERVISORY_REVEAL_CONFIRMED:-false},
  "expiry_enforcement_confirmed": ${EXPIRY_ENFORCEMENT_CONFIRMED:-false},
  "single_use_enforcement_confirmed": ${SINGLE_USE_ENFORCEMENT_CONFIRMED:-false},
  "gps_validation_confirmed": ${GPS_VALIDATION_CONFIRMED:-false},
  "tests_passed": $TESTS_PASSED,
  "tests_failed": $TESTS_FAILED
}
EOF

echo "Evidence written to: $EVIDENCE_FILE"
echo ""

# Exit with appropriate code
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}E2E verification FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}E2E verification PASSED${NC}"
    exit 0
fi
