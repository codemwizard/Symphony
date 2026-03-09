#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="LEDGER-002"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase2/ledger_002_internal_proof_jobs.json}"

mkdir -p "$(dirname "$EVIDENCE_PATH")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
ts="$(evidence_now_utc)"
git_sha_val="$(git_sha)"
schema_fp="$(schema_fingerprint)"

psql_q() {
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "$1" | tr -d '[:space:]'
}

tenant_id="$(psql_q "SELECT tenant_id::text FROM public.tenants ORDER BY created_at LIMIT 1;")"
if [[ -z "$tenant_id" ]]; then
  tenant_id="$(psql_q "
WITH bc AS (
  INSERT INTO public.billable_clients(legal_name, client_type, status, client_key)
  VALUES ('LEDGER-002 root', 'ENTERPRISE', 'ACTIVE', 'ledger_002_root')
  RETURNING billable_client_id
)
INSERT INTO public.tenants(tenant_key, tenant_name, tenant_type, status, billable_client_id)
SELECT 'ledger_002_tenant', 'LEDGER-002 tenant', 'COMMERCIAL', 'ACTIVE', billable_client_id
FROM bc
RETURNING tenant_id::text;
")"
fi

tables_exist="$(psql_q "SELECT (to_regclass('public.internal_ledger_journals') IS NOT NULL AND to_regclass('public.internal_ledger_postings') IS NOT NULL)::text;")"
function_exists="$(psql_q "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='create_internal_ledger_journal')::text;")"

balanced_ok=false
imbalanced_rejected=false
if [[ "$tables_exist" == "true" && "$function_exists" == "true" ]]; then
  jid="$(psql_q "SELECT public.create_internal_ledger_journal('$tenant_id'::uuid, 'ledger-zero-sum-fixture', 'INTERNAL_PROOF', 'ZMW', '[{\"account_code\":\"CASH\",\"direction\":\"DEBIT\",\"amount_minor\":1000,\"currency_code\":\"ZMW\"},{\"account_code\":\"SETTLEMENT_CLEARING\",\"direction\":\"CREDIT\",\"amount_minor\":1000,\"currency_code\":\"ZMW\"}]'::jsonb, 'zero-sum-fixture')::text;")"
  balanced="$(psql_q "SELECT public.verify_internal_ledger_journal_balance('$jid'::uuid)::text;")"
  [[ "$balanced" == "true" ]] && balanced_ok=true

  set +e
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "SELECT public.create_internal_ledger_journal('$tenant_id'::uuid, 'ledger-imbalanced-fixture', 'INTERNAL_PROOF', 'ZMW', '[{\"account_code\":\"CASH\",\"direction\":\"DEBIT\",\"amount_minor\":1000,\"currency_code\":\"ZMW\"},{\"account_code\":\"SETTLEMENT_CLEARING\",\"direction\":\"CREDIT\",\"amount_minor\":900,\"currency_code\":\"ZMW\"}]'::jsonb, 'imbalanced-fixture');" >/tmp/ledger_imbalance.log 2>&1
  rc=$?
  set -e
  [[ $rc -ne 0 ]] && imbalanced_rejected=true
fi

status=PASS
pass=true
if [[ "$tables_exist" != "true" || "$function_exists" != "true" || "$balanced_ok" != true || "$imbalanced_rejected" != true ]]; then
  status=FAIL
  pass=false
fi

py_pass="False"
[[ "$pass" == "true" ]] && py_pass="True"
py_tables_exist="False"
[[ "$tables_exist" == "true" ]] && py_tables_exist="True"
py_function_exists="False"
[[ "$function_exists" == "true" ]] && py_function_exists="True"
py_balanced_ok="False"
[[ "$balanced_ok" == "true" ]] && py_balanced_ok="True"
py_imbalanced_rejected="False"
[[ "$imbalanced_rejected" == "true" ]] && py_imbalanced_rejected="True"

python3 - <<PY
import json
from pathlib import Path
payload = {
  "check_id": "LEDGER-002-ZERO-SUM",
  "task_id": "$TASK_ID",
  "timestamp_utc": "$ts",
  "git_sha": "$git_sha_val",
  "schema_fingerprint": "$schema_fp",
  "status": "$status",
  "pass": $py_pass,
  "details": {
    "tables_exist": $py_tables_exist,
    "function_exists": $py_function_exists,
    "balanced_fixture_passed": $py_balanced_ok,
    "imbalanced_fixture_rejected": $py_imbalanced_rejected
  }
}
Path("$EVIDENCE_PATH").write_text(json.dumps(payload, indent=2) + "\\n", encoding="utf-8")
PY

python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task "$TASK_ID" --evidence "$EVIDENCE_PATH"
