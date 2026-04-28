#!/bin/bash
# Verification script for TSK-P2-W6-REM-17c-alpha
# Verifies NOT NULL constraint on state_transitions.interpretation_version_id
# and ensures all 11 Wave 5 verifiers pass with updated fixtures.

set -e

TASK_ID="TSK-P2-W6-REM-17c-alpha"
GIT_SHA=$(git rev-parse HEAD || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w6_rem_17c_alpha.json"

mkdir -p $(dirname "$EVIDENCE_FILE")

echo "Running verification for $TASK_ID..."

# 1. Check is_nullable in information_schema
IS_NULLABLE=$(psql "$DATABASE_URL" -tAc "
  SELECT is_nullable 
  FROM information_schema.columns 
  WHERE table_name = 'state_transitions' 
    AND column_name = 'interpretation_version_id';
")

if [ "$IS_NULLABLE" != "NO" ]; then
  echo "FAIL: interpretation_version_id is nullable (is_nullable=$IS_NULLABLE)"
  exit 1
fi

echo "  is_nullable=$IS_NULLABLE"

# 2. Negative Test: INSERT without interpretation_version_id should fail
N1_ERROR=$(psql "$DATABASE_URL" -c "
  BEGIN;
  DO \$\$
  DECLARE
      v_exec UUID := gen_random_uuid();
      v_proj UUID := gen_random_uuid();
      v_pol UUID := gen_random_uuid();
      v_tenant UUID := gen_random_uuid();
      v_bc UUID := gen_random_uuid();
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
      
      -- This should fail because interpretation_version_id is missing
      INSERT INTO state_transitions (transition_id, project_id, entity_type, entity_id, from_state, to_state, transition_timestamp, execution_id, policy_decision_id, transition_hash, signature)
      VALUES (gen_random_uuid(), v_proj, 'TEST_ENTITY', gen_random_uuid(), 'A', 'B', NOW(), v_exec, v_pol, 'testhash1', repeat('0', 128));
  END \$\$;
  ROLLBACK;
" 2>&1 || true)

if echo "$N1_ERROR" | grep -q "null value in column \"interpretation_version_id\""; then
  N1_RESULT="PASS"
  echo "  N1: Failed as expected due to missing interpretation_version_id"
else
  N1_RESULT="FAIL"
  echo "FAIL: Expected NOT NULL violation, got: $N1_ERROR"
  exit 1
fi

# 3. Verify all 11 W5 fixtures
echo "  Running W5 fix verification scripts..."
FAILED_TESTS=""
for script in \
  scripts/db/verify_tsk_p2_preauth_005_01.sh \
  scripts/db/verify_tsk_p2_preauth_005_03.sh \
  scripts/db/verify_tsk_p2_preauth_005_04.sh \
  scripts/db/verify_tsk_p2_preauth_005_05.sh \
  scripts/db/verify_tsk_p2_preauth_005_06.sh \
  scripts/db/verify_tsk_p2_preauth_005_07.sh \
  scripts/db/verify_tsk_p2_preauth_005_08.sh \
  scripts/db/verify_tsk_p2_w5_fix_01.sh \
  scripts/db/verify_tsk_p2_w5_fix_02.sh \
  scripts/db/verify_tsk_p2_w5_fix_03.sh \
  scripts/db/verify_wave5_state_machine_integration.sh
do
  if bash "$script" >/dev/null 2>&1; then
    echo "    [PASS] $script"
  else
    echo "    [FAIL] $script"
    FAILED_TESTS="$FAILED_TESTS $script"
  fi
done

if [ -n "$FAILED_TESTS" ]; then
  echo "FAIL: The following W5 verifiers failed after migration 0159:"
  echo "$FAILED_TESTS"
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
    "w5_fixtures_passed": true
  },
  "negative_test_results": {
    "TSK-P2-W6-REM-17c-alpha-N1": "$N1_RESULT"
  }
}
EOF

echo "Verification successful for $TASK_ID"
