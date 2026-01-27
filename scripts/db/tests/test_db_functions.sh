#!/usr/bin/env bash
# ============================================================
# test_db_functions.sh — Database function tests
# ============================================================
# Tests outbox functions against a real Postgres database.
# Requires: DATABASE_URL environment variable
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

echo "==> DB Function Tests"
echo ""

PASS=0
FAIL=0

run_test() {
  local name="$1"
  local sql="$2"
  echo -n "  $name: "
  if result=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -t -A -c "$sql" 2>&1); then
    if [[ "$result" == "PASS" ]]; then
      echo "✅ PASS"
      ((PASS++))
    else
      echo "❌ FAIL (got: $result)"
      ((FAIL++))
    fi
  else
    echo "❌ ERROR: $result"
    ((FAIL++))
  fi
}

# ============================================================
# Test 1: uuid_v7_or_random() returns valid UUID
# ============================================================
run_test "uuid_v7_or_random returns valid UUID" \
  "SELECT CASE WHEN public.uuid_v7_or_random()::text ~ '^[0-9a-f-]{36}\$' THEN 'PASS' ELSE 'FAIL' END;"

# ============================================================
# Test 2: uuid_strategy() returns known value
# ============================================================
run_test "uuid_strategy returns known strategy" \
  "SELECT CASE WHEN public.uuid_strategy() IN ('uuidv7', 'pgcrypto', 'gen_random_uuid') THEN 'PASS' ELSE 'FAIL' END;"

# ============================================================
# Test 3: bump_participant_outbox_seq returns monotonic sequence
# ============================================================
run_test "bump_participant_outbox_seq is monotonic" \
  "WITH a AS (SELECT public.bump_participant_outbox_seq('test_mono') AS x),
        b AS (SELECT public.bump_participant_outbox_seq('test_mono') AS y)
   SELECT CASE WHEN (SELECT x FROM a) < (SELECT y FROM b) THEN 'PASS' ELSE 'FAIL' END;"

# ============================================================
# Test 4: outbox_retry_ceiling returns finite value
# ============================================================
run_test "outbox_retry_ceiling is finite" \
  "SELECT CASE WHEN public.outbox_retry_ceiling() > 0 AND public.outbox_retry_ceiling() < 1000 THEN 'PASS' ELSE 'FAIL' END;"

# ============================================================
# Test 5: deny_outbox_attempts_mutation trigger exists
# ============================================================
run_test "append-only trigger exists" \
  "SELECT CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_deny_outbox_attempts_mutation') THEN 'PASS' ELSE 'FAIL' END;"

# ============================================================
# Test 6: policy_versions has is_active column
# ============================================================
run_test "policy_versions has is_active column" \
  "SELECT CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'policy_versions' AND column_name = 'is_active') THEN 'PASS' ELSE 'FAIL' END;"

# ============================================================
# Test 7: Exactly one ACTIVE policy exists (after seeding)
# ============================================================
run_test "exactly one ACTIVE policy exists" \
  "SELECT CASE WHEN (SELECT COUNT(*) FROM public.policy_versions WHERE is_active = true) = 1 THEN 'PASS' ELSE 'FAIL' END;"


# ============================================================
# Test 8: No PUBLIC privileges on core tables
# ============================================================
run_test "no PUBLIC privileges on payment_outbox_pending" \
  "SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM information_schema.role_table_grants WHERE grantee = 'PUBLIC' AND table_schema = 'public' AND table_name = 'payment_outbox_pending') THEN 'PASS' ELSE 'FAIL' END;"

# ============================================================
# Summary
# ============================================================
echo ""
echo "==> Test Summary: $PASS passed, $FAIL failed"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi

echo "✅ All DB function tests passed."
