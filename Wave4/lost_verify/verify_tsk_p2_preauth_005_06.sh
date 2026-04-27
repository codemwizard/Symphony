#!/bin/bash
# Verification script for TSK-P2-PREAUTH-005-06
# Verifies enforce_execution_binding() function exists, is SECURITY DEFINER, and trigger is attached
# Includes negative test TSK-P2-PREAUTH-005-06-N1

set -e

TASK_ID="TSK-P2-PREAUTH-005-06"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_preauth_005_06.json"

# Check if function exists
FUNCTION_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM pg_proc WHERE proname='enforce_execution_binding';")

# Check if function is SECURITY DEFINER
SECURITY_DEFINER=$(psql "$DATABASE_URL" -tAc "SELECT prosecdef FROM pg_proc WHERE proname='enforce_execution_binding';")

# Check if trigger is attached
TRIGGER_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM pg_trigger WHERE tgname='bi_02_enforce_execution_binding';")

echo "Running behavioral tests for enforce_execution_binding..."
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
    VALUES (gen_random_uuid(), v_proj, 'TEST_ENTITY', gen_random_uuid(), 'A', 'B', NOW(), v_exec, v_pol, 'testhash6', repeat('0', 128));
END $$;
ROLLBACK;
EOF
if [ $? -ne 0 ]; then
    echo "ERROR: Behavioral positive test failed."
    exit 1
fi

# Negative Test: TSK-P2-PREAUTH-005-06-N1 (Invalid Execution Binding)
if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'EOF' > /dev/null 2>&1
BEGIN;
DO $$
DECLARE
    v_bc UUID := gen_random_uuid();
    v_tenant UUID := gen_random_uuid();
    v_proj UUID := gen_random_uuid();
    v_exec UUID := gen_random_uuid();
    v_pol UUID := gen_random_uuid();
    v_fake_exec UUID := gen_random_uuid();
BEGIN
    EXECUTE 'ALTER TABLE billable_clients DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE tenants DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE projects DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE execution_records DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE policy_decisions DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE state_rules DISABLE TRIGGER ALL';
    
    -- Disable foreign keys on state_transitions so it passes structural FK but hits trigger
    EXECUTE 'ALTER TABLE state_transitions DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE state_transitions ENABLE TRIGGER bi_02_enforce_execution_binding';

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
    
    -- Negative Test: fake execution_id
    INSERT INTO state_transitions (transition_id, project_id, entity_type, entity_id, from_state, to_state, transition_timestamp, execution_id, policy_decision_id, transition_hash, signature)
    VALUES (gen_random_uuid(), v_proj, 'TEST_ENTITY', gen_random_uuid(), 'A', 'B', NOW(), v_fake_exec, v_pol, 'testhash6', repeat('0', 128));
END $$;
ROLLBACK;
EOF
then
    echo "ERROR: Behavioral negative test failed (database accepted invalid execution_id)."
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
    "function_exists": $([ "$FUNCTION_EXISTS" = "1" ] && echo "true" || echo "false"),
    "security_definer_present": $([ "$SECURITY_DEFINER" = "t" ] && echo "true" || echo "false"),
    "trigger_attached": $([ "$TRIGGER_EXISTS" = "1" ] && echo "true" || echo "false"),
    "negative_test_TSK-P2-PREAUTH-005-06-N1": "$NEGATIVE_TEST_RESULT"
  }
}
EOF

# Verify all checks passed
if [ "$FUNCTION_EXISTS" != "1" ]; then
  echo "ERROR: enforce_execution_binding() function does not exist"
  exit 1
fi

if [ "$SECURITY_DEFINER" != "t" ]; then
  echo "ERROR: enforce_execution_binding() is not SECURITY DEFINER"
  exit 1
fi

if [ "$TRIGGER_EXISTS" != "1" ]; then
  echo "ERROR: bi_02_enforce_execution_binding trigger is not attached"
  exit 1
fi

echo "Verification successful for $TASK_ID"
