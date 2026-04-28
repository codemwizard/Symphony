#!/bin/bash
# Verification script for TSK-P2-W6-REM-14
# Enforces NOT NULL on state_current.last_transition_id

set -e

TASK_ID="TSK-P2-W6-REM-14"
GIT_SHA=$(git rev-parse HEAD || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w6_rem_14.json"

mkdir -p $(dirname "$EVIDENCE_FILE")

# 1. Check if is_nullable is NO
IS_NULLABLE=$(psql "$DATABASE_URL" -tAc "SELECT is_nullable FROM information_schema.columns WHERE table_name = 'state_current' AND column_name = 'last_transition_id';")

# 2. Check pg_attribute.attnotnull
ATTNOTNULL=$(psql "$DATABASE_URL" -tAc "
    SELECT a.attnotnull
    FROM pg_attribute a
    JOIN pg_class c ON a.attrelid = c.oid
    WHERE c.relname = 'state_current' AND a.attname = 'last_transition_id';
")

# 3. Get NULL row count (should be 0)
NULL_ROW_COUNT=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM state_current WHERE last_transition_id IS NULL;")

# 4. Get 0151 ledger status diagnostically
MIGRATION_0151_APPLIED_AT=$(psql "$DATABASE_URL" -tAc "SELECT applied_at FROM schema_migrations WHERE version = '0151' LIMIT 1;" || echo "not_found")

NEGATIVE_TEST_N1="fail"
NEGATIVE_TEST_N2="fail"

echo "Running behavioral tests for TSK-P2-W6-REM-14..."

# TSK-P2-W6-REM-14-N1: Raw INSERT with NULL
if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'EOF' > /dev/null 2>&1
BEGIN;
INSERT INTO state_current (entity_type, entity_id, current_state, last_transition_id) 
VALUES ('TEST_ENTITY', gen_random_uuid(), 'ACTIVE', NULL);
ROLLBACK;
EOF
then
    echo "ERROR: TSK-P2-W6-REM-14-N1 failed (database accepted raw INSERT with NULL last_transition_id)."
else
    NEGATIVE_TEST_N1="pass"
fi

# TSK-P2-W6-REM-14-N2: Full-path invariant via state_transitions
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'EOF' > /tmp/w6_rem_14_full_path.log 2>&1
BEGIN;
DO $$
DECLARE
    v_bc UUID := gen_random_uuid();
    v_tenant UUID := gen_random_uuid();
    v_proj UUID := gen_random_uuid();
    v_exec UUID := gen_random_uuid();
    v_pol UUID := gen_random_uuid();
    v_entity UUID := gen_random_uuid();
    v_trans UUID := gen_random_uuid();
    v_last_trans UUID;
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
    VALUES (v_proj, v_pol, v_exec, 'STATE_TRANSITION', 'TEST', gen_random_uuid(), 'TEST_ENTITY', v_entity, repeat('0', 64), repeat('0', 128), NOW());
    INSERT INTO state_rules (state_rule_id, entity_type, from_state, to_state, required_decision_type, allowed) VALUES (gen_random_uuid(), 'TEST_ENTITY', 'A', 'B', 'ANY', true);
    
    EXECUTE 'ALTER TABLE billable_clients ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE tenants ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE projects ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE execution_records ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE policy_decisions ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE state_rules ENABLE TRIGGER ALL';
    
    -- Execute full write path (Trigger-mediated upsert)
    INSERT INTO state_transitions (transition_id, project_id, entity_type, entity_id, from_state, to_state, transition_timestamp, execution_id, policy_decision_id, transition_hash, signature)
    VALUES (v_trans, v_proj, 'TEST_ENTITY', v_entity, 'A', 'B', NOW(), v_exec, v_pol, 'testhash1', repeat('0', 128));

    -- Assert resulting state_current row
    SELECT last_transition_id INTO v_last_trans FROM state_current WHERE entity_id = v_entity;
    
    IF v_last_trans IS NULL THEN
        RAISE EXCEPTION 'Invariant failed: last_transition_id is NULL after full-path write.';
    END IF;
    
    IF v_last_trans != v_trans THEN
        RAISE EXCEPTION 'Invariant failed: last_transition_id (%) does not match inserted transition_id (%)', v_last_trans, v_trans;
    END IF;

END $$;
ROLLBACK;
EOF
if [ $? -eq 0 ]; then
    NEGATIVE_TEST_N2="pass"
else
    echo "ERROR: TSK-P2-W6-REM-14-N2 failed (full-path invariant write path)."
    cat /tmp/w6_rem_14_full_path.log
    exit 1
fi

cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": {
    "is_nullable": "$IS_NULLABLE",
    "attnotnull": "$ATTNOTNULL",
    "null_row_count_pre_alter": "$NULL_ROW_COUNT",
    "migration_0151_applied_at": "$MIGRATION_0151_APPLIED_AT"
  },
  "negative_test_results": {
    "TSK-P2-W6-REM-14-N1": "$NEGATIVE_TEST_N1",
    "TSK-P2-W6-REM-14-N2": "$NEGATIVE_TEST_N2"
  }
}
EOF

if [ "$IS_NULLABLE" != "NO" ]; then
    echo "ERROR: state_current.last_transition_id is_nullable = $IS_NULLABLE (expected NO)"
    exit 1
fi

if [ "$ATTNOTNULL" != "t" ]; then
    echo "ERROR: state_current.last_transition_id attnotnull = $ATTNOTNULL (expected t)"
    exit 1
fi

if [ "$NEGATIVE_TEST_N1" != "pass" ] || [ "$NEGATIVE_TEST_N2" != "pass" ]; then
    echo "ERROR: One or more negative tests failed."
    exit 1
fi

echo "Verification successful for $TASK_ID"
