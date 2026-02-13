#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

echo "==> Instruction finality runtime tests"

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
EVIDENCE_FILE="$EVIDENCE_DIR/instruction_finality_runtime.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

seed_sql="$(cat <<'SQL'
DO $$
DECLARE
  v_settled TEXT := 'if_settled_' || replace(gen_random_uuid()::text, '-', '');
  v_reversal TEXT := 'if_reversal_' || replace(gen_random_uuid()::text, '-', '');
BEGIN
  INSERT INTO public.instruction_settlement_finality(
    instruction_id,
    participant_id,
    final_state,
    rail_message_type,
    finalized_at
  ) VALUES (
    v_settled,
    'participant_finality_test',
    'SETTLED',
    'pacs.008',
    NOW()
  );

  INSERT INTO public.instruction_settlement_finality(
    instruction_id,
    participant_id,
    final_state,
    rail_message_type,
    reversal_of_instruction_id,
    finalized_at
  ) VALUES (
    v_reversal,
    'participant_finality_test',
    'REVERSED',
    'camt.056',
    v_settled,
    NOW()
  );
END $$;

SELECT 'PASS';
SQL
)"
run_test "insert settled + reversal records succeeds" "$seed_sql"

update_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._expect_update_denied() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_target TEXT;
BEGIN
  SELECT instruction_id
  INTO v_target
  FROM public.instruction_settlement_finality
  WHERE final_state = 'SETTLED'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_target IS NULL THEN
    RETURN 'FAIL';
  END IF;

  BEGIN
    UPDATE public.instruction_settlement_finality
    SET metadata = jsonb_build_object('updated', true)
    WHERE instruction_id = v_target;
    RETURN 'FAIL';
  EXCEPTION WHEN SQLSTATE 'P7003' THEN
    RETURN 'PASS';
  END;
END;
$fn$;
SELECT pg_temp._expect_update_denied();
SQL
)"
run_test "update on final instruction is blocked" "$update_sql"

delete_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._expect_delete_denied() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_target TEXT;
BEGIN
  SELECT instruction_id
  INTO v_target
  FROM public.instruction_settlement_finality
  WHERE final_state = 'SETTLED'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_target IS NULL THEN
    RETURN 'FAIL';
  END IF;

  BEGIN
    DELETE FROM public.instruction_settlement_finality
    WHERE instruction_id = v_target;
    RETURN 'FAIL';
  EXCEPTION WHEN SQLSTATE 'P7003' THEN
    RETURN 'PASS';
  END;
END;
$fn$;
SELECT pg_temp._expect_delete_denied();
SQL
)"
run_test "delete on final instruction is blocked" "$delete_sql"

invalid_source_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._expect_invalid_reversal_source_denied() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_source TEXT;
  v_bad_rev TEXT := 'if_bad_rev_' || replace(gen_random_uuid()::text, '-', '');
BEGIN
  SELECT instruction_id
  INTO v_source
  FROM public.instruction_settlement_finality
  WHERE final_state = 'REVERSED'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_source IS NULL THEN
    RETURN 'FAIL';
  END IF;

  BEGIN
    INSERT INTO public.instruction_settlement_finality(
      instruction_id,
      participant_id,
      final_state,
      rail_message_type,
      reversal_of_instruction_id,
      finalized_at
    ) VALUES (
      v_bad_rev,
      'participant_finality_test',
      'REVERSED',
      'camt.056',
      v_source,
      NOW()
    );
    RETURN 'FAIL';
  EXCEPTION WHEN SQLSTATE 'P7003' THEN
    RETURN 'PASS';
  END;
END;
$fn$;
SELECT pg_temp._expect_invalid_reversal_source_denied();
SQL
)"
run_test "reversal requires SETTLED source" "$invalid_source_sql"

duplicate_reversal_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._expect_duplicate_reversal_denied() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_source TEXT;
  v_dup_rev TEXT := 'if_dup_rev_' || replace(gen_random_uuid()::text, '-', '');
BEGIN
  SELECT reversal_of_instruction_id
  INTO v_source
  FROM public.instruction_settlement_finality
  WHERE final_state = 'REVERSED'
    AND reversal_of_instruction_id IS NOT NULL
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_source IS NULL THEN
    RETURN 'FAIL';
  END IF;

  BEGIN
    INSERT INTO public.instruction_settlement_finality(
      instruction_id,
      participant_id,
      final_state,
      rail_message_type,
      reversal_of_instruction_id,
      finalized_at
    ) VALUES (
      v_dup_rev,
      'participant_finality_test',
      'REVERSED',
      'camt.056',
      v_source,
      NOW()
    );
    RETURN 'FAIL';
  EXCEPTION WHEN unique_violation THEN
    RETURN 'PASS';
  END;
END;
$fn$;
SELECT pg_temp._expect_duplicate_reversal_denied();
SQL
)"
run_test "only one reversal per settled instruction" "$duplicate_reversal_sql"

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
  "check_id": "DB-INSTRUCTION-FINALITY-RUNTIME",
  "gate_id": "INT-G25",
  "invariant_id": "INV-114",
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
