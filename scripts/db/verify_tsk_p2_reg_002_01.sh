#!/bin/bash
# Verification script for TSK-P2-REG-002-01: Create exchange_rate_audit_log table

set -e

TASK_ID="TSK-P2-REG-002-01"
EVIDENCE_PATH="evidence/phase2/tsk_p2_reg_002_01.json"

# Create evidence directory if it doesn't exist
mkdir -p "$(dirname "$EVIDENCE_PATH")"

# Initialize evidence JSON
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$(git rev-parse HEAD)",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "in_progress",
  "checks": []
}
EOF

# Check 1: Migration file exists
if [ -f "schema/migrations/0124_create_exchange_rate_audit_log.sql" ]; then
  jq '.checks += [{"check_id": "migration_file_exists", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "migration_file_exists", "status": "fail", "message": "Migration file not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 2: MIGRATION_HEAD is 0124
if [ "$(cat schema/migrations/MIGRATION_HEAD)" = "0124" ]; then
  jq '.checks += [{"check_id": "migration_head_correct", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "migration_head_correct", "status": "fail", "message": "MIGRATION_HEAD is not 0124"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 3: Migration file contains table definition
if grep -q "CREATE TABLE.*exchange_rate_audit_log" schema/migrations/0124_create_exchange_rate_audit_log.sql; then
  jq '.checks += [{"check_id": "table_definition_present", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "table_definition_present", "status": "fail", "message": "Table definition not found in migration"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 4: rate_value column is NUMERIC(18,8)
if grep -q "rate_value NUMERIC(18,8)" schema/migrations/0124_create_exchange_rate_audit_log.sql; then
  jq '.checks += [{"check_id": "precision_correct", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "precision_correct", "status": "fail", "message": "rate_value is not NUMERIC(18,8)"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 5: UNIQUE constraint on (from_currency, to_currency, effective_from)
if grep -q "UNIQUE.*from_currency.*to_currency.*effective_from" schema/migrations/0124_create_exchange_rate_audit_log.sql; then
  jq '.checks += [{"check_id": "unique_constraint_present", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "unique_constraint_present", "status": "fail", "message": "UNIQUE constraint not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 6: Revoke-first privileges present
if grep -q "REVOKE ALL ON TABLE public.exchange_rate_audit_log FROM PUBLIC" schema/migrations/0124_create_exchange_rate_audit_log.sql; then
  jq '.checks += [{"check_id": "revoke_first_privileges", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "revoke_first_privileges", "status": "fail", "message": "Revoke-first privileges not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# All checks passed
jq '.status = "passed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.table_exists = true' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.precision_correct = true' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.migration_head = "0124"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"

echo "Verification passed for $TASK_ID"
