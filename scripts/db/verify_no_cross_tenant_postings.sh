#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="LEDGER-002"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase2/ledger_002_tenant_scope_checks.json}"

mkdir -p "$(dirname "$EVIDENCE_PATH")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
ts="$(evidence_now_utc)"
git_sha_val="$(git_sha)"
schema_fp="$(schema_fingerprint)"

psql_q() {
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "$1" | tr -d '[:space:]'
}

tenant_a="$(psql_q "SELECT tenant_id::text FROM public.tenants ORDER BY created_at LIMIT 1;")"
if [[ -z "$tenant_a" ]]; then
  tenant_a="$(psql_q "
WITH bc AS (
  INSERT INTO public.billable_clients(legal_name, client_type, status, client_key)
  VALUES ('LEDGER-002 root-a', 'ENTERPRISE', 'ACTIVE', 'ledger_002_root_a')
  RETURNING billable_client_id
)
INSERT INTO public.tenants(tenant_key, tenant_name, tenant_type, status, billable_client_id)
SELECT 'ledger_002_tenant_a', 'LEDGER-002 tenant a', 'COMMERCIAL', 'ACTIVE', billable_client_id
FROM bc
RETURNING tenant_id::text;
")"
fi
tenant_b="$(psql_q "SELECT tenant_id::text FROM public.tenants ORDER BY created_at OFFSET 1 LIMIT 1;")"
if [[ -z "$tenant_b" ]]; then
  tenant_b="$(psql_q "
WITH bc AS (
  INSERT INTO public.billable_clients(legal_name, client_type, status, client_key)
  VALUES ('LEDGER-002 root-b', 'ENTERPRISE', 'ACTIVE', 'ledger_002_root_b')
  RETURNING billable_client_id
)
INSERT INTO public.tenants(tenant_key, tenant_name, tenant_type, status, billable_client_id)
SELECT 'ledger_002_tenant_b', 'LEDGER-002 tenant b', 'COMMERCIAL', 'ACTIVE', billable_client_id
FROM bc
RETURNING tenant_id::text;
")"
fi

jid="$(psql_q "SELECT public.create_internal_ledger_journal('$tenant_a'::uuid, 'ledger-tenant-fixture', 'INTERNAL_PROOF', 'ZMW', '[{\"account_code\":\"A_CASH\",\"direction\":\"DEBIT\",\"amount_minor\":700,\"currency_code\":\"ZMW\"},{\"account_code\":\"A_CLEARING\",\"direction\":\"CREDIT\",\"amount_minor\":700,\"currency_code\":\"ZMW\"}]'::jsonb, 'tenant-fixture')::text;")"

set +e
psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "INSERT INTO public.internal_ledger_postings(journal_id, tenant_id, account_code, direction, amount_minor, currency_code) VALUES ('$jid'::uuid, '$tenant_b'::uuid, 'B_ATTACK', 'DEBIT', 1, 'ZMW');" >/tmp/ledger_cross_tenant.log 2>&1
rc=$?
set -e

cross_tenant_rejected=false
[[ $rc -ne 0 ]] && cross_tenant_rejected=true

policy_exists="$(psql_q "SELECT EXISTS(SELECT 1 FROM pg_trigger WHERE tgname='trg_enforce_internal_ledger_posting_context')::text;")"

status=PASS
pass=true
if [[ "$cross_tenant_rejected" != true || "$policy_exists" != "true" ]]; then
  status=FAIL
  pass=false
fi

py_pass="False"
[[ "$pass" == "true" ]] && py_pass="True"
py_policy_exists="False"
[[ "$policy_exists" == "true" ]] && py_policy_exists="True"
py_cross_tenant_rejected="False"
[[ "$cross_tenant_rejected" == "true" ]] && py_cross_tenant_rejected="True"

python3 - <<PY
import json
from pathlib import Path
payload = {
  "check_id": "LEDGER-002-TENANT-SCOPE",
  "task_id": "$TASK_ID",
  "timestamp_utc": "$ts",
  "git_sha": "$git_sha_val",
  "schema_fingerprint": "$schema_fp",
  "status": "$status",
  "pass": $py_pass,
  "details": {
    "posting_context_trigger_exists": $py_policy_exists,
    "cross_tenant_posting_rejected": $py_cross_tenant_rejected
  }
}
Path("$EVIDENCE_PATH").write_text(json.dumps(payload, indent=2) + "\\n", encoding="utf-8")
PY

python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task "$TASK_ID" --evidence "$EVIDENCE_PATH"
