#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/TSK-P0-LEVY-003.json"

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

ingress_exists="$(query_bool "SELECT to_regclass('public.ingress_attestations') IS NOT NULL;")"
levy_rates_exists="$(query_bool "SELECT to_regclass('public.levy_rates') IS NOT NULL;")"

[[ "$ingress_exists" == "true" ]] || add_failure "PREREQ MISSING: ingress_attestations table not found"
[[ "$levy_rates_exists" == "true" ]] || add_failure "PREREQ MISSING: TSK-P0-LEVY-001 must complete before TSK-P0-LEVY-003"

table_exists="$(query_bool "SELECT to_regclass('public.levy_calculation_records') IS NOT NULL;")"
pk_verified="false"
fk_ingress_verified="false"
fk_levy_rate_verified="false"
unique_constraint_verified="false"
amount_columns_nullable="false"
status_column_unconstrained="false"
indexes_verified="false"
table_is_empty="false"
no_runtime_references="true"
no_triggers_or_functions="false"
migration_checksum_valid="false"
reporting_period_check_verified="false"

if [[ "$table_exists" != "true" ]]; then
  add_failure "table_missing:public.levy_calculation_records"
fi

if [[ "$table_exists" == "true" ]]; then
  pk_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='levy_calculation_records'
    AND c.contype='p'
    AND c.conname='levy_calculation_records_pkey'
);
")"
  [[ "$pk_verified" == "true" ]] || add_failure "pk_missing_or_invalid"

  fk_ingress_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  JOIN pg_class rt ON rt.oid=c.confrelid
  JOIN pg_namespace rn ON rn.oid=rt.relnamespace
  WHERE n.nspname='public' AND t.relname='levy_calculation_records'
    AND c.contype='f'
    AND c.conname='levy_calculation_records_instruction_id_fkey'
    AND rn.nspname='public' AND rt.relname='ingress_attestations'
);
")"
  [[ "$fk_ingress_verified" == "true" ]] || add_failure "fk_ingress_missing_or_invalid"

  fk_levy_rate_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  JOIN pg_class rt ON rt.oid=c.confrelid
  JOIN pg_namespace rn ON rn.oid=rt.relnamespace
  WHERE n.nspname='public' AND t.relname='levy_calculation_records'
    AND c.contype='f'
    AND c.conname='levy_calculation_records_levy_rate_id_fkey'
    AND rn.nspname='public' AND rt.relname='levy_rates'
);
")"
  [[ "$fk_levy_rate_verified" == "true" ]] || add_failure "fk_levy_rate_missing_or_invalid"

  unique_constraint_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='levy_calculation_records'
    AND c.contype='u'
    AND c.conname='levy_calculation_one_per_instruction'
);
")"
  [[ "$unique_constraint_verified" == "true" ]] || add_failure "unique_constraint_missing"

  amount_columns_nullable="$(query_bool "
WITH amount_cols(col) AS (
  VALUES ('taxable_amount_minor'), ('levy_amount_pre_cap'), ('cap_applied_minor'), ('levy_amount_final')
), col_ok AS (
  SELECT COUNT(*) AS c
  FROM amount_cols ac
  JOIN information_schema.columns c
    ON c.table_schema='public'
   AND c.table_name='levy_calculation_records'
   AND c.column_name=ac.col
  WHERE c.data_type='bigint' AND c.is_nullable='YES'
), check_ok AS (
  SELECT COUNT(*) AS c
  FROM amount_cols ac
  WHERE EXISTS (
    SELECT 1
    FROM pg_constraint k
    JOIN pg_class t ON t.oid=k.conrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='public' AND t.relname='levy_calculation_records' AND k.contype='c'
      AND pg_get_constraintdef(k.oid) ILIKE '%' || ac.col || '%'
      AND pg_get_constraintdef(k.oid) LIKE '%>= 0%'
  )
)
SELECT ((SELECT c FROM col_ok)=4 AND (SELECT c FROM check_ok)=4);
")"
  [[ "$amount_columns_nullable" == "true" ]] || add_failure "amount_columns_contract_mismatch"

  reporting_period_check_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='levy_calculation_records' AND c.contype='c'
    AND pg_get_constraintdef(c.oid) ILIKE '%reporting_period%'
    AND pg_get_constraintdef(c.oid) LIKE '%~%'
    AND replace(pg_get_constraintdef(c.oid), '\\', '') LIKE '%d{4}-d{2}%'
);
")"
  [[ "$reporting_period_check_verified" == "true" ]] || add_failure "reporting_period_check_missing"

  status_column_unconstrained="$(query_bool "
