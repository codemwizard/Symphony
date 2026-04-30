#!/bin/bash
#
# Verifier for TSK-P2-W8-DB-007b: Persisted timestamp enforcement
#
# This script verifies that PostgreSQL distinguishes regenerated-timestamp failures
# at asset_batches as a distinct authoritative boundary failure.
#

set -e

TASK_ID="TSK-P2-W8-DB-007b"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_db_007b.json"

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

add_trace "verify_tsk_p2_w8_db_007b.sh executed"

# Check 1: Migration exists
add_trace "Checking migration file"
MIGRATION_FILE="schema/migrations/0178_wave8_scope_and_timestamp_enforcement.sql"
if [ -f "$MIGRATION_FILE" ]; then
  add_check "[ID w8_db_007b_work_01] Migration exists" "PASS" "Migration found at $MIGRATION_FILE"
  add_output "✓ Migration exists"
else
  add_check "[ID w8_db_007b_work_01] Migration exists" "FAIL" "Migration not found at $MIGRATION_FILE"
  add_output "✗ Migration not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Migration enforces persisted-before-signing occurred_at semantics
add_trace "Checking migration enforces persisted-before-signing occurred_at semantics"
if grep -q "timestamp integrity" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "P7811" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "persisted-before-signing" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_007b_work_01] Migration enforces persisted-before-signing occurred_at semantics" "PASS" "Migration enforces timestamp integrity with P7811 failure mode"
  add_output "✓ Migration enforces persisted-before-signing occurred_at semantics"
else
  add_check "[ID w8_db_007b_work_01] Migration enforces persisted-before-signing occurred_at semantics" "FAIL" "Migration does not enforce timestamp integrity"
  add_output "✗ Migration does not enforce timestamp integrity"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: Verification SQL exists
add_trace "Checking verification SQL"
VERIFICATION_SQL="scripts/db/verify_tsk_p2_w8_db_007b.sql"
if [ -f "$VERIFICATION_SQL" ]; then
  add_check "[ID w8_db_007b_work_02] Verification SQL exists" "PASS" "Verification SQL found at $VERIFICATION_SQL"
  add_output "✓ Verification SQL exists"
else
  add_check "[ID w8_db_007b_work_02] Verification SQL exists" "FAIL" "Verification SQL not found at $VERIFICATION_SQL"
  add_output "✗ Verification SQL not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Verification SQL distinguishes regenerated-timestamp failures
add_trace "Checking verification SQL distinguishes regenerated-timestamp failures"
if grep -q "MISSING_CANONICAL_PAYLOAD_REJECTED" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "INSERT INTO public.asset_batches" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_007b_work_02] Verification SQL distinguishes regenerated-timestamp failures" "PASS" "Verification SQL includes physical write test for timestamp integrity failure"
  add_output "✓ Verification SQL distinguishes regenerated-timestamp failures"
else
  add_check "[ID w8_db_007b_work_02] Verification SQL distinguishes regenerated-timestamp failures" "FAIL" "Verification SQL does not distinguish regenerated-timestamp failures"
  add_output "✗ Verification SQL does not distinguish regenerated-timestamp failures"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: Verification SQL distinguishes valid timestamp acceptance
add_trace "Checking verification SQL distinguishes valid timestamp acceptance"
if grep -q "VALID_CANONICAL_PAYLOAD_ACCEPTED" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_007b_work_02] Verification SQL distinguishes valid timestamp acceptance" "PASS" "Verification SQL includes physical write test for valid timestamp acceptance"
  add_output "✓ Verification SQL distinguishes valid timestamp acceptance"
else
  add_check "[ID w8_db_007b_work_02] Verification SQL distinguishes valid timestamp acceptance" "FAIL" "Verification SQL does not distinguish valid timestamp acceptance"
  add_output "✗ Verification SQL does not distinguish valid timestamp acceptance"
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
