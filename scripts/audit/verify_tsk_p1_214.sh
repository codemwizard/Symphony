#!/usr/bin/env bash
set -euo pipefail

# --- PRE_CI_CONTEXT_GUARD ---
# This script writes evidence and must run via pre_ci.sh or run_task.sh.
# Direct execution bypasses the enforcement harness and is blocked.
# Debugging override: PRE_CI_CONTEXT=1 bash <script>
if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Direct execution blocked to protect evidence integrity." >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  mkdir -p .toolchain/audit
  printf '%s rogue_execution attempted: %s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${BASH_SOURCE[0]}" \
    >> .toolchain/audit/rogue_execution.log
  return 1 2>/dev/null || exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---


ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_214_supplier_registry_persistence.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$([[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]] && echo "19700101T000000Z" || date -u +%Y%m%dT%H%M%SZ)}"
DATABASE_URL="${DATABASE_URL:-postgres://symphony_admin:symphony_pass@localhost:5432/symphony}"

mkdir -p "$(dirname "$EVIDENCE")"
errors=()

echo "==> Verifying TSK-P1-214 supplier registry persistence..."

# 0. Apply migration and mock FK data
psql "$DATABASE_URL" -q -f "$ROOT/schema/migrations/0075_supplier_registry_and_programme_allowlist.sql"

IDS="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "
WITH existing_program AS (
  SELECT p.program_id, p.tenant_id 
  FROM public.programs p 
  JOIN public.tenants t ON t.tenant_id = p.tenant_id 
  LIMIT 1
),
new_bc AS (
  INSERT INTO public.billable_clients(legal_name, client_type, status, client_key)
  SELECT 'TSK-P1-214 billable root', 'ENTERPRISE', 'ACTIVE', 'tsk-p1-214'
  WHERE NOT EXISTS (SELECT 1 FROM existing_program)
  RETURNING billable_client_id
),
new_tenant AS (
  INSERT INTO public.tenants(tenant_key, tenant_name, tenant_type, status, billable_client_id)
  SELECT 'tsk_p1_214_tenant', 'TSK-P1-214 tenant', 'COMMERCIAL', 'ACTIVE', billable_client_id
  FROM new_bc
  WHERE NOT EXISTS (SELECT 1 FROM existing_program)
  RETURNING tenant_id
),
new_escrow AS (
  INSERT INTO public.escrow_accounts(tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code, authorization_expires_at)
  SELECT tenant_id, public.uuid_v7_or_random(), 'ENTITY-P214', 'CREATED', 10000, 'ZMW', NOW() + interval '20 minutes'
  FROM new_tenant
  WHERE NOT EXISTS (SELECT 1 FROM existing_program)
  RETURNING escrow_id, tenant_id
),
new_program AS (
  INSERT INTO public.programs(program_id, tenant_id, program_key, program_name, status, program_escrow_id)
  SELECT public.uuid_v7_or_random(), tenant_id, 'tsk_p1_214_program', 'TSK-P1-214 program', 'ACTIVE', escrow_id
  FROM new_escrow
  WHERE NOT EXISTS (SELECT 1 FROM existing_program)
  RETURNING program_id, tenant_id
)
SELECT program_id || ',' || tenant_id FROM existing_program
UNION ALL
SELECT program_id || ',' || tenant_id FROM new_program;
" | tail -n 1 | tr -d '[:space:]')"

PROGRAM_ID="${IDS%,*}"
TENANT_ID="${IDS#*,}"

echo "Using Tenant: $TENANT_ID, Program: $PROGRAM_ID"
has_supplier_table=$(psql "$DATABASE_URL" -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema='public' AND table_name='supplier_registry');")
has_allowlist_table=$(psql "$DATABASE_URL" -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema='public' AND table_name='program_supplier_allowlist');")

if [ "$has_supplier_table" != "t" ]; then
  errors+=("supplier_registry_table_missing")
fi
if [ "$has_allowlist_table" != "t" ]; then
  errors+=("program_supplier_allowlist_table_missing")
fi

rls_supplier=$(psql "$DATABASE_URL" -tAc "SELECT relrowsecurity FROM pg_class WHERE relname='supplier_registry';")
if [ "$rls_supplier" != "t" ]; then
  errors+=("supplier_registry_missing_rls")
fi

rls_allowlist=$(psql "$DATABASE_URL" -tAc "SELECT relrowsecurity FROM pg_class WHERE relname='program_supplier_allowlist';")
if [ "$rls_allowlist" != "t" ]; then
  errors+=("program_supplier_allowlist_missing_rls")
fi

# 2. Start API in DB mode, write data, restart, read back
PORT=5098
BASE_URL="http://127.0.0.1:$PORT"
API_LOG="/tmp/ledger_api_214.log"
SUPPLIER_ID="SUP-214-TEST"

