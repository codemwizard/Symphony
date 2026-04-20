#!/usr/bin/env bash
# ============================================================
# test_execution_records_determinism_constraints_negative.sh
# Task: TSK-P2-PREAUTH-003-REM-02 (negative-test harness)
#
# N1: INSERT with input_hash = NULL      -> SQLSTATE 23502 (NOT NULL)
# N2: INSERT with runtime_version = NULL -> SQLSTATE 23502
# N3: Two INSERTs sharing the same (input_hash, interpretation_version_id,
#     runtime_version) -> SQLSTATE 23505 (unique_violation)
#
# N1/N2 use synthetic UUIDs because the NOT NULL check fires before any
# FK/RLS/trigger — no real pack/project row is required for the assertion
# to reach the constraint under test.
#
# N3 seeds a valid row first (bypassing the 0134 temporal-binding trigger
# by resolving a real interpretation pack + timestamp). If no pack exists
# we skip N3 with a loud warning rather than fabricating one (seeding
# projects/tenants would cross RLS boundaries outside this task's scope).
# ============================================================
set -Eeuo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

assert_insert_fails_with() {
    local label="$1"
    local expected_sqlstate="$2"
    local sql="$3"
    local err
    set +e
    err="$(psql "$DATABASE_URL" -v VERBOSITY=verbose -v ON_ERROR_STOP=0 -c "$sql" 2>&1 >/dev/null)"
    local rc=$?
    set -e
    if [[ $rc -eq 0 ]]; then
        echo "FAIL: $label INSERT succeeded (expected SQLSTATE $expected_sqlstate)" >&2
        return 1
    fi
    if echo "$err" | grep -Eq "(^|[^0-9])$expected_sqlstate([^0-9]|$)"; then
        echo "PASS: $label (SQLSTATE $expected_sqlstate)"
        return 0
    fi
    echo "FAIL: $label rejected but SQLSTATE did not match $expected_sqlstate" >&2
    echo "$err" | head -5 >&2
    return 1
}

echo "==> N1: INSERT with NULL input_hash"
assert_insert_fails_with "N1 NULL input_hash" "23502" "
INSERT INTO public.execution_records
    (project_id, execution_timestamp, interpretation_version_id, input_hash, output_hash, runtime_version, tenant_id)
VALUES (gen_random_uuid(), NOW(), gen_random_uuid(), NULL, 'out_n1', 'rt_1.0', gen_random_uuid());"

echo "==> N2: INSERT with NULL runtime_version"
assert_insert_fails_with "N2 NULL runtime_version" "23502" "
INSERT INTO public.execution_records
    (project_id, execution_timestamp, interpretation_version_id, input_hash, output_hash, runtime_version, tenant_id)
VALUES (gen_random_uuid(), NOW(), gen_random_uuid(), 'in_n2', 'out_n2', NULL, gen_random_uuid());"

echo "==> N3: duplicate (input_hash, interpretation_version_id, runtime_version)"
PACK_ROW="$(psql "$DATABASE_URL" -qAt -c "
SELECT ip.interpretation_pack_id::text,
       COALESCE(ip.project_id::text, ''),
       COALESCE(ip.effective_from::text, '')
FROM public.interpretation_packs ip
WHERE ip.project_id IS NOT NULL AND ip.effective_from IS NOT NULL
ORDER BY ip.effective_from DESC
LIMIT 1;")"

if [[ -z "$PACK_ROW" ]]; then
    echo "SKIP: N3 — no interpretation_packs row with project_id + effective_from available."
    echo "      UNIQUE enforcement is still asserted at catalog level by the verifier."
    echo "      (Seeding packs crosses RLS boundaries outside REM-02 scope.)"
    echo "PASS: REM-02 negative tests (N1, N2 executed; N3 skipped per guard)"
    exit 0
fi

PACK_ID="$(echo "$PACK_ROW" | awk -F'|' '{print $1}')"
PROJECT_ID="$(echo "$PACK_ROW" | awk -F'|' '{print $2}')"
EFFECTIVE_FROM="$(echo "$PACK_ROW" | awk -F'|' '{print $3}')"
TS="$(psql "$DATABASE_URL" -qAt -c "SELECT ('$EFFECTIVE_FROM'::timestamptz + interval '1 second')::text;")"
TENANT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT gen_random_uuid()::text;")"
SEED_IN="seed_$(date +%s%N)"

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "
INSERT INTO public.execution_records
    (project_id, execution_timestamp, interpretation_version_id, input_hash, output_hash, runtime_version, tenant_id)
VALUES ('$PROJECT_ID', '$TS', '$PACK_ID', '$SEED_IN', 'seed_out', 'rt_seed', '$TENANT_ID');" >/dev/null

assert_insert_fails_with "N3 duplicate determinism tuple" "23505" "
INSERT INTO public.execution_records
    (project_id, execution_timestamp, interpretation_version_id, input_hash, output_hash, runtime_version, tenant_id)
VALUES ('$PROJECT_ID', '$TS', '$PACK_ID', '$SEED_IN', 'other_out', 'rt_seed', '$TENANT_ID');"

echo "PASS: REM-02 negative tests (23502 x2, 23505 x1)"
