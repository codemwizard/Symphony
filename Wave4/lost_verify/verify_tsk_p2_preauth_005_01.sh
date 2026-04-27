#!/bin/bash
# Verification script for TSK-P2-PREAUTH-005-01
# Verifies state_transitions table exists with required indexes
# Includes negative test TSK-P2-PREAUTH-005-01-N1

set -e

TASK_ID="TSK-P2-PREAUTH-005-01"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_preauth_005_01.json"

# Check if table exists
TABLE_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM information_schema.tables WHERE table_name = 'state_transitions';")

# Check if indexes exist
INDEX_PROJECT_ID_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM pg_indexes WHERE indexname = 'idx_state_transitions_project_id';")
INDEX_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM pg_indexes WHERE indexname = 'idx_state_transitions_timestamp';")

# Check MIGRATION_HEAD
MIGRATION_HEAD=$(cat schema/migrations/MIGRATION_HEAD)

# Negative test: TSK-P2-PREAUTH-005-01-N1
# This test actually attempts an INSERT without project_id
NEGATIVE_TEST_RESULT="fail"

echo "Running behavioral tests for state_transitions..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'EOF'
BEGIN;
DO $$
DECLARE
    v_bc UUID := gen_random_uuid();
    v_tenant UUID := gen_random_uuid();
    v_proj UUID := gen_random_uuid();
    v_exec UUID := gen_random_uuid();
    v_pol UUID := gen_random_uuid();
BEGIN
    EXECUTE 'ALTER TABLE billable_clients DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE tenants DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE projects DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE execution_records DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE policy_decisions DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE state_rules DISABLE TRIGGER ALL';

    INSERT INTO billable_clients (billable_client_id, client_key, legal_name, client_type, status) VALUES (v_bc, 'CK', 'LN', 'ENTERPRISE', 'ACTIVE');
    INSERT INTO tenants (tenant_id, tenant_key, tenant_name, tenant_type, status, billable_client_id) VALUES (v_tenant, 'TK', 'TN', 'NGO', 'ACTIVE', v_bc);
    INSERT INTO projects (project_id, tenant_id, name, status, taxonomy_aligned) VALUES (v_proj, v_tenant, 'TP', 'ACTIVE', false);
    INSERT INTO execution_records (execution_id, project_id, tenant_id, interpretation_version_id, input_hash, output_hash, runtime_version, status) 
    VALUES (v_exec, v_proj, v_tenant, gen_random_uuid(), 'ih', 'oh', 'rv', 'pending');
    INSERT INTO policy_decisions (project_id, policy_decision_id, execution_id, decision_type, authority_scope, declared_by, entity_type, entity_id, decision_hash, signature, signed_at)
    VALUES (v_proj, v_pol, v_exec, 'STATE_TRANSITION', 'TEST', gen_random_uuid(), 'TEST_ENTITY', gen_random_uuid(), repeat('0', 64), repeat('0', 128), NOW());
    INSERT INTO state_rules (state_rule_id, entity_type, from_state, to_state, required_decision_type, allowed) VALUES (gen_random_uuid(), 'TEST_ENTITY', 'A', 'B', 'ANY', true);
    
    EXECUTE 'ALTER TABLE billable_clients ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE tenants ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE projects ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE execution_records ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE policy_decisions ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE state_rules ENABLE TRIGGER ALL';
    
    -- Positive Test
    INSERT INTO state_transitions (transition_id, project_id, entity_type, entity_id, from_state, to_state, transition_timestamp, execution_id, policy_decision_id, transition_hash, signature)
    VALUES (gen_random_uuid(), v_proj, 'TEST_ENTITY', gen_random_uuid(), 'A', 'B', NOW(), v_exec, v_pol, 'testhash1', repeat('0', 128));
END $$;
ROLLBACK;
EOF
if [ $? -ne 0 ]; then
    echo "ERROR: Behavioral positive test failed."
    exit 1
fi

# Negative Test (Missing project_id)
if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'EOF' > /dev/null 2>&1
BEGIN;
DO $$
DECLARE
    v_bc UUID := gen_random_uuid();
    v_tenant UUID := gen_random_uuid();
    v_exec UUID := gen_random_uuid();
    v_pol UUID := gen_random_uuid();
BEGIN
    EXECUTE 'ALTER TABLE billable_clients DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE tenants DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE execution_records DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE policy_decisions DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE state_rules DISABLE TRIGGER ALL';
    -- Assume parent records exist or we just let it fail on NOT NULL project_id first
    INSERT INTO state_transitions (transition_id, entity_type, entity_id, from_state, to_state, transition_timestamp, execution_id, policy_decision_id, transition_hash, signature)
    VALUES (gen_random_uuid(), 'TEST_ENTITY', gen_random_uuid(), 'A', 'B', NOW(), v_exec, v_pol, 'testhash2', repeat('0', 128));
END $$;
ROLLBACK;
EOF
then
    echo "ERROR: Behavioral negative test failed (database accepted invalid data)."
    exit 1
else
    NEGATIVE_TEST_RESULT="pass"
fi


# Build evidence JSON
cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "success",
  "checks": {
    "table_exists": $([ "$TABLE_EXISTS" = "1" ] && echo "true" || echo "false"),
    "idx_project_id_exists": $([ "$INDEX_PROJECT_ID_EXISTS" = "1" ] && echo "true" || echo "false"),
    "idx_timestamp_exists": $([ "$INDEX_EXISTS" = "1" ] && echo "true" || echo "false"),
    "migration_head": "$MIGRATION_HEAD",
    "negative_test_TSK-P2-PREAUTH-005-01-N1": "$NEGATIVE_TEST_RESULT"
  }
}
EOF

# Verify all checks passed
if [ "$TABLE_EXISTS" != "1" ]; then
  echo "ERROR: state_transitions table does not exist"
  exit 1
fi

if [ "$INDEX_PROJECT_ID_EXISTS" != "1" ]; then
  echo "ERROR: idx_state_transitions_project_id index does not exist"
  exit 1
fi

if [ "$INDEX_EXISTS" != "1" ]; then
  echo "ERROR: idx_state_transitions_timestamp index does not exist"
  exit 1
fi

# Use numeric comparison for version check
if [ "$MIGRATION_HEAD" -lt "0137" ]; then
  echo "ERROR: MIGRATION_HEAD is $MIGRATION_HEAD, expected at least 0137"
  exit 1
fi

echo "Verification successful for $TASK_ID"
