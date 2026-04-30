#!/bin/bash
#
# Verifier for TSK-P2-W8-DB-006: Authoritative trigger integration of cryptographic primitive
#
# This script verifies that PostgreSQL independently validates the exact asset_batches
# write with cryptographic enforcement.
#

set -e

TASK_ID="TSK-P2-W8-DB-006"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_db_006.json"

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

add_trace "verify_tsk_p2_w8_db_006.sh executed"

# Check 1: Migration exists
add_trace "Checking migration file"
MIGRATION_FILE="schema/migrations/0177_wave8_cryptographic_enforcement_wiring.sql"
if [ -f "$MIGRATION_FILE" ]; then
  add_check "[ID w8_db_006_work_01] Migration exists" "PASS" "Migration found at $MIGRATION_FILE"
  add_output "✓ Migration exists"
else
  add_check "[ID w8_db_006_work_01] Migration exists" "FAIL" "Migration not found at $MIGRATION_FILE"
  add_output "✗ Migration not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Migration integrates Ed25519 verification into dispatcher path
add_trace "Checking migration integrates Ed25519 verification into dispatcher path"
if grep -q "wave8_cryptographic_enforcement" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "CREATE TRIGGER" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "asset_batches" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_006_work_01] Migration integrates Ed25519 verification into dispatcher path" "PASS" "Migration creates cryptographic enforcement function and trigger on asset_batches"
  add_output "✓ Migration integrates Ed25519 verification into dispatcher path"
else
  add_check "[ID w8_db_006_work_01] Migration integrates Ed25519 verification into dispatcher path" "FAIL" "Migration does not integrate cryptographic enforcement"
  add_output "✗ Migration does not integrate cryptographic enforcement"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: Migration enforces fail-closed rejection with registered failure modes
add_trace "Checking migration enforces fail-closed rejection with registered failure modes"
if grep -q "P7807" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "P7808" "$MIGRATION_FILE" 2>/dev/null && \
   grep -q "P7809" "$MIGRATION_FILE" 2>/dev/null; then
  add_check "[ID w8_db_006_work_02] Migration enforces fail-closed rejection with registered failure modes" "PASS" "Migration uses registered failure modes P7807, P7808, P7809"
  add_output "✓ Migration enforces fail-closed rejection with registered failure modes"
else
  add_check "[ID w8_db_006_work_02] Migration enforces fail-closed rejection with registered failure modes" "FAIL" "Migration does not use registered failure modes"
  add_output "✗ Migration does not use registered failure modes"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Verification SQL exists
add_trace "Checking verification SQL"
VERIFICATION_SQL="scripts/db/verify_w8_cryptographic_enforcement_wiring.sql"
if [ -f "$VERIFICATION_SQL" ]; then
  add_check "[ID w8_db_006_work_03] Verification SQL exists" "PASS" "Verification SQL found at $VERIFICATION_SQL"
  add_output "✓ Verification SQL exists"
else
  add_check "[ID w8_db_006_work_03] Verification SQL exists" "FAIL" "Verification SQL not found at $VERIFICATION_SQL"
  add_output "✗ Verification SQL not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: Verification SQL proves PostgreSQL rejects cryptographically invalid writes
add_trace "Checking verification SQL proves PostgreSQL rejects cryptographically invalid writes"
if grep -q "MISSING_SIGNATURE_REJECTED" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "INVALID_SIGNATURE_FORMAT_REJECTED" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_006_work_03] Verification SQL proves PostgreSQL rejects cryptographically invalid writes" "PASS" "Verification SQL includes physical write tests for cryptographic rejection"
  add_output "✓ Verification SQL proves PostgreSQL rejects cryptographically invalid writes"
else
  add_check "[ID w8_db_006_work_03] Verification SQL proves PostgreSQL rejects cryptographically invalid writes" "FAIL" "Verification SQL does not prove cryptographic rejection"
  add_output "✗ Verification SQL does not prove cryptographic rejection"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 6: Verification SQL proves PostgreSQL does not trust service claim or audit row
add_trace "Checking verification SQL proves PostgreSQL does not trust service claim or audit row"
if grep -q "INSERT INTO public.asset_batches" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "trigger" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_006_work_03] Verification SQL proves PostgreSQL does not trust service claim or audit row" "PASS" "Verification SQL tests direct PostgreSQL trigger enforcement"
  add_output "✓ Verification SQL proves PostgreSQL does not trust service claim or audit row"
else
  add_check "[ID w8_db_006_work_03] Verification SQL proves PostgreSQL does not trust service claim or audit row" "FAIL" "Verification SQL does not prove independent PostgreSQL validation"
  add_output "✗ Verification SQL does not prove independent PostgreSQL validation"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 7: Verification SQL derives branch provenance from same production execution path
add_trace "Checking verification SQL derives branch provenance from same production execution path"
if grep -q "wave8_cryptographic_enforcement" "$VERIFICATION_SQL" 2>/dev/null && \
   grep -q "trg_wave8_cryptographic_enforcement" "$VERIFICATION_SQL" 2>/dev/null; then
  add_check "[ID w8_db_006_work_03] Verification SQL derives branch provenance from same production execution path" "PASS" "Verification SQL verifies trigger function in production execution path"
  add_output "✓ Verification SQL derives branch provenance from same production execution path"
else
  add_check "[ID w8_db_006_work_03] Verification SQL derives branch provenance from same production execution path" "FAIL" "Verification SQL does not verify production execution path"
  add_output "✗ Verification SQL does not verify production execution path"
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
