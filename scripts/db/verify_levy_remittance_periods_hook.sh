#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/TSK-P0-LEVY-004.json"

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

table_exists="$(query_bool "SELECT to_regclass('public.levy_remittance_periods') IS NOT NULL;")"
pk_verified="false"
unique_constraint_verified="false"
period_code_check_verified="false"
date_range_check_verified="false"
filing_deadline_check_verified="false"
status_column_unconstrained="false"
nullable_columns_verified="false"
indexes_verified="false"
table_is_empty="false"
no_runtime_references="true"
no_auto_triggers="false"
no_auto_functions="false"
no_premature_fk="false"
migration_checksum_valid="false"

if [[ "$table_exists" != "true" ]]; then
  add_failure "table_missing:public.levy_remittance_periods"
fi

if [[ "$table_exists" == "true" ]]; then
  pk_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='levy_remittance_periods'
    AND c.contype='p' AND c.conname='levy_remittance_periods_pkey'
);
")"
  [[ "$pk_verified" == "true" ]] || add_failure "pk_missing_or_invalid"

  unique_constraint_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='levy_remittance_periods'
    AND c.contype='u' AND c.conname='levy_periods_unique_period_jurisdiction'
);
")"
  [[ "$unique_constraint_verified" == "true" ]] || add_failure "unique_constraint_missing"

  period_code_check_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='levy_remittance_periods' AND c.contype='c'
    AND pg_get_constraintdef(c.oid) ILIKE '%period_code%'
    AND pg_get_constraintdef(c.oid) LIKE '%~%'
    AND replace(pg_get_constraintdef(c.oid), ' ', '') LIKE '%[0-9]{4}-[0-9]{2}%'
);
")"
  [[ "$period_code_check_verified" == "true" ]] || add_failure "period_code_check_missing_or_invalid"

  date_range_check_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='levy_remittance_periods' AND c.contype='c'
    AND pg_get_constraintdef(c.oid) ILIKE '%period_end%'
    AND pg_get_constraintdef(c.oid) ILIKE '%period_start%'
    AND pg_get_constraintdef(c.oid) LIKE '%>=%'
);
")"
  [[ "$date_range_check_verified" == "true" ]] || add_failure "period_date_range_check_missing"

  filing_deadline_check_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='levy_remittance_periods' AND c.contype='c'
    AND pg_get_constraintdef(c.oid) ILIKE '%filing_deadline%'
    AND pg_get_constraintdef(c.oid) ILIKE '%period_end%'
    AND pg_get_constraintdef(c.oid) LIKE '%>=%'
);
")"
  [[ "$filing_deadline_check_verified" == "true" ]] || add_failure "filing_deadline_check_missing"

  status_column_unconstrained="$(query_bool "
WITH status_col AS (
  SELECT data_type='text' AS is_text
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='levy_remittance_periods' AND column_name='period_status'
), status_check AS (
  SELECT EXISTS (
    SELECT 1 FROM pg_constraint c
    JOIN pg_class t ON t.oid=c.conrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='public' AND t.relname='levy_remittance_periods' AND c.contype='c'
      AND pg_get_constraintdef(c.oid) ILIKE '%period_status%'
  ) AS has_check
)
SELECT COALESCE((SELECT is_text FROM status_col), FALSE) AND NOT (SELECT has_check FROM status_check);
")"
  [[ "$status_column_unconstrained" == "true" ]] || add_failure "period_status_must_be_unconstrained_text"

  nullable_columns_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='public' AND table_name='levy_remittance_periods'
    AND column_name='filed_at' AND is_nullable='YES'
)
AND EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='public' AND table_name='levy_remittance_periods'
    AND column_name='zra_reference' AND is_nullable='YES'
)
AND EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='public' AND table_name='levy_remittance_periods'
    AND column_name='filing_deadline' AND is_nullable='YES'
);
")"
  [[ "$nullable_columns_verified" == "true" ]] || add_failure "nullable_columns_contract_mismatch"

  indexes_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_indexes
  WHERE schemaname='public' AND tablename='levy_remittance_periods'
    AND indexname='levy_periods_jurisdiction_idx'
)
AND EXISTS (
  SELECT 1 FROM pg_indexes
  WHERE schemaname='public' AND tablename='levy_remittance_periods'
    AND indexname='levy_periods_status_idx'
    AND indexdef ILIKE '%WHERE (period_status IS NOT NULL)%'
);
")"
  [[ "$indexes_verified" == "true" ]] || add_failure "required_indexes_missing_or_invalid"

  table_is_empty="$(query_bool "SELECT COUNT(*)=0 FROM public.levy_remittance_periods;")"
  [[ "$table_is_empty" == "true" ]] || add_failure "table_not_empty_phase0_violation"

  no_auto_triggers="$(query_bool "
SELECT COUNT(*)=0
FROM pg_trigger tg
JOIN pg_class t ON t.oid=tg.tgrelid
JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname='public' AND t.relname='levy_remittance_periods' AND NOT tg.tgisinternal;
")"
  [[ "$no_auto_triggers" == "true" ]] || add_failure "auto_triggers_found"

  no_auto_functions="$(query_bool "
