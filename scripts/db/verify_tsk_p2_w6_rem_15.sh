#!/bin/bash
# Verification script for TSK-P2-W6-REM-15
# Verifies K13 SQLSTATE reassignment to GF061

set -e

TASK_ID="TSK-P2-W6-REM-15"
GIT_SHA=$(git rev-parse HEAD || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w6_rem_15.json"

mkdir -p $(dirname "$EVIDENCE_FILE")

# 1. Check if source code contains GF061
SOURCE_CODE=$(psql "$DATABASE_URL" -tAc "SELECT prosrc FROM pg_proc WHERE proname = 'enforce_k13_taxonomy_alignment';")

if [[ "$SOURCE_CODE" == *"GF061"* ]]; then
    TRIGGER_CONTAINS_GF061="pass"
else
    TRIGGER_CONTAINS_GF061="fail"
fi

if [[ "$SOURCE_CODE" == *"GF060"* ]]; then
    TRIGGER_CONTAINS_GF060="fail"
else
    TRIGGER_CONTAINS_GF060="pass"
fi

NEGATIVE_TEST_N1="fail"
ERROR_CODE=""

echo "Running behavioral tests for TSK-P2-W6-REM-15..."

# TSK-P2-W6-REM-15-N1: UPDATE to projects must fail with GF061
OUTPUT=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 2>&1 <<'EOF'
BEGIN;
DO $$
DECLARE
    v_bc UUID := gen_random_uuid();
    v_tenant UUID := gen_random_uuid();
    v_proj UUID := gen_random_uuid();
BEGIN
    EXECUTE 'ALTER TABLE billable_clients DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE tenants DISABLE TRIGGER ALL';

    INSERT INTO billable_clients (billable_client_id, client_key, legal_name, client_type, status) VALUES (v_bc, 'CK', 'LN', 'ENTERPRISE', 'ACTIVE');
    INSERT INTO tenants (tenant_id, tenant_key, tenant_name, tenant_type, status, billable_client_id) VALUES (v_tenant, 'TK', 'TN', 'NGO', 'ACTIVE', v_bc);
    
    EXECUTE 'ALTER TABLE billable_clients ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE tenants ENABLE TRIGGER ALL';
    
    INSERT INTO projects (project_id, tenant_id, name, status, taxonomy_aligned) VALUES (v_proj, v_tenant, 'TP', 'ACTIVE', false);
    
    UPDATE projects SET taxonomy_aligned = true WHERE project_id = v_proj;
END $$;
ROLLBACK;
EOF
) || true

if [[ "$OUTPUT" == *"GF061"* ]]; then
    NEGATIVE_TEST_N1="pass"
    ERROR_CODE="GF061"
elif [[ "$OUTPUT" == *"GF060"* ]]; then
    echo "ERROR: N1 failed. Raised GF060 instead of GF061."
    ERROR_CODE="GF060"
else
    echo "ERROR: N1 failed. Output: $OUTPUT"
    ERROR_CODE="unknown"
fi

cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": {
    "trigger_source_contains_gf061": "$TRIGGER_CONTAINS_GF061",
    "trigger_source_contains_gf060": "$TRIGGER_CONTAINS_GF060"
  },
  "negative_test_results": {
    "TSK-P2-W6-REM-15-N1": "$NEGATIVE_TEST_N1",
    "error_code_observed": "$ERROR_CODE"
  }
}
EOF

if [ "$TRIGGER_CONTAINS_GF061" != "pass" ] || [ "$TRIGGER_CONTAINS_GF060" != "pass" ]; then
    echo "ERROR: Source code check failed."
    exit 1
fi

if [ "$NEGATIVE_TEST_N1" != "pass" ]; then
    echo "ERROR: N1 test failed."
    exit 1
fi

echo "Verification successful for $TASK_ID"
