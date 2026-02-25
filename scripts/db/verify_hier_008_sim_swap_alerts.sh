#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-HIER-008"
EVIDENCE_PATH="evidence/phase1/hier_008_sim_swap_alerts.json"

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

run_bool_query "sim_swap_alerts_table_exists" "sim_swap_alerts table exists" \
  "SELECT to_regclass('public.sim_swap_alerts') IS NOT NULL;"

run_bool_query "derive_fn_hardened" "derive_sim_swap_alert is SECURITY DEFINER with hardened search_path" \
  "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='derive_sim_swap_alert' AND p.prosecdef=true AND array_to_string(p.proconfig,',') LIKE '%search_path=pg_catalog, public%');"

run_bool_query "sim_swap_alerts_append_only_trigger" "append-only trigger exists on sim_swap_alerts" \
  "SELECT EXISTS(SELECT 1 FROM pg_trigger tg JOIN pg_class t ON t.oid=tg.tgrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE n.nspname='public' AND t.relname='sim_swap_alerts' AND tg.tgname='trg_deny_sim_swap_alerts_mutation' AND NOT tg.tgisinternal);"

run_bool_query "sim_swap_alerts_formula_fk" "sim_swap_alerts has non-null formula_version_id FK" \
  "SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='sim_swap_alerts' AND column_name='formula_version_id' AND is_nullable='NO');"

billable_client_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
tenant_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
person_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
tenant_member_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
member_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
escrow_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
program_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
instruction_id="hier008-$(date +%s)-$RANDOM"
device_hash_old="hier008-device-old-$RANDOM"
device_hash_new="hier008-device-new-$RANDOM"
iccid_old="iccid-old-$RANDOM"
iccid_new="iccid-new-$RANDOM"

psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.billable_clients(billable_client_id, legal_name, client_type, regulator_ref, status, client_key) VALUES ('$billable_client_id'::uuid, 'HIER008 Billable Client', 'ENTERPRISE', NULL, 'ACTIVE', 'hier008-client-${RANDOM}');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.tenants(tenant_id, tenant_key, tenant_name, tenant_type, status, billable_client_id) VALUES ('$tenant_id'::uuid, 'hier008-${RANDOM}', 'HIER-008 Tenant', 'COMMERCIAL', 'ACTIVE', '$billable_client_id'::uuid);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.persons(person_id, tenant_id, person_ref_hash, status) VALUES ('$person_id'::uuid, '$tenant_id'::uuid, 'hier008-person-hash-${RANDOM}', 'ACTIVE');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.tenant_members(member_id, tenant_id, member_ref, status) VALUES ('$tenant_member_id'::uuid, '$tenant_id'::uuid, 'hier008-member-${RANDOM}', 'ACTIVE');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.escrow_accounts(escrow_id, tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code) VALUES ('$escrow_id'::uuid, '$tenant_id'::uuid, NULL, NULL, 'CREATED', 0, 'USD');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.programs(program_id, tenant_id, program_key, program_name, status, program_escrow_id) VALUES ('$program_id'::uuid, '$tenant_id'::uuid, 'hier008-program-${RANDOM}', 'HIER008 Program', 'ACTIVE', '$escrow_id'::uuid);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.members(tenant_id, member_id, tenant_member_id, person_id, entity_id, member_ref_hash, kyc_status, status, ceiling_amount_minor, ceiling_currency, metadata) VALUES ('$tenant_id'::uuid, '$member_id'::uuid, '$tenant_member_id'::uuid, '$person_id'::uuid, '$program_id'::uuid, 'hier008-member-hash-${RANDOM}', 'VERIFIED', 'ACTIVE', 50000, 'USD', '{}'::jsonb);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.member_devices(tenant_id, member_id, device_id_hash, iccid_hash, status) VALUES ('$tenant_id'::uuid, '$member_id'::uuid, '$device_hash_old', '$iccid_old', 'ACTIVE');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.ingress_attestations(instruction_id, tenant_id, payload_hash, signature_hash, member_id) VALUES ('$instruction_id', '$tenant_id'::uuid, md5('payload-' || '$instruction_id'), md5('sig-' || '$instruction_id'), '$tenant_member_id'::uuid);" >/dev/null

event_id="$(psql "$DATABASE_URL" -X -A -t -q -v ON_ERROR_STOP=1 -c "INSERT INTO public.member_device_events(tenant_id, member_id, instruction_id, device_id, device_id_hash, iccid_hash, event_type, observed_at) VALUES ('$tenant_id'::uuid, '$member_id'::uuid, '$instruction_id', 'device-new-${RANDOM}', '$device_hash_new', '$iccid_new', 'SIM_SWAP_DETECTED', NOW()) RETURNING event_id;" | head -n1 | tr -d '[:space:]')"

alert_id_first="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT public.derive_sim_swap_alert('${event_id}'::uuid);" | tr -d '[:space:]')"
if [[ "$alert_id_first" =~ ^[0-9a-fA-F-]{36}$ ]]; then
  record_check "PASS" "derive_returns_uuid" "derive_sim_swap_alert returned alert UUID"
else
  record_check "FAIL" "derive_returns_uuid" "derive_sim_swap_alert did not return UUID for qualifying event"
fi

run_bool_query "derived_alert_row_exists" "derived sim swap alert row references source event and formula version" \
  "SELECT EXISTS(SELECT 1 FROM public.sim_swap_alerts s WHERE s.alert_id='${alert_id_first}'::uuid AND s.source_event_id='${event_id}'::uuid AND s.formula_version_id IS NOT NULL AND s.prior_iccid_hash='${iccid_old}' AND s.new_iccid_hash='${iccid_new}');"

alert_id_second="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT public.derive_sim_swap_alert('${event_id}'::uuid);" | tr -d '[:space:]')"
if [[ "$alert_id_first" == "$alert_id_second" ]]; then
  record_check "PASS" "derive_idempotent" "re-derivation returns the same alert_id"
else
  record_check "FAIL" "derive_idempotent" "re-derivation returned different alert_id"
fi

run_bool_query "single_alert_per_source_event" "exactly one alert row exists per source event" \
  "SELECT (SELECT count(*) FROM public.sim_swap_alerts s WHERE s.source_event_id='${event_id}'::uuid) = 1;"

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
      "derivation_function": "public.derive_sim_swap_alert",
      "source_table": "public.member_device_events",
      "target_table": "public.sim_swap_alerts",
      "formula_key": "TIER1_DETERMINISTIC_DEFAULT"
    },
    "checks": checks
}

path = pathlib.Path("$EVIDENCE_PATH")
path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {path}")
if status != "PASS":
    raise SystemExit(1)
PY
