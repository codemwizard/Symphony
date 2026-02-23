#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/TSK-P0-KYC-001.json"

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

table_exists="$(query_bool "SELECT to_regclass('public.kyc_provider_registry') IS NOT NULL;")"
column_count_verified="false"
constraints_verified="false"
indexes_verified="false"
table_is_empty="false"
no_runtime_references="true"
migration_checksum_valid="false"

if [[ "$table_exists" != "true" ]]; then
  add_failure "table_missing:public.kyc_provider_registry"
fi

if [[ "$table_exists" == "true" ]]; then
  column_count_verified="$(query_bool "
WITH cols AS (
  SELECT column_name, udt_name, is_nullable, column_default
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='kyc_provider_registry'
), ok AS (
  SELECT
    EXISTS (SELECT 1 FROM cols WHERE column_name='id' AND udt_name='uuid' AND is_nullable='NO') AS c1,
    EXISTS (SELECT 1 FROM cols WHERE column_name='provider_code' AND udt_name='text' AND is_nullable='NO') AS c2,
    EXISTS (SELECT 1 FROM cols WHERE column_name='provider_name' AND udt_name='text' AND is_nullable='NO') AS c3,
    EXISTS (SELECT 1 FROM cols WHERE column_name='jurisdiction_code' AND udt_name='bpchar' AND is_nullable='NO') AS c4,
    EXISTS (SELECT 1 FROM cols WHERE column_name='public_key_pem' AND udt_name='text' AND is_nullable='YES') AS c5,
    EXISTS (SELECT 1 FROM cols WHERE column_name='signing_algorithm' AND udt_name='text' AND is_nullable='YES') AS c6,
    EXISTS (SELECT 1 FROM cols WHERE column_name='boz_licence_reference' AND udt_name='text' AND is_nullable='YES') AS c7,
    EXISTS (SELECT 1 FROM cols WHERE column_name='is_active' AND udt_name='bool' AND is_nullable='YES'
            AND (column_default IS NULL OR trim(column_default) IN ('NULL::boolean','NULL'))) AS c8,
    EXISTS (SELECT 1 FROM cols WHERE column_name='active_from' AND udt_name='date' AND is_nullable='YES') AS c9,
    EXISTS (SELECT 1 FROM cols WHERE column_name='active_to' AND udt_name='date' AND is_nullable='YES') AS c10,
    EXISTS (SELECT 1 FROM cols WHERE column_name='created_at' AND udt_name='timestamptz' AND is_nullable='NO') AS c11,
    EXISTS (SELECT 1 FROM cols WHERE column_name='created_by' AND udt_name='text' AND is_nullable='NO') AS c12,
    EXISTS (SELECT 1 FROM cols WHERE column_name='updated_at' AND udt_name='timestamptz' AND is_nullable='YES') AS c13,
    (SELECT COUNT(*) FROM cols)=13 AS ccount
)
SELECT c1 AND c2 AND c3 AND c4 AND c5 AND c6 AND c7 AND c8 AND c9 AND c10 AND c11 AND c12 AND c13 AND ccount
FROM ok;
")"
  [[ "$column_count_verified" == "true" ]] || add_failure "column_spec_mismatch"

  constraint_set_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='kyc_provider_registry'
    AND c.contype='u' AND c.conname='kyc_provider_unique_code'
)
AND NOT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='kyc_provider_registry'
    AND c.contype='u' AND c.conname='kyc_provider_unique_active_per_jurisdiction'
)
AND EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='kyc_provider_registry' AND c.contype='c'
    AND pg_get_constraintdef(c.oid) ILIKE '%active_to%'
    AND pg_get_constraintdef(c.oid) ILIKE '%active_from%'
    AND pg_get_constraintdef(c.oid) LIKE '%>=%'
);
")"

  signing_unconstrained="$(query_bool "
