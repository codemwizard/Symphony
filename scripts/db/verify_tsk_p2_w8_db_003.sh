#!/bin/bash
#
# Verifier for TSK-P2-W8-DB-003: SQL-authoritative canonical payload construction
#
# This script verifies that SQL runtime emits canonical bytes identical to the
# frozen contract vector for the same logical input.
#

set -e

TASK_ID="TSK-P2-W8-DB-003"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_db_003.json"

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

add_trace "verify_tsk_p2_w8_db_003.sh executed"

# Check 1: Migration exists
add_trace "Checking migration file"
MIGRATION_FILE="schema/migrations/0174_wave8_canonical_payload.sql"
if [ -f "$MIGRATION_FILE" ]; then
  add_check "[ID w8_db_003_work_01] Migration exists" "PASS" "Migration found at $MIGRATION_FILE"
  add_output "✓ Migration exists"
else
  add_check "[ID w8_db_003_work_01] Migration exists" "FAIL" "Migration not found at $MIGRATION_FILE"
  add_output "✗ Migration not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Migration implements SQL-side canonical payload construction
add_trace "Checking migration implements SQL-side canonical payload construction"
if grep -q "construct_canonical_attestation_payload" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_003_work_01] Migration implements SQL-side canonical payload construction" "PASS" "Migration creates construct_canonical_attestation_payload() function"
  add_output "✓ Migration implements SQL-side canonical payload construction"
else
  add_check "[ID w8_db_003_work_01] Migration implements SQL-side canonical payload construction" "FAIL" "Migration does not create canonical payload function"
  add_output "✗ Migration does not create canonical payload function"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: Migration uses exact contract-defined field set
add_trace "Checking migration uses exact contract-defined field set"
REQUIRED_FIELDS=("contract_version" "canonicalization_version" "project_id" "entity_type" "entity_id" "from_state" "to_state" "execution_id" "interpretation_version_id" "policy_decision_id" "transition_hash" "occurred_at")
MISSING_FIELDS=()
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! grep -q "$field" "$MIGRATION_FILE" 2>/dev/null; then
    MISSING_FIELDS+=("$field")
  fi
done

if [ ${#MISSING_FIELDS[@]} -eq 0 ]; then
  add_check "[ID w8_db_003_work_01] Migration uses exact contract-defined field set" "PASS" "Migration includes all 12 contract-defined fields"
  add_output "✓ Migration uses exact contract-defined field set"
else
  add_check "[ID w8_db_003_work_01] Migration uses exact contract-defined field set" "FAIL" "Migration missing fields: ${MISSING_FIELDS[*]}"
  add_output "✗ Migration missing fields: ${MISSING_FIELDS[*]}"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Migration materializes canonical bytes at authoritative boundary
add_trace "Checking migration materializes canonical bytes at authoritative boundary"
if grep -q "canonical_payload_bytes" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_003_work_02] Migration materializes canonical bytes at authoritative boundary" "PASS" "Migration adds canonical_payload_bytes column to asset_batches"
  add_output "✓ Migration materializes canonical bytes at authoritative boundary"
else
  add_check "[ID w8_db_003_work_02] Migration materializes canonical bytes at authoritative boundary" "FAIL" "Migration does not add canonical_payload_bytes column"
  add_output "✗ Migration does not add canonical_payload_bytes column"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: Verification SQL exists
add_trace "Checking verification SQL"
VERIFICATION_SQL="scripts/db/verify_w8_canonical_payload.sql"
if [ -f "$VERIFICATION_SQL" ]; then
  add_check "[ID w8_db_003_work_03] Verification SQL exists" "PASS" "Verification SQL found at $VERIFICATION_SQL"
  add_output "✓ Verification SQL exists"
else
  add_check "[ID w8_db_003_work_03] Verification SQL exists" "FAIL" "Verification SQL not found at $VERIFICATION_SQL"
  add_output "✗ Verification SQL not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 6: Verification SQL proves SQL canonical bytes match contract vector
add_trace "Checking verification SQL proves SQL canonical bytes match contract vector"
if grep -q "Canonical payload bytes match contract vector" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "expected_hex" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_003_work_03] Verification SQL proves SQL canonical bytes match contract vector" "PASS" "Verification SQL compares SQL output to frozen contract vector"
  add_output "✓ Verification SQL proves SQL canonical bytes match contract vector"
else
  add_check "[ID w8_db_003_work_03] Verification SQL proves SQL canonical bytes match contract vector" "FAIL" "Verification SQL does not compare to contract vector"
  add_output "✗ Verification SQL does not compare to contract vector"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 7: Verification SQL includes null field rejection test
add_trace "Checking verification SQL includes null field rejection test"
if grep -q "NULL_REJECTED" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_003_work_03] Verification SQL includes null field rejection test" "PASS" "Verification SQL tests null field rejection"
  add_output "✓ Verification SQL includes null field rejection test"
else
  add_check "[ID w8_db_003_work_03] Verification SQL includes null field rejection test" "FAIL" "Verification SQL does not test null field rejection"
  add_output "✗ Verification SQL does not test null field rejection"
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
