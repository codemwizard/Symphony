#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

echo "==> Rail sequence continuity runtime tests"

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
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/rail_sequence_runtime.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

setup_sql="$(cat <<'SQL'
DELETE FROM public.payment_outbox_pending;
SELECT 'PASS';
SQL
)"
run_test "setup pending queue" "$setup_sql"

anchor_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._dispatch_with_anchor() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_instruction TEXT := 'rail_ok_' || replace(gen_random_uuid()::text, '-', '');
  v_participant TEXT := 'rail_participant_main';
  v_idempotency TEXT := 'rail_key_' || replace(gen_random_uuid()::text, '-', '');
  v_outbox UUID;
  v_lease UUID;
  v_seq TEXT := 'nfs_seq_' || replace(gen_random_uuid()::text, '-', '');
BEGIN
  SELECT outbox_id INTO v_outbox
  FROM public.enqueue_payment_outbox(v_instruction, v_participant, v_idempotency, 'ZM-NFS', '{}'::jsonb)
  LIMIT 1;

  SELECT lease_token INTO v_lease
  FROM public.claim_outbox_batch(1, 'rail_worker_ok', 30)
  WHERE outbox_id = v_outbox;

  IF v_lease IS NULL THEN
    RETURN 'FAIL';
  END IF;

  PERFORM *
  FROM public.complete_outbox_attempt(v_outbox, v_lease, 'rail_worker_ok', 'DISPATCHED', v_seq, 'OK', NULL, NULL, 20, 1);

  IF NOT EXISTS (
    SELECT 1
    FROM public.rail_dispatch_truth_anchor
    WHERE outbox_id = v_outbox
      AND rail_sequence_ref = v_seq
      AND rail_participant_id = v_participant
      AND state = 'DISPATCHED'
  ) THEN
    RETURN 'FAIL';
  END IF;

  RETURN 'PASS';
END;
$fn$;

SELECT pg_temp._dispatch_with_anchor();
SQL
)"
run_test "dispatch success creates truth anchor" "$anchor_sql"

missing_seq_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._reject_missing_sequence() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_instruction TEXT := 'rail_missing_' || replace(gen_random_uuid()::text, '-', '');
  v_participant TEXT := 'rail_participant_main';
  v_idempotency TEXT := 'rail_key_' || replace(gen_random_uuid()::text, '-', '');
  v_outbox UUID;
  v_lease UUID;
BEGIN
  SELECT outbox_id INTO v_outbox
  FROM public.enqueue_payment_outbox(v_instruction, v_participant, v_idempotency, 'ZM-NFS', '{}'::jsonb)
  LIMIT 1;

  SELECT lease_token INTO v_lease
  FROM public.claim_outbox_batch(1, 'rail_worker_missing', 30)
  WHERE outbox_id = v_outbox;

  IF v_lease IS NULL THEN
    RETURN 'FAIL';
  END IF;

  BEGIN
    PERFORM *
    FROM public.complete_outbox_attempt(v_outbox, v_lease, 'rail_worker_missing', 'DISPATCHED', NULL, 'OK', NULL, NULL, 15, 1);
    RETURN 'FAIL';
  EXCEPTION WHEN SQLSTATE 'P7005' THEN
    RETURN 'PASS';
  END;
END;
$fn$;

SELECT pg_temp._reject_missing_sequence();
SQL
)"
run_test "dispatch without sequence reference is blocked" "$missing_seq_sql"

dupe_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._reject_duplicate_sequence_scope() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_existing_seq TEXT;
  v_instruction TEXT := 'rail_dupe_' || replace(gen_random_uuid()::text, '-', '');
  v_participant TEXT := 'rail_participant_main';
  v_idempotency TEXT := 'rail_key_' || replace(gen_random_uuid()::text, '-', '');
  v_outbox UUID;
  v_lease UUID;
BEGIN
  SELECT rail_sequence_ref INTO v_existing_seq
  FROM public.rail_dispatch_truth_anchor
  WHERE rail_participant_id = v_participant
  ORDER BY anchored_at DESC
  LIMIT 1;

  IF v_existing_seq IS NULL THEN
    RETURN 'FAIL';
  END IF;

  SELECT outbox_id INTO v_outbox
  FROM public.enqueue_payment_outbox(v_instruction, v_participant, v_idempotency, 'ZM-NFS', '{}'::jsonb)
  LIMIT 1;

  SELECT lease_token INTO v_lease
  FROM public.claim_outbox_batch(1, 'rail_worker_dupe', 30)
  WHERE outbox_id = v_outbox;

  IF v_lease IS NULL THEN
    RETURN 'FAIL';
  END IF;

  BEGIN
    PERFORM *
    FROM public.complete_outbox_attempt(v_outbox, v_lease, 'rail_worker_dupe', 'DISPATCHED', v_existing_seq, 'OK', NULL, NULL, 10, 1);
    RETURN 'FAIL';
  EXCEPTION WHEN unique_violation THEN
    RETURN 'PASS';
  END;
END;
$fn$;

SELECT pg_temp._reject_duplicate_sequence_scope();
SQL
)"
run_test "duplicate sequence within participant scope is blocked" "$dupe_sql"

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
  "schema_version": "1.0",
  "check_id": "DB-RAIL-SEQUENCE-RUNTIME",
  "gate_id": "INT-G27",
  "invariant_id": "INV-116",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status": "${status}",
  "tests_passed": ${PASS},
  "tests_failed": ${FAIL},
}
Path("${EVIDENCE_FILE}").write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
PY

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
