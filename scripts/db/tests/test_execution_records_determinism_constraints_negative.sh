#!/usr/bin/env bash
set -euo pipefail

# test_execution_records_determinism_constraints_negative.sh
#
# Task: TSK-P2-PREAUTH-003-REM-02
#
# Negative-path harness for the determinism contract. Drives three exploits
# against a live database and asserts each raises the expected SQLSTATE:
#   1. INSERT with NULL input_hash                      -> 23502
#   2. INSERT with NULL interpretation_version_id       -> 23502
#   3. Duplicate (input_hash, interpretation_version_id, runtime_version) -> 23505
#
# Invoked by scripts/db/verify_execution_records_determinism_constraints.sh;
# safe to run standalone for debugging.

: "${DATABASE_URL:?DATABASE_URL is required}"

expect_sqlstate() {
    local label="$1" expected="$2" sql="$3"
    local output
    output="$(psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "$sql" 2>&1 || true)"
    if echo "$output" | grep -qE "SQLSTATE=$expected|ERRCODE=$expected|(23502.*null|23505.*duplicate)"; then
        echo "  PASS: $label (expected=$expected)"
        return 0
    fi
    if [[ "$expected" == "23502" ]] && echo "$output" | grep -qiE "null value|not-null constraint"; then
        echo "  PASS: $label (expected=$expected)"
        return 0
    fi
    if [[ "$expected" == "23505" ]] && echo "$output" | grep -qiE "duplicate key value|unique constraint"; then
        echo "  PASS: $label (expected=$expected)"
        return 0
    fi
    echo "  FAIL: $label (expected $expected)"
    echo "  raw: $output"
    return 1
}

echo "==> REM-02 negative tests"

FAIL=0

expect_sqlstate "null_input_hash" "23502" "
  BEGIN;
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id)
  VALUES (gen_random_uuid(), 'completed', NULL, 'x', 'v1', gen_random_uuid(), gen_random_uuid());
  ROLLBACK;" || FAIL=1

expect_sqlstate "null_interpretation_version_id" "23502" "
  BEGIN;
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id)
  VALUES (gen_random_uuid(), 'completed', 'h', 'o', 'v1', gen_random_uuid(), NULL);
  ROLLBACK;" || FAIL=1

PACK_ID="$(psql "$DATABASE_URL" -X -q -t -A -v ON_ERROR_STOP=1 -c "
  INSERT INTO public.interpretation_packs (jurisdiction_code, pack_type, pack_payload_json, project_id, effective_from)
  VALUES ('ZM', 'rem02_neg_test', '{}'::jsonb, gen_random_uuid(), NOW())
  RETURNING interpretation_pack_id;" | tail -n1)"

expect_sqlstate "duplicate_determinism_tuple" "23505" "
  BEGIN;
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id)
  VALUES (gen_random_uuid(), 'completed', 'neg_h', 'o1', 'neg_rt', gen_random_uuid(), '$PACK_ID'::uuid);
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id)
  VALUES (gen_random_uuid(), 'completed', 'neg_h', 'o2', 'neg_rt', gen_random_uuid(), '$PACK_ID'::uuid);
  ROLLBACK;" || FAIL=1

psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "DELETE FROM public.interpretation_packs WHERE interpretation_pack_id='$PACK_ID';" >/dev/null

exit $FAIL
