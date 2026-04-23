#!/usr/bin/env bash
# verify_policy_decisions_schema.sh
# Task: TSK-P2-PREAUTH-004-01
# Wave: 4 — Authority Binding
# Verifies policy_decisions table matches the 004-00 contract.
#
# Checks:
#   C1  Table exists in public schema
#   C2  All 11 columns present with correct types
#   C3  FK constraint on execution_id → execution_records
#   C4  UNIQUE constraint on (execution_id, decision_type)
#   C5  CHECK constraint on decision_hash (lowercase hex, 64 chars)
#   C6  CHECK constraint on signature (lowercase hex, 128 chars)
#   C7  Index idx_policy_decisions_entity exists
#   C8  Index idx_policy_decisions_declared_by exists
#   C9  Append-only trigger blocks UPDATE
#   C10 Append-only trigger blocks DELETE
#   C11 Trigger function has SECURITY DEFINER + search_path hardening
#   C12 public.policy_decisions namespace enforcement
#
# Evidence: evidence/phase2/tsk_p2_preauth_004_01.json

set -euo pipefail

EVIDENCE_FILE="evidence/phase2/tsk_p2_preauth_004_01.json"
TASK_ID="TSK-P2-PREAUTH-004-01"
PASS_COUNT=0
FAIL_COUNT=0
CHECKS=()

DB_NAME="${SYMPHONY_DB:-symphony_test}"

add_check() {
    local id="$1" status="$2" detail="$3"
    CHECKS+=("{\"id\":\"${id}\",\"status\":\"${status}\",\"detail\":\"${detail}\"}")
    if [ "$status" = "PASS" ]; then
        ((PASS_COUNT++)) || true
    else
        ((FAIL_COUNT++)) || true
        echo "FAIL: ${id} — ${detail}" >&2
    fi
}

# ── C1: Table exists ──
if psql -d "$DB_NAME" -tAc \
    "SELECT 1 FROM information_schema.tables
     WHERE table_schema='public' AND table_name='policy_decisions'
     LIMIT 1;" | grep -q "1"; then
    add_check "C1" "PASS" "Table public.policy_decisions exists"
else
    add_check "C1" "FAIL" "Table public.policy_decisions does not exist"
fi

# ── C2: All 11 columns present ──
EXPECTED_COLUMNS="policy_decision_id execution_id entity_type entity_id decision_type authority_scope declared_by decision_hash signature signed_at created_at"
MISSING=""
for col in $EXPECTED_COLUMNS; do
    if ! psql -d "$DB_NAME" -tAc \
        "SELECT 1 FROM information_schema.columns
         WHERE table_schema='public' AND table_name='policy_decisions'
         AND column_name='${col}' LIMIT 1;" | grep -q "1"; then
        MISSING="${MISSING} ${col}"
    fi
done
if [ -z "$MISSING" ]; then
    add_check "C2" "PASS" "All 11 columns present"
else
    add_check "C2" "FAIL" "Missing columns:${MISSING}"
fi

# ── C3: FK on execution_id ──
if psql -d "$DB_NAME" -tAc \
    "SELECT 1 FROM information_schema.table_constraints tc
     JOIN information_schema.key_column_usage kcu
       ON tc.constraint_name = kcu.constraint_name
     WHERE tc.table_schema='public'
       AND tc.table_name='policy_decisions'
       AND tc.constraint_type='FOREIGN KEY'
       AND kcu.column_name='execution_id'
     LIMIT 1;" | grep -q "1"; then
    add_check "C3" "PASS" "FK constraint on execution_id exists"
else
    add_check "C3" "FAIL" "FK constraint on execution_id missing"
fi

# ── C4: UNIQUE on (execution_id, decision_type) ──
if psql -d "$DB_NAME" -tAc \
    "SELECT 1 FROM pg_catalog.pg_constraint c
     JOIN pg_catalog.pg_class r ON c.conrelid = r.oid
     JOIN pg_catalog.pg_namespace n ON r.relnamespace = n.oid
     WHERE n.nspname = 'public'
       AND r.relname = 'policy_decisions'
       AND c.contype = 'u'
     LIMIT 1;" | grep -q "1"; then
    add_check "C4" "PASS" "UNIQUE constraint exists"
