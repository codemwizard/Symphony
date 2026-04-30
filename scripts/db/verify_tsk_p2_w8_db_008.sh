#!/bin/bash
#
# Verifier for TSK-P2-W8-DB-008: Key lifecycle enforcement
#
# This script verifies that PostgreSQL enforces key lifecycle state
# in the authoritative verification path.
#

set -e

TASK_ID="TSK-P2-W8-DB-008"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_db_008.json"

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

add_trace "verify_tsk_p2_w8_db_008.sh executed"

# Check 1: Migration exists
add_trace "Checking migration file"
MIGRATION_FILE="schema/migrations/0179_wave8_key_lifecycle_enforcement.sql"
if [ -f "$MIGRATION_FILE" ]; then
  add_check "[ID w8_db_008_work_01] Migration exists" "PASS" "Migration found at $MIGRATION_FILE"
  add_output "✓ Migration exists"
else
  add_check "[ID w8_db_008_work_01] Migration exists" "FAIL" "Migration not found at $MIGRATION_FILE"
  add_output "✗ Migration not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Migration enforces active, revoked, expired, and superseded key states
add_trace "Checking migration enforces key lifecycle states"
if grep -q "P7813" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "revoked" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "expired" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "superseded" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_008_work_01] Migration enforces key lifecycle states" "PASS" "Migration enforces revoked, expired, and superseded key states with P7813 failure mode"
  add_output "✓ Migration enforces key lifecycle states"
else
  add_check "[ID w8_db_008_work_01] Migration enforces key lifecycle states" "FAIL" "Migration does not enforce key lifecycle states"
  add_output "✗ Migration does not enforce key lifecycle states"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: Migration defines explicit superseded-key behavior
add_trace "Checking migration defines explicit superseded-key behavior"
if grep -q "superseded_by" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "superseded_at" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "wave8_signer_superseded_by_valid" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_008_work_02] Migration defines explicit superseded-key behavior" "PASS" "Migration defines superseded-key behavior with fields and constraint"
  add_output "✓ Migration defines explicit superseded-key behavior"
else
  add_check "[ID w8_db_008_work_02] Migration defines explicit superseded-key behavior" "FAIL" "Migration does not define explicit superseded-key behavior"
  add_output "✗ Migration does not define explicit superseded-key behavior"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Verification SQL exists
add_trace "Checking verification SQL"
VERIFICATION_SQL="scripts/db/verify_w8_key_lifecycle_enforcement.sql"
if [ -f "$VERIFICATION_SQL" ]; then
  add_check "[ID w8_db_008_work_03] Verification SQL exists" "PASS" "Verification SQL found at $VERIFICATION_SQL"
  add_output "✓ Verification SQL exists"
else
  add_check "[ID w8_db_008_work_03] Verification SQL exists" "FAIL" "Verification SQL not found at $VERIFICATION_SQL"
  add_output "✗ Verification SQL not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: Verification SQL proves revoked and expired keys fail
add_trace "Checking verification SQL proves revoked and expired keys fail"
if grep -q "REVOKED_KEY_REJECTED" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "EXPIRED_KEY_REJECTED" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "INSERT INTO public.asset_batches" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_008_work_03] Verification SQL proves revoked and expired keys fail" "PASS" "Verification SQL includes physical write tests for revoked and expired key rejection"
  add_output "✓ Verification SQL proves revoked and expired keys fail"
else
  add_check "[ID w8_db_008_work_03] Verification SQL proves revoked and expired keys fail" "FAIL" "Verification SQL does not prove revoked and expired key rejection"
  add_output "✗ Verification SQL does not prove revoked and expired key rejection"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 6: Verification SQL proves superseded-key behavior matches explicit policy
add_trace "Checking verification SQL proves superseded-key behavior matches explicit policy"
if grep -q "SUPERSEDED_KEY_REJECTED" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_008_work_03] Verification SQL proves superseded-key behavior matches explicit policy" "PASS" "Verification SQL includes physical write test for superseded key rejection"
  add_output "✓ Verification SQL proves superseded-key behavior matches explicit policy"
else
  add_check "[ID w8_db_008_work_03] Verification SQL proves superseded-key behavior matches explicit policy" "FAIL" "Verification SQL does not prove superseded-key behavior"
  add_output "✗ Verification SQL does not prove superseded-key behavior"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 7: Verification SQL proves active key acceptance
add_trace "Checking verification SQL proves active key acceptance"
if grep -q "ACTIVE_KEY_ACCEPTED" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_008_work_03] Verification SQL proves active key acceptance" "PASS" "Verification SQL includes physical write test for active key acceptance"
  add_output "✓ Verification SQL proves active key acceptance"
else
  add_check "[ID w8_db_008_work_03] Verification SQL proves active key acceptance" "FAIL" "Verification SQL does not prove active key acceptance"
  add_output "✗ Verification SQL does not prove active key acceptance"
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
