#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/TSK-P0-KYC-004.json"

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

query_text() {
  local sql="$1"
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "$sql" | sed 's/[[:space:]]*$//' || true
}

migration_framework_ready="$(query_bool "SELECT to_regclass('public.schema_migrations') IS NOT NULL;")"
if [[ "$migration_framework_ready" != "true" ]]; then
  add_failure "PREREQ MISSING: migration framework not initialised"
fi

table_exists="$(query_bool "SELECT to_regclass('public.kyc_retention_policy') IS NOT NULL;")"
pk_verified="false"
unique_constraint_verified="false"
retention_years_check_verified="false"
append_only_rules_verified="false"
row_count_is_one="false"
zm_fic_act_row_verified="false"
statutory_reference_contains_fic_act="false"
no_runtime_references="true"
table_comment_verified="false"
migration_checksum_valid="false"

if [[ "$table_exists" != "true" ]]; then
  add_failure "table_missing:public.kyc_retention_policy"
fi

if [[ "$table_exists" == "true" ]]; then
  pk_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='kyc_retention_policy'
    AND c.contype='p' AND c.conname='kyc_retention_policy_pkey'
);")"
  [[ "$pk_verified" == "true" ]] || add_failure "pk_missing_or_invalid"

  unique_constraint_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='kyc_retention_policy'
    AND c.contype='u' AND c.conname='kyc_retention_unique_active_class'
);")"
  [[ "$unique_constraint_verified" == "true" ]] || add_failure "unique_constraint_missing"

  retention_years_check_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public' AND t.relname='kyc_retention_policy'
    AND c.contype='c'
    AND pg_get_constraintdef(c.oid) ILIKE '%retention_years%'
    AND pg_get_constraintdef(c.oid) ILIKE '%> 0%'
);")"
  [[ "$retention_years_check_verified" == "true" ]] || add_failure "retention_years_check_missing"

  is_active_default_ok="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='kyc_retention_policy'
    AND column_name='is_active' AND is_nullable='NO' AND column_default ILIKE '%true%'
);")"
  [[ "$is_active_default_ok" == "true" ]] || add_failure "is_active_default_or_nullability_mismatch"

  statutory_reference_not_null="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='kyc_retention_policy'
    AND column_name='statutory_reference' AND is_nullable='NO'
);")"
  [[ "$statutory_reference_not_null" == "true" ]] || add_failure "statutory_reference_not_null_missing"

  append_only_rules_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM pg_rules
  WHERE schemaname='public' AND tablename='kyc_retention_policy' AND rulename='kyc_retention_policy_no_update'
)
AND EXISTS (
  SELECT 1 FROM pg_rules
  WHERE schemaname='public' AND tablename='kyc_retention_policy' AND rulename='kyc_retention_policy_no_delete'
);")"
  [[ "$append_only_rules_verified" == "true" ]] || add_failure "GOVERNANCE DEFECT: kyc_retention_policy has no append-only rules. This table must be immutable."

  row_count="$(query_text "SELECT COUNT(*) FROM public.kyc_retention_policy;")"
  if [[ "$row_count" == "1" ]]; then
    row_count_is_one="true"
  elif [[ "$row_count" == "0" ]]; then
    add_failure "SEEDING FAILURE: Zambia FIC Act row not found. Check migration for INSERT statement."
  else
    add_failure "PHASE VIOLATION: kyc_retention_policy contains more than one row. Only the ZM FIC Act seed row is permitted in Phase-0."
  fi

  zm_fic_act_row_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM public.kyc_retention_policy
  WHERE jurisdiction_code='ZM'
    AND retention_class='FIC_AML_CUSTOMER_ID'
    AND retention_years=10
);")"
  [[ "$zm_fic_act_row_verified" == "true" ]] || add_failure "STATUTORY ERROR: retention_years must be 10 for FIC_AML_CUSTOMER_ID. Check statutory reference."

  statutory_reference_contains_fic_act="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM public.kyc_retention_policy
  WHERE jurisdiction_code='ZM'
    AND retention_class='FIC_AML_CUSTOMER_ID'
    AND statutory_reference ILIKE '%Financial Intelligence Centre Act%'
);")"
  [[ "$statutory_reference_contains_fic_act" == "true" ]] || add_failure "statutory_reference_missing_fic_act"

  table_comment_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_description d
  JOIN pg_class c ON c.oid=d.objoid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='public' AND c.relname='kyc_retention_policy' AND d.objsubid=0
    AND d.description LIKE '%Phase-0 governance declaration%'
);")"
  [[ "$table_comment_verified" == "true" ]] || add_failure "table_comment_missing_required_phrase"
