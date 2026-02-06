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
terminal_uniqueness_result="UNKNOWN"
notify_result="UNKNOWN"

run_test() {
  local name="$1"
  local sql="$2"
  echo -n "  $name: "
  if result=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -q -t -A -c "$sql" 2>&1); then
    if [[ "$result" == "PASS" ]]; then
      echo "✅ PASS"
      PASS=$((PASS+1))
      if [[ "$name" == "terminal uniqueness enforced" ]]; then
        terminal_uniqueness_result="PASS"
      fi
    else
      echo "❌ FAIL (got: $result)"
      FAIL=$((FAIL+1))
      if [[ "$name" == "terminal uniqueness enforced" ]]; then
        terminal_uniqueness_result="FAIL"
      fi
    fi
  else
    echo "❌ ERROR: $result"
    FAIL=$((FAIL+1))
    if [[ "$name" == "terminal uniqueness enforced" ]]; then
      terminal_uniqueness_result="ERROR"
    fi
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
# Test 7: At most one ACTIVE policy exists (seed may be skipped in CI)
# ============================================================
run_test "at most one ACTIVE policy exists" \
  "SELECT CASE WHEN (SELECT COUNT(*) FROM public.policy_versions WHERE is_active = true) <= 1 THEN 'PASS' ELSE 'FAIL' END;"

# ============================================================
# Test 8: Enforce one terminal attempt per outbox_id
# ============================================================
run_test "terminal uniqueness enforced" \
  "CREATE OR REPLACE FUNCTION pg_temp._test_terminal_uniqueness() RETURNS text LANGUAGE plpgsql AS \$\$
   DECLARE
     v_outbox_id UUID := public.uuid_v7_or_random();
     v_instruction_id TEXT := 'test_terminal_' || v_outbox_id::text;
     v_participant_id TEXT := 'test_terminal_participant';
     v_idempotency_key TEXT := 'test_terminal_key_' || v_outbox_id::text;
     v_constraint TEXT;
   BEGIN
     INSERT INTO public.payment_outbox_attempts(
       outbox_id, instruction_id, participant_id, sequence_id,
       idempotency_key, rail_type, payload, attempt_no, state
     ) VALUES (
       v_outbox_id, v_instruction_id, v_participant_id, 1,
       v_idempotency_key, 'TEST', '{}'::jsonb, 1, 'DISPATCHED'
     );

     BEGIN
       INSERT INTO public.payment_outbox_attempts(
         outbox_id, instruction_id, participant_id, sequence_id,
         idempotency_key, rail_type, payload, attempt_no, state
       ) VALUES (
         v_outbox_id, v_instruction_id, v_participant_id, 2,
         v_idempotency_key, 'TEST', '{}'::jsonb, 2, 'FAILED'
       );
       RETURN 'FAIL';
     EXCEPTION WHEN unique_violation THEN
       GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
       IF v_constraint = 'ux_outbox_attempts_one_terminal_per_outbox' THEN
         RETURN 'PASS';
       END IF;
       RETURN 'FAIL';
     END;
   END;
   \$\$;
   SELECT pg_temp._test_terminal_uniqueness();"

# ============================================================
# Test 9: NOTIFY emitted on enqueue (wakeup-only)
# ============================================================
notify_output="$(
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<'SQL'
LISTEN symphony_outbox;
SELECT (enqueue_payment_outbox(
  'test_notify_' || public.uuid_v7_or_random()::text,
  'test_notify_participant',
  'test_notify_key_' || public.uuid_v7_or_random()::text,
  'TEST',
  '{}'::jsonb
)).outbox_id;
SELECT pg_sleep(0.2);
UNLISTEN *;
SQL
)"
if echo "$notify_output" | grep -q "Asynchronous notification \"symphony_outbox\""; then
  echo "  outbox notify emitted: ✅ PASS"
  PASS=$((PASS+1))
  notify_result="PASS"
else
  echo "  outbox notify emitted: ❌ FAIL"
  FAIL=$((FAIL+1))
  notify_result="FAIL"
fi


# ============================================================
# Test 10: No PUBLIC privileges on core tables
# ============================================================
run_test "no PUBLIC privileges on payment_outbox_pending" \
  "SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM information_schema.role_table_grants WHERE grantee = 'PUBLIC' AND table_schema = 'public' AND table_name = 'payment_outbox_pending') THEN 'PASS' ELSE 'FAIL' END;"

# ============================================================
# Summary
# ============================================================
echo ""
echo "Summary: $PASS passed, $FAIL failed"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/outbox_terminal_uniqueness.json"
NOTIFY_EVIDENCE_FILE="$EVIDENCE_DIR/outbox_notify.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "DB-OUTBOX-TERMINAL-UNIQUENESS",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status": "PASS" if "$terminal_uniqueness_result" == "PASS" else "FAIL",
  "terminal_uniqueness_result": "$terminal_uniqueness_result",
  "tests_passed": $PASS,
  "tests_failed": $FAIL,
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "DB-OUTBOX-NOTIFY",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status": "PASS" if "$notify_result" == "PASS" else "FAIL",
  "notify_result": "$notify_result",
  "tests_passed": $PASS,
  "tests_failed": $FAIL,
}
Path("$NOTIFY_EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

if [[ $FAIL -gt 0 ]]; then
  echo "exit code 1"
  exit 1
fi

echo "exit code 0"
