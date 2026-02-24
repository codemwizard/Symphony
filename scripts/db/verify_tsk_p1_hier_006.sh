#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-HIER-006"
EVIDENCE_PATH="evidence/phase1/tsk_p1_hier_006__append_only_member_device_events_anchored.json"

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

# READ_ONLY / AUDIT / APPROVAL_REQUIRED policy semantics.
run_bool_query "policy_table_exists" "supervisor_access_policies table exists" \
  "SELECT to_regclass('public.supervisor_access_policies') IS NOT NULL;"

run_bool_query "policy_scope_rows" "all three supervisor scopes are present" \
  "SELECT (SELECT count(*) FROM public.supervisor_access_policies WHERE scope IN ('READ_ONLY','AUDIT','APPROVAL_REQUIRED')) = 3;"

run_bool_query "read_only_semantics" "READ_ONLY denies API and DB access but enables report delivery" \
  "SELECT EXISTS(SELECT 1 FROM public.supervisor_access_policies WHERE scope='READ_ONLY' AND api_access=false AND db_access=false AND report_delivery=true);"

run_bool_query "audit_semantics" "AUDIT enables API-only bounded read window" \
  "SELECT EXISTS(SELECT 1 FROM public.supervisor_access_policies WHERE scope='AUDIT' AND api_access=true AND db_access=false AND report_delivery=false AND read_window_minutes IS NOT NULL AND read_window_minutes > 0);"

run_bool_query "approval_required_semantics" "APPROVAL_REQUIRED has non-null hold timeout" \
  "SELECT EXISTS(SELECT 1 FROM public.supervisor_access_policies WHERE scope='APPROVAL_REQUIRED' AND api_access=true AND db_access=false AND hold_timeout_minutes IS NOT NULL AND hold_timeout_minutes > 0);"

# AUDIT token table/view posture.
run_bool_query "audit_tokens_table" "supervisor_audit_tokens table exists" \
  "SELECT to_regclass('public.supervisor_audit_tokens') IS NOT NULL;"

run_bool_query "audit_tokens_program_expires_index" "program+expires index exists" \
  "SELECT to_regclass('public.idx_supervisor_audit_tokens_program_expires') IS NOT NULL;"

run_bool_query "audit_view_exists" "supervisor audit view exists" \
  "SELECT to_regclass('public.supervisor_audit_member_device_events') IS NOT NULL;"

# SECURITY DEFINER + search_path hardening checks.
run_bool_query "submit_function_hardened" "submit_for_supervisor_approval is SECURITY DEFINER with hardened search_path" \
  "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname='public' AND p.proname='submit_for_supervisor_approval' AND p.prosecdef=true AND array_to_string(p.proconfig,',') LIKE '%search_path=pg_catalog, public%');"

run_bool_query "decide_function_hardened" "decide_supervisor_approval is SECURITY DEFINER with hardened search_path" \
  "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname='public' AND p.proname='decide_supervisor_approval' AND p.prosecdef=true AND array_to_string(p.proconfig,',') LIKE '%search_path=pg_catalog, public%');"

run_bool_query "expire_function_hardened" "expire_supervisor_approvals is SECURITY DEFINER with hardened search_path" \
  "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname='public' AND p.proname='expire_supervisor_approvals' AND p.prosecdef=true AND array_to_string(p.proconfig,',') LIKE '%search_path=pg_catalog, public%');"

# Revoke-first posture.
run_bool_query "policies_revoke_public" "PUBLIC has no privileges on supervisor_access_policies" \
  "SELECT NOT has_table_privilege('public', 'public.supervisor_access_policies', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER');"

run_bool_query "tokens_revoke_public" "PUBLIC has no privileges on supervisor_audit_tokens" \
  "SELECT NOT has_table_privilege('public', 'public.supervisor_audit_tokens', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER');"

run_bool_query "queue_revoke_public" "PUBLIC has no privileges on supervisor_approval_queue" \
  "SELECT NOT has_table_privilege('public', 'public.supervisor_approval_queue', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER');"

