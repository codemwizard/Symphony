#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-HIER-011"
EVIDENCE_PATH="evidence/phase1/hier_011_supervisor_access_mechanisms.json"

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
trap 'rm -rf "$TMPDIR"; if [[ -n "${API_PID:-}" ]]; then kill "$API_PID" >/dev/null 2>&1 || true; fi' EXIT
CHECKS="$TMPDIR/checks.ndjson"
errors=0

record() {
  local status="$1"; shift
  local id="$1"; shift
  local detail="$1"
  printf '{"check_id":"%s","status":"%s","detail":"%s"}\n' "$id" "$status" "$detail" >> "$CHECKS"
  if [[ "$status" == "FAIL" ]]; then
    errors=$((errors + 1))
  fi
}

run_bool_sql() {
  local id="$1"; shift
  local detail="$1"; shift
  local sql="$1"
  local out
  out="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "$sql" | tr -d '[:space:]')"
  if [[ "$out" == "t" ]]; then
    record PASS "$id" "$detail"
  else
    record FAIL "$id" "$detail"
  fi
}

run_bool_sql "approval_queue_columns" "approval queue has held/approved/submitted columns" \
  "SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='supervisor_approval_queue' AND column_name='held_reason') AND EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='supervisor_approval_queue' AND column_name='submitted_by') AND EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='supervisor_approval_queue' AND column_name='approved_by') AND EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='supervisor_approval_queue' AND column_name='approved_at');"

run_bool_sql "submit_function_single_arg" "single-arg submit_for_supervisor_approval exists" \
  "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname='public' AND p.proname='submit_for_supervisor_approval' AND p.pronargs=1);"

run_bool_sql "decide_function_guarded" "decide_supervisor_approval is SECURITY DEFINER with hardened search_path" \
  "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname='public' AND p.proname='decide_supervisor_approval' AND p.prosecdef=true AND array_to_string(p.proconfig,',') LIKE '%search_path=pg_catalog, public%');"

# Seed entities for runtime checks.
billable_client_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
tenant_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
escrow_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
program_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
person_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
member_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
tenant_member_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"

event_instruction="hier011-evt-${RANDOM}-$(date +%s)"
self_instruction="hier011-self-${RANDOM}-$(date +%s)"

psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.billable_clients(billable_client_id, legal_name, client_type, regulator_ref, status, client_key) VALUES ('$billable_client_id'::uuid, 'HIER011 Billable Client', 'ENTERPRISE', NULL, 'ACTIVE', 'hier011-client-${RANDOM}') ON CONFLICT DO NOTHING;" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.tenants(tenant_id, tenant_key, tenant_name, tenant_type, status, billable_client_id) VALUES ('$tenant_id'::uuid, 'hier011-${RANDOM}', 'HIER-011 Tenant', 'COMMERCIAL', 'ACTIVE', '$billable_client_id'::uuid) ON CONFLICT DO NOTHING;" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.escrow_accounts(escrow_id, tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code) VALUES ('$escrow_id'::uuid, '$tenant_id'::uuid, NULL, NULL, 'CREATED', 0, 'USD') ON CONFLICT DO NOTHING;" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.programs(program_id, tenant_id, program_key, program_name, status, program_escrow_id) VALUES ('$program_id'::uuid, '$tenant_id'::uuid, 'hier011-program-${RANDOM}', 'HIER011 Program', 'ACTIVE', '$escrow_id'::uuid) ON CONFLICT DO NOTHING;" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.persons(person_id, tenant_id, person_ref_hash) VALUES ('$person_id'::uuid, '$tenant_id'::uuid, encode(digest('hier011-${person_id}', 'sha256'), 'hex')) ON CONFLICT DO NOTHING;" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.tenant_members(member_id, tenant_id, member_ref, status) VALUES ('$tenant_member_id'::uuid, '$tenant_id'::uuid, 'hier011-tenant-member-${RANDOM}', 'ACTIVE') ON CONFLICT DO NOTHING;" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.members(member_id, tenant_id, tenant_member_id, person_id, entity_id, member_ref_hash, status, enrolled_at) VALUES ('$member_id'::uuid, '$tenant_id'::uuid, '$tenant_member_id'::uuid, '$person_id'::uuid, '$program_id'::uuid, encode(digest('hier011-member-${member_id}', 'sha256'), 'hex'), 'ACTIVE', NOW()) ON CONFLICT DO NOTHING;" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.ingress_attestations(instruction_id, tenant_id, payload_hash, member_id) VALUES ('$event_instruction', '$tenant_id'::uuid, encode(digest('hier011-payload-${event_instruction}', 'sha256'), 'hex'), '$tenant_member_id'::uuid);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.member_device_events(tenant_id, member_id, instruction_id, device_id, event_type, observed_at) VALUES ('$tenant_id'::uuid, '$member_id'::uuid, '$event_instruction', 'device-hier011', 'SIM_SWAP_DETECTED', NOW());" >/dev/null

