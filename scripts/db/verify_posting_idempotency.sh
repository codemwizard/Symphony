#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="LEDGER-002"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase2/ledger_002_posting_idempotency.json}"

mkdir -p "$(dirname "$EVIDENCE_PATH")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
ts="$(evidence_now_utc)"
git_sha_val="$(git_sha)"
schema_fp="$(schema_fingerprint)"

psql_q() {
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "$1" | tr -d '[:space:]'
}

tenant_id="$(psql_q "SELECT tenant_id::text FROM public.tenants ORDER BY created_at LIMIT 1;")"
idempotency_ok=false
row_count_ok=false

if [[ -n "$tenant_id" ]]; then
  jid1="$(psql_q "SELECT public.create_internal_ledger_journal('$tenant_id'::uuid, 'ledger-idempotency-fixture', 'INTERNAL_PROOF', 'ZMW', '[{\"account_code\":\"RESERVE\",\"direction\":\"DEBIT\",\"amount_minor\":2500,\"currency_code\":\"ZMW\"},{\"account_code\":\"OBLIGATION\",\"direction\":\"CREDIT\",\"amount_minor\":2500,\"currency_code\":\"ZMW\"}]'::jsonb, 'idempotency-fixture')::text;")"
  jid2="$(psql_q "SELECT public.create_internal_ledger_journal('$tenant_id'::uuid, 'ledger-idempotency-fixture', 'INTERNAL_PROOF', 'ZMW', '[{\"account_code\":\"RESERVE\",\"direction\":\"DEBIT\",\"amount_minor\":2500,\"currency_code\":\"ZMW\"},{\"account_code\":\"OBLIGATION\",\"direction\":\"CREDIT\",\"amount_minor\":2500,\"currency_code\":\"ZMW\"}]'::jsonb, 'idempotency-fixture')::text;")"
  count="$(psql_q "SELECT COUNT(*)::text FROM public.internal_ledger_journals WHERE tenant_id='$tenant_id'::uuid AND idempotency_key='ledger-idempotency-fixture';")"
  [[ "$jid1" == "$jid2" ]] && idempotency_ok=true
  [[ "$count" == "1" ]] && row_count_ok=true
fi

status=PASS
pass=true
if [[ "$idempotency_ok" != true || "$row_count_ok" != true ]]; then
  status=FAIL
  pass=false
fi

py_pass="False"
[[ "$pass" == "true" ]] && py_pass="True"
py_idempotency_ok="False"
[[ "$idempotency_ok" == "true" ]] && py_idempotency_ok="True"
py_row_count_ok="False"
[[ "$row_count_ok" == "true" ]] && py_row_count_ok="True"

python3 - <<PY
import json
from pathlib import Path
payload = {
  "check_id": "LEDGER-002-IDEMPOTENCY",
  "task_id": "$TASK_ID",
  "timestamp_utc": "$ts",
  "git_sha": "$git_sha_val",
  "schema_fingerprint": "$schema_fp",
  "status": "$status",
  "pass": $py_pass,
  "details": {
    "same_journal_id_returned": $py_idempotency_ok,
    "single_row_for_idempotency_key": $py_row_count_ok
  }
}
Path("$EVIDENCE_PATH").write_text(json.dumps(payload, indent=2) + "\\n", encoding="utf-8")
PY

python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task "$TASK_ID" --evidence "$EVIDENCE_PATH"
