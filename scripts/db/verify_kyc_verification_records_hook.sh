#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/TSK-P0-KYC-002.json"
MIGRATION_VERSION="0042_kyc_verification_records_hook.sql"
MIGRATION_FILE="$ROOT_DIR/schema/migrations/$MIGRATION_VERSION"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

failures=()
runtime_reference_paths=()
add_failure() { failures+=("$1"); }

query_bool() {
  local sql="$1"
  local val
  val="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "$sql" | tr -d '[:space:]')"
  [[ "$val" == "t" ]] && echo "true" || echo "false"
}

migration_framework_ready="$(query_bool "SELECT to_regclass('public.schema_migrations') IS NOT NULL;")"
if [[ "$migration_framework_ready" != "true" ]]; then
  add_failure "PREREQ MISSING: migration framework not initialised"
fi

tenant_members_exists="$(query_bool "SELECT to_regclass('public.tenant_members') IS NOT NULL;")"
if [[ "$tenant_members_exists" != "true" ]]; then
  add_failure "PREREQ MISSING: tenant_members table not found"
fi

provider_registry_exists="$(query_bool "SELECT to_regclass('public.kyc_provider_registry') IS NOT NULL;")"
if [[ "$provider_registry_exists" != "true" ]]; then
  add_failure "PREREQ MISSING: TSK-P0-KYC-001 must complete before TSK-P0-KYC-002"
fi

table_exists="$(query_bool "SELECT to_regclass('public.kyc_verification_records') IS NOT NULL;")"
pk_verified="false"
fk_members_verified="false"
fk_provider_verified="false"
retention_class_constraint_verified="false"
hash_columns_nullable="false"
outcome_columns_unconstrained="false"
indexes_verified="false"
table_is_empty="false"
no_runtime_references="true"
no_triggers_or_functions="false"
migration_checksum_valid="false"

if [[ "$table_exists" != "true" ]]; then
  add_failure "table_missing:public.kyc_verification_records"
fi

if [[ "$table_exists" == "true" ]]; then
  required_columns_ok="$(query_bool "
