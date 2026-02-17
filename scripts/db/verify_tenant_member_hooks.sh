#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_OUT="$EVIDENCE_DIR/tenant_member_hooks.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

failures=()
checks=()

check_bool() {
  local name="$1"
  local sql="$2"
  local val
  val=$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "$sql" || echo "")
  checks+=("$name=$val")
  if [[ "$val" != "t" ]]; then
    failures+=("$name")
  fi
}

# Tables
check_bool "tenants_table" "SELECT to_regclass('public.tenants') IS NOT NULL;"
check_bool "tenant_clients_table" "SELECT to_regclass('public.tenant_clients') IS NOT NULL;"
check_bool "tenant_members_table" "SELECT to_regclass('public.tenant_members') IS NOT NULL;"

# ingress_attestations columns
check_bool "ingress_tenant_id_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='tenant_id');"
check_bool "ingress_tenant_id_uuid" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='tenant_id' AND udt_name='uuid');"
check_bool "ingress_tenant_id_not_null" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='tenant_id' AND is_nullable='NO');"
check_bool "ingress_client_id_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='client_id');"
check_bool "ingress_client_id_hash_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='client_id_hash');"
check_bool "ingress_member_id_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='member_id');"
check_bool "ingress_participant_id_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='participant_id');"
check_bool "ingress_cert_fingerprint_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='cert_fingerprint_sha256');"
check_bool "ingress_token_jti_hash_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='token_jti_hash');"

# Unique index for tenant/instruction
check_bool "ingress_tenant_instruction_unique" "SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='ingress_attestations' AND indexname='ux_ingress_attestations_tenant_instruction');"

# Guard function + trigger
check_bool "member_tenant_match_fn" "SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname='enforce_member_tenant_match');"
check_bool "member_tenant_match_trigger" "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_ingress_member_tenant_match');"

# Outbox columns (expand-first)
check_bool "outbox_pending_tenant_id_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='payment_outbox_pending' AND column_name='tenant_id');"
check_bool "outbox_attempts_tenant_id_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='payment_outbox_attempts' AND column_name='tenant_id');"
check_bool "outbox_attempts_member_id_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='payment_outbox_attempts' AND column_name='member_id');"

result="PASS"
if [[ ${#failures[@]} -gt 0 ]]; then
  result="FAIL"
fi

CHECKS_JOINED="$(printf '%s\n' "${checks[@]}")"
FAILURES_JOINED="$(printf '%s\n' "${failures[@]}")"

CHECKS_JOINED="$CHECKS_JOINED" FAILURES_JOINED="$FAILURES_JOINED" python3 - <<PY
import json
import os

checks = [c for c in os.environ.get("CHECKS_JOINED","").split("\\n") if c]
failures = [c for c in os.environ.get("FAILURES_JOINED","").split("\\n") if c]

out = {
  "check_id": "DB-TENANT-MEMBER-HOOKS",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status": "${result}",
  "details": {
    "checks": checks,
    "failures": failures
  }
}

with open("${EVIDENCE_OUT}", "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
PY

if [[ "$result" == "FAIL" ]]; then
  echo "Tenant/member hooks verification failed." >&2
  exit 1
fi

echo "Tenant/member hooks verification OK. Evidence: $EVIDENCE_OUT"