SELECT NOT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='kyc_provider_registry' AND c.contype='c'
    AND pg_get_constraintdef(c.oid) ILIKE '%signing_algorithm%'
);
")"

  table_comment_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_description d
  JOIN pg_class c ON c.oid=d.objoid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='public' AND c.relname='kyc_provider_registry'
    AND d.objsubid=0
    AND d.description LIKE '%Phase-0 structural hook%'
);
")"

  if [[ "$constraint_set_ok" == "true" && "$signing_unconstrained" == "true" && "$table_comment_ok" == "true" ]]; then
    constraints_verified="true"
  else
    [[ "$constraint_set_ok" == "true" ]] || add_failure "required_constraints_missing_or_conflicting_full_uniqueness_present"
    [[ "$signing_unconstrained" == "true" ]] || add_failure "signing_algorithm_has_check_constraint_phase_violation"
    [[ "$table_comment_ok" == "true" ]] || add_failure "table_comment_missing_required_phrase"
  fi

  indexes_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_indexes
  WHERE schemaname='public' AND tablename='kyc_provider_registry'
    AND indexname='kyc_provider_active_idx'
    AND indexdef ILIKE '%WHERE ((active_to IS NULL) AND (is_active IS NOT FALSE))%'
)
AND EXISTS (
  SELECT 1 FROM pg_indexes
  WHERE schemaname='public' AND tablename='kyc_provider_registry'
    AND indexname='kyc_provider_jurisdiction_idx'
);
")"
  [[ "$indexes_verified" == "true" ]] || add_failure "required_indexes_missing_or_invalid"

  table_is_empty="$(query_bool "SELECT COUNT(*)=0 FROM public.kyc_provider_registry;")"
  [[ "$table_is_empty" == "true" ]] || add_failure "PHASE VIOLATION: kyc_provider_registry contains rows. Provider registration requires Compliance sign-off and belongs in Phase-2."
fi

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  runtime_reference_paths+=("$path")
done < <(
  rg -n --glob '!scripts/**' --glob '!schema/**' --glob '*.cs' --glob '*.ts' --glob '*.js' "\\bkyc_provider_registry\\b" "$ROOT_DIR" \
    | cut -d: -f1 | sort -u
)
if [[ ${#runtime_reference_paths[@]} -gt 0 ]]; then
  no_runtime_references="false"
  add_failure "runtime_references_found"
fi

migration_version="0041_kyc_provider_registry_drop_conflicting_uniqueness.sql"
migration_file="$ROOT_DIR/schema/migrations/$migration_version"
if [[ ! -f "$migration_file" ]]; then
  add_failure "migration_file_missing:$migration_version"
else
  expected_checksum="$(sha256sum "$migration_file" | awk '{print $1}')"
  if [[ "$migration_framework_ready" == "true" ]]; then
    applied_checksum="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "SELECT checksum FROM public.schema_migrations WHERE version='$migration_version'" | tr -d '[:space:]')"
    if [[ -z "$applied_checksum" ]]; then
      add_failure "migration_checksum_missing_in_registry:$migration_version"
    elif [[ "$applied_checksum" != "$expected_checksum" ]]; then
      add_failure "migration_checksum_mismatch:$migration_version:expected=$expected_checksum:actual=$applied_checksum"
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
COLUMN_COUNT_VERIFIED="$column_count_verified" CONSTRAINTS_VERIFIED="$constraints_verified" \
INDEXES_VERIFIED="$indexes_verified" TABLE_IS_EMPTY="$table_is_empty" \
NO_RUNTIME_REFERENCES="$no_runtime_references" MIGRATION_CHECKSUM_VALID="$migration_checksum_valid" \
RUNTIME_REFS="$RUNTIME_REFS" FAILURES="$FAILURES" \
python3 - <<'PY'
import json
import os
from pathlib import Path

def to_bool(v: str) -> bool:
    return str(v).lower() == "true"

out = {
    "task_id": "TSK-P0-KYC-001",
    "check_id": "TSK-P0-KYC-001",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": os.environ.get("STATUS", "FAIL"),
    "pass": to_bool(os.environ.get("PASS_BOOL", "false")),
    "table_exists": to_bool(os.environ.get("TABLE_EXISTS", "false")),
    "column_count_verified": to_bool(os.environ.get("COLUMN_COUNT_VERIFIED", "false")),
    "constraints_verified": to_bool(os.environ.get("CONSTRAINTS_VERIFIED", "false")),
    "indexes_verified": to_bool(os.environ.get("INDEXES_VERIFIED", "false")),
    "table_is_empty": to_bool(os.environ.get("TABLE_IS_EMPTY", "false")),
    "no_runtime_references": to_bool(os.environ.get("NO_RUNTIME_REFERENCES", "false")),
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
  echo "kyc_provider_registry hook verification failed" >&2
  for f in "${failures[@]}"; do
    echo " - $f" >&2
  done
  exit 1
fi

echo "kyc_provider_registry hook verification OK. Evidence: $EVIDENCE_FILE"