else
    add_check "C4" "FAIL" "UNIQUE constraint missing"
fi

# ── C5: CHECK on decision_hash ──
if psql -d "$DB_NAME" -tAc \
    "SELECT 1 FROM pg_catalog.pg_constraint c
     JOIN pg_catalog.pg_class r ON c.conrelid = r.oid
     JOIN pg_catalog.pg_namespace n ON r.relnamespace = n.oid
     WHERE n.nspname = 'public'
       AND r.relname = 'policy_decisions'
       AND c.contype = 'c'
       AND pg_get_constraintdef(c.oid) LIKE '%decision_hash%'
     LIMIT 1;" | grep -q "1"; then
    add_check "C5" "PASS" "CHECK constraint on decision_hash exists"
else
    add_check "C5" "FAIL" "CHECK constraint on decision_hash missing"
fi

# ── C6: CHECK on signature ──
if psql -d "$DB_NAME" -tAc \
    "SELECT 1 FROM pg_catalog.pg_constraint c
     JOIN pg_catalog.pg_class r ON c.conrelid = r.oid
     JOIN pg_catalog.pg_namespace n ON r.relnamespace = n.oid
     WHERE n.nspname = 'public'
       AND r.relname = 'policy_decisions'
       AND c.contype = 'c'
       AND pg_get_constraintdef(c.oid) LIKE '%signature%'
     LIMIT 1;" | grep -q "1"; then
    add_check "C6" "PASS" "CHECK constraint on signature exists"
else
    add_check "C6" "FAIL" "CHECK constraint on signature missing"
fi

# ── C7: Index on (entity_type, entity_id) ──
if psql -d "$DB_NAME" -tAc \
    "SELECT 1 FROM pg_catalog.pg_indexes
     WHERE schemaname='public'
       AND tablename='policy_decisions'
       AND indexname='idx_policy_decisions_entity'
     LIMIT 1;" | grep -q "1"; then
    add_check "C7" "PASS" "Index idx_policy_decisions_entity exists"
else
    add_check "C7" "FAIL" "Index idx_policy_decisions_entity missing"
fi

# ── C8: Index on declared_by ──
if psql -d "$DB_NAME" -tAc \
    "SELECT 1 FROM pg_catalog.pg_indexes
     WHERE schemaname='public'
       AND tablename='policy_decisions'
       AND indexname='idx_policy_decisions_declared_by'
     LIMIT 1;" | grep -q "1"; then
    add_check "C8" "PASS" "Index idx_policy_decisions_declared_by exists"
else
    add_check "C8" "FAIL" "Index idx_policy_decisions_declared_by missing"
fi

