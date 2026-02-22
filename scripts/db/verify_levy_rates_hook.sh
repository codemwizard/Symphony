#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/TSK-P0-LEVY-001.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

failures=()
add_failure() {
  failures+=("$1")
}

query_bool() {
  local sql="$1"
  local val
  val="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "$sql" | tr -d '[:space:]')"
  if [[ "$val" == "t" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

table_exists="$(query_bool "SELECT to_regclass('public.levy_rates') IS NOT NULL;")"
if [[ "$table_exists" != "true" ]]; then
  add_failure "table_missing:public.levy_rates"
fi

column_count_verified="false"
constraints_verified="false"
indexes_verified="false"
no_runtime_references="true"
migration_checksum_valid="false"
runtime_reference_paths=()

if [[ "$table_exists" == "true" ]]; then
  columns_ok="$(query_bool "
SELECT
  EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='levy_rates' AND column_name='id' AND udt_name='uuid' AND is_nullable='NO')
  AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='levy_rates' AND column_name='jurisdiction_code' AND udt_name='bpchar' AND character_maximum_length=2 AND is_nullable='NO')
  AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='levy_rates' AND column_name='statutory_reference' AND udt_name='text' AND is_nullable='YES')
  AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='levy_rates' AND column_name='rate_bps' AND udt_name='int4' AND is_nullable='NO')
  AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='levy_rates' AND column_name='cap_amount_minor' AND udt_name='int8' AND is_nullable='YES')
  AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='levy_rates' AND column_name='cap_currency_code' AND udt_name='bpchar' AND character_maximum_length=3 AND is_nullable='YES')
  AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='levy_rates' AND column_name='effective_from' AND udt_name='date' AND is_nullable='NO')
  AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='levy_rates' AND column_name='effective_to' AND udt_name='date' AND is_nullable='YES')
  AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='levy_rates' AND column_name='created_at' AND udt_name='timestamptz' AND is_nullable='NO')
  AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='levy_rates' AND column_name='created_by' AND udt_name='text' AND is_nullable='NO');
")"
  if [[ "$columns_ok" == "true" ]]; then
    column_count_verified="true"
  else
    add_failure "column_spec_mismatch"
  fi

  primary_key_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint
  WHERE conrelid='public.levy_rates'::regclass
    AND contype='p'
    AND conname='levy_rates_pkey'
);
")"
  rate_check_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint
  WHERE conrelid='public.levy_rates'::regclass
    AND contype='c'
    AND pg_get_constraintdef(oid) LIKE '%rate_bps >= 0%'
    AND pg_get_constraintdef(oid) LIKE '%rate_bps <= 10000%'
);
")"
  cap_amount_check_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint
  WHERE conrelid='public.levy_rates'::regclass
    AND contype='c'
    AND regexp_replace(pg_get_constraintdef(oid), '\s+', ' ', 'g')
        ~* 'cap_amount_minor.*IS NULL.*cap_amount_minor.*> *0'
);
")"
  effective_window_check_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint
  WHERE conrelid='public.levy_rates'::regclass
    AND contype='c'
    AND regexp_replace(pg_get_constraintdef(oid), '\s+', ' ', 'g')
        ~* 'effective_to.*IS NULL.*effective_to.*>=.*effective_from'
);
")"
  cap_currency_check_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint
  WHERE conrelid='public.levy_rates'::regclass
    AND conname='levy_rates_cap_currency_required'
);
")"
  if [[ "$primary_key_ok" == "true" \
    && "$rate_check_ok" == "true" \
    && "$cap_amount_check_ok" == "true" \
    && "$effective_window_check_ok" == "true" \
    && "$cap_currency_check_ok" == "true" ]]; then
    constraints_verified="true"
  else
    [[ "$primary_key_ok" == "true" ]] || add_failure "missing_primary_key:levy_rates_pkey"
    [[ "$rate_check_ok" == "true" ]] || add_failure "missing_rate_bps_range_check"
    [[ "$cap_amount_check_ok" == "true" ]] || add_failure "missing_cap_amount_minor_positive_check"
    [[ "$effective_window_check_ok" == "true" ]] || add_failure "missing_effective_window_check"
    [[ "$cap_currency_check_ok" == "true" ]] || add_failure "missing_constraint:levy_rates_cap_currency_required"
  fi

  partial_idx_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_indexes
  WHERE schemaname='public'
    AND tablename='levy_rates'
    AND indexname='levy_rates_one_active_per_jurisdiction'
    AND indexdef LIKE '%UNIQUE INDEX levy_rates_one_active_per_jurisdiction%'
    AND indexdef LIKE '%(jurisdiction_code)%'
    AND indexdef LIKE '%WHERE (effective_to IS NULL)%'
);
")"
  lookup_idx_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_indexes
  WHERE schemaname='public'
    AND tablename='levy_rates'
    AND indexname='levy_rates_jurisdiction_date_idx'
);
")"
  if [[ "$partial_idx_ok" == "true" && "$lookup_idx_ok" == "true" ]]; then
    indexes_verified="true"
  else
    [[ "$partial_idx_ok" == "true" ]] || add_failure "missing_or_invalid_partial_index:levy_rates_one_active_per_jurisdiction"
    [[ "$lookup_idx_ok" == "true" ]] || add_failure "missing_index:levy_rates_jurisdiction_date_idx"
  fi

  table_comment_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_description d
  JOIN pg_class c ON c.oid = d.objoid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname='public' AND c.relname='levy_rates'
    AND d.description LIKE '%Phase-0 structural hook%'
);
")"
  if [[ "$table_comment_ok" != "true" ]]; then
    add_failure "table_comment_missing_required_phrase"
  fi
