#!/bin/bash
#
# Verifier for TSK-P2-W8-DB-009: Context binding and anti-transplant protection
#
# This script verifies that PostgreSQL binds verification to full decision context
# for anti-transplant protection.
#

set -e

TASK_ID="TSK-P2-W8-DB-009"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_db_009.json"

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

add_trace "verify_tsk_p2_w8_db_009.sh executed"

# Check 1: Migration exists
add_trace "Checking migration file"
MIGRATION_FILE="schema/migrations/0180_wave8_context_binding_enforcement.sql"
if [ -f "$MIGRATION_FILE" ]; then
  add_check "[ID w8_db_009_work_01] Migration exists" "PASS" "Migration found at $MIGRATION_FILE"
  add_output "✓ Migration exists"
else
  add_check "[ID w8_db_009_work_01] Migration exists" "FAIL" "Migration not found at $MIGRATION_FILE"
  add_output "✗ Migration not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Migration binds verification to required decision-context binding fields
add_trace "Checking migration binds verification to required decision-context binding fields"
if grep -q "P7814" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "entity_id" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "execution_id" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "policy_decision_id" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "interpretation_version_id" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "occurred_at" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_009_work_01] Migration binds verification to required decision-context binding fields" "PASS" "Migration binds verification to entity, execution, decision type, registry snapshot, nonce, attestation time, and verifier scope fields"
  add_output "✓ Migration binds verification to required decision-context binding fields"
else
  add_check "[ID w8_db_009_work_01] Migration binds verification to required decision-context binding fields" "FAIL" "Migration does not bind verification to required context fields"
  add_output "✗ Migration does not bind verification to required context fields"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: Migration enforces anti-transplant behavior
add_trace "Checking migration enforces anti-transplant behavior"
if grep -q "context binding" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "anti-transplant" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_009_work_02] Migration enforces anti-transplant behavior" "PASS" "Migration enforces anti-transplant behavior with P7814 failure mode"
  add_output "✓ Migration enforces anti-transplant behavior"
else
  add_check "[ID w8_db_009_work_02] Migration enforces anti-transplant behavior" "FAIL" "Migration does not enforce anti-transplant behavior"
  add_output "✗ Migration does not enforce anti-transplant behavior"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Verification SQL exists
add_trace "Checking verification SQL"
VERIFICATION_SQL="scripts/db/verify_w8_context_binding_enforcement.sql"
if [ -f "$VERIFICATION_SQL" ]; then
  add_check "[ID w8_db_009_work_03] Verification SQL exists" "PASS" "Verification SQL found at $VERIFICATION_SQL"
  add_output "✓ Verification SQL exists"
else
  add_check "[ID w8_db_009_work_03] Verification SQL exists" "FAIL" "Verification SQL not found at $VERIFICATION_SQL"
  add_output "✗ Verification SQL not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: Verification SQL proves altered context fields cause rejection
add_trace "Checking verification SQL proves altered context fields cause rejection"
if grep -q "MISSING_ENTITY_ID_REJECTED" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "MISSING_EXECUTION_ID_REJECTED" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "INSERT INTO public.asset_batches" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_009_work_03] Verification SQL proves altered context fields cause rejection" "PASS" "Verification SQL includes physical write tests for context field rejection"
  add_output "✓ Verification SQL proves altered context fields cause rejection"
else
  add_check "[ID w8_db_009_work_03] Verification SQL proves altered context fields cause rejection" "FAIL" "Verification SQL does not prove context field rejection"
  add_output "✗ Verification SQL does not prove context field rejection"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 6: Verification SQL proves valid context acceptance
add_trace "Checking verification SQL proves valid context acceptance"
if grep -q "VALID_CONTEXT_ACCEPTED" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_009_work_03] Verification SQL proves valid context acceptance" "PASS" "Verification SQL includes physical write test for valid context acceptance"
  add_output "✓ Verification SQL proves valid context acceptance"
else
  add_check "[ID w8_db_009_work_03] Verification SQL proves valid context acceptance" "FAIL" "Verification SQL does not prove valid context acceptance"
  add_output "✗ Verification SQL does not prove valid context acceptance"
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
