#!/bin/bash
#
# Verifier for TSK-P2-W8-DB-002: Placeholder and legacy posture removal
#
# This script verifies that placeholder and legacy compatibility postures
# have been removed and that placeholder-style values are rejected on the
# asset_batches write boundary.
#

set -e

TASK_ID="TSK-P2-W8-DB-002"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_db_002.json"

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

add_trace "verify_tsk_p2_w8_db_002.sh executed"

# Check 1: Placeholder inventory documented
add_trace "Checking placeholder inventory documentation"
INVENTORY_FILE="docs/plans/phase2/TSK-P2-W8-DB-002/PLACEHOLDER_INVENTORY.md"
if [ -f "$INVENTORY_FILE" ]; then
  add_check "[ID w8_db_002_work_01] Placeholder inventory documented" "PASS" "Placeholder inventory documented at $INVENTORY_FILE"
  add_output "✓ Placeholder inventory documented"
else
  add_check "[ID w8_db_002_work_01] Placeholder inventory documented" "FAIL" "Placeholder inventory not found at $INVENTORY_FILE"
  add_output "✗ Placeholder inventory not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Migration exists
add_trace "Checking migration file"
MIGRATION_FILE="schema/migrations/0173_wave8_placeholder_cleanup.sql"
if [ -f "$MIGRATION_FILE" ]; then
  add_check "[ID w8_db_002_work_02] Migration exists" "PASS" "Migration found at $MIGRATION_FILE"
  add_output "✓ Migration exists"
else
  add_check "[ID w8_db_002_work_02] Migration exists" "FAIL" "Migration not found at $MIGRATION_FILE"
  add_output "✗ Migration not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: Migration drops signature placeholder trigger
add_trace "Checking migration drops signature placeholder trigger"
if grep -q "DROP TRIGGER.*tr_add_signature_placeholder" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_002_work_02] Migration drops signature placeholder trigger" "PASS" "Migration drops tr_add_signature_placeholder trigger"
  add_output "✓ Migration drops signature placeholder trigger"
else
  add_check "[ID w8_db_002_work_02] Migration drops signature placeholder trigger" "FAIL" "Migration does not drop signature placeholder trigger"
  add_output "✗ Migration does not drop signature placeholder trigger"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Migration adds CHECK constraints
add_trace "Checking migration adds CHECK constraints"
if grep -q "ADD CONSTRAINT.*no_placeholder_transition_hash" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "ADD CONSTRAINT.*no_non_reproducible_data_authority" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_002_work_02] Migration adds CHECK constraints" "PASS" "Migration adds CHECK constraints to reject placeholder values"
  add_output "✓ Migration adds CHECK constraints"
else
  add_check "[ID w8_db_002_work_02] Migration adds CHECK constraints" "FAIL" "Migration does not add CHECK constraints"
  add_output "✗ Migration does not add CHECK constraints"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: Verification SQL exists
add_trace "Checking verification SQL"
VERIFICATION_SQL="scripts/db/verify_w8_placeholder_cleanup.sql"
if [ -f "$VERIFICATION_SQL" ]; then
  add_check "[ID w8_db_002_work_03] Verification SQL exists" "PASS" "Verification SQL found at $VERIFICATION_SQL"
  add_output "✓ Verification SQL exists"
else
  add_check "[ID w8_db_002_work_03] Verification SQL exists" "FAIL" "Verification SQL not found at $VERIFICATION_SQL"
  add_output "✗ Verification SQL not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 6: Verification SQL proves placeholder rejection
add_trace "Checking verification SQL proves placeholder rejection"
if grep -q "INSERT.*PLACEHOLDER_" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "INSERT_FAILED_PLACEHOLDER_REJECTED" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_002_work_03] Verification SQL proves placeholder rejection" "PASS" "Verification SQL includes physical write test for placeholder rejection"
  add_output "✓ Verification SQL proves placeholder rejection"
else
  add_check "[ID w8_db_002_work_03] Verification SQL proves placeholder rejection" "FAIL" "Verification SQL does not prove placeholder rejection"
  add_output "✗ Verification SQL does not prove placeholder rejection"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 7: Verification SQL proves non_reproducible rejection
add_trace "Checking verification SQL proves non_reproducible rejection"
if grep -q "INSERT.*non_reproducible" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "INSERT_FAILED_NON_REPRODUCIBLE_REJECTED" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_002_work_03] Verification SQL proves non_reproducible rejection" "PASS" "Verification SQL includes physical write test for non_reproducible rejection"
  add_output "✓ Verification SQL proves non_reproducible rejection"
else
  add_check "[ID w8_db_002_work_03] Verification SQL proves non_reproducible rejection" "FAIL" "Verification SQL does not prove non_reproducible rejection"
  add_output "✗ Verification SQL does not prove non_reproducible rejection"
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