fi

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  runtime_reference_paths+=("$path")
done < <(
  rg -n --glob '!scripts/**' --glob '!schema/**' --glob '*.cs' --glob '*.ts' --glob '*.js' "\bkyc_retention_policy\b" "$ROOT_DIR" \
    | cut -d: -f1 | sort -u
)
if [[ ${#runtime_reference_paths[@]} -gt 0 ]]; then
  no_runtime_references="false"
  add_failure "runtime_references_found"
fi

migration_version="0044_kyc_retention_policy_hook.sql"
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
PK_VERIFIED="$pk_verified" UNIQUE_CONSTRAINT_VERIFIED="$unique_constraint_verified" \
RETENTION_YEARS_CHECK_VERIFIED="$retention_years_check_verified" APPEND_ONLY_RULES_VERIFIED="$append_only_rules_verified" \
ROW_COUNT_IS_ONE="$row_count_is_one" ZM_FIC_ACT_ROW_VERIFIED="$zm_fic_act_row_verified" \
STAT_REF_HAS_FIC_ACT="$statutory_reference_contains_fic_act" NO_RUNTIME_REFERENCES="$no_runtime_references" \
MIGRATION_CHECKSUM_VALID="$migration_checksum_valid" TABLE_COMMENT_VERIFIED="$table_comment_verified" \
RUNTIME_REFS="$RUNTIME_REFS" FAILURES="$FAILURES" \
python3 - <<'PY'
import json
import os
from pathlib import Path

def to_bool(v: str) -> bool:
    return str(v).lower() == "true"

out = {
    "task_id": "TSK-P0-KYC-004",
    "check_id": "TSK-P0-KYC-004",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": os.environ.get("STATUS", "FAIL"),
    "pass": to_bool(os.environ.get("PASS_BOOL", "false")),
    "table_exists": to_bool(os.environ.get("TABLE_EXISTS", "false")),
    "pk_verified": to_bool(os.environ.get("PK_VERIFIED", "false")),
    "unique_constraint_verified": to_bool(os.environ.get("UNIQUE_CONSTRAINT_VERIFIED", "false")),
    "retention_years_check_verified": to_bool(os.environ.get("RETENTION_YEARS_CHECK_VERIFIED", "false")),
    "append_only_rules_verified": to_bool(os.environ.get("APPEND_ONLY_RULES_VERIFIED", "false")),
    "row_count_is_one": to_bool(os.environ.get("ROW_COUNT_IS_ONE", "false")),
    "zm_fic_act_row_verified": to_bool(os.environ.get("ZM_FIC_ACT_ROW_VERIFIED", "false")),
    "statutory_reference_contains_fic_act": to_bool(os.environ.get("STAT_REF_HAS_FIC_ACT", "false")),
    "table_comment_verified": to_bool(os.environ.get("TABLE_COMMENT_VERIFIED", "false")),
    "no_runtime_references": to_bool(os.environ.get("NO_RUNTIME_REFERENCES", "false")),
    "migration_checksum_valid": to_bool(os.environ.get("MIGRATION_CHECKSUM_VALID", "false")),
    "measurement_truth": "phase0_governance_declaration_single_row",
    "details": {
        "runtime_reference_paths": [p for p in os.environ.get("RUNTIME_REFS", "").split("\n") if p],
        "failures": [f for f in os.environ.get("FAILURES", "").split("\n") if f],
    },
}
Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
PY

if [[ "$status" != "PASS" ]]; then
  echo "kyc_retention_policy hook verification failed" >&2
  for f in "${failures[@]}"; do
    echo " - $f" >&2
  done
  exit 1
fi

echo "kyc_retention_policy hook verification OK. Evidence: $EVIDENCE_FILE"