start_api() {
  export INGRESS_STORAGE_MODE="db_psql"
  export SYMPHONY_RUNTIME_PROFILE="developer"
  export ADMIN_API_KEY="test-admin-key"
  export INGRESS_API_KEY="test-api-key"
  export EVIDENCE_SIGNING_KEY="test-signing-key"
  export DEMO_INSTRUCTION_SIGNING_KEY="test-signing-key"
  export EVIDENCE_SIGNING_KEY_ID="test-key-id"
  export SYMPHONY_KNOWN_TENANTS="$TENANT_ID"
  export DATABASE_URL
  export ASPNETCORE_URLS="http://*:$PORT"

  # Run daemonized
  dotnet run --project "$ROOT/services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj" --no-build --urls "http://*:$PORT" > "$API_LOG" 2>&1 &
  API_PID=$!
  for i in {1..15}; do
    if grep -q "Now listening" "$API_LOG"; then break; fi
    sleep 1
  done
  if ! kill -0 $API_PID 2>/dev/null; then
    echo "API failed to start. Logs:"
    cat "$API_LOG"
    exit 1
  fi
}

echo "    Starting API for write phase..."
start_api

upsert_resp=$(curl -sS -X POST "$BASE_URL/v1/admin/suppliers/upsert" \
  -H "x-admin-api-key: test-admin-key" \
  -H "Content-Type: application/json" \
  -d "{
    \"tenant_id\": \"$TENANT_ID\",
    \"supplier_id\": \"$SUPPLIER_ID\",
    \"supplier_name\": \"TSK-214 Test Supplier\",
    \"payout_target\": \"test-target\",
    \"active\": true
  }")

if ! echo "$upsert_resp" | grep -q "\"upserted\":true"; then
  echo "Upsert failed. Response: $upsert_resp"
  errors+=("supplier_upsert_failed")
fi

allowlist_resp=$(curl -sS -X POST "$BASE_URL/v1/admin/program-supplier-allowlist/upsert" \
  -H "x-admin-api-key: test-admin-key" \
  -H "Content-Type: application/json" \
  -d "{
    \"tenant_id\": \"$TENANT_ID\",
    \"program_id\": \"$PROGRAM_ID\",
    \"supplier_id\": \"$SUPPLIER_ID\",
    \"allowed\": true
  }")

if ! echo "$allowlist_resp" | grep -q "\"updated\":true"; then
  errors+=("allowlist_upsert_failed")
fi

echo "    Shutting down API..."
kill $API_PID || true
wait $API_PID 2>/dev/null || true

echo "    Restarting API for read phase..."
start_api

read_resp=$(curl -sS "$BASE_URL/v1/programs/$PROGRAM_ID/suppliers/$SUPPLIER_ID/policy" \
  -H "x-tenant-id: $TENANT_ID" \
  -H "x-api-key: test-api-key" || echo "failed")

if ! echo "$read_resp" | grep -q "\"supplier_exists\":true"; then
  echo "Supplier read failed. Response: $read_resp"
  errors+=("supplier_read_failed_after_restart")
fi
if ! echo "$read_resp" | grep -q "\"allowlisted\":true"; then
  echo "Allowlist read failed. Response: $read_resp"
  errors+=("allowlist_read_failed_after_restart")
fi
if ! echo "$read_resp" | grep -q "\"decision\":\"ALLOW\""; then
  echo "Decision read failed. Response: $read_resp"
  errors+=("supplier_policy_decision_not_allow")
fi

echo "    Shutting down API..."
kill $API_PID || true
wait $API_PID 2>/dev/null || true

# 3. No fallback file mentions
if grep -q "SUPPLIER_REGISTRY_PATH" "$ROOT/docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md" 2>/dev/null; then
  errors+=("hardened_docs_mention_file_backed_supplier")
fi

if [[ ${#errors[@]} -eq 0 ]]; then
  status="PASS"
else
  status="FAIL"
fi

source "$ROOT/scripts/lib/evidence.sh" 2>/dev/null || {
  git_sha() { git rev-parse HEAD 2>/dev/null || echo "unknown"; }
  schema_fingerprint() { echo "unknown"; }
  evidence_now_utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }
}

TS_UTC="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"
SCHEMA_FP="$(schema_fingerprint)"

python3 - <<PY "$EVIDENCE" "$RUN_ID" "$status" "$TS_UTC" "$GIT_SHA" "$SCHEMA_FP" "$(IFS=,; echo "${errors[*]:-}")"
import json, sys, os
evidence_path, run_id, status, ts, sha, schema_fp, errors_csv = sys.argv[1:8]
errors = [e for e in errors_csv.split(",") if e]
payload = {
    "check_id": "TSK-P1-214",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": schema_fp,
    "status": status,
    "task_id": "TSK-P1-214",
    "run_id": run_id,
    "checks": {
        "tables_exist": "supplier_registry_table_missing" not in errors and "program_supplier_allowlist_table_missing" not in errors,
        "rls_enforced": "supplier_registry_missing_rls" not in errors and "program_supplier_allowlist_missing_rls" not in errors,
        "survives_restart": "supplier_read_failed_after_restart" not in errors and "allowlist_read_failed_after_restart" not in errors,
        "hardened_docs_clean": "hardened_docs_mention_file_backed_supplier" not in errors
    },
    "errors": errors
}
os.makedirs(os.path.dirname(evidence_path), exist_ok=True)
with open(evidence_path, "w", encoding="utf-8") as f:
    f.write(json.dumps(payload, indent=2) + "\n")
PY

if [[ "$status" != "PASS" ]]; then
  echo "FAIL: ${errors[*]}" >&2
  exit 1
fi

echo "PASS: TSK-P1-214 supplier registry persistence verified."
echo "Evidence: $EVIDENCE"
