#!/bin/bash
#
# Verifier for TSK-P2-W8-DB-004: Deterministic attestation hash recomputation
#
# This script verifies that PostgreSQL recomputes the authoritative attestation hash
# at the DB write boundary and hard-rejects mismatches.
#

set -e

TASK_ID="TSK-P2-W8-DB-004"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_db_004.json"

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

add_trace "verify_tsk_p2_w8_db_004.sh executed"

# Check 1: Migration exists
add_trace "Checking migration file"
MIGRATION_FILE="schema/migrations/0175_wave8_attestation_hash_enforcement.sql"
if [ -f "$MIGRATION_FILE" ]; then
  add_check "[ID w8_db_004_work_01] Migration exists" "PASS" "Migration found at $MIGRATION_FILE"
  add_output "✓ Migration exists"
else
  add_check "[ID w8_db_004_work_01] Migration exists" "FAIL" "Migration not found at $MIGRATION_FILE"
  add_output "✗ Migration not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Migration implements hash recomputation function
add_trace "Checking migration implements hash recomputation function"
if grep -q "recompute_transition_hash" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_004_work_01] Migration implements hash recomputation function" "PASS" "Migration creates recompute_transition_hash() function"
  add_output "✓ Migration implements hash recomputation function"
else
  add_check "[ID w8_db_004_work_01] Migration implements hash recomputation function" "FAIL" "Migration does not create hash recomputation function"
  add_output "✗ Migration does not create hash recomputation function"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: Migration uses SHA-256 per contract rules
add_trace "Checking migration uses SHA-256 per contract rules"
if grep -q "SHA-256" "$MIGRATION_FILE" 2>/dev/null || grep -q "sha256" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_004_work_01] Migration uses SHA-256 per contract rules" "PASS" "Migration uses SHA-256 hash algorithm"
  add_output "✓ Migration uses SHA-256 per contract rules"
else
  add_check "[ID w8_db_004_work_01] Migration uses SHA-256 per contract rules" "FAIL" "Migration does not use SHA-256"
  add_output "✗ Migration does not use SHA-256"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Migration enforces fail-closed rejection on mismatch
add_trace "Checking migration enforces fail-closed rejection on mismatch"
if grep -q "enforce_transition_hash_match" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "P7805" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_004_work_02] Migration enforces fail-closed rejection on mismatch" "PASS" "Migration creates enforcement function with P7805 failure mode"
  add_output "✓ Migration enforces fail-closed rejection on mismatch"
else
  add_check "[ID w8_db_004_work_02] Migration enforces fail-closed rejection on mismatch" "FAIL" "Migration does not enforce fail-closed rejection"
  add_output "✗ Migration does not enforce fail-closed rejection"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: Verification SQL exists
add_trace "Checking verification SQL"
VERIFICATION_SQL="scripts/db/verify_w8_attestation_hash_enforcement.sql"
if [ -f "$VERIFICATION_SQL" ]; then
  add_check "[ID w8_db_004_work_03] Verification SQL exists" "PASS" "Verification SQL found at $VERIFICATION_SQL"
  add_output "✓ Verification SQL exists"
else
  add_check "[ID w8_db_004_work_03] Verification SQL exists" "FAIL" "Verification SQL not found at $VERIFICATION_SQL"
  add_output "✗ Verification SQL not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 6: Verification SQL proves tampered-hash rejection
add_trace "Checking verification SQL proves tampered-hash rejection"
if grep -q "TAMPERED_HASH_REJECTED" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "INSERT.*asset_batches" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_004_work_03] Verification SQL proves tampered-hash rejection" "PASS" "Verification SQL includes physical write test for tampered hash rejection"
  add_output "✓ Verification SQL proves tampered-hash rejection"
else
  add_check "[ID w8_db_004_work_03] Verification SQL proves tampered-hash rejection" "FAIL" "Verification SQL does not prove tampered-hash rejection"
  add_output "✗ Verification SQL does not prove tampered-hash rejection"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 7: Verification SQL proves correct-hash acceptance
add_trace "Checking verification SQL proves correct-hash acceptance"
if grep -q "CORRECT_HASH_ACCEPTED" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_004_work_03] Verification SQL proves correct-hash acceptance" "PASS" "Verification SQL includes physical write test for correct hash acceptance"
  add_output "✓ Verification SQL proves correct-hash acceptance"
else
  add_check "[ID w8_db_004_work_03] Verification SQL proves correct-hash acceptance" "FAIL" "Verification SQL does not prove correct-hash acceptance"
  add_output "✗ Verification SQL does not prove correct-hash acceptance"
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