# READ_ONLY: signed aggregate report delivery.
openssl genrsa -out "$TMPDIR/report_signing_key.pem" 2048 >/dev/null 2>&1
SUPERVISOR_REPORT_SIGNING_KEY_PATH="$TMPDIR/report_signing_key.pem" scripts/reporting/deliver_supervisor_report.sh "$program_id" "$TMPDIR" >/dev/null
report_path="$TMPDIR/supervisor_report_${program_id}.json"
sig_path="$report_path.sig"
pub_path="$report_path.pub.pem"

if openssl dgst -sha256 -verify "$pub_path" -signature "$sig_path" "$report_path" >/dev/null 2>&1; then
  record PASS "read_only_report_signature_valid" "READ_ONLY report signature verifies"
else
  record FAIL "read_only_report_signature_valid" "READ_ONLY report signature verification failed"
fi

if jq -e '.aggregate | type == "array"' "$report_path" >/dev/null 2>&1 && ! jq -e '.aggregate[]? | has("member_id") or has("person_id") or has("full_name")' "$report_path" >/dev/null 2>&1; then
  record PASS "read_only_report_no_raw_pii" "READ_ONLY report contains aggregate-only payload"
else
  record FAIL "read_only_report_no_raw_pii" "READ_ONLY report contains disallowed raw fields"
fi

# AUDIT + APPROVAL_REQUIRED API runtime.
export SUPERVISOR_API_PORT=18081
export SUPERVISOR_API_TEST_MODE=1
python3 -m venv "$TMPDIR/venv"
"$TMPDIR/venv/bin/pip" install -r services/supervisor_api/requirements.txt >/dev/null 2>&1
"$TMPDIR/venv/bin/python3" services/supervisor_api/server.py >"$TMPDIR/api.log" 2>&1 &
API_PID=$!
for _ in 1 2 3 4 5; do
  if curl -fsS "http://127.0.0.1:${SUPERVISOR_API_PORT}/nope" >/dev/null 2>&1 || rg -q "supervisor_api_listening" "$TMPDIR/api.log"; then
    break
  fi
  sleep 1
done

# Create short-lived audit token and verify expiry behavior.
create_short_resp="$TMPDIR/create_short.json"
curl -sS -X POST "http://127.0.0.1:${SUPERVISOR_API_PORT}/v1/admin/supervisor/audit-token" \
  -H 'Content-Type: application/json' \
  -d "{\"program_id\":\"$program_id\",\"issued_by\":\"hier011-verifier\",\"ttl_seconds\":1}" > "$create_short_resp"
short_token="$(jq -r '.token' "$create_short_resp")"
if [[ -n "$short_token" && "$short_token" != "null" ]]; then
  record PASS "audit_token_created" "AUDIT token API issues scoped token"
else
  record FAIL "audit_token_created" "AUDIT token API did not issue token"
fi

sleep 2
expired_code="$(curl -sS -o "$TMPDIR/expired.json" -w '%{http_code}' "http://127.0.0.1:${SUPERVISOR_API_PORT}/v1/admin/supervisor/audit-records" -H "Authorization: Bearer ${short_token}")"
if [[ "$expired_code" == "401" ]] && jq -e '.error=="TOKEN_EXPIRED"' "$TMPDIR/expired.json" >/dev/null 2>&1; then
  record PASS "audit_token_expires" "AUDIT token expires automatically"
else
  record FAIL "audit_token_expires" "AUDIT token expiry behavior failed"
fi

# Create normal token, verify anonymized records and revoke.
create_resp="$TMPDIR/create.json"
curl -sS -X POST "http://127.0.0.1:${SUPERVISOR_API_PORT}/v1/admin/supervisor/audit-token" \
  -H 'Content-Type: application/json' \
  -d "{\"program_id\":\"$program_id\",\"issued_by\":\"hier011-verifier\"}" > "$create_resp"
token="$(jq -r '.token' "$create_resp")"
token_id="$(jq -r '.token_id' "$create_resp")"

