#!/bin/bash
#
# Verifier for TSK-P2-W8-DB-001: Authoritative Wave 8 dispatcher trigger topology
#
# This script verifies that one authoritative dispatcher trigger has been
# established on asset_batches and that writes run through one explicit
# dispatcher path rather than multiple independent triggers.
#

set -e

TASK_ID="TSK-P2-W8-DB-001"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_db_001.json"

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

add_trace "verify_tsk_p2_w8_db_001.sh executed"

# Check 1: Trigger inventory documented
add_trace "Checking trigger inventory documentation"
INVENTORY_FILE="docs/plans/phase2/TSK-P2-W8-DB-001/ASSET_BATCHES_TRIGGER_INVENTORY.md"
if [ -f "$INVENTORY_FILE" ]; then
  add_check "[ID w8_db_001_work_01] Trigger inventory documented" "PASS" "Trigger inventory documented at $INVENTORY_FILE"
  add_output "✓ Trigger inventory documented"
else
  add_check "[ID w8_db_001_work_01] Trigger inventory documented" "FAIL" "Trigger inventory not found at $INVENTORY_FILE"
  add_output "✗ Trigger inventory not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Migration exists
add_trace "Checking migration file"
MIGRATION_FILE="schema/migrations/0172_wave8_dispatcher_topology.sql"
if [ -f "$MIGRATION_FILE" ]; then
  add_check "[ID w8_db_001_work_02] Migration exists" "PASS" "Migration found at $MIGRATION_FILE"
  add_output "✓ Migration exists"
else
  add_check "[ID w8_db_001_work_02] Migration exists" "FAIL" "Migration not found at $MIGRATION_FILE"
  add_output "✗ Migration not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: Migration establishes dispatcher trigger
add_trace "Checking migration establishes dispatcher trigger"
if grep -q "wave8_asset_batches_dispatcher" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_001_work_02] Migration establishes dispatcher trigger" "PASS" "Migration creates wave8_asset_batches_dispatcher function and trigger"
  add_output "✓ Migration establishes dispatcher trigger"
else
  add_check "[ID w8_db_001_work_02] Migration establishes dispatcher trigger" "FAIL" "Migration does not create dispatcher trigger"
  add_output "✗ Migration does not create dispatcher trigger"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Migration removes competing triggers
add_trace "Checking migration removes competing triggers"
if grep -q "DROP TRIGGER.*trg_attestation_gate_asset_batches" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "DROP TRIGGER.*trg_enforce_attestation_freshness" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "DROP TRIGGER.*trg_enforce_asset_batch_authority" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_001_work_02] Migration removes competing triggers" "PASS" "Migration drops all competing authority triggers"
  add_output "✓ Migration removes competing triggers"
else
  add_check "[ID w8_db_001_work_02] Migration removes competing triggers" "FAIL" "Migration does not drop all competing triggers"
  add_output "✗ Migration does not drop all competing triggers"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: Verification SQL exists
add_trace "Checking verification SQL"
VERIFICATION_SQL="scripts/db/verify_w8_dispatcher_topology.sql"
if [ -f "$VERIFICATION_SQL" ]; then
  add_check "[ID w8_db_001_work_03] Verification SQL exists" "PASS" "Verification SQL found at $VERIFICATION_SQL"
  add_output "✓ Verification SQL exists"
else
  add_check "[ID w8_db_001_work_03] Verification SQL exists" "FAIL" "Verification SQL not found at $VERIFICATION_SQL"
  add_output "✗ Verification SQL not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 6: Verification SQL proves single dispatcher path
add_trace "Checking verification SQL proves single dispatcher path"
if grep -q "COUNT.*trigger_count" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "trg_wave8_asset_batches_dispatcher" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_001_work_03] Verification SQL proves single dispatcher path" "PASS" "Verification SQL checks for single trigger and dispatcher existence"
  add_output "✓ Verification SQL proves single dispatcher path"
else
  add_check "[ID w8_db_001_work_03] Verification SQL proves single dispatcher path" "FAIL" "Verification SQL does not prove single dispatcher path"
  add_output "✗ Verification SQL does not prove single dispatcher path"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 7: Verification SQL includes physical write test
add_trace "Checking verification SQL includes physical write test"
if grep -q "INSERT INTO public.asset_batches" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_001_work_03] Verification SQL includes physical write test" "PASS" "Verification SQL includes actual insert test to prove dispatcher intercepts writes"
  add_output "✓ Verification SQL includes physical write test"
else
  add_check "[ID w8_db_001_work_03] Verification SQL includes physical write test" "FAIL" "Verification SQL does not include physical write test"
  add_output "✗ Verification SQL does not include physical write test"
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