WITH cols AS (
  SELECT column_name, udt_name, is_nullable, column_default
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='kyc_verification_records'
), ok AS (
  SELECT
    EXISTS (SELECT 1 FROM cols WHERE column_name='id' AND udt_name='uuid' AND is_nullable='NO') AS c1,
    EXISTS (SELECT 1 FROM cols WHERE column_name='member_id' AND udt_name='uuid' AND is_nullable='NO') AS c2,
    EXISTS (SELECT 1 FROM cols WHERE column_name='provider_id' AND udt_name='uuid' AND is_nullable='YES') AS c3,
    EXISTS (SELECT 1 FROM cols WHERE column_name='provider_code' AND udt_name='text') AS c4,
    EXISTS (SELECT 1 FROM cols WHERE column_name='outcome' AND udt_name='text') AS c5,
    EXISTS (SELECT 1 FROM cols WHERE column_name='verification_method' AND udt_name='text') AS c6,
    EXISTS (SELECT 1 FROM cols WHERE column_name='verification_hash' AND udt_name='text' AND is_nullable='YES') AS c7,
    EXISTS (SELECT 1 FROM cols WHERE column_name='hash_algorithm' AND udt_name='text' AND is_nullable='YES') AS c8,
    EXISTS (SELECT 1 FROM cols WHERE column_name='provider_signature' AND udt_name='text' AND is_nullable='YES') AS c9,
    EXISTS (SELECT 1 FROM cols WHERE column_name='provider_key_version' AND udt_name='text' AND is_nullable='YES') AS c10,
    EXISTS (SELECT 1 FROM cols WHERE column_name='provider_reference' AND udt_name='text' AND is_nullable='YES') AS c11,
    EXISTS (SELECT 1 FROM cols WHERE column_name='jurisdiction_code' AND udt_name='bpchar') AS c12,
    EXISTS (SELECT 1 FROM cols WHERE column_name='document_type' AND udt_name='text') AS c13,
    EXISTS (SELECT 1 FROM cols WHERE column_name='verified_at_provider' AND udt_name='timestamptz' AND is_nullable='YES') AS c14,
    EXISTS (SELECT 1 FROM cols WHERE column_name='anchored_at' AND udt_name='timestamptz' AND is_nullable='NO'
            AND lower(COALESCE(column_default, '')) LIKE '%now()%') AS c15,
    EXISTS (SELECT 1 FROM cols WHERE column_name='retention_class' AND udt_name='text' AND is_nullable='NO'
            AND lower(COALESCE(column_default, '')) LIKE '%fic_aml_customer_id%') AS c16,
    EXISTS (SELECT 1 FROM cols WHERE column_name='created_at' AND udt_name='timestamptz' AND is_nullable='NO') AS c17,
    EXISTS (SELECT 1 FROM cols WHERE column_name='created_by' AND udt_name='text' AND is_nullable='NO') AS c18,
    (SELECT COUNT(*) FROM cols) = 18 AS ccount
)
SELECT c1 AND c2 AND c3 AND c4 AND c5 AND c6 AND c7 AND c8 AND c9 AND c10 AND c11 AND c12 AND c13 AND c14 AND c15 AND c16 AND c17 AND c18 AND ccount
FROM ok;
")"
  [[ "$required_columns_ok" == "true" ]] || add_failure "column_spec_mismatch"

  pk_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='kyc_verification_records'
    AND c.contype='p'
    AND pg_get_constraintdef(c.oid) ILIKE '%(id)%'
);
")"
  [[ "$pk_verified" == "true" ]] || add_failure "primary_key_missing_or_invalid"

  fk_members_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='kyc_verification_records' AND c.contype='f'
    AND pg_get_constraintdef(c.oid) ILIKE '%(member_id)%REFERENCES tenant_members(member_id)%ON DELETE RESTRICT%'
);
")"
  [[ "$fk_members_verified" == "true" ]] || add_failure "fk_member_id_missing_or_invalid"

  fk_provider_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='kyc_verification_records' AND c.contype='f'
    AND pg_get_constraintdef(c.oid) ILIKE '%(provider_id)%REFERENCES kyc_provider_registry(id)%ON DELETE RESTRICT%'
);
")"
  [[ "$fk_provider_verified" == "true" ]] || add_failure "fk_provider_id_missing_or_invalid"

  retention_class_constraint_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='kyc_verification_records'
    AND c.contype='c'
    AND pg_get_constraintdef(c.oid) ILIKE '%retention_class%'
    AND pg_get_constraintdef(c.oid) ILIKE '%FIC_AML_CUSTOMER_ID%'
);
")"
  [[ "$retention_class_constraint_verified" == "true" ]] || add_failure "retention_class_constraint_missing_or_invalid"

  hash_columns_nullable="$(query_bool "
WITH cols AS (
  SELECT column_name, is_nullable
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='kyc_verification_records'
)
SELECT
  EXISTS (SELECT 1 FROM cols WHERE column_name='verification_hash' AND is_nullable='YES')
  AND EXISTS (SELECT 1 FROM cols WHERE column_name='hash_algorithm' AND is_nullable='YES')
  AND EXISTS (SELECT 1 FROM cols WHERE column_name='provider_signature' AND is_nullable='YES')
  AND EXISTS (SELECT 1 FROM cols WHERE column_name='provider_key_version' AND is_nullable='YES')
  AND EXISTS (SELECT 1 FROM cols WHERE column_name='provider_reference' AND is_nullable='YES');
")"
  [[ "$hash_columns_nullable" == "true" ]] || add_failure "hash_columns_nullability_mismatch"

  outcome_columns_unconstrained="$(query_bool "
SELECT NOT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='kyc_verification_records'
    AND c.contype='c'
    AND (
      pg_get_constraintdef(c.oid) ILIKE '%outcome%'
      OR pg_get_constraintdef(c.oid) ILIKE '%verification_method%'
      OR pg_get_constraintdef(c.oid) ILIKE '%document_type%'
    )
);
")"
  [[ "$outcome_columns_unconstrained" == "true" ]] || add_failure "phase_scope_violation_outcome_or_method_constrained"

  indexes_verified="$(query_bool "
