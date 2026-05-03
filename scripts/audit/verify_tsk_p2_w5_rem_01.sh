#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [ -z "${DATABASE_URL:-}" ]; then
    echo "FATAL: DATABASE_URL not set"
    exit 1
fi

FAIL=0

echo "═══════════════════════════════════════════════════════"
echo "Verifier: TSK-P2-W5-REM-01 (Cross-Entity Protection)"
echo "═══════════════════════════════════════════════════════"

# 1. Structural Check
echo -n "Checking schema columns... "
count=$(psql "$DATABASE_URL" -t -A -c "
    SELECT count(*) 
    FROM information_schema.columns 
    WHERE table_name = 'execution_records' 
    AND column_name IN ('entity_type', 'entity_id') 
    AND is_nullable = 'NO';")
if [[ "$count" == "2" ]]; then
    echo "✅ PASS"
else
    echo "❌ FAIL (found $count columns)"
    FAIL=$((FAIL + 1))
fi

echo -n "Checking coherence trigger... "
count=$(psql "$DATABASE_URL" -t -A -c "
    SELECT count(*) 
    FROM pg_trigger 
    WHERE tgname = 'enforce_policy_decisions_entity_coherence';")
if [[ "$count" == "1" ]]; then
    echo "✅ PASS"
else
    echo "❌ FAIL"
    FAIL=$((FAIL + 1))
fi

# 2. Behavioral Check (Positive/Negative)
echo "Running behavioral tests..."

TEST_EXEC_ID=$(psql "$DATABASE_URL" -t -A -c "SELECT gen_random_uuid();")
ENTITY_A_ID=$(psql "$DATABASE_URL" -t -A -c "SELECT gen_random_uuid();")
ENTITY_B_ID=$(psql "$DATABASE_URL" -t -A -c "SELECT gen_random_uuid();")

# Setup: Insert dummy interpretation pack and execution record
PROJECT_ID=$(psql "$DATABASE_URL" -t -A -c "SELECT gen_random_uuid();")
PACK_ID=$(psql "$DATABASE_URL" -t -A -c "SELECT gen_random_uuid();")
PACK_TYPE="TEST_$(date +%s)"
psql "$DATABASE_URL" -c "
    INSERT INTO interpretation_packs (interpretation_pack_id, project_id, jurisdiction_code, pack_type, effective_from)
    VALUES ('$PACK_ID', '$PROJECT_ID', 'US', '$PACK_TYPE', now() - interval '1 hour');
" > /dev/null

psql "$DATABASE_URL" -c "
    INSERT INTO execution_records (
        execution_id, project_id, interpretation_version_id, 
        input_hash, output_hash, runtime_version, tenant_id,
        entity_type, entity_id, status
    ) VALUES (
        '$TEST_EXEC_ID', '$PROJECT_ID', '$PACK_ID', 
        'HASH_1', 'HASH_2', 'v1', gen_random_uuid(),
        'ENTITY_A', '$ENTITY_A_ID', 'PENDING'
    );
" > /dev/null

echo -n "  Negative Test (mismatched entity_type)... "
if psql "$DATABASE_URL" -c "
    INSERT INTO policy_decisions (
        policy_decision_id, project_id, execution_id, decision_type, authority_scope, declared_by, 
        entity_type, entity_id, decision_hash, signature, signed_at
    ) VALUES (
        gen_random_uuid(), '$PROJECT_ID', '$TEST_EXEC_ID', 'GRANT', 'GLOBAL', gen_random_uuid(), 
        'ENTITY_B', '$ENTITY_A_ID', 
        '0000000000000000000000000000000000000000000000000000000000000000', 
        '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 
        now()
    );" 2>&1 | grep -q "GF062"; then
    echo "✅ PASS (Blocked)"
else
    echo "❌ FAIL (Allowed incorrectly!)"
    FAIL=$((FAIL + 1))
fi

echo -n "  Negative Test (mismatched entity_id)... "
if psql "$DATABASE_URL" -c "
    INSERT INTO policy_decisions (
        policy_decision_id, project_id, execution_id, decision_type, authority_scope, declared_by, 
        entity_type, entity_id, decision_hash, signature, signed_at
    ) VALUES (
        gen_random_uuid(), '$PROJECT_ID', '$TEST_EXEC_ID', 'GRANT', 'GLOBAL', gen_random_uuid(), 
        'ENTITY_A', '$ENTITY_B_ID', 
        '0000000000000000000000000000000000000000000000000000000000000000', 
        '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 
        now()
    );" 2>&1 | grep -q "GF062"; then
    echo "✅ PASS (Blocked)"
else
    echo "❌ FAIL (Allowed incorrectly!)"
    FAIL=$((FAIL + 1))
fi

echo -n "  Positive Test (matching entity info)... "
if psql "$DATABASE_URL" -c "
    INSERT INTO policy_decisions (
        policy_decision_id, project_id, execution_id, decision_type, authority_scope, declared_by, 
        entity_type, entity_id, decision_hash, signature, signed_at
    ) VALUES (
        gen_random_uuid(), '$PROJECT_ID', '$TEST_EXEC_ID', 'GRANT', 'GLOBAL', gen_random_uuid(), 
        'ENTITY_A', '$ENTITY_A_ID', 
        '0000000000000000000000000000000000000000000000000000000000000000', 
        '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 
        now()
    );" > /dev/null 2>&1; then
    echo "✅ PASS (Allowed)"
else
    echo "❌ FAIL (Blocked incorrectly!)"
    FAIL=$((FAIL + 1))
fi

# Cleanup
psql "$DATABASE_URL" -c "DELETE FROM policy_decisions WHERE execution_id = '$TEST_EXEC_ID'; DELETE FROM execution_records WHERE execution_id = '$TEST_EXEC_ID'; DELETE FROM interpretation_packs WHERE interpretation_pack_id = '$PACK_ID';" > /dev/null

echo "═══════════════════════════════════════════════════════"
if [[ $FAIL -eq 0 ]]; then
    echo "STATUS: ✅ VERIFIED"
    exit 0
else
    echo "STATUS: ❌ FAILED ($FAIL errors)"
    exit 1
fi
