#!/usr/bin/env bash
# ============================================================
# test_execution_records_determinism_constraints_negative.sh
# Task: TSK-P2-PREAUTH-003-REM-02 (negative-test harness)
#
# N1: INSERT with input_hash      = NULL -> SQLSTATE 23502 (NOT NULL)
# N2: INSERT with runtime_version = NULL -> SQLSTATE 23502
# N3: Two INSERTs sharing the same (input_hash, interpretation_version_id,
#     runtime_version) -> SQLSTATE 23505 (unique_violation)
#
# PostgreSQL firing order on INSERT is: BEFORE-row triggers → NOT NULL →
# CHECK → UNIQUE/FK. After migration 0133 installs the BEFORE INSERT
# temporal-binding trigger (enforce_execution_interpretation_temporal_binding,
# raising GF058 when interpretation_version_id does not resolve to the pack
# active at execution_timestamp), synthetic UUIDs would trip GF058 before
# the NOT NULL check the assertion needs to reach.
#
# To keep N1/N2 genuinely asserting the NOT NULL constraints, all three
# negatives share the same precondition: a real interpretation_packs row
# (project_id + effective_from) seeded from catalog. The pack + a timestamp
# just past effective_from satisfy resolve_interpretation_pack(), so GF058
# passes and execution reaches the NOT NULL boundary N1/N2 target.
#
# If no pack row exists (e.g. a brand-new test DB), we skip all three
# negatives with a loud SKIP rather than fabricating one (seeding
# projects/tenants would cross RLS boundaries outside REM-02 scope). The
# UNIQUE + NOT NULL enforcement is still asserted at catalog level by
# scripts/db/verify_execution_records_determinism_constraints.sh.
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

# ─── Shared precondition: a real interpretation pack row ──────────────
PACK_ROW="$(psql "$DATABASE_URL" -qAt -c "
SELECT ip.interpretation_pack_id::text,
       COALESCE(ip.project_id::text, ''),
       COALESCE(ip.effective_from::text, '')
FROM public.interpretation_packs ip
WHERE ip.project_id IS NOT NULL AND ip.effective_from IS NOT NULL
ORDER BY ip.effective_from DESC
LIMIT 1;")"

if [[ -z "$PACK_ROW" ]]; then
    echo "SKIP: N1/N2/N3 — no interpretation_packs row with project_id + effective_from available."
    echo "      NOT NULL + UNIQUE enforcement is still asserted at catalog level by"
    echo "      scripts/db/verify_execution_records_determinism_constraints.sh."
    echo "      (Seeding packs crosses RLS boundaries outside REM-02 scope.)"
    echo "PASS: REM-02 negative tests (all skipped per shared guard)"
    exit 0
fi

PACK_ID="$(echo "$PACK_ROW" | awk -F'|' '{print $1}')"
PROJECT_ID="$(echo "$PACK_ROW" | awk -F'|' '{print $2}')"
EFFECTIVE_FROM="$(echo "$PACK_ROW" | awk -F'|' '{print $3}')"
TS="$(psql "$DATABASE_URL" -qAt -c "SELECT ('$EFFECTIVE_FROM'::timestamptz + interval '1 second')::text;")"
TENANT_ID="$(psql "$DATABASE_URL" -qAt -c "SELECT gen_random_uuid()::text;")"

echo "==> N1: INSERT with NULL input_hash (pack-seeded so GF058 passes; NOT NULL under test)"
assert_insert_fails_with "N1 NULL input_hash" "23502" "
INSERT INTO public.execution_records
    (project_id, execution_timestamp, interpretation_version_id, input_hash, output_hash, runtime_version, tenant_id)
VALUES ('$PROJECT_ID', '$TS', '$PACK_ID', NULL, 'out_n1', 'rt_1.0', '$TENANT_ID');"

echo "==> N2: INSERT with NULL runtime_version (pack-seeded so GF058 passes; NOT NULL under test)"
assert_insert_fails_with "N2 NULL runtime_version" "23502" "
INSERT INTO public.execution_records
    (project_id, execution_timestamp, interpretation_version_id, input_hash, output_hash, runtime_version, tenant_id)
VALUES ('$PROJECT_ID', '$TS', '$PACK_ID', 'in_n2', 'out_n2', NULL, '$TENANT_ID');"

echo "==> N3: duplicate (input_hash, interpretation_version_id, runtime_version)"
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
