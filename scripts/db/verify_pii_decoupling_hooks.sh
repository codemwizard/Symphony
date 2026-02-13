#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/pii_decoupling_invariant.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

failures=()
checks=()

check_bool() {
  local name="$1"
  local sql="$2"
  local val
  val="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "$sql" || echo "")"
  checks+=("$name=$val")
  if [[ "$val" != "t" ]]; then
    failures+=("$name")
  fi
}

check_bool "table_pii_vault_records" "SELECT to_regclass('public.pii_vault_records') IS NOT NULL;"
check_bool "table_pii_purge_requests" "SELECT to_regclass('public.pii_purge_requests') IS NOT NULL;"
check_bool "table_pii_purge_events" "SELECT to_regclass('public.pii_purge_events') IS NOT NULL;"
check_bool "constraint_pii_vault_purge_shape" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='pii_vault_records_purge_shape_chk' AND conrelid='public.pii_vault_records'::regclass);"
check_bool "constraint_pii_vault_purge_request_fk" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='pii_vault_records_purge_request_fk' AND conrelid='public.pii_vault_records'::regclass);"
check_bool "trigger_deny_pii_vault_mutation" "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_deny_pii_vault_mutation');"
check_bool "trigger_deny_pii_purge_requests_mutation" "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_deny_pii_purge_requests_mutation');"
check_bool "trigger_deny_pii_purge_events_mutation" "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_deny_pii_purge_events_mutation');"
check_bool "function_request_pii_purge" "SELECT to_regprocedure('public.request_pii_purge(text,text,text)') IS NOT NULL;"
check_bool "function_execute_pii_purge" "SELECT to_regprocedure('public.execute_pii_purge(uuid,text)') IS NOT NULL;"
check_bool "public_no_privs_pii_vault_records" "SELECT NOT (has_table_privilege('public','public.pii_vault_records','SELECT') OR has_table_privilege('public','public.pii_vault_records','INSERT') OR has_table_privilege('public','public.pii_vault_records','UPDATE') OR has_table_privilege('public','public.pii_vault_records','DELETE') OR has_table_privilege('public','public.pii_vault_records','TRUNCATE') OR has_table_privilege('public','public.pii_vault_records','REFERENCES') OR has_table_privilege('public','public.pii_vault_records','TRIGGER'));"
check_bool "public_no_privs_pii_purge_requests" "SELECT NOT (has_table_privilege('public','public.pii_purge_requests','SELECT') OR has_table_privilege('public','public.pii_purge_requests','INSERT') OR has_table_privilege('public','public.pii_purge_requests','UPDATE') OR has_table_privilege('public','public.pii_purge_requests','DELETE') OR has_table_privilege('public','public.pii_purge_requests','TRUNCATE') OR has_table_privilege('public','public.pii_purge_requests','REFERENCES') OR has_table_privilege('public','public.pii_purge_requests','TRIGGER'));"
check_bool "public_no_privs_pii_purge_events" "SELECT NOT (has_table_privilege('public','public.pii_purge_events','SELECT') OR has_table_privilege('public','public.pii_purge_events','INSERT') OR has_table_privilege('public','public.pii_purge_events','UPDATE') OR has_table_privilege('public','public.pii_purge_events','DELETE') OR has_table_privilege('public','public.pii_purge_events','TRUNCATE') OR has_table_privilege('public','public.pii_purge_events','REFERENCES') OR has_table_privilege('public','public.pii_purge_events','TRIGGER'));"

status="PASS"
if [[ ${#failures[@]} -gt 0 ]]; then
  status="FAIL"
fi

CHECKS_JOINED="$(printf '%s\n' "${checks[@]}")"
FAILURES_JOINED="$(printf '%s\n' "${failures[@]}")"

CHECKS_JOINED="$CHECKS_JOINED" FAILURES_JOINED="$FAILURES_JOINED" python3 - <<PY
import json
import os
from pathlib import Path

checks = [c for c in os.environ.get("CHECKS_JOINED", "").split("\n") if c]
failures = [c for c in os.environ.get("FAILURES_JOINED", "").split("\n") if c]

out = {
  "schema_version": "1.0",
  "check_id": "DB-PII-DECOUPLING-HOOKS",
  "gate_id": "INT-G26",
  "invariant_id": "INV-115",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status": "${status}",
  "details": {
    "checks": checks,
    "failures": failures,
  },
}

Path("${EVIDENCE_FILE}").write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
PY

if [[ "$status" != "PASS" ]]; then
  echo "PII decoupling invariant verification failed." >&2
  exit 1
fi

echo "PII decoupling invariant verification OK. Evidence: $EVIDENCE_FILE"