read_code="$(curl -sS -o "$TMPDIR/read.json" -w '%{http_code}' "http://127.0.0.1:${SUPERVISOR_API_PORT}/v1/admin/supervisor/audit-records" -H "Authorization: Bearer ${token}")"
if [[ "$read_code" == "200" ]] && jq -e '.records | type == "array"' "$TMPDIR/read.json" >/dev/null 2>&1 && ! jq -e '.records[]? | has("member_id") or has("person_id")' "$TMPDIR/read.json" >/dev/null 2>&1; then
  record PASS "audit_records_anonymized" "AUDIT token returns anonymized raw records"
else
  record FAIL "audit_records_anonymized" "AUDIT record payload is not anonymized"
fi

revoke_code="$(curl -sS -o "$TMPDIR/revoke.json" -w '%{http_code}' -X DELETE "http://127.0.0.1:${SUPERVISOR_API_PORT}/v1/admin/supervisor/audit-token/${token_id}")"
post_revoke_code="$(curl -sS -o "$TMPDIR/revoked_read.json" -w '%{http_code}' "http://127.0.0.1:${SUPERVISOR_API_PORT}/v1/admin/supervisor/audit-records" -H "Authorization: Bearer ${token}")"
if [[ "$revoke_code" == "200" && "$post_revoke_code" == "401" ]] && jq -e '.error=="TOKEN_REVOKED"' "$TMPDIR/revoked_read.json" >/dev/null 2>&1; then
  record PASS "audit_token_revocable" "AUDIT token is revocable via DELETE endpoint"
else
  record FAIL "audit_token_revocable" "AUDIT token revocation behavior failed"
fi

# APPROVAL_REQUIRED: cannot self-approve.
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "SELECT public.submit_for_supervisor_approval('$self_instruction', '$program_id'::uuid, 30, 'fraud_watch', 'actor_self');" >/dev/null
self_code="$(curl -sS -o "$TMPDIR/self.json" -w '%{http_code}' -X POST "http://127.0.0.1:${SUPERVISOR_API_PORT}/v1/admin/supervisor/approve/${self_instruction}" -H 'Content-Type: application/json' -d '{"approved_by":"actor_self","reason":"attempt self approval"}')"
if [[ "$self_code" == "403" ]] && jq -e '.error=="SELF_APPROVAL_FORBIDDEN"' "$TMPDIR/self.json" >/dev/null 2>&1; then
  record PASS "approval_cannot_self_approve" "APPROVAL_REQUIRED blocks self-approval"
else
  record FAIL "approval_cannot_self_approve" "self-approval was not blocked"
fi

approve_code="$(curl -sS -o "$TMPDIR/approve.json" -w '%{http_code}' -X POST "http://127.0.0.1:${SUPERVISOR_API_PORT}/v1/admin/supervisor/approve/${self_instruction}" -H 'Content-Type: application/json' -d '{"approved_by":"actor_supervisor","reason":"manual approval"}')"
if [[ "$approve_code" == "200" ]]; then
  record PASS "approval_endpoint_approves" "APPROVAL_REQUIRED endpoint approves pending instruction"
else
  record FAIL "approval_endpoint_approves" "approval endpoint failed to approve"
fi

status="PASS"
if (( errors > 0 )); then status="FAIL"; fi

mkdir -p "$(dirname "$EVIDENCE_PATH")"
python3 - <<PY
import datetime, json, pathlib, subprocess
checks=[json.loads(line) for line in pathlib.Path("$CHECKS").read_text().splitlines() if line.strip()]
try:
    git_sha=subprocess.check_output(["git","rev-parse","HEAD"], text=True).strip()
except Exception:
    git_sha="UNKNOWN"
out={
  "check_id":"$TASK_ID",
  "task_id":"$TASK_ID",
  "status":"$status",
  "pass": "$status"=="PASS",
  "git_sha":git_sha,
  "timestamp_utc":datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace('+00:00','Z'),
  "details":{
    "mechanisms":["READ_ONLY","AUDIT","APPROVAL_REQUIRED"],
    "api_endpoints":[
      "POST /v1/admin/supervisor/audit-token",
      "DELETE /v1/admin/supervisor/audit-token/{token_id}",
      "POST /v1/admin/supervisor/approve/{instruction_id}"
    ]
  },
  "checks":checks
}
path=pathlib.Path("$EVIDENCE_PATH")
path.write_text(json.dumps(out, indent=2)+"\n", encoding="utf-8")
print(f"Evidence written: {path}")
if out["status"]!="PASS":
    raise SystemExit(1)
PY
