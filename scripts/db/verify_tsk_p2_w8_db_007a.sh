#!/bin/bash
#
# Verifier for TSK-P2-W8-DB-007a: Scope authorization enforcement
#
# This script verifies that PostgreSQL distinguishes wrong-scope failures
# at asset_batches as a distinct authoritative boundary failure.
#

set -e

TASK_ID="TSK-P2-W8-DB-007a"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_db_007a.json"

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

add_trace "verify_tsk_p2_w8_db_007a.sh executed"

# Check 1: Migration exists
add_trace "Checking migration file"
MIGRATION_FILE="schema/migrations/0178_wave8_scope_and_timestamp_enforcement.sql"
if [ -f "$MIGRATION_FILE" ]; then
  add_check "[ID w8_db_007a_work_01] Migration exists" "PASS" "Migration found at $MIGRATION_FILE"
  add_output "✓ Migration exists"
else
  add_check "[ID w8_db_007a_work_01] Migration exists" "FAIL" "Migration not found at $MIGRATION_FILE"
  add_output "✗ Migration not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Migration enforces project scope authorization
add_trace "Checking migration enforces project scope authorization"
if grep -q "scope authorization" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "P7810" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_007a_work_01] Migration enforces project scope authorization" "PASS" "Migration enforces scope authorization with P7810 failure mode"
  add_output "✓ Migration enforces project scope authorization"
else
  add_check "[ID w8_db_007a_work_01] Migration enforces project scope authorization" "FAIL" "Migration does not enforce scope authorization"
  add_output "✗ Migration does not enforce scope authorization"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: Migration enforces entity-type scope authorization
add_trace "Checking migration enforces entity-type scope authorization"
if grep -q "entity_type" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "entity-type scope" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_007a_work_01] Migration enforces entity-type scope authorization" "PASS" "Migration enforces entity-type scope authorization"
  add_output "✓ Migration enforces entity-type scope authorization"
else
  add_check "[ID w8_db_007a_work_01] Migration enforces entity-type scope authorization" "FAIL" "Migration does not enforce entity-type scope authorization"
  add_output "✗ Migration does not enforce entity-type scope authorization"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Verification SQL exists
add_trace "Checking verification SQL"
VERIFICATION_SQL="scripts/db/verify_tsk_p2_w8_db_007a.sql"
if [ -f "$VERIFICATION_SQL" ]; then
  add_check "[ID w8_db_007a_work_02] Verification SQL exists" "PASS" "Verification SQL found at $VERIFICATION_SQL"
  add_output "✓ Verification SQL exists"
else
  add_check "[ID w8_db_007a_work_02] Verification SQL exists" "FAIL" "Verification SQL not found at $VERIFICATION_SQL"
  add_output "✗ Verification SQL not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: Verification SQL distinguishes wrong-scope failures
add_trace "Checking verification SQL distinguishes wrong-scope failures"
if grep -q "WRONG_SCOPE_REJECTED" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "INSERT INTO public.asset_batches" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_007a_work_02] Verification SQL distinguishes wrong-scope failures" "PASS" "Verification SQL includes physical write test for wrong-scope rejection"
  add_output "✓ Verification SQL distinguishes wrong-scope failures"
else
  add_check "[ID w8_db_007a_work_02] Verification SQL distinguishes wrong-scope failures" "FAIL" "Verification SQL does not distinguish wrong-scope failures"
  add_output "✗ Verification SQL does not distinguish wrong-scope failures"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 6: Verification SQL distinguishes correct-scope acceptance
add_trace "Checking verification SQL distinguishes correct-scope acceptance"
if grep -q "CORRECT_SCOPE_ACCEPTED" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_007a_work_02] Verification SQL distinguishes correct-scope acceptance" "PASS" "Verification SQL includes physical write test for correct-scope acceptance"
  add_output "✓ Verification SQL distinguishes correct-scope acceptance"
else
  add_check "[ID w8_db_007a_work_02] Verification SQL distinguishes correct-scope acceptance" "FAIL" "Verification SQL does not distinguish correct-scope acceptance"
  add_output "✗ Verification SQL does not distinguish correct-scope acceptance"
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
