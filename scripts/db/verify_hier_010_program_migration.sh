#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-HIER-010"
EVIDENCE_PATH="evidence/phase1/hier_010_program_migration.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

: "${DATABASE_URL:?DATABASE_URL is required}"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
CHECKS_NDJSON="$TMPDIR/checks.ndjson"
errors=0

record_check() {
  local status="$1"
  local check_id="$2"
  local detail="$3"
  printf '{"check_id":"%s","status":"%s","detail":"%s"}\n' "$check_id" "$status" "$detail" >> "$CHECKS_NDJSON"
  if [[ "$status" == "FAIL" ]]; then
    errors=$((errors + 1))
  fi
}

run_bool_query() {
  local check_id="$1"
  local detail="$2"
  local sql="$3"
  local out
  out="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "$sql" | tr -d '[:space:]')"
  if [[ "$out" == "t" ]]; then
    record_check "PASS" "$check_id" "$detail"
  else
    record_check "FAIL" "$check_id" "$detail"
  fi
}

capture_sqlstate() {
  local sql="$1"
  local stderr_file="$2"
  psql "$DATABASE_URL" -X --set=VERBOSITY=verbose -v ON_ERROR_STOP=1 -c "$sql" >/dev/null 2>"$stderr_file" && return 0
  if grep -q "SQL state:" "$stderr_file"; then
    grep -m1 "SQL state:" "$stderr_file" | awk '{print $3}'
    return 1
  fi
  if grep -Eq "^ERROR:\s+[A-Z0-9]{5}:" "$stderr_file"; then
    grep -E "^ERROR:\s+[A-Z0-9]{5}:" "$stderr_file" | head -n1 | sed -E 's/^ERROR:\s+([A-Z0-9]{5}):.*/\1/'
    return 1
  fi
  echo "UNKNOWN"
  return 1
}

run_bool_query "program_migration_events_exists" "program_migration_events table exists" \
  "SELECT to_regclass('public.program_migration_events') IS NOT NULL;"

run_bool_query "program_migration_events_required_columns" "program_migration_events has required columns for HIER-010 contract" \
  "SELECT (
     SELECT count(*)
     FROM information_schema.columns
     WHERE table_schema='public'
       AND table_name='program_migration_events'
       AND column_name IN ('tenant_id','person_id','from_program_id','to_program_id','migrated_at','migrated_by','reason','new_member_id','created_at')
   ) = 9;"

run_bool_query "program_migration_reason_nullable" "program_migration_events.reason is nullable" \
  "SELECT EXISTS(
     SELECT 1
     FROM information_schema.columns
     WHERE table_schema='public' AND table_name='program_migration_events'
       AND column_name='reason' AND is_nullable='YES'
   );"

run_bool_query "migration_function_exists_hier010_signature" "migrate_person_to_program has HIER-010 signature" \
  "SELECT EXISTS(
     SELECT 1
     FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
     WHERE n.nspname='public' AND p.proname='migrate_person_to_program'
       AND pg_get_function_identity_arguments(p.oid)='p_tenant_id uuid, p_person_id uuid, p_from_program_id uuid, p_to_program_id uuid, p_new_entity_id uuid, p_reason text'
   );"

run_bool_query "migration_function_hardened" "migrate_person_to_program is SECURITY DEFINER with hardened search_path" \
  "SELECT EXISTS(
     SELECT 1
     FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
     WHERE n.nspname='public' AND p.proname='migrate_person_to_program'
       AND pg_get_function_identity_arguments(p.oid)='p_tenant_id uuid, p_person_id uuid, p_from_program_id uuid, p_to_program_id uuid, p_new_entity_id uuid, p_reason text'
       AND p.prosecdef=true
       AND array_to_string(p.proconfig,',') LIKE '%search_path=pg_catalog, public%'
   );"

billable_client_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
tenant_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
person_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
tenant_member_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
member_source_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
escrow_from_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
escrow_to_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
program_from_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
program_to_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"

psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.billable_clients(billable_client_id, legal_name, client_type, regulator_ref, status, client_key) VALUES ('$billable_client_id'::uuid, 'HIER010 Billable Client', 'ENTERPRISE', NULL, 'ACTIVE', 'hier010-client-${RANDOM}');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.tenants(tenant_id, tenant_key, tenant_name, tenant_type, status, billable_client_id) VALUES ('$tenant_id'::uuid, 'hier010-${RANDOM}', 'HIER-010 Tenant', 'COMMERCIAL', 'ACTIVE', '$billable_client_id'::uuid);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.persons(person_id, tenant_id, person_ref_hash, status) VALUES ('$person_id'::uuid, '$tenant_id'::uuid, 'person-hash-${RANDOM}', 'ACTIVE');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.tenant_members(member_id, tenant_id, member_ref, status) VALUES ('$tenant_member_id'::uuid, '$tenant_id'::uuid, 'hier010-member-${RANDOM}', 'ACTIVE');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.escrow_accounts(escrow_id, tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code) VALUES ('$escrow_from_id'::uuid, '$tenant_id'::uuid, NULL, NULL, 'CREATED', 0, 'USD');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.escrow_accounts(escrow_id, tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code) VALUES ('$escrow_to_id'::uuid, '$tenant_id'::uuid, NULL, NULL, 'CREATED', 0, 'USD');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.programs(program_id, tenant_id, program_key, program_name, status, program_escrow_id) VALUES ('$program_from_id'::uuid, '$tenant_id'::uuid, 'hier010-program-from-${RANDOM}', 'HIER010 Program From', 'ACTIVE', '$escrow_from_id'::uuid);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.programs(program_id, tenant_id, program_key, program_name, status, program_escrow_id) VALUES ('$program_to_id'::uuid, '$tenant_id'::uuid, 'hier010-program-to-${RANDOM}', 'HIER010 Program To', 'ACTIVE', '$escrow_to_id'::uuid);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.members(tenant_id, member_id, tenant_member_id, person_id, entity_id, member_ref_hash, kyc_status, status, ceiling_amount_minor, ceiling_currency, metadata) VALUES ('$tenant_id'::uuid, '$member_source_id'::uuid, '$tenant_member_id'::uuid, '$person_id'::uuid, '$program_from_id'::uuid, 'member-hash-${RANDOM}', 'VERIFIED', 'ACTIVE', 1000, 'USD', '{}'::jsonb);" >/dev/null

migrated_member_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT public.migrate_person_to_program('$tenant_id'::uuid, '$person_id'::uuid, '$program_from_id'::uuid, '$program_to_id'::uuid, '$program_to_id'::uuid, 'annual migration');" | tr -d '[:space:]')"

if [[ "$migrated_member_id" =~ ^[0-9a-fA-F-]{36}$ ]]; then
  record_check "PASS" "migrate_function_returns_uuid" "migrate_person_to_program returns target member UUID"
else
  record_check "FAIL" "migrate_function_returns_uuid" "migrate_person_to_program returned invalid UUID"
fi

run_bool_query "migrated_member_created" "target member row created with same person_id and requested new entity_id" \
  "SELECT EXISTS(SELECT 1 FROM public.members m WHERE m.member_id='${migrated_member_id}'::uuid AND m.tenant_id='${tenant_id}'::uuid AND m.person_id='${person_id}'::uuid AND m.entity_id='${program_to_id}'::uuid);"

run_bool_query "original_member_preserved" "original member row is preserved (additive migration)" \
  "SELECT EXISTS(SELECT 1 FROM public.members m WHERE m.member_id='${member_source_id}'::uuid AND m.tenant_id='${tenant_id}'::uuid AND m.entity_id='${program_from_id}'::uuid);"

run_bool_query "migration_event_written" "program_migration_events row written with new_member_id and created_at" \
  "SELECT EXISTS(SELECT 1 FROM public.program_migration_events e WHERE e.tenant_id='${tenant_id}'::uuid AND e.person_id='${person_id}'::uuid AND e.from_program_id='${program_from_id}'::uuid AND e.to_program_id='${program_to_id}'::uuid AND e.new_member_id='${migrated_member_id}'::uuid AND e.created_at IS NOT NULL);"

dup_err="$TMPDIR/duplicate.err"
actual_sqlstate="NO_ERROR"
if actual_sqlstate="$(capture_sqlstate "SELECT public.migrate_person_to_program('$tenant_id'::uuid, '$person_id'::uuid, '$program_from_id'::uuid, '$program_to_id'::uuid, '$program_to_id'::uuid, 'annual migration');" "$dup_err")"; then
  actual_sqlstate="NO_ERROR"
fi
if [[ "$actual_sqlstate" == "23505" ]]; then
  record_check "PASS" "duplicate_call_stable_sqlstate" "duplicate call raises expected SQLSTATE 23505"
else
  record_check "FAIL" "duplicate_call_stable_sqlstate" "duplicate call expected_sqlstate=23505 actual=${actual_sqlstate}"
fi

status="PASS"
if (( errors > 0 )); then
  status="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE_PATH")"

python3 - <<PY
import datetime
import json
import pathlib
import subprocess

task_id = "$TASK_ID"
status = "$status"
checks = [json.loads(line) for line in pathlib.Path("$CHECKS_NDJSON").read_text(encoding="utf-8").splitlines() if line.strip()]

try:
    git_sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
except Exception:
    git_sha = "UNKNOWN"

result = {
    "check_id": task_id,
    "task_id": task_id,
    "status": status,
    "pass": status == "PASS",
    "git_sha": git_sha,
    "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "details": {
      "migration_function": "public.migrate_person_to_program",
      "duplicate_sqlstate": "23505",
      "event_table": "public.program_migration_events"
    },
    "checks": checks
}

path = pathlib.Path("$EVIDENCE_PATH")
path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {path}")
if status != "PASS":
    raise SystemExit(1)
PY
