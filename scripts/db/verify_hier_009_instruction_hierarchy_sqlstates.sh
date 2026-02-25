#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-HIER-009"
EVIDENCE_PATH="evidence/phase1/hier_009_instruction_hierarchy_sqlstates.json"

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
MAPPING_JSON="$TMPDIR/sqlstate_mapping_verified.json"
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

run_sqlstate_test() {
  local link_name="$1"
  local expected="$2"
  local sql="$3"
  local check_id="$4"
  local errf="$TMPDIR/${check_id}.err"
  local actual pass status pass_py
  if actual="$(capture_sqlstate "$sql" "$errf")"; then
    actual="NO_ERROR"
  fi
  if [[ "$actual" == "$expected" ]]; then
    pass=true
    pass_py="True"
    status="PASS"
  else
    pass=false
    pass_py="False"
    status="FAIL"
  fi
  record_check "$status" "$check_id" "link=${link_name};expected=${expected};actual=${actual}"
  python3 - <<PY
import json
from pathlib import Path
path = Path("$MAPPING_JSON")
rows = []
if path.exists():
    rows = json.loads(path.read_text(encoding="utf-8"))
rows.append({
  "link": "$link_name",
  "expected": "$expected",
  "actual": "$actual",
  "pass": $pass_py
})
path.write_text(json.dumps(rows, indent=2) + "\n", encoding="utf-8")
PY
}

run_bool_query "function_exists" "verify_instruction_hierarchy exists in public schema" \
  "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='verify_instruction_hierarchy');"

run_bool_query "function_signature" "verify_instruction_hierarchy has required signature" \
  "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='verify_instruction_hierarchy' AND pg_get_function_identity_arguments(p.oid)='p_instruction_id text, p_tenant_id uuid, p_participant_id text, p_program_id uuid, p_entity_id uuid, p_member_id uuid, p_device_id text');"

run_bool_query "function_security_definer" "verify_instruction_hierarchy is SECURITY DEFINER" \
  "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='verify_instruction_hierarchy' AND p.prosecdef=true);"

run_bool_query "function_search_path_hardening" "verify_instruction_hierarchy uses SET search_path = pg_catalog, public" \
  "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='verify_instruction_hierarchy' AND array_to_string(p.proconfig,',') LIKE '%search_path=pg_catalog, public%');"

tenant_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
billable_client_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
person_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
tenant_member_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
member_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
program_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
escrow_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
instruction_id="hier009-inst-${RANDOM}-$(date +%s)"
participant_id="hier009-participant-${RANDOM}"
device_id_hash="hier009-device-${RANDOM}"
other_uuid="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"

psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.billable_clients(billable_client_id, legal_name, client_type, regulator_ref, status, client_key) VALUES ('$billable_client_id'::uuid, 'HIER009 Billable Client', 'ENTERPRISE', NULL, 'ACTIVE', 'hier009-client-${RANDOM}');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.tenants(tenant_id, tenant_key, tenant_name, tenant_type, status, billable_client_id) VALUES ('$tenant_id'::uuid, 'hier009-${RANDOM}', 'HIER-009 Tenant', 'COMMERCIAL', 'ACTIVE', '$billable_client_id'::uuid);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.participants(participant_id, legal_name, participant_kind, status) VALUES ('$participant_id', 'HIER009 Participant', 'INTERNAL', 'ACTIVE') ON CONFLICT (participant_id) DO NOTHING;" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.tenant_members(member_id, tenant_id, member_ref, status) VALUES ('$tenant_member_id'::uuid, '$tenant_id'::uuid, 'hier009-member-${RANDOM}', 'ACTIVE');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.persons(person_id, tenant_id, person_ref_hash, status) VALUES ('$person_id'::uuid, '$tenant_id'::uuid, 'person-hash-${RANDOM}', 'ACTIVE');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.escrow_accounts(escrow_id, tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code) VALUES ('$escrow_id'::uuid, '$tenant_id'::uuid, NULL, NULL, 'CREATED', 0, 'USD');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.programs(program_id, tenant_id, program_key, program_name, status, program_escrow_id) VALUES ('$program_id'::uuid, '$tenant_id'::uuid, 'hier009-program-${RANDOM}', 'HIER009 Program', 'ACTIVE', '$escrow_id'::uuid);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.members(tenant_id, member_id, tenant_member_id, person_id, entity_id, member_ref_hash, kyc_status, status, ceiling_amount_minor, ceiling_currency, metadata) VALUES ('$tenant_id'::uuid, '$member_id'::uuid, '$tenant_member_id'::uuid, '$person_id'::uuid, '$program_id'::uuid, 'member-hash-${RANDOM}', 'VERIFIED', 'ACTIVE', 0, 'USD', '{}'::jsonb);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.member_devices(tenant_id, member_id, device_id_hash, iccid_hash, status) VALUES ('$tenant_id'::uuid, '$member_id'::uuid, '$device_id_hash', NULL, 'ACTIVE');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.ingress_attestations(instruction_id, tenant_id, payload_hash, signature_hash, member_id, participant_id) VALUES ('$instruction_id', '$tenant_id'::uuid, 'payload-hash-${RANDOM}', NULL, '$tenant_member_id'::uuid, '$participant_id');" >/dev/null

