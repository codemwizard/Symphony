#!/usr/bin/env bash
set -euo pipefail

# test_execution_records_temporal_binding_negative.sh
#
# Task: TSK-P2-PREAUTH-003-REM-03
#
# INSERTs a row into public.execution_records whose interpretation_version_id
# is intentionally set to a value different from resolve_interpretation_pack(
# project_id, execution_timestamp). Asserts SQLSTATE GF058.

: "${DATABASE_URL:?DATABASE_URL is required}"

FAIL=0

check_gf058() {
    local label="$1" sql="$2"
    local output
    output="$(psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "$sql" 2>&1 || true)"
    if echo "$output" | grep -qE "GF058|temporal binding|no interpretation_pack resolvable"; then
        echo "  PASS: $label"
    else
        echo "  FAIL: $label"
        echo "  raw: $output"
        FAIL=1
    fi
}

# Case 1: project has no interpretation_pack -> resolve returns NULL -> GF058.
check_gf058 "no_resolvable_pack" "
  BEGIN;
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id, execution_timestamp)
  VALUES (gen_random_uuid(), 'completed', 'h1', 'o1', 'v1', gen_random_uuid(), gen_random_uuid(), NOW());
  ROLLBACK;"

# Case 2: pack exists for project; caller supplies a WRONG interpretation_version_id -> GF058.
PROJECT_ID="$(psql "$DATABASE_URL" -X -q -t -A -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tail -n1)"
PACK_ID="$(psql "$DATABASE_URL" -X -q -t -A -v ON_ERROR_STOP=1 -c "
  INSERT INTO public.interpretation_packs (jurisdiction_code, pack_type, pack_payload_json, project_id, effective_from)
  VALUES ('ZM', 'rem03_temporal_test', '{}'::jsonb, '$PROJECT_ID'::uuid, '2020-01-01'::timestamptz)
  RETURNING interpretation_pack_id;" | tail -n1)"

check_gf058 "mismatched_pack_id" "
  BEGIN;
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id, execution_timestamp)
  VALUES ('$PROJECT_ID'::uuid, 'completed', 'h2', 'o2', 'v1', gen_random_uuid(), gen_random_uuid(), '2024-01-01'::timestamptz);
  ROLLBACK;"

psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "DELETE FROM public.interpretation_packs WHERE interpretation_pack_id='$PACK_ID';" >/dev/null

exit $FAIL
