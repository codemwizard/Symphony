#!/usr/bin/env bash
# ============================================================
# test_outbox_lease_fencing.sh — Lease fencing tests
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

echo "==> Outbox lease fencing tests"

PASS=0
FAIL=0

run_test() {
  local name="$1"
  local sql="$2"
  echo -n "  $name: "
  if result=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -q -t -A -c "$sql" 2>&1); then
    if [[ "$result" == "PASS" ]]; then
      echo "✅ PASS"
      PASS=$((PASS+1))
    else
      echo "❌ FAIL (got: $result)"
      FAIL=$((FAIL+1))
    fi
  else
    echo "❌ ERROR: $result"
    FAIL=$((FAIL+1))
  fi
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/outbox_lease_fencing.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "DELETE FROM public.payment_outbox_pending;"

instruction_id="test_lease_fence_$(date +%s%N)"
participant_id="test_lease_fence_participant"
idempotency_key="test_lease_fence_key_$(date +%s%N)"

outbox_id="$(
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -t -A -c \
    "SELECT (enqueue_payment_outbox('$instruction_id','$participant_id','$idempotency_key','TEST','{}'::jsonb)).outbox_id;"
)"

# Claim with worker A for 2 seconds
claim_line="$(
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -t -A -c \
    "SELECT lease_token::text || '|' || lease_expires_at::text FROM claim_outbox_batch(1, 'worker_a', 2) WHERE outbox_id = '$outbox_id';"
)"
lease_token="${claim_line%%|*}"

sql_wrong_token="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._expect_lease_lost_wrong_token() RETURNS text
LANGUAGE plpgsql AS $fn$
BEGIN
  PERFORM * FROM complete_outbox_attempt('__OUTBOX_ID__'::uuid, '00000000-0000-0000-0000-000000000000'::uuid, 'worker_a', 'DISPATCHED');
  RETURN 'FAIL';
EXCEPTION WHEN SQLSTATE 'P7002' THEN
  RETURN 'PASS';
END;
$fn$;
SELECT pg_temp._expect_lease_lost_wrong_token();
SQL
)"
sql_wrong_token="${sql_wrong_token//__OUTBOX_ID__/$outbox_id}"
run_test "complete fails on wrong lease token" "$sql_wrong_token"

sql_wrong_worker="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._expect_lease_lost_wrong_worker() RETURNS text
LANGUAGE plpgsql AS $fn$
BEGIN
  PERFORM * FROM complete_outbox_attempt('__OUTBOX_ID__'::uuid, '__LEASE_TOKEN__'::uuid, 'other_worker', 'DISPATCHED');
  RETURN 'FAIL';
EXCEPTION WHEN SQLSTATE 'P7002' THEN
  RETURN 'PASS';
END;
$fn$;
SELECT pg_temp._expect_lease_lost_wrong_worker();
SQL
)"
sql_wrong_worker="${sql_wrong_worker//__OUTBOX_ID__/$outbox_id}"
sql_wrong_worker="${sql_wrong_worker//__LEASE_TOKEN__/$lease_token}"
run_test "complete fails on wrong worker" "$sql_wrong_worker"

# Sleep until lease expires, then completion must fail with LEASE_LOST.
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "SELECT pg_sleep(3);"

sql_expired="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._expect_lease_lost_expired() RETURNS text
LANGUAGE plpgsql AS $fn$
BEGIN
  PERFORM * FROM complete_outbox_attempt('__OUTBOX_ID__'::uuid, '__LEASE_TOKEN__'::uuid, 'worker_a', 'DISPATCHED');
  RETURN 'FAIL';
EXCEPTION WHEN SQLSTATE 'P7002' THEN
  RETURN 'PASS';
END;
$fn$;
SELECT pg_temp._expect_lease_lost_expired();
SQL
)"
sql_expired="${sql_expired//__OUTBOX_ID__/$outbox_id}"
sql_expired="${sql_expired//__LEASE_TOKEN__/$lease_token}"
run_test "complete fails on expired lease" "$sql_expired"

echo ""
echo "Summary: $PASS passed, $FAIL failed"

status="PASS"
if [[ $FAIL -gt 0 ]]; then
  status="FAIL"
fi

python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "DB-OUTBOX-LEASE-FENCING",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status": "${status}",
  "tests_passed": $PASS,
  "tests_failed": $FAIL,
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2) + "\n")
PY

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
