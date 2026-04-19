#!/bin/bash
# Verification script for TSK-P2-REG-003-05: Implement enforce_dns_harm() trigger

set -e

TASK_ID="TSK-P2-REG-003-05"
EVIDENCE_PATH="evidence/phase2/tsk_p2_reg_003_05.json"

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
if [ -f "schema/migrations/0129_enforce_dns_harm_trigger.sql" ]; then
  jq '.checks += [{"check_id": "migration_file_exists", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "migration_file_exists", "status": "fail", "message": "Migration file not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 2: MIGRATION_HEAD is 0129
if [ "$(cat schema/migrations/MIGRATION_HEAD)" = "0129" ]; then
  jq '.checks += [{"check_id": "migration_head_correct", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "migration_head_correct", "status": "fail", "message": "MIGRATION_HEAD is not 0129"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 3: Function definition present
if grep -q "CREATE OR REPLACE FUNCTION public.enforce_dns_harm" schema/migrations/0129_enforce_dns_harm_trigger.sql; then
  jq '.checks += [{"check_id": "function_definition_present", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "function_definition_present", "status": "fail", "message": "Function definition not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 4: Function is SECURITY DEFINER
if grep -q "SECURITY DEFINER" schema/migrations/0129_enforce_dns_harm_trigger.sql; then
  jq '.checks += [{"check_id": "security_definer", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "security_definer", "status": "fail", "message": "SECURITY DEFINER not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 5: Hardened search_path
if grep -q "SET search_path = pg_catalog, public" schema/migrations/0129_enforce_dns_harm_trigger.sql; then
  jq '.checks += [{"check_id": "hardened_search_path", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "hardened_search_path", "status": "fail", "message": "Hardened search_path not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 6: Trigger raises GF057
if grep -q "GF057" schema/migrations/0129_enforce_dns_harm_trigger.sql; then
  jq '.checks += [{"check_id": "gf057_error_code", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "gf057_error_code", "status": "fail", "message": "GF057 error code not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 7: Trigger attached as BEFORE INSERT OR UPDATE
if grep -q "BEFORE INSERT OR UPDATE ON public.project_boundaries" schema/migrations/0129_enforce_dns_harm_trigger.sql; then
  jq '.checks += [{"check_id": "trigger_attached", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "trigger_attached", "status": "fail", "message": "Trigger not attached as BEFORE INSERT OR UPDATE"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# All checks passed
jq '.status = "passed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.function_exists = true' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.security_definer = true' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.trigger_attached = true' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.migration_head = "0129"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.observed_paths = ["schema/migrations/0129_enforce_dns_harm_trigger.sql", "schema/migrations/MIGRATION_HEAD"]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.observed_hashes = {}' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.command_outputs = []' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.execution_trace = []' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"

echo "Verification passed for $TASK_ID"