# Runtime behavior checks for APPROVAL_REQUIRED flows.
billable_client_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
tenant_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
escrow_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
program_id="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tr -d '[:space:]')"
instruction_id="hier006-inst-${RANDOM}-$(date +%s)"

psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.billable_clients(billable_client_id, legal_name, client_type, regulator_ref, status, client_key) VALUES ('$billable_client_id'::uuid, 'HIER006 Billable Client', 'ENTERPRISE', NULL, 'ACTIVE', 'hier006-client-${RANDOM}');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.tenants(tenant_id, tenant_key, tenant_name, tenant_type, status, billable_client_id) VALUES ('$tenant_id'::uuid, 'hier006-${RANDOM}', 'HIER-006 Tenant', 'COMMERCIAL', 'ACTIVE', '$billable_client_id'::uuid);" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.escrow_accounts(escrow_id, tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code) VALUES ('$escrow_id'::uuid, '$tenant_id'::uuid, NULL, NULL, 'CREATED', 0, 'USD');" >/dev/null
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "INSERT INTO public.programs(program_id, tenant_id, program_key, program_name, status, program_escrow_id) VALUES ('$program_id'::uuid, '$tenant_id'::uuid, 'hier006-program-${RANDOM}', 'HIER006 Program', 'ACTIVE', '$escrow_id'::uuid);" >/dev/null

psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "SELECT public.submit_for_supervisor_approval('$instruction_id', '$program_id'::uuid, 30);" >/dev/null
run_bool_query "approval_pending_inserted" "submit_for_supervisor_approval creates pending queue row" \
  "SELECT EXISTS(SELECT 1 FROM public.supervisor_approval_queue WHERE instruction_id='${instruction_id}' AND program_id='${program_id}'::uuid AND status='PENDING_SUPERVISOR_APPROVAL');"

psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "SELECT public.decide_supervisor_approval('$instruction_id', 'APPROVED', 'supervisor-hier006', 'approved in verifier');" >/dev/null
run_bool_query "approval_decision_applied" "decide_supervisor_approval moves row to APPROVED" \
  "SELECT EXISTS(SELECT 1 FROM public.supervisor_approval_queue WHERE instruction_id='${instruction_id}' AND status='APPROVED' AND decided_by='supervisor-hier006');"

instruction_timeout_id="hier006-timeout-${RANDOM}-$(date +%s)"
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "SELECT public.submit_for_supervisor_approval('$instruction_timeout_id', '$program_id'::uuid, 1);" >/dev/null
run_bool_query "approval_timeout_transition" "expire_supervisor_approvals marks pending rows as TIMED_OUT" \
  "SELECT public.expire_supervisor_approvals(NOW() + INTERVAL '2 minutes') >= 1;"
run_bool_query "approval_timeout_marked" "timeout row is marked TIMED_OUT" \
  "SELECT EXISTS(SELECT 1 FROM public.supervisor_approval_queue WHERE instruction_id='${instruction_timeout_id}' AND status='TIMED_OUT');"

# Negative decision test.
neg_err="$TMPDIR/invalid_decision.err"
if psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c "SELECT public.decide_supervisor_approval('$instruction_timeout_id', 'MAYBE', 'supervisor-hier006', NULL);" >/dev/null 2>"$neg_err"; then
  record_check "FAIL" "approval_invalid_decision_rejected" "invalid decision unexpectedly accepted"
else
  if rg -q "invalid decision" "$neg_err"; then
    record_check "PASS" "approval_invalid_decision_rejected" "invalid decision is rejected"
  else
    record_check "FAIL" "approval_invalid_decision_rejected" "invalid decision failure message not observed"
  fi
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
      "implemented_scopes": ["READ_ONLY", "AUDIT", "APPROVAL_REQUIRED"],
      "evidence_contract_path": "$EVIDENCE_PATH"
    },
    "checks": checks
}

path = pathlib.Path("$EVIDENCE_PATH")
path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {path}")
if status != "PASS":
    raise SystemExit(1)
PY