run_sqlstate_test "tenant_to_participant_invalid" "P7299" \
  "SELECT public.verify_instruction_hierarchy('$instruction_id', '$other_uuid'::uuid, '$participant_id', '$program_id'::uuid, '$program_id'::uuid, '$member_id'::uuid, '$device_id_hash');" \
  "tenant_participant_link_invalid"

run_sqlstate_test "participant_to_program_invalid" "P7300" \
  "SELECT public.verify_instruction_hierarchy('$instruction_id', '$tenant_id'::uuid, '$participant_id', '$other_uuid'::uuid, '$other_uuid'::uuid, '$member_id'::uuid, '$device_id_hash');" \
  "participant_program_link_invalid"

run_sqlstate_test "program_to_entity_invalid" "P7301" \
  "SELECT public.verify_instruction_hierarchy('$instruction_id', '$tenant_id'::uuid, '$participant_id', '$program_id'::uuid, '$other_uuid'::uuid, '$member_id'::uuid, '$device_id_hash');" \
  "program_entity_link_invalid"

run_sqlstate_test "entity_to_member_invalid" "P7302" \
  "SELECT public.verify_instruction_hierarchy('$instruction_id', '$tenant_id'::uuid, '$participant_id', '$program_id'::uuid, '$program_id'::uuid, '$other_uuid'::uuid, '$device_id_hash');" \
  "entity_member_link_invalid"

run_sqlstate_test "member_to_device_invalid" "P7303" \
  "SELECT public.verify_instruction_hierarchy('$instruction_id', '$tenant_id'::uuid, '$participant_id', '$program_id'::uuid, '$program_id'::uuid, '$member_id'::uuid, 'missing-device');" \
  "member_device_link_invalid"

if psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c \
  "SELECT public.verify_instruction_hierarchy('$instruction_id', '$tenant_id'::uuid, '$participant_id', '$program_id'::uuid, '$program_id'::uuid, '$member_id'::uuid, '$device_id_hash');" \
  | tr -d '[:space:]' | grep -q "^t$"; then
  record_check "PASS" "happy_path" "function returns true for valid hierarchy"
else
  record_check "FAIL" "happy_path" "function failed valid hierarchy"
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
sqlstate_mapping_verified = json.loads(pathlib.Path("$MAPPING_JSON").read_text(encoding="utf-8")) if pathlib.Path("$MAPPING_JSON").exists() else []

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
    "sqlstate_mapping_verified": sqlstate_mapping_verified,
    "details": {
      "function_name": "public.verify_instruction_hierarchy",
      "reserved_sqlstates": ["P7304", "P7305", "P7306", "P7307"],
      "sqlstate_mapping_verified": sqlstate_mapping_verified
    },
    "checks": checks
}

path = pathlib.Path("$EVIDENCE_PATH")
path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {path}")
if status != "PASS":
    raise SystemExit(1)
PY