SELECT COUNT(*)=0
FROM pg_proc p
JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.prokind='f'
  AND pg_get_functiondef(p.oid) ILIKE '%levy_remittance_periods%';
")"
  [[ "$no_auto_functions" == "true" ]] || add_failure "auto_functions_found"

  no_premature_fk="$(query_bool "
SELECT NOT EXISTS (
  SELECT 1 FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  JOIN pg_class rt ON rt.oid=c.confrelid
  JOIN pg_namespace rn ON rn.oid=rt.relnamespace
  WHERE c.contype='f'
    AND n.nspname='public' AND t.relname='levy_calculation_records'
    AND rn.nspname='public' AND rt.relname='levy_remittance_periods'
);
")"
  [[ "$no_premature_fk" == "true" ]] || add_failure "PHASE VIOLATION: FK levy_calculation_records -> levy_remittance_periods belongs in Phase-2. Remove from this migration."

  comment_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_description d
  JOIN pg_class c ON c.oid=d.objoid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='public' AND c.relname='levy_remittance_periods'
    AND d.objsubid=0
    AND d.description LIKE '%Phase-0 structural hook%'
);
")"
  [[ "$comment_ok" == "true" ]] || add_failure "table_comment_missing_required_phrase"
fi

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  runtime_reference_paths+=("$path")
done < <(
  rg -n --glob '!scripts/**' --glob '!schema/**' --glob '*.cs' --glob '*.ts' --glob '*.js' "\\blevy_remittance_periods\\b" "$ROOT_DIR" \
    | cut -d: -f1 | sort -u
)
if [[ ${#runtime_reference_paths[@]} -gt 0 ]]; then
  no_runtime_references="false"
  add_failure "runtime_references_found"
fi

migration_version="0038_levy_remittance_periods_hook.sql"
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

EVIDENCE_FILE="$EVIDENCE_FILE" PASS_BOOL="$pass_bool" STATUS="$status" TABLE_EXISTS="$table_exists" \
PK_VERIFIED="$pk_verified" UNIQUE_CONSTRAINT_VERIFIED="$unique_constraint_verified" \
PERIOD_CODE_CHECK_VERIFIED="$period_code_check_verified" DATE_RANGE_CHECK_VERIFIED="$date_range_check_verified" \
STATUS_COLUMN_UNCONSTRAINED="$status_column_unconstrained" NULLABLE_COLUMNS_VERIFIED="$nullable_columns_verified" \
INDEXES_VERIFIED="$indexes_verified" TABLE_IS_EMPTY="$table_is_empty" NO_RUNTIME_REFERENCES="$no_runtime_references" \
NO_AUTO_TRIGGERS="$no_auto_triggers" NO_AUTO_FUNCTIONS="$no_auto_functions" NO_PREMATURE_FK="$no_premature_fk" \
MIGRATION_CHECKSUM_VALID="$migration_checksum_valid" RUNTIME_REFS="$RUNTIME_REFS" FAILURES="$FAILURES" \
python3 - <<'PY'
import json
import os
from pathlib import Path

def to_bool(v: str) -> bool:
    return str(v).lower() == "true"

out = {
    "task_id": "TSK-P0-LEVY-004",
    "check_id": "TSK-P0-LEVY-004",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": os.environ.get("STATUS", "FAIL"),
    "pass": to_bool(os.environ.get("PASS_BOOL", "false")),
    "table_exists": to_bool(os.environ.get("TABLE_EXISTS", "false")),
    "pk_verified": to_bool(os.environ.get("PK_VERIFIED", "false")),
    "unique_constraint_verified": to_bool(os.environ.get("UNIQUE_CONSTRAINT_VERIFIED", "false")),
    "period_code_check_verified": to_bool(os.environ.get("PERIOD_CODE_CHECK_VERIFIED", "false")),
    "date_range_check_verified": to_bool(os.environ.get("DATE_RANGE_CHECK_VERIFIED", "false")),
    "status_column_unconstrained": to_bool(os.environ.get("STATUS_COLUMN_UNCONSTRAINED", "false")),
    "nullable_columns_verified": to_bool(os.environ.get("NULLABLE_COLUMNS_VERIFIED", "false")),
    "indexes_verified": to_bool(os.environ.get("INDEXES_VERIFIED", "false")),
    "table_is_empty": to_bool(os.environ.get("TABLE_IS_EMPTY", "false")),
    "no_runtime_references": to_bool(os.environ.get("NO_RUNTIME_REFERENCES", "false")),
    "no_auto_triggers": to_bool(os.environ.get("NO_AUTO_TRIGGERS", "false")),
    "no_auto_functions": to_bool(os.environ.get("NO_AUTO_FUNCTIONS", "false")),
    "no_premature_fk": to_bool(os.environ.get("NO_PREMATURE_FK", "false")),
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
  echo "levy_remittance_periods hook verification failed" >&2
  for f in "${failures[@]}"; do
    echo " - $f" >&2
  done
  exit 1
fi

echo "levy_remittance_periods hook verification OK. Evidence: $EVIDENCE_FILE"
