#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-HIER-007"
EVIDENCE_PATH="evidence/phase1/tsk_p1_hier_007__risk_formula_registry_tier_deterministic_default.json"

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

run_bool_query "risk_formula_versions_exists" "risk_formula_versions table exists" \
  "SELECT to_regclass('public.risk_formula_versions') IS NOT NULL;"

run_bool_query "risk_formula_default_seed" "default deterministic Tier-1 formula exists and active" \
  "SELECT EXISTS(SELECT 1 FROM public.risk_formula_versions WHERE formula_key='TIER1_DETERMINISTIC_DEFAULT' AND tier='TIER1' AND is_active=true);"

run_bool_query "program_migration_events_exists" "program_migration_events table exists" \
  "SELECT to_regclass('public.program_migration_events') IS NOT NULL;"

run_bool_query "program_migration_events_required_columns" "program_migration_events has required columns" \
  "SELECT (SELECT count(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='program_migration_events' AND column_name IN ('tenant_id','person_id','from_program_id','to_program_id','migrated_at','migrated_by','reason','formula_version_id')) = 8;"

run_bool_query "migration_function_hardened" "migrate_person_to_program is SECURITY DEFINER with hardened search_path" \
  "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='migrate_person_to_program' AND p.prosecdef=true AND array_to_string(p.proconfig,',') LIKE '%search_path=pg_catalog, public%');"

run_bool_query "unique_beneficiaries_view_exists" "tenant_program_year_unique_beneficiaries view exists" \
  "SELECT to_regclass('public.tenant_program_year_unique_beneficiaries') IS NOT NULL;"

# Fixture setup for deterministic migration behavior.
billable_client_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
tenant_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
person_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
tenant_member_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
member_source_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
escrow_from_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
escrow_to_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
program_from_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
program_to_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"

psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.billable_clients(billable_client_id, legal_name, client_type, regulator_ref, status, client_key) VALUES ('$billable_client_id'::uuid, 'HIER007 Billable Client', 'ENTERPRISE', NULL, 'ACTIVE', 'hier007-client-${RANDOM}');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.tenants(tenant_id, tenant_key, tenant_name, tenant_type, status, billable_client_id) VALUES ('$tenant_id'::uuid, 'hier007-${RANDOM}', 'HIER-007 Tenant', 'COMMERCIAL', 'ACTIVE', '$billable_client_id'::uuid);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.persons(person_id, tenant_id, person_ref_hash, status) VALUES ('$person_id'::uuid, '$tenant_id'::uuid, 'person-hash-${RANDOM}', 'ACTIVE');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.tenant_members(member_id, tenant_id, member_ref, status) VALUES ('$tenant_member_id'::uuid, '$tenant_id'::uuid, 'hier007-member-${RANDOM}', 'ACTIVE');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.escrow_accounts(escrow_id, tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code) VALUES ('$escrow_from_id'::uuid, '$tenant_id'::uuid, NULL, NULL, 'CREATED', 0, 'USD');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.escrow_accounts(escrow_id, tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code) VALUES ('$escrow_to_id'::uuid, '$tenant_id'::uuid, NULL, NULL, 'CREATED', 0, 'USD');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.programs(program_id, tenant_id, program_key, program_name, status, program_escrow_id) VALUES ('$program_from_id'::uuid, '$tenant_id'::uuid, 'hier007-program-from-${RANDOM}', 'HIER007 Program From', 'ACTIVE', '$escrow_from_id'::uuid);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.programs(program_id, tenant_id, program_key, program_name, status, program_escrow_id) VALUES ('$program_to_id'::uuid, '$tenant_id'::uuid, 'hier007-program-to-${RANDOM}', 'HIER007 Program To', 'ACTIVE', '$escrow_to_id'::uuid);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.members(tenant_id, member_id, tenant_member_id, person_id, entity_id, member_ref_hash, kyc_status, status, ceiling_amount_minor, ceiling_currency, metadata) VALUES ('$tenant_id'::uuid, '$member_source_id'::uuid, '$tenant_member_id'::uuid, '$person_id'::uuid, '$program_from_id'::uuid, 'member-hash-${RANDOM}', 'VERIFIED', 'ACTIVE', 1000, 'USD', '{}'::jsonb);" >/dev/null

migrated_member_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT public.migrate_person_to_program('$tenant_id'::uuid, '$person_id'::uuid, '$program_from_id'::uuid, '$program_to_id'::uuid, 'verifier-hier007', 'annual migration', 'TIER1_DETERMINISTIC_DEFAULT');" | tr -d '[:space:]')"

if [[ "$migrated_member_id" =~ ^[0-9a-fA-F-]{36}$ ]]; then
  record_check "PASS" "migrate_function_returns_uuid" "migrate_person_to_program returns target member UUID"
else
  record_check "FAIL" "migrate_function_returns_uuid" "migrate_person_to_program returned invalid UUID"
fi

run_bool_query "migrated_member_created" "target member row created on to_program preserving person linkage" \
  "SELECT EXISTS(SELECT 1 FROM public.members m WHERE m.member_id='${migrated_member_id}'::uuid AND m.tenant_id='${tenant_id}'::uuid AND m.person_id='${person_id}'::uuid AND m.entity_id='${program_to_id}'::uuid AND m.tenant_member_id='${tenant_member_id}'::uuid);"

run_bool_query "migration_event_written" "program_migration_events row written with formula version" \
  "SELECT EXISTS(SELECT 1 FROM public.program_migration_events e WHERE e.tenant_id='${tenant_id}'::uuid AND e.person_id='${person_id}'::uuid AND e.from_program_id='${program_from_id}'::uuid AND e.to_program_id='${program_to_id}'::uuid AND e.migrated_member_id='${migrated_member_id}'::uuid AND e.formula_version_id IS NOT NULL);"

migrated_member_id_again="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT public.migrate_person_to_program('$tenant_id'::uuid, '$person_id'::uuid, '$program_from_id'::uuid, '$program_to_id'::uuid, 'verifier-hier007', 'annual migration', 'TIER1_DETERMINISTIC_DEFAULT');" | tr -d '[:space:]')"
if [[ "$migrated_member_id_again" == "$migrated_member_id" ]]; then
  record_check "PASS" "migration_deterministic_idempotent_return" "repeat migration call returns same target member_id"
else
  record_check "FAIL" "migration_deterministic_idempotent_return" "repeat migration call returned different member_id"
fi

run_bool_query "migration_event_not_duplicated" "deterministic migration event uniqueness preserved" \
  "SELECT (SELECT count(*) FROM public.program_migration_events e WHERE e.tenant_id='${tenant_id}'::uuid AND e.person_id='${person_id}'::uuid AND e.from_program_id='${program_from_id}'::uuid AND e.to_program_id='${program_to_id}'::uuid) = 1;"

run_bool_query "unique_beneficiaries_query_operational" "unique beneficiaries query produces tenant-year aggregate" \
  "SELECT EXISTS(SELECT 1 FROM public.tenant_program_year_unique_beneficiaries v WHERE v.tenant_id='${tenant_id}'::uuid AND v.unique_beneficiaries >= 1);"

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
      "default_formula_key": "TIER1_DETERMINISTIC_DEFAULT",
      "deterministic_migration_function": "public.migrate_person_to_program",
      "beneficiary_query": "public.tenant_program_year_unique_beneficiaries"
    },
    "checks": checks
}

path = pathlib.Path("$EVIDENCE_PATH")
path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {path}")
if status != "PASS":
    raise SystemExit(1)
PY
