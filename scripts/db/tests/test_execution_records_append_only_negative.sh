#!/usr/bin/env bash
set -euo pipefail

# test_execution_records_append_only_negative.sh
#
# Task: TSK-P2-PREAUTH-003-REM-03
#
# Drives UPDATE and DELETE against public.execution_records and asserts each
# raises SQLSTATE GF056 before any row is mutated. Statements run inside a
# BEGIN/ROLLBACK so nothing persists even in the (unreachable) success path.

: "${DATABASE_URL:?DATABASE_URL is required}"

FAIL=0

check_gf056() {
    local label="$1" sql="$2"
    local output
    output="$(psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "$sql" 2>&1 || true)"
    if echo "$output" | grep -qE "GF056|execution_records is append-only"; then
        echo "  PASS: $label"
    else
        echo "  FAIL: $label"
        echo "  raw: $output"
        FAIL=1
    fi
}

check_gf056 "update_execution_records" "
  BEGIN;
  UPDATE public.execution_records SET status='x' WHERE execution_id = gen_random_uuid();
  ROLLBACK;"

check_gf056 "delete_execution_records" "
  BEGIN;
  DELETE FROM public.execution_records WHERE execution_id = gen_random_uuid();
  ROLLBACK;"

exit $FAIL