SELECT
  EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname='public' AND tablename='kyc_verification_records'
      AND indexname='kyc_verification_member_idx'
  )
  AND EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname='public' AND tablename='kyc_verification_records'
      AND indexname='kyc_verification_provider_idx'
      AND indexdef ILIKE '%WHERE (provider_id IS NOT NULL)%'
  )
  AND EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname='public' AND tablename='kyc_verification_records'
      AND indexname='kyc_verification_jurisdiction_outcome_idx'
      AND indexdef ILIKE '%WHERE (outcome IS NOT NULL)%'
  );
")"
  [[ "$indexes_verified" == "true" ]] || add_failure "required_indexes_missing_or_invalid"

  table_is_empty="$(query_bool "SELECT COUNT(*)=0 FROM public.kyc_verification_records;")"
  [[ "$table_is_empty" == "true" ]] || add_failure "phase_violation_table_not_empty"

  table_comment_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_description d
  JOIN pg_class c ON c.oid=d.objoid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='public' AND c.relname='kyc_verification_records'
    AND d.objsubid=0
    AND d.description LIKE '%Phase-0 structural hook%'
);
")"
  [[ "$table_comment_ok" == "true" ]] || add_failure "table_comment_missing_required_phrase"

  trigger_count="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "
SELECT COUNT(*)
FROM pg_trigger tg
JOIN pg_class t ON t.oid=tg.tgrelid
JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname='public'
  AND t.relname='kyc_verification_records'
  AND NOT tg.tgisinternal;
" | tr -d '[:space:]')"

  function_write_count="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "
SELECT COUNT(*)
FROM pg_proc p
JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname NOT IN ('pg_catalog','information_schema')
  AND p.prokind = 'f'
  AND (
    pg_get_functiondef(p.oid) ILIKE '%insert into public.kyc_verification_records%'
    OR pg_get_functiondef(p.oid) ILIKE '%update public.kyc_verification_records%'
    OR pg_get_functiondef(p.oid) ILIKE '%delete from public.kyc_verification_records%'
    OR pg_get_functiondef(p.oid) ILIKE '%insert into kyc_verification_records%'
    OR pg_get_functiondef(p.oid) ILIKE '%update kyc_verification_records%'
    OR pg_get_functiondef(p.oid) ILIKE '%delete from kyc_verification_records%'
  );
" | tr -d '[:space:]')"

  if [[ "${trigger_count:-0}" == "0" && "${function_write_count:-0}" == "0" ]]; then
    no_triggers_or_functions="true"
  else
    no_triggers_or_functions="false"
    [[ "${trigger_count:-0}" == "0" ]] || add_failure "triggers_found_on_kyc_verification_records"
    [[ "${function_write_count:-0}" == "0" ]] || add_failure "function_writes_found_for_kyc_verification_records"
  fi

  pii_column_count="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "
SELECT COUNT(*)
FROM information_schema.columns
WHERE table_schema='public'
  AND table_name='kyc_verification_records'
  AND (
    column_name ~* '(nrc|passport|full_?name|date_?of_?birth|dob|photo|address|phone)'
  );
" | tr -d '[:space:]')"
  if [[ "${pii_column_count:-0}" != "0" ]]; then
    add_failure "ARCHITECTURE VIOLATION: PII columns must not appear in kyc_verification_records"
  fi
fi

