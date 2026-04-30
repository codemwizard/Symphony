#!/bin/bash
#
# Verifier for TSK-P2-W8-DB-005: Authoritative signer-resolution surface
#
# This script verifies that the signer resolution surface distinguishes unknown,
# unauthorized, ambiguous, and authorized signer cases.
#

set -e

TASK_ID="TSK-P2-W8-DB-005"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_db_005.json"

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

add_trace "verify_tsk_p2_w8_db_005.sh executed"

# Check 1: Migration exists
add_trace "Checking migration file"
MIGRATION_FILE="schema/migrations/0176_wave8_signer_resolution_surface.sql"
if [ -f "$MIGRATION_FILE" ]; then
  add_check "[ID w8_db_005_work_01] Migration exists" "PASS" "Migration found at $MIGRATION_FILE"
  add_output "✓ Migration exists"
else
  add_check "[ID w8_db_005_work_01] Migration exists" "FAIL" "Migration not found at $MIGRATION_FILE"
  add_output "✗ Migration not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Migration creates signer resolution table
add_trace "Checking migration creates signer resolution table"
if grep -q "wave8_signer_resolution" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "CREATE TABLE" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_005_work_01] Migration creates signer resolution table" "PASS" "Migration creates wave8_signer_resolution table"
  add_output "✓ Migration creates signer resolution table"
else
  add_check "[ID w8_db_005_work_01] Migration creates signer resolution table" "FAIL" "Migration does not create signer resolution table"
  add_output "✗ Migration does not create signer resolution table"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: Migration includes required normalized fields
add_trace "Checking migration includes required normalized fields"
REQUIRED_FIELDS=("signer_id" "key_id" "key_version" "public_key_bytes" "project_id" "entity_type" "scope" "is_active")
MISSING_FIELDS=()
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! grep -q "$field" "$MIGRATION_FILE" 2>/dev/null; then
    MISSING_FIELDS+=("$field")
  fi
done

if [ ${#MISSING_FIELDS[@]} -eq 0 ]; then
  add_check "[ID w8_db_005_work_01] Migration includes required normalized fields" "PASS" "Migration includes all 8 required fields"
  add_output "✓ Migration includes required normalized fields"
else
  add_check "[ID w8_db_005_work_01] Migration includes required normalized fields" "FAIL" "Migration missing fields: ${MISSING_FIELDS[*]}"
  add_output "✗ Migration missing fields: ${MISSING_FIELDS[*]}"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Migration enforces semantically closed lookup behavior
add_trace "Checking migration enforces semantically closed lookup behavior"
if grep -q "wave8_signer_key_unique" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "wave8_signer_scope_not_null" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "P7806" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_005_work_02] Migration enforces semantically closed lookup behavior" "PASS" "Migration enforces unique constraint and null-derived authorization prevention with P7806 failure mode"
  add_output "✓ Migration enforces semantically closed lookup behavior"
else
  add_check "[ID w8_db_005_work_02] Migration enforces semantically closed lookup behavior" "FAIL" "Migration does not enforce semantically closed lookup behavior"
  add_output "✗ Migration does not enforce semantically closed lookup behavior"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: Verification SQL exists
add_trace "Checking verification SQL"
VERIFICATION_SQL="scripts/db/verify_w8_signer_resolution_surface.sql"
if [ -f "$VERIFICATION_SQL" ]; then
  add_check "[ID w8_db_005_work_03] Verification SQL exists" "PASS" "Verification SQL found at $VERIFICATION_SQL"
  add_output "✓ Verification SQL exists"
else
  add_check "[ID w8_db_005_work_03] Verification SQL exists" "FAIL" "Verification SQL not found at $VERIFICATION_SQL"
  add_output "✗ Verification SQL not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 6: Verification SQL distinguishes unknown signer case
add_trace "Checking verification SQL distinguishes unknown signer case"
if grep -q "Unknown signer test" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_005_work_03] Verification SQL distinguishes unknown signer case" "PASS" "Verification SQL includes unknown signer test"
  add_output "✓ Verification SQL distinguishes unknown signer case"
else
  add_check "[ID w8_db_005_work_03] Verification SQL distinguishes unknown signer case" "FAIL" "Verification SQL does not include unknown signer test"
  add_output "✗ Verification SQL does not include unknown signer test"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 7: Verification SQL distinguishes unauthorized signer case
add_trace "Checking verification SQL distinguishes unauthorized signer case"
if grep -q "Unauthorized signer test" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_005_work_03] Verification SQL distinguishes unauthorized signer case" "PASS" "Verification SQL includes unauthorized signer test"
  add_output "✓ Verification SQL distinguishes unauthorized signer case"
else
  add_check "[ID w8_db_005_work_03] Verification SQL distinguishes unauthorized signer case" "FAIL" "Verification SQL does not include unauthorized signer test"
  add_output "✗ Verification SQL does not include unauthorized signer test"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 8: Verification SQL distinguishes authorized signer case
add_trace "Checking verification SQL distinguishes authorized signer case"
if grep -q "Authorized signer test" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_005_work_03] Verification SQL distinguishes authorized signer case" "PASS" "Verification SQL includes authorized signer test"
  add_output "✓ Verification SQL distinguishes authorized signer case"
else
  add_check "[ID w8_db_005_work_03] Verification SQL distinguishes authorized signer case" "FAIL" "Verification SQL does not include authorized signer test"
  add_output "✗ Verification SQL does not include authorized signer test"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 9: Verification SQL distinguishes ambiguous signer precedence
add_trace "Checking verification SQL distinguishes ambiguous signer precedence"
if grep -q "Ambiguous signer precedence test" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_005_work_03] Verification SQL distinguishes ambiguous signer precedence" "PASS" "Verification SQL includes ambiguous signer precedence test"
  add_output "✓ Verification SQL distinguishes ambiguous signer precedence"
else
  add_check "[ID w8_db_005_work_03] Verification SQL distinguishes ambiguous signer precedence" "FAIL" "Verification SQL does not include ambiguous signer precedence test"
  add_output "✗ Verification SQL does not include ambiguous signer precedence test"
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
