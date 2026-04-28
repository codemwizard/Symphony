#!/bin/bash
# Verification script for TSK-P2-PREAUTH-005-03
# Verifies enforce_transition_state_rules() function exists, is SECURITY DEFINER, and trigger is attached
# Includes negative test TSK-P2-PREAUTH-005-03-N1

set -e

TASK_ID="TSK-P2-PREAUTH-005-03"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_preauth_005_03.json"

# Check if function exists
FUNCTION_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM pg_proc WHERE proname='enforce_transition_state_rules';")

# Check if function is SECURITY DEFINER
SECURITY_DEFINER=$(psql "$DATABASE_URL" -tAc "SELECT prosecdef FROM pg_proc WHERE proname='enforce_transition_state_rules';")

# Check if trigger is attached (using new deterministic name from 0149)
TRIGGER_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM pg_trigger WHERE tgname='bi_03_enforce_transition_state_rules';")

# Negative test: TSK-P2-PREAUTH-005-03-N1
NEGATIVE_TEST_RESULT="fail"

echo "Running behavioral tests for enforce_transition_state_rules..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'EOF'
BEGIN;
DO $$
DECLARE
    v_interp UUID := gen_random_uuid();
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
    VALUES (v_exec, v_proj, v_tenant, v_interp, 'ih', 'oh', 'rv', 'pending');
    INSERT INTO policy_decisions (project_id, policy_decision_id, execution_id, decision_type, authority_scope, declared_by, entity_type, entity_id, decision_hash, signature, signed_at)
    VALUES (v_proj, v_pol, v_exec, 'ANY', 'TEST', gen_random_uuid(), 'TEST_ENTITY', gen_random_uuid(), repeat('0', 64), repeat('0', 128), NOW());
    INSERT INTO state_rules (state_rule_id, entity_type, from_state, to_state, required_decision_type, allowed) VALUES (gen_random_uuid(), 'TEST_ENTITY', 'A', 'B', 'ANY', true);
    
    EXECUTE 'ALTER TABLE billable_clients ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE tenants ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE projects ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE execution_records ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE policy_decisions ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE state_rules ENABLE TRIGGER ALL';
    
    -- Positive Test
    INSERT INTO state_transitions (transition_id, project_id, entity_type, entity_id, from_state, to_state, transition_timestamp, execution_id, policy_decision_id, transition_hash, signature, interpretation_version_id)
    VALUES (gen_random_uuid(), v_proj, 'TEST_ENTITY', gen_random_uuid(), 'A', 'B', NOW(), v_exec, v_pol, 'testhash3', repeat('0', 128), v_interp);
END $$;
ROLLBACK;
EOF
if [ $? -ne 0 ]; then
    echo "ERROR: Behavioral positive test failed."
    exit 1
fi

# Negative Test (Invalid transition, should raise exception)
if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'EOF' > /dev/null 2>&1
BEGIN;
DO $$
DECLARE
    v_interp UUID := gen_random_uuid();
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
    VALUES (v_exec, v_proj, v_tenant, v_interp, 'ih', 'oh', 'rv', 'pending');
    INSERT INTO policy_decisions (project_id, policy_decision_id, execution_id, decision_type, authority_scope, declared_by, entity_type, entity_id, decision_hash, signature, signed_at)
    VALUES (v_proj, v_pol, v_exec, 'ANY', 'TEST', gen_random_uuid(), 'TEST_ENTITY', gen_random_uuid(), repeat('0', 64), repeat('0', 128), NOW());
    
    EXECUTE 'ALTER TABLE billable_clients ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE tenants ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE projects ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE execution_records ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE policy_decisions ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE state_rules ENABLE TRIGGER ALL';
    -- Note: We do NOT insert a state_rule for INVALID -> INVALID, so it should fail
    
    INSERT INTO state_transitions (transition_id, project_id, entity_type, entity_id, from_state, to_state, transition_timestamp, execution_id, policy_decision_id, transition_hash, signature, interpretation_version_id)
    VALUES (gen_random_uuid(), v_proj, 'TEST_ENTITY', gen_random_uuid(), 'INVALID', 'INVALID', NOW(), v_exec, v_pol, 'testhash4', repeat('0', 128), v_interp);
END $$;
ROLLBACK;
EOF
then
    echo "ERROR: Behavioral negative test failed (database allowed invalid transition)."
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
    "negative_test_TSK-P2-PREAUTH-005-03-N1": "$NEGATIVE_TEST_RESULT"
  }
}
EOF

# Verify all checks passed
if [ "$FUNCTION_EXISTS" != "1" ]; then
  echo "ERROR: enforce_transition_state_rules() function does not exist"
  exit 1
fi

if [ "$SECURITY_DEFINER" != "t" ]; then
  echo "ERROR: enforce_transition_state_rules() is not SECURITY DEFINER"
  exit 1
fi

if [ "$TRIGGER_EXISTS" != "1" ]; then
  echo "ERROR: bi_03_enforce_transition_state_rules trigger is not attached"
  exit 1
fi

echo "Verification successful for $TASK_ID"