WITH status_col AS (
  SELECT data_type='text' AS is_text
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='levy_calculation_records' AND column_name='levy_status'
), status_check AS (
  SELECT EXISTS (
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class t ON t.oid=c.conrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='public' AND t.relname='levy_calculation_records' AND c.contype='c'
      AND pg_get_constraintdef(c.oid) ILIKE '%levy_status%'
  ) AS has_check
)
SELECT COALESCE((SELECT is_text FROM status_col), FALSE) AND NOT (SELECT has_check FROM status_check);
")"
  [[ "$status_column_unconstrained" == "true" ]] || add_failure "levy_status_must_be_unconstrained_text"

  indexes_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_indexes
  WHERE schemaname='public' AND tablename='levy_calculation_records'
    AND indexname='levy_calc_reporting_period_idx'
    AND indexdef ILIKE '%WHERE (reporting_period IS NOT NULL)%'
)
AND EXISTS (
  SELECT 1 FROM pg_indexes
  WHERE schemaname='public' AND tablename='levy_calculation_records'
    AND indexname='levy_calc_status_idx'
    AND indexdef ILIKE '%WHERE (levy_status IS NOT NULL)%'
);
")"
  [[ "$indexes_verified" == "true" ]] || add_failure "required_indexes_missing_or_nonpartial"

  table_is_empty="$(query_bool "SELECT COUNT(*)=0 FROM public.levy_calculation_records;")"
  [[ "$table_is_empty" == "true" ]] || add_failure "table_not_empty_phase0_violation"

  no_triggers="$(query_bool "
SELECT COUNT(*)=0
FROM pg_trigger tg
JOIN pg_class t ON t.oid=tg.tgrelid
JOIN pg_namespace n ON n.oid=t.relnamespace
WHERE n.nspname='public' AND t.relname='levy_calculation_records' AND NOT tg.tgisinternal;
")"
  no_functions="$(query_bool "
SELECT COUNT(*)=0
FROM pg_proc p
JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public'
  AND p.prokind='f'
  AND pg_get_functiondef(p.oid) ILIKE '%levy_calculation_records%';
")"
  if [[ "$no_triggers" == "true" && "$no_functions" == "true" ]]; then
    no_triggers_or_functions="true"
  else
    add_failure "triggers_or_functions_reference_table"
  fi

  comment_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_description d
  JOIN pg_class c ON c.oid=d.objoid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='public' AND c.relname='levy_calculation_records'
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
  rg -n --glob '!scripts/**' --glob '!schema/**' --glob '*.cs' --glob '*.ts' --glob '*.js' "\\blevy_calculation_records\\b" "$ROOT_DIR" \
    | cut -d: -f1 | sort -u
)
if [[ ${#runtime_reference_paths[@]} -gt 0 ]]; then
  no_runtime_references="false"
  add_failure "runtime_references_found"
fi

migration_version="0037_levy_calculation_records_hook.sql"
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
PK_VERIFIED="$pk_verified" FK_INGRESS_VERIFIED="$fk_ingress_verified" FK_LEVY_RATE_VERIFIED="$fk_levy_rate_verified" \
UNIQUE_CONSTRAINT_VERIFIED="$unique_constraint_verified" AMOUNT_COLUMNS_NULLABLE="$amount_columns_nullable" \
STATUS_COLUMN_UNCONSTRAINED="$status_column_unconstrained" INDEXES_VERIFIED="$indexes_verified" \
TABLE_IS_EMPTY="$table_is_empty" NO_RUNTIME_REFERENCES="$no_runtime_references" \
NO_TRIGGERS_OR_FUNCTIONS="$no_triggers_or_functions" MIGRATION_CHECKSUM_VALID="$migration_checksum_valid" \
REPORTING_PERIOD_CHECK_VERIFIED="$reporting_period_check_verified" RUNTIME_REFS="$RUNTIME_REFS" FAILURES="$FAILURES" \
python3 - <<'PY'
import json
import os
from pathlib import Path

def to_bool(v: str) -> bool:
    return str(v).lower() == "true"

out = {
    "task_id": "TSK-P0-LEVY-003",
    "check_id": "TSK-P0-LEVY-003",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": os.environ.get("STATUS", "FAIL"),
    "pass": to_bool(os.environ.get("PASS_BOOL", "false")),
    "table_exists": to_bool(os.environ.get("TABLE_EXISTS", "false")),
    "pk_verified": to_bool(os.environ.get("PK_VERIFIED", "false")),
    "fk_ingress_verified": to_bool(os.environ.get("FK_INGRESS_VERIFIED", "false")),
    "fk_levy_rate_verified": to_bool(os.environ.get("FK_LEVY_RATE_VERIFIED", "false")),
    "unique_constraint_verified": to_bool(os.environ.get("UNIQUE_CONSTRAINT_VERIFIED", "false")),
    "amount_columns_nullable": to_bool(os.environ.get("AMOUNT_COLUMNS_NULLABLE", "false")),
    "reporting_period_check_verified": to_bool(os.environ.get("REPORTING_PERIOD_CHECK_VERIFIED", "false")),
    "status_column_unconstrained": to_bool(os.environ.get("STATUS_COLUMN_UNCONSTRAINED", "false")),
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
  echo "levy_calculation_records hook verification failed" >&2
  for f in "${failures[@]}"; do
    echo " - $f" >&2
  done
  exit 1
fi

echo "levy_calculation_records hook verification OK. Evidence: $EVIDENCE_FILE"
