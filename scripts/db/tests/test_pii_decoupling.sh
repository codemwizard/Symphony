#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

echo "==> PII decoupling runtime tests"

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
EVIDENCE_FILE="$EVIDENCE_DIR/pii_decoupling_runtime.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

seed_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._seed_pii_decoupling() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_subject_token TEXT := 'subject_' || replace(gen_random_uuid()::text, '-', '');
  v_identity_hash TEXT := md5(v_subject_token || '_identity');
  v_pack_id UUID;
  v_request_id UUID;
  v_root_before TEXT;
  v_root_after TEXT;
  v_rows INTEGER;
  v_already BOOLEAN;
BEGIN
  INSERT INTO public.pii_vault_records(
    subject_token,
    identity_hash,
    protected_payload
  ) VALUES (
    v_subject_token,
    v_identity_hash,
    jsonb_build_object('blob', 'sealed')
  );

  INSERT INTO public.evidence_packs(
    pack_type,
    root_hash
  ) VALUES (
    'INSTRUCTION_BUNDLE',
    v_identity_hash
  )
  RETURNING pack_id, root_hash
  INTO v_pack_id, v_root_before;

  INSERT INTO public.evidence_pack_items(
    pack_id,
    artifact_hash
  ) VALUES (
    v_pack_id,
    md5(v_identity_hash || '_artifact')
  );

  SELECT public.request_pii_purge(
    v_subject_token,
    'pii_tester',
    'subject purge'
  ) INTO v_request_id;

  SELECT rows_affected, already_purged
  INTO v_rows, v_already
  FROM public.execute_pii_purge(v_request_id, 'pii_executor');

  IF v_rows <> 1 OR v_already IS DISTINCT FROM FALSE THEN
    RETURN 'FAIL';
  END IF;

  SELECT root_hash
  INTO v_root_after
  FROM public.evidence_packs
  WHERE pack_id = v_pack_id;

  IF v_root_after IS DISTINCT FROM v_root_before THEN
    RETURN 'FAIL';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.pii_vault_records
    WHERE subject_token = v_subject_token
      AND protected_payload IS NULL
      AND purged_at IS NOT NULL
      AND purge_request_id = v_request_id
      AND identity_hash = v_identity_hash
  ) THEN
    RETURN 'FAIL';
  END IF;

  RETURN 'PASS';
END;
$fn$;

SELECT pg_temp._seed_pii_decoupling();
SQL
)"
run_test "purge clears vault payload while preserving evidence root hash" "$seed_sql"

idempotent_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._purge_idempotent() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_request_id UUID;
  v_rows INTEGER;
  v_already BOOLEAN;
BEGIN
  SELECT purge_request_id
  INTO v_request_id
  FROM public.pii_purge_requests
  ORDER BY requested_at DESC
  LIMIT 1;

  IF v_request_id IS NULL THEN
    RETURN 'FAIL';
  END IF;

  SELECT rows_affected, already_purged
  INTO v_rows, v_already
  FROM public.execute_pii_purge(v_request_id, 'pii_executor_repeat');

  IF v_rows <> 1 OR v_already IS DISTINCT FROM TRUE THEN
    RETURN 'FAIL';
  END IF;

  RETURN 'PASS';
END;
$fn$;

SELECT pg_temp._purge_idempotent();
SQL
)"
run_test "purge executor is idempotent for same request" "$idempotent_sql"

direct_update_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._deny_direct_update() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_subject_token TEXT;
BEGIN
  SELECT subject_token
  INTO v_subject_token
  FROM public.pii_vault_records
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_subject_token IS NULL THEN
    RETURN 'FAIL';
  END IF;

  BEGIN
    UPDATE public.pii_vault_records
       SET protected_payload = jsonb_build_object('blob', 'mutated')
     WHERE subject_token = v_subject_token;
    RETURN 'FAIL';
  EXCEPTION WHEN SQLSTATE 'P7004' THEN
    RETURN 'PASS';
  END;
END;
$fn$;

SELECT pg_temp._deny_direct_update();
SQL
)"
run_test "direct vault update is blocked" "$direct_update_sql"

direct_delete_sql="$(cat <<'SQL'
CREATE OR REPLACE FUNCTION pg_temp._deny_direct_delete() RETURNS text
LANGUAGE plpgsql AS $fn$
DECLARE
  v_subject_token TEXT;
BEGIN
  SELECT subject_token
  INTO v_subject_token
  FROM public.pii_vault_records
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_subject_token IS NULL THEN
    RETURN 'FAIL';
  END IF;

  BEGIN
    DELETE FROM public.pii_vault_records
    WHERE subject_token = v_subject_token;
    RETURN 'FAIL';
  EXCEPTION WHEN SQLSTATE 'P7004' THEN
    RETURN 'PASS';
  END;
END;
$fn$;

SELECT pg_temp._deny_direct_delete();
SQL
)"
run_test "direct vault delete is blocked" "$direct_delete_sql"

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
  "check_id": "DB-PII-DECOUPLING-RUNTIME",
  "gate_id": "INT-G26",
  "invariant_id": "INV-115",
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