fi

# Runtime references are forbidden in app code extensions (.cs/.ts/.js) outside scripts/schema.
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  runtime_reference_paths+=("$path")
done < <(
  rg -n -i --glob '!scripts/**' --glob '!schema/**' --glob '*.cs' --glob '*.ts' --glob '*.js' "\blevy_rates\b" "$ROOT_DIR" \
    | cut -d: -f1 | sort -u
)

if [[ ${#runtime_reference_paths[@]} -gt 0 ]]; then
  no_runtime_references="false"
  add_failure "runtime_references_found"
fi

migration_version="0035_levy_rates_hook.sql"
migration_file="$ROOT_DIR/schema/migrations/$migration_version"
if [[ ! -f "$migration_file" ]]; then
  add_failure "migration_file_missing:$migration_version"
else
  expected_checksum="$(sha256sum "$migration_file" | awk '{print $1}')"
  applied_checksum="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "SELECT checksum FROM public.schema_migrations WHERE version='$migration_version'" | tr -d '[:space:]')"
  if [[ -z "$applied_checksum" ]]; then
    add_failure "migration_checksum_missing_in_registry:$migration_version"
  elif [[ "$applied_checksum" != "$expected_checksum" ]]; then
    add_failure "migration_checksum_mismatch:$migration_version:expected=$expected_checksum:actual=$applied_checksum"
  else
    migration_checksum_valid="true"
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

EVIDENCE_FILE="$EVIDENCE_FILE" TABLE_EXISTS="$table_exists" COLUMN_COUNT_VERIFIED="$column_count_verified" \
CONSTRAINTS_VERIFIED="$constraints_verified" INDEXES_VERIFIED="$indexes_verified" \
NO_RUNTIME_REFERENCES="$no_runtime_references" MIGRATION_CHECKSUM_VALID="$migration_checksum_valid" \
PASS_BOOL="$pass_bool" STATUS="$status" RUNTIME_REFS="$RUNTIME_REFS" FAILURES="$FAILURES" python3 - <<'PY'
import json
import os
from pathlib import Path

def to_bool(v: str) -> bool:
    return str(v).lower() == "true"

runtime_refs = [p for p in os.environ.get("RUNTIME_REFS", "").split("\n") if p]
failures = [f for f in os.environ.get("FAILURES", "").split("\n") if f]

out = {
    "task_id": "TSK-P0-LEVY-001",
    "check_id": "TSK-P0-LEVY-001",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": os.environ.get("STATUS", "FAIL"),
    "pass": to_bool(os.environ.get("PASS_BOOL", "false")),
    "table_exists": to_bool(os.environ.get("TABLE_EXISTS", "false")),
    "column_count_verified": to_bool(os.environ.get("COLUMN_COUNT_VERIFIED", "false")),
    "constraints_verified": to_bool(os.environ.get("CONSTRAINTS_VERIFIED", "false")),
    "indexes_verified": to_bool(os.environ.get("INDEXES_VERIFIED", "false")),
    "no_runtime_references": to_bool(os.environ.get("NO_RUNTIME_REFERENCES", "false")),
    "migration_checksum_valid": to_bool(os.environ.get("MIGRATION_CHECKSUM_VALID", "false")),
    "measurement_truth": "phase0_structural_hook_only",
    "details": {
        "runtime_reference_paths": runtime_refs,
        "failures": failures,
    },
}
Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
PY

if [[ "$status" != "PASS" ]]; then
  echo "levy_rates hook verification failed" >&2
  for f in "${failures[@]}"; do
    echo " - $f" >&2
  done
  if [[ ${#runtime_reference_paths[@]} -gt 0 ]]; then
    echo "Runtime references:" >&2
    printf ' - %s\n' "${runtime_reference_paths[@]}" >&2
  fi
  exit 1
fi

echo "levy_rates hook verification OK. Evidence: $EVIDENCE_FILE"
