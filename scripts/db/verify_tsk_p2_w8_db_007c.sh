#!/bin/bash
#
# Verifier for TSK-P2-W8-DB-007c: Replay law enforcement
#
# This script verifies that PostgreSQL distinguishes replay-invalid failures
# at asset_batches as a distinct authoritative boundary failure.
#

set -e

TASK_ID="TSK-P2-W8-DB-007c"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_db_007c.json"

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

add_trace "verify_tsk_p2_w8_db_007c.sh executed"

# Check 1: Migration exists
add_trace "Checking migration file"
MIGRATION_FILE="schema/migrations/0178_wave8_scope_and_timestamp_enforcement.sql"
if [ -f "$MIGRATION_FILE" ]; then
  add_check "[ID w8_db_007c_work_01] Migration exists" "PASS" "Migration found at $MIGRATION_FILE"
  add_output "✓ Migration exists"
else
  add_check "[ID w8_db_007c_work_01] Migration exists" "FAIL" "Migration not found at $MIGRATION_FILE"
  add_output "✗ Migration not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Migration enforces replay law from signing contract
add_trace "Checking migration enforces replay law from signing contract"
if grep -q "replay prevention" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "P7812" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "attestation_nonce" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_007c_work_01] Migration enforces replay law from signing contract" "PASS" "Migration enforces replay prevention with P7812 failure mode"
  add_output "✓ Migration enforces replay law from signing contract"
else
  add_check "[ID w8_db_007c_work_01] Migration enforces replay law from signing contract" "FAIL" "Migration does not enforce replay prevention"
  add_output "✗ Migration does not enforce replay prevention"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: Verification SQL exists
add_trace "Checking verification SQL"
VERIFICATION_SQL="scripts/db/verify_tsk_p2_w8_db_007c.sql"
if [ -f "$VERIFICATION_SQL" ]; then
  add_check "[ID w8_db_007c_work_02] Verification SQL exists" "PASS" "Verification SQL found at $VERIFICATION_SQL"
  add_output "✓ Verification SQL exists"
else
  add_check "[ID w8_db_007c_work_02] Verification SQL exists" "FAIL" "Verification SQL not found at $VERIFICATION_SQL"
  add_output "✗ Verification SQL not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Verification SQL distinguishes replay-invalid failures
add_trace "Checking verification SQL distinguishes replay-invalid failures"
if grep -q "MISSING_NONCE_REJECTED" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "INSERT INTO public.asset_batches" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_007c_work_02] Verification SQL distinguishes replay-invalid failures" "PASS" "Verification SQL includes physical write test for replay prevention failure"
  add_output "✓ Verification SQL distinguishes replay-invalid failures"
else
  add_check "[ID w8_db_007c_work_02] Verification SQL distinguishes replay-invalid failures" "FAIL" "Verification SQL does not distinguish replay-invalid failures"
  add_output "✗ Verification SQL does not distinguish replay-invalid failures"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: Verification SQL distinguishes valid nonce acceptance
add_trace "Checking verification SQL distinguishes valid nonce acceptance"
if grep -q "VALID_NONCE_ACCEPTED" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_007c_work_02] Verification SQL distinguishes valid nonce acceptance" "PASS" "Verification SQL includes physical write test for valid nonce acceptance"
  add_output "✓ Verification SQL distinguishes valid nonce acceptance"
else
  add_check "[ID w8_db_007c_work_02] Verification SQL distinguishes valid nonce acceptance" "FAIL" "Verification SQL does not distinguish valid nonce acceptance"
  add_output "✗ Verification SQL does not distinguish valid nonce acceptance"
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