runtime_scan_output="$(
  rg -n --glob '*.cs' --glob '*.ts' --glob '*.js' --glob '*.tsx' --glob '*.py' --glob '*.go' \
    "\\bkyc_verification_records\\b" \
    "$ROOT_DIR/services" "$ROOT_DIR/src" "$ROOT_DIR/packages" 2>/dev/null \
    | cut -d: -f1 | sort -u || true
)"
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  runtime_reference_paths+=("$path")
done <<< "$runtime_scan_output"
if [[ ${#runtime_reference_paths[@]} -gt 0 ]]; then
  no_runtime_references="false"
  add_failure "runtime_references_found"
fi

if [[ ! -f "$MIGRATION_FILE" ]]; then
  add_failure "migration_file_missing:$MIGRATION_VERSION"
else
  expected_checksum="$(sha256sum "$MIGRATION_FILE" | awk '{print $1}')"
  if [[ "$migration_framework_ready" == "true" ]]; then
    applied_checksum="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "SELECT checksum FROM public.schema_migrations WHERE version='$MIGRATION_VERSION'" | tr -d '[:space:]')"
    if [[ -z "$applied_checksum" ]]; then
      add_failure "migration_checksum_missing_in_registry:$MIGRATION_VERSION"
    elif [[ "$applied_checksum" != "$expected_checksum" ]]; then
      add_failure "migration_checksum_mismatch:$MIGRATION_VERSION:expected=$expected_checksum:actual=$applied_checksum"
    else
      migration_checksum_valid="true"
    fi
  fi
fi

status="PASS"
pass_bool="true"
if [[ ${#failures[@]} -gt 0 ]]; then
  status="FAIL"
  pass_bool="false"
fi

RUNTIME_REFS="$(printf '%s\n' "${runtime_reference_paths[@]:-}")"
FAILURES="$(printf '%s\n' "${failures[@]:-}")"

EVIDENCE_FILE="$EVIDENCE_FILE" PASS_BOOL="$pass_bool" STATUS="$status" TABLE_EXISTS="$table_exists" \
PK_VERIFIED="$pk_verified" FK_MEMBERS_VERIFIED="$fk_members_verified" FK_PROVIDER_VERIFIED="$fk_provider_verified" \
RETENTION_CLASS_CONSTRAINT_VERIFIED="$retention_class_constraint_verified" HASH_COLUMNS_NULLABLE="$hash_columns_nullable" \
OUTCOME_COLUMNS_UNCONSTRAINED="$outcome_columns_unconstrained" INDEXES_VERIFIED="$indexes_verified" \
TABLE_IS_EMPTY="$table_is_empty" NO_RUNTIME_REFERENCES="$no_runtime_references" \
NO_TRIGGERS_OR_FUNCTIONS="$no_triggers_or_functions" MIGRATION_CHECKSUM_VALID="$migration_checksum_valid" \
RUNTIME_REFS="$RUNTIME_REFS" FAILURES="$FAILURES" \
python3 - <<'PY'
import json
import os
from pathlib import Path

def to_bool(v: str) -> bool:
    return str(v).lower() == "true"

out = {
    "task_id": "TSK-P0-KYC-002",
    "check_id": "TSK-P0-KYC-002",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": os.environ.get("STATUS", "FAIL"),
    "pass": to_bool(os.environ.get("PASS_BOOL", "false")),
    "table_exists": to_bool(os.environ.get("TABLE_EXISTS", "false")),
    "pk_verified": to_bool(os.environ.get("PK_VERIFIED", "false")),
    "fk_members_verified": to_bool(os.environ.get("FK_MEMBERS_VERIFIED", "false")),
    "fk_provider_verified": to_bool(os.environ.get("FK_PROVIDER_VERIFIED", "false")),
    "retention_class_constraint_verified": to_bool(os.environ.get("RETENTION_CLASS_CONSTRAINT_VERIFIED", "false")),
    "hash_columns_nullable": to_bool(os.environ.get("HASH_COLUMNS_NULLABLE", "false")),
    "outcome_columns_unconstrained": to_bool(os.environ.get("OUTCOME_COLUMNS_UNCONSTRAINED", "false")),
    "indexes_verified": to_bool(os.environ.get("INDEXES_VERIFIED", "false")),
    "table_is_empty": to_bool(os.environ.get("TABLE_IS_EMPTY", "false")),
    "no_runtime_references": to_bool(os.environ.get("NO_RUNTIME_REFERENCES", "false")),
    "no_triggers_or_functions": to_bool(os.environ.get("NO_TRIGGERS_OR_FUNCTIONS", "false")),
    "migration_checksum_valid": to_bool(os.environ.get("MIGRATION_CHECKSUM_VALID", "false")),
    "measurement_truth": "phase0_structural_hook_only",
    "details": {
        "runtime_reference_paths": [p for p in os.environ.get("RUNTIME_REFS", "").split("\n") if p],
        "failures": [f for f in os.environ.get("FAILURES", "").split("\n") if f],
    },
}
Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
PY

if [[ "$status" != "PASS" ]]; then
  echo "kyc_verification_records hook verification failed" >&2
  for f in "${failures[@]}"; do
    echo " - $f" >&2
  done
  exit 1
fi

echo "kyc_verification_records hook verification OK. Evidence: $EVIDENCE_FILE"
