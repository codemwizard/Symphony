#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/TSK-P0-KYC-003.json"

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

table_exists="$(query_bool "SELECT to_regclass('public.payment_outbox_pending') IS NOT NULL;")"
column_exists="false"
type_correct="false"
nullable_confirmed="false"
no_default_value="false"
comment_verified="false"
no_runtime_references="true"
no_premature_index="false"
row_count_unchanged="false"
migration_checksum_valid="false"

if [[ "$table_exists" != "true" ]]; then
  add_failure "PREREQ MISSING: payment_outbox_pending table not found"
fi

before_count="$(query_text "SELECT COUNT(*) FROM public.payment_outbox_pending;")"

if [[ "$table_exists" == "true" ]]; then
  column_exists="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='public' AND table_name='payment_outbox_pending' AND column_name='kyc_hold'
);")"
  [[ "$column_exists" == "true" ]] || add_failure "column_missing:public.payment_outbox_pending.kyc_hold"

  type_correct="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='public' AND table_name='payment_outbox_pending'
    AND column_name='kyc_hold' AND udt_name='bool'
);")"
  [[ "$type_correct" == "true" ]] || add_failure "column_type_mismatch:expected=boolean"

  nullable_confirmed="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='public' AND table_name='payment_outbox_pending'
    AND column_name='kyc_hold' AND is_nullable='YES'
);")"
  [[ "$nullable_confirmed" == "true" ]] || add_failure "not_nullable_violation"

  no_default_value="$(query_bool "
SELECT EXISTS (
  SELECT 1 FROM information_schema.columns
  WHERE table_schema='public' AND table_name='payment_outbox_pending'
    AND column_name='kyc_hold'
    AND (column_default IS NULL OR trim(column_default) IN ('NULL::boolean','NULL'))
);")"
  [[ "$no_default_value" == "true" ]] || add_failure "default_must_be_null_or_absent"

  comment_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_catalog.pg_description d
  JOIN pg_catalog.pg_class c ON c.oid=d.objoid
  JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
  JOIN pg_catalog.pg_attribute a ON a.attrelid=c.oid AND a.attnum=d.objsubid
  WHERE n.nspname='public' AND c.relname='payment_outbox_pending' AND a.attname='kyc_hold'
    AND d.description LIKE '%Phase-0 structural hook%'
);")"
  [[ "$comment_verified" == "true" ]] || add_failure "column_comment_missing_required_phrase"

  no_premature_index="$(query_bool "
SELECT NOT EXISTS (
  SELECT 1
  FROM pg_indexes i
  WHERE i.schemaname='public' AND i.tablename='payment_outbox_pending'
    AND (
      i.indexdef ~* '\\(kyc_hold[,)]' OR
      i.indexdef ~* '\\(\\(kyc_hold\\)\\)'
    )
);")"
  [[ "$no_premature_index" == "true" ]] || add_failure "premature_index_on_kyc_hold_detected"
fi

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  runtime_reference_paths+=("$path")
done < <(
  rg -n --glob '!scripts/**' --glob '!schema/**' --glob '*.cs' --glob '*.ts' --glob '*.js' "\\bkyc_hold\\b" "$ROOT_DIR" \
    | cut -d: -f1 | sort -u
)
if [[ ${#runtime_reference_paths[@]} -gt 0 ]]; then
  no_runtime_references="false"
  add_failure "runtime_references_found"
fi

after_count="$(query_text "SELECT COUNT(*) FROM public.payment_outbox_pending;")"
if [[ "$before_count" == "$after_count" ]]; then
  row_count_unchanged="true"
else
  add_failure "row_count_changed:before=${before_count}:after=${after_count}"
fi

migration_version="0043_payment_outbox_pending_kyc_hold_hook.sql"
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
COLUMN_EXISTS="$column_exists" TYPE_CORRECT="$type_correct" NULLABLE_CONFIRMED="$nullable_confirmed" \
NO_DEFAULT_VALUE="$no_default_value" NO_RUNTIME_REFERENCES="$no_runtime_references" \
NO_PREMATURE_INDEX="$no_premature_index" ROW_COUNT_UNCHANGED="$row_count_unchanged" \
MIGRATION_CHECKSUM_VALID="$migration_checksum_valid" COMMENT_VERIFIED="$comment_verified" \
RUNTIME_REFS="$RUNTIME_REFS" FAILURES="$FAILURES" \
python3 - <<'PY'
import json
import os
from pathlib import Path

def to_bool(v: str) -> bool:
    return str(v).lower() == "true"

out = {
    "task_id": "TSK-P0-KYC-003",
    "check_id": "TSK-P0-KYC-003",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": os.environ.get("STATUS", "FAIL"),
    "pass": to_bool(os.environ.get("PASS_BOOL", "false")),
    "column_exists": to_bool(os.environ.get("COLUMN_EXISTS", "false")),
    "type_correct": to_bool(os.environ.get("TYPE_CORRECT", "false")),
    "nullable_confirmed": to_bool(os.environ.get("NULLABLE_CONFIRMED", "false")),
    "no_default_value": to_bool(os.environ.get("NO_DEFAULT_VALUE", "false")),
    "comment_verified": to_bool(os.environ.get("COMMENT_VERIFIED", "false")),
    "no_runtime_references": to_bool(os.environ.get("NO_RUNTIME_REFERENCES", "false")),
    "no_premature_index": to_bool(os.environ.get("NO_PREMATURE_INDEX", "false")),
    "row_count_unchanged": to_bool(os.environ.get("ROW_COUNT_UNCHANGED", "false")),
    "migration_checksum_valid": to_bool(os.environ.get("MIGRATION_CHECKSUM_VALID", "false")),
    "measurement_truth": "phase0_expand_first_hook_only",
    "details": {
        "runtime_reference_paths": [p for p in os.environ.get("RUNTIME_REFS", "").split("\n") if p],
        "failures": [f for f in os.environ.get("FAILURES", "").split("\n") if f],
    },
}
Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
PY

if [[ "$status" != "PASS" ]]; then
  echo "kyc_hold hook verification failed" >&2
  for f in "${failures[@]}"; do
    echo " - $f" >&2
  done
  exit 1
fi

echo "kyc_hold hook verification OK. Evidence: $EVIDENCE_FILE"