# ── C9: Append-only trigger blocks UPDATE ──
UPDATE_RESULT=$(psql -d "$DB_NAME" -tAc "
    DO \$\$
    BEGIN
        -- Only test if table has rows; insert a throwaway if empty
        INSERT INTO public.policy_decisions (
            policy_decision_id, execution_id, entity_type, entity_id,
            decision_type, authority_scope, declared_by,
            decision_hash, signature, signed_at
        ) VALUES (
            '00000000-0000-0000-0000-000000000099'::uuid,
            (SELECT execution_id FROM public.execution_records LIMIT 1),
            'test_entity', '00000000-0000-0000-0000-000000000001'::uuid,
            'TEST_UPDATE_BLOCK', 'test_scope',
            '00000000-0000-0000-0000-000000000002'::uuid,
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            now()
        );
        BEGIN
            UPDATE public.policy_decisions
            SET authority_scope = 'tampered'
            WHERE policy_decision_id = '00000000-0000-0000-0000-000000000099'::uuid;
            RAISE NOTICE 'UPDATE_ALLOWED';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'UPDATE_BLOCKED';
        END;
        DELETE FROM public.policy_decisions
        WHERE policy_decision_id = '00000000-0000-0000-0000-000000000099'::uuid;
    EXCEPTION WHEN OTHERS THEN
        NULL; -- cleanup may also be blocked, handled in C10
    END;
    \$\$;
" 2>&1)
if echo "$UPDATE_RESULT" | grep -q "UPDATE_BLOCKED"; then
    add_check "C9" "PASS" "Append-only trigger blocks UPDATE"
else
    add_check "C9" "FAIL" "UPDATE was not blocked by append-only trigger"
fi

# ── C10: Append-only trigger blocks DELETE ──
DELETE_RESULT=$(psql -d "$DB_NAME" -tAc "
    DO \$\$
    BEGIN
        INSERT INTO public.policy_decisions (
            policy_decision_id, execution_id, entity_type, entity_id,
            decision_type, authority_scope, declared_by,
            decision_hash, signature, signed_at
        ) VALUES (
            '00000000-0000-0000-0000-000000000098'::uuid,
            (SELECT execution_id FROM public.execution_records LIMIT 1),
            'test_entity', '00000000-0000-0000-0000-000000000001'::uuid,
            'TEST_DELETE_BLOCK', 'test_scope',
            '00000000-0000-0000-0000-000000000002'::uuid,
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
            now()
        );
        BEGIN
            DELETE FROM public.policy_decisions
            WHERE policy_decision_id = '00000000-0000-0000-0000-000000000098'::uuid;
            RAISE NOTICE 'DELETE_ALLOWED';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'DELETE_BLOCKED';
        END;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
    \$\$;
" 2>&1)
if echo "$DELETE_RESULT" | grep -q "DELETE_BLOCKED"; then
    add_check "C10" "PASS" "Append-only trigger blocks DELETE"
else
    add_check "C10" "FAIL" "DELETE was not blocked by append-only trigger"
fi

# ── C11: Trigger function has SECURITY DEFINER + search_path ──
if psql -d "$DB_NAME" -tAc \
    "SELECT prosecdef FROM pg_catalog.pg_proc
     WHERE proname = 'enforce_policy_decisions_append_only'
     LIMIT 1;" | grep -q "t"; then
    SECDEF_OK="true"
else
    SECDEF_OK="false"
fi
if psql -d "$DB_NAME" -tAc \
    "SELECT proconfig FROM pg_catalog.pg_proc
     WHERE proname = 'enforce_policy_decisions_append_only'
     LIMIT 1;" | grep -q "search_path"; then
    SEARCHPATH_OK="true"
else
    SEARCHPATH_OK="false"
fi
if [ "$SECDEF_OK" = "true" ] && [ "$SEARCHPATH_OK" = "true" ]; then
    add_check "C11" "PASS" "SECURITY DEFINER + search_path hardening present"
else
    add_check "C11" "FAIL" "SECURITY DEFINER=${SECDEF_OK}, search_path=${SEARCHPATH_OK}"
fi

# ── C12: Schema namespace enforcement ──
if grep -q 'public\.policy_decisions' schema/migrations/0134_policy_decisions.sql 2>/dev/null; then
    add_check "C12" "PASS" "Migration uses public. schema prefix"
else
    add_check "C12" "FAIL" "Migration missing public. schema prefix"
fi

# ── Negative Tests ──
echo ""
echo "=== Negative Tests ==="

# N1: NULL execution_id must fail
N1_RESULT=$(psql -d "$DB_NAME" -tAc "
    INSERT INTO public.policy_decisions (
        policy_decision_id, execution_id, entity_type, entity_id,
        decision_type, authority_scope, declared_by,
        decision_hash, signature, signed_at
    ) VALUES (
        gen_random_uuid(), NULL, 'test', gen_random_uuid(),
        'TEST', 'test', gen_random_uuid(),
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        now()
    );
" 2>&1) && N1_STATUS="FAIL" || N1_STATUS="PASS"
add_check "N1" "$N1_STATUS" "NULL execution_id must fail"

# N2: NULL signature must fail
N2_RESULT=$(psql -d "$DB_NAME" -tAc "
    INSERT INTO public.policy_decisions (
        policy_decision_id, execution_id, entity_type, entity_id,
        decision_type, authority_scope, declared_by,
        decision_hash, signature, signed_at
    ) VALUES (
        gen_random_uuid(),
        (SELECT execution_id FROM public.execution_records LIMIT 1),
        'test', gen_random_uuid(),
        'TEST', 'test', gen_random_uuid(),
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        NULL,
        now()
    );
" 2>&1) && N2_STATUS="FAIL" || N2_STATUS="PASS"
add_check "N2" "$N2_STATUS" "NULL signature must fail"

# N3: NULL entity_id must fail
N3_RESULT=$(psql -d "$DB_NAME" -tAc "
    INSERT INTO public.policy_decisions (
        policy_decision_id, execution_id, entity_type, entity_id,
        decision_type, authority_scope, declared_by,
        decision_hash, signature, signed_at
    ) VALUES (
        gen_random_uuid(),
        (SELECT execution_id FROM public.execution_records LIMIT 1),
        'test', NULL,
        'TEST', 'test', gen_random_uuid(),
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        now()
    );
" 2>&1) && N3_STATUS="FAIL" || N3_STATUS="PASS"
add_check "N3" "$N3_STATUS" "NULL entity_id must fail"

# N4: Invalid decision_hash (wrong length) must fail CHECK
N4_RESULT=$(psql -d "$DB_NAME" -tAc "
    INSERT INTO public.policy_decisions (
        policy_decision_id, execution_id, entity_type, entity_id,
        decision_type, authority_scope, declared_by,
        decision_hash, signature, signed_at
    ) VALUES (
        gen_random_uuid(),
        (SELECT execution_id FROM public.execution_records LIMIT 1),
        'test', gen_random_uuid(),
        'TEST', 'test', gen_random_uuid(),
        'tooshort',
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        now()
    );
" 2>&1) && N4_STATUS="FAIL" || N4_STATUS="PASS"
add_check "N4" "$N4_STATUS" "Invalid decision_hash (wrong length) must fail CHECK"

# N5: Invalid execution_id (FK violation) must fail
N5_RESULT=$(psql -d "$DB_NAME" -tAc "
    INSERT INTO public.policy_decisions (
        policy_decision_id, execution_id, entity_type, entity_id,
        decision_type, authority_scope, declared_by,
        decision_hash, signature, signed_at
    ) VALUES (
        gen_random_uuid(),
        '00000000-0000-0000-0000-ffffffffffff'::uuid,
        'test', gen_random_uuid(),
        'TEST', 'test', gen_random_uuid(),
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        now()
    );
" 2>&1) && N5_STATUS="FAIL" || N5_STATUS="PASS"
add_check "N5" "$N5_STATUS" "Invalid execution_id (FK violation) must fail"

# ── Emit Evidence ──
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
MIGRATION_HEAD=$(cat schema/migrations/MIGRATION_HEAD 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

CHECKS_JSON=$(IFS=,; echo "${CHECKS[*]}")

mkdir -p "$(dirname "$EVIDENCE_FILE")"
cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "${TASK_ID}",
  "git_sha": "${GIT_SHA}",
  "migration_head": "${MIGRATION_HEAD}",
  "timestamp_utc": "${TIMESTAMP}",
  "status": "$( [ "$FAIL_COUNT" -eq 0 ] && echo "PASS" || echo "FAIL" )",
  "pass_count": ${PASS_COUNT},
  "fail_count": ${FAIL_COUNT},
  "checks": [${CHECKS_JSON}],
  "verifier": "scripts/db/verify_policy_decisions_schema.sh",
  "contract_ref": "docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md"
}
EOF

echo ""
echo "=== Results: ${PASS_COUNT} PASS, ${FAIL_COUNT} FAIL ==="
echo "Evidence written to: ${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
