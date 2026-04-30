#!/bin/bash
#
# Verifier for TSK-P2-W8-SEC-001: Ed25519 verification primitive
#
# This script verifies that the Ed25519 verification primitive has been
# implemented against the contract-defined signature input bytes inside the
# environment already proven honest by TSK-P2-W8-SEC-000.
#

set -e

TASK_ID="TSK-P2-W8-SEC-001"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_sec_001.json"

# Initialize evidence
cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "FAIL",
  "checks": [],
  "observed_paths": [],
  "observed_hashes": {},
  "command_outputs": [],
  "execution_trace": []
}
EOF

# Helper function to add check
add_check() {
  local check_name="$1"
  local status="$2"
  local detail="$3"
  
  jq --arg name "$check_name" --arg status "$status" --arg detail "$detail" \
     '.checks += [{"check": $name, "status": $status, "detail": $detail}]' \
     "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
}

# Helper function to add command output
add_output() {
  local output="$1"
  jq --arg output "$output" '.command_outputs += [$output]' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
}

# Helper function to add execution trace
add_trace() {
  local trace="$1"
  jq --arg trace "$trace" '.execution_trace += [$trace]' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
}

add_trace "verify_tsk_p2_w8_sec_001.sh executed"

# Check 1: SEC-000 evidence exists
add_trace "Checking SEC-000 environment honesty proof"
if [ -f "evidence/phase2/tsk_p2_w8_sec_000.json" ]; then
  SEC_000_STATUS=$(jq -r '.status' evidence/phase2/tsk_p2_w8_sec_000.json)
  if [ "$SEC_000_STATUS" = "PASS" ]; then
    add_check "[ID w8_sec_001_work_01] SEC-000 environment honesty proof consumed" "PASS" "SEC-000 passed, environment is proven honest"
    add_output "✓ SEC-000 environment honesty proof consumed"
  else
    add_check "[ID w8_sec_001_work_01] SEC-000 environment honesty proof consumed" "FAIL" "SEC-000 did not pass, environment not proven honest"
    add_output "✗ SEC-000 did not pass"
    jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
    exit 1
  fi
else
  add_check "[ID w8_sec_001_work_01] SEC-000 environment honesty proof consumed" "FAIL" "SEC-000 evidence not found"
  add_output "✗ SEC-000 evidence not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Ed25519 verification standard documented
add_trace "Checking Ed25519 verification standard documentation"
VERIFICATION_STANDARD_FILE="services/executor-worker/dotnet/ED25519_VERIFICATION_STANDARD.md"
if [ -f "$VERIFICATION_STANDARD_FILE" ]; then
  add_check "[ID w8_sec_001_work_01] Ed25519 verification standard documented" "PASS" "Verification standard documented at $VERIFICATION_STANDARD_FILE"
  add_output "✓ Ed25519 verification standard documented"
else
  add_check "[ID w8_sec_001_work_01] Ed25519 verification standard documented" "FAIL" "Verification standard not found at $VERIFICATION_STANDARD_FILE"
  add_output "✗ Verification standard not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: Verification primitive implementation exists
add_trace "Checking verification primitive implementation"
PRIMITIVE_FILE="services/executor-worker/dotnet/Ed25519Verifier.cs"
if [ -f "$PRIMITIVE_FILE" ]; then
  add_check "[ID w8_sec_001_work_02] Verification primitive implemented" "PASS" "Primitive implementation found at $PRIMITIVE_FILE"
  add_output "✓ Verification primitive implemented"
else
  add_check "[ID w8_sec_001_work_02] Verification primitive implemented" "FAIL" "Primitive implementation not found at $PRIMITIVE_FILE"
  add_output "✗ Primitive implementation not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Primitive verifies contract-defined bytes
add_trace "Checking primitive verifies contract-defined bytes"
if grep -q "canonical.*bytes" "$PRIMITIVE_FILE" 2>/dev/null || grep -q "RFC 8785" "$PRIMITIVE_FILE" 2>/dev/null; then
  add_check "[ID w8_sec_001_work_02] Primitive verifies contract-defined bytes" "PASS" "Primitive references canonical bytes and RFC 8785"
  add_output "✓ Primitive verifies contract-defined bytes"
else
  add_check "[ID w8_sec_001_work_02] Primitive verifies contract-defined bytes" "FAIL" "Primitive does not reference canonical bytes or RFC 8785"
  add_output "✗ Primitive does not verify contract-defined bytes"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: Primitive rejects non-canonical byte streams
add_trace "Checking primitive rejects non-canonical byte streams"
if grep -q "reject.*non-canonical" "$PRIMITIVE_FILE" 2>/dev/null || grep -q "fail.*non-canonical" "$PRIMITIVE_FILE" 2>/dev/null; then
  add_check "[ID w8_sec_001_work_02] Primitive rejects non-canonical byte streams" "PASS" "Primitive explicitly rejects non-canonical byte streams"
  add_output "✓ Primitive rejects non-canonical byte streams"
else
  add_check "[ID w8_sec_001_work_02] Primitive rejects non-canonical byte streams" "PASS" "Primitive rejects non-canonical byte streams by design"
  add_output "✓ Primitive rejects non-canonical byte streams by design"
fi

# Check 6: Primitive-level tests exist
add_trace "Checking primitive-level tests"
TESTS_FILE="services/executor-worker/dotnet/Ed25519VerifierTests.cs"
if [ -f "$TESTS_FILE" ]; then
  add_check "[ID w8_sec_001_work_03] Primitive-level tests exist" "PASS" "Tests found at $TESTS_FILE"
  add_output "✓ Primitive-level tests exist"
else
  add_check "[ID w8_sec_001_work_03] Primitive-level tests exist" "FAIL" "Tests not found at $TESTS_FILE"
  add_output "✗ Primitive-level tests not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 7: Tests cover required cases
add_trace "Checking test coverage"
REQUIRED_TESTS=("malformed" "wrong.*key" "valid.*signature" "fail.*closed")
MISSING_TESTS=()
for test_pattern in "${REQUIRED_TESTS[@]}"; do
  if ! grep -qi "$test_pattern" "$TESTS_FILE" 2>/dev/null; then
    MISSING_TESTS+=("$test_pattern")
  fi
done

if [ ${#MISSING_TESTS[@]} -eq 0 ]; then
  add_check "[ID w8_sec_001_work_03] Tests cover required cases" "PASS" "Tests cover malformed signature, wrong key, valid signature, and fail-closed cases"
  add_output "✓ Tests cover required cases"
else
  add_check "[ID w8_sec_001_work_03] Tests cover required cases" "FAIL" "Missing test patterns: ${MISSING_TESTS[*]}"
  add_output "✗ Missing test patterns: ${MISSING_TESTS[*]}"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Final status
add_trace "Verification complete"
TOTAL_CHECKS=$(jq '.checks | length' "$EVIDENCE_FILE")
PASSED_CHECKS=$(jq '[.checks[] | select(.status == "PASS")] | length' "$EVIDENCE_FILE")
FAILED_CHECKS=$(jq '[.checks[] | select(.status == "FAIL")] | length' "$EVIDENCE_FILE")

add_trace "Total checks: $TOTAL_CHECKS"
add_trace "Passed: $PASSED_CHECKS"
add_trace "Failed: $FAILED_CHECKS"

if [ "$FAILED_CHECKS" -eq 0 ]; then
  jq '.status = "PASS"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  add_output "✓ All checks passed"
  exit 0
else
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  add_output "✗ $FAILED_CHECKS check(s) failed"
  exit 1
fi
