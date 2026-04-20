#!/usr/bin/env bash
# ============================================================
# test_execution_records_temporal_binding_negative.sh
# Task: TSK-P2-PREAUTH-003-REM-03
#
# N3: INSERT with interpretation_version_id that does not match
#     resolve_interpretation_pack(project_id, execution_timestamp)
#     -> SQLSTATE GF058
#
# We use synthetic UUIDs for project_id/interpretation_version_id so that
# resolve_interpretation_pack() returns NULL while NEW.interpretation_version_id
# is non-NULL — the IS DISTINCT FROM comparison fires GF058 before any FK
# check. This exercises the trigger without requiring seeded interpretation
# packs.
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
    if echo "$err" | grep -Eq "(^|[^A-Za-z0-9])$expected_sqlstate([^A-Za-z0-9]|$)"; then
        echo "PASS: $label (SQLSTATE $expected_sqlstate)"
        return 0
    fi
    echo "FAIL: $label rejected but SQLSTATE did not match $expected_sqlstate" >&2
    echo "$err" | head -5 >&2
    return 1
}

echo "==> N3: INSERT with mismatched interpretation_version_id"
assert_insert_fails_with "N3 temporal mismatch" "GF058" "
INSERT INTO public.execution_records
    (project_id, execution_timestamp, interpretation_version_id, input_hash, output_hash, runtime_version, tenant_id)
VALUES (gen_random_uuid(), NOW(), gen_random_uuid(), 'in_n3', 'out_n3', 'rt_1.0', gen_random_uuid());"

echo "PASS: REM-03 temporal-binding negative test (GF058)"
