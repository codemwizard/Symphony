#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

echo "==> Anchor-sync operational runtime tests"

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
EVIDENCE_FILE="$EVIDENCE_DIR/anchor_sync_resume_semantics.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

completion_gate_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._anchor_completion_gate() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_pack UUID;
  v_op UUID;
  v_claim RECORD;
BEGIN
  INSERT INTO public.evidence_packs(pack_type, root_hash)
  VALUES ('INSTRUCTION_BUNDLE', encode(gen_random_bytes(16), 'hex'))
  RETURNING pack_id INTO v_pack;

  SELECT public.ensure_anchor_sync_operation(v_pack, 'SIM') INTO v_op;
  SELECT * INTO v_claim FROM public.claim_anchor_sync_operation('anchor_worker_a', 30);
  IF v_claim.operation_id IS DISTINCT FROM v_op THEN
    RETURN 'FAIL';
  END IF;

  BEGIN
    PERFORM public.complete_anchor_sync_operation(v_op, v_claim.lease_token, 'anchor_worker_a');
    RETURN 'FAIL';
  EXCEPTION WHEN SQLSTATE 'P7211' THEN
    RETURN 'PASS';
  END;
END;
$fn$;

SELECT pg_temp._anchor_completion_gate();
SQL
)"
run_test "completion_without_anchor_is_blocked" "$completion_gate_sql"

anchored_complete_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._anchor_then_complete() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_pack UUID;
  v_op UUID;
  v_claim RECORD;
  v_state TEXT;
BEGIN
  INSERT INTO public.evidence_packs(pack_type, root_hash)
  VALUES ('INSTRUCTION_BUNDLE', encode(gen_random_bytes(16), 'hex'))
  RETURNING pack_id INTO v_pack;

  SELECT public.ensure_anchor_sync_operation(v_pack, 'SIM') INTO v_op;
  SELECT * INTO v_claim FROM public.claim_anchor_sync_operation('anchor_worker_b', 30);
  IF v_claim.operation_id IS DISTINCT FROM v_op THEN
    RETURN 'FAIL';
  END IF;

  PERFORM public.mark_anchor_sync_anchored(v_op, v_claim.lease_token, 'anchor_worker_b', 'anchor-ref-1', 'HYBRID_SYNC');
  PERFORM public.complete_anchor_sync_operation(v_op, v_claim.lease_token, 'anchor_worker_b');

  SELECT state INTO v_state FROM public.anchor_sync_operations WHERE operation_id = v_op;
  IF v_state <> 'COMPLETED' THEN
    RETURN 'FAIL';
  END IF;

  RETURN 'PASS';
END;
$fn$;

SELECT pg_temp._anchor_then_complete();
SQL
)"
run_test "anchored_path_completes" "$anchored_complete_sql"

resume_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._resume_after_expiry() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_pack UUID;
  v_op UUID;
  v_claim RECORD;
  v_reclaimed RECORD;
  v_repaired INTEGER;
BEGIN
  INSERT INTO public.evidence_packs(pack_type, root_hash)
  VALUES ('INSTRUCTION_BUNDLE', encode(gen_random_bytes(16), 'hex'))
  RETURNING pack_id INTO v_pack;

  SELECT public.ensure_anchor_sync_operation(v_pack, 'SIM') INTO v_op;
  SELECT * INTO v_claim FROM public.claim_anchor_sync_operation('anchor_worker_c', 1);

  IF v_claim.operation_id IS NULL OR v_claim.operation_id IS DISTINCT FROM v_op THEN
    RETURN 'FAIL';
  END IF;

  PERFORM pg_sleep(2);
  SELECT public.repair_expired_anchor_sync_leases('anchor_repair') INTO v_repaired;

  IF v_repaired < 1 THEN
    RETURN 'FAIL';
  END IF;

  SELECT * INTO v_reclaimed FROM public.claim_anchor_sync_operation('anchor_worker_c_resume', 30);
  IF v_reclaimed.operation_id IS DISTINCT FROM v_op THEN
    RETURN 'FAIL';
  END IF;

  RETURN 'PASS';
END;
$fn$;

SELECT pg_temp._resume_after_expiry();
SQL
)"
run_test "resume_after_crash_is_deterministic" "$resume_sql"

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
  "check_id": "DB-ANCHOR-SYNC-RESUME-SEMANTICS",
  "gate_id": "INT-G29",
  "invariant_id": "INV-113",
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
