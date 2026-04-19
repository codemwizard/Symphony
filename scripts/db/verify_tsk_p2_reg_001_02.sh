#!/bin/bash
# Verification script for TSK-P2-REG-001-02: Add append-only trigger and privileges to statutory_levy_registry

set -e

TASK_ID="TSK-P2-REG-001-02"
EVIDENCE_PATH="evidence/phase2/tsk_p2_reg_001_02.json"

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

# Check 1: Trigger function exists in migration
if grep -q "statutory_levy_registry_append_only" schema/migrations/0123_create_statutory_levy_registry.sql; then
  jq '.checks += [{"check_id": "trigger_function_present", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "trigger_function_present", "status": "fail", "message": "Trigger function not found in migration"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 2: Trigger is SECURITY DEFINER
if grep -q "SECURITY DEFINER" schema/migrations/0123_create_statutory_levy_registry.sql; then
  jq '.checks += [{"check_id": "security_definer", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "security_definer", "status": "fail", "message": "SECURITY DEFINER not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 3: Hardened search_path
if grep -q "SET search_path = pg_catalog, public" schema/migrations/0123_create_statutory_levy_registry.sql; then
  jq '.checks += [{"check_id": "hardened_search_path", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "hardened_search_path", "status": "fail", "message": "Hardened search_path not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 4: Trigger raises GF050
if grep -q "GF050" schema/migrations/0123_create_statutory_levy_registry.sql; then
  jq '.checks += [{"check_id": "gf050_error_code", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "gf050_error_code", "status": "fail", "message": "GF050 error code not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 5: Trigger attached as BEFORE UPDATE OR DELETE
if grep -q "BEFORE UPDATE OR DELETE" schema/migrations/0123_create_statutory_levy_registry.sql; then
  jq '.checks += [{"check_id": "trigger_attached", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "trigger_attached", "status": "fail", "message": "Trigger not attached as BEFORE UPDATE OR DELETE"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 6: Revoke-first privileges present
if grep -q "REVOKE ALL ON TABLE public.statutory_levy_registry FROM PUBLIC" schema/migrations/0123_create_statutory_levy_registry.sql; then
  jq '.checks += [{"check_id": "revoke_first_privileges", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "revoke_first_privileges", "status": "fail", "message": "Revoke-first privileges not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# All checks passed
jq '.status = "passed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.trigger_exists = true' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.privileges_correct = true' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"

echo "Verification passed for $TASK_ID"
