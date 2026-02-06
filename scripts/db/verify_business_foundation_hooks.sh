#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_OUT="$EVIDENCE_DIR/business_foundation_hooks.json"

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
  val="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "$sql" || echo "")"
  checks+=("$name=$val")
  if [[ "$val" != "t" ]]; then
    failures+=("$name")
  fi
}

# Core tables
check_bool "billable_clients_table" "SELECT to_regclass('public.billable_clients') IS NOT NULL;"
check_bool "billing_usage_events_table" "SELECT to_regclass('public.billing_usage_events') IS NOT NULL;"
check_bool "external_proofs_table" "SELECT to_regclass('public.external_proofs') IS NOT NULL;"
check_bool "evidence_packs_table" "SELECT to_regclass('public.evidence_packs') IS NOT NULL;"
check_bool "evidence_pack_items_table" "SELECT to_regclass('public.evidence_pack_items') IS NOT NULL;"

# Tenant hierarchy hooks
check_bool "tenants_billable_client_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tenants' AND column_name='billable_client_id');"
check_bool "tenants_parent_tenant_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tenants' AND column_name='parent_tenant_id');"
check_bool "tenants_billable_client_fk" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='tenants_billable_client_fk' AND conrelid='public.tenants'::regclass);"
check_bool "tenants_parent_tenant_fk" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='tenants_parent_tenant_fk' AND conrelid='public.tenants'::regclass);"
check_bool "idx_tenants_billable_client_id" "SELECT to_regclass('public.idx_tenants_billable_client_id') IS NOT NULL;"
check_bool "idx_tenants_parent_tenant_id" "SELECT to_regclass('public.idx_tenants_parent_tenant_id') IS NOT NULL;"

# Multi-signature ingress hook
check_bool "ingress_signatures_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='signatures' AND udt_name='jsonb');"
check_bool "ingress_signatures_not_null" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='signatures' AND is_nullable='NO');"
check_bool "ingress_signatures_default" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='signatures' AND column_default LIKE '%[]%jsonb%');"

# Correlation and rail refs
check_bool "ingress_correlation_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='correlation_id');"
check_bool "pending_correlation_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='payment_outbox_pending' AND column_name='correlation_id');"
check_bool "attempts_correlation_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='payment_outbox_attempts' AND column_name='correlation_id');"
check_bool "ingress_upstream_ref_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='upstream_ref');"
check_bool "ingress_downstream_ref_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='downstream_ref');"
check_bool "ingress_nfs_sequence_ref_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ingress_attestations' AND column_name='nfs_sequence_ref');"
check_bool "pending_upstream_ref_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='payment_outbox_pending' AND column_name='upstream_ref');"
check_bool "pending_downstream_ref_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='payment_outbox_pending' AND column_name='downstream_ref');"
check_bool "pending_nfs_sequence_ref_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='payment_outbox_pending' AND column_name='nfs_sequence_ref');"
check_bool "attempts_upstream_ref_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='payment_outbox_attempts' AND column_name='upstream_ref');"
check_bool "attempts_downstream_ref_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='payment_outbox_attempts' AND column_name='downstream_ref');"
check_bool "attempts_nfs_sequence_ref_col" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='payment_outbox_attempts' AND column_name='nfs_sequence_ref');"

# Correlation indexes
check_bool "idx_ingress_attestations_tenant_correlation" "SELECT to_regclass('public.idx_ingress_attestations_tenant_correlation') IS NOT NULL;"
check_bool "idx_ingress_attestations_correlation_id" "SELECT to_regclass('public.idx_ingress_attestations_correlation_id') IS NOT NULL;"
check_bool "idx_payment_outbox_pending_tenant_correlation" "SELECT to_regclass('public.idx_payment_outbox_pending_tenant_correlation') IS NOT NULL;"
check_bool "idx_payment_outbox_pending_correlation_id" "SELECT to_regclass('public.idx_payment_outbox_pending_correlation_id') IS NOT NULL;"
check_bool "idx_payment_outbox_attempts_tenant_correlation" "SELECT to_regclass('public.idx_payment_outbox_attempts_tenant_correlation') IS NOT NULL;"
check_bool "idx_payment_outbox_attempts_correlation_id" "SELECT to_regclass('public.idx_payment_outbox_attempts_correlation_id') IS NOT NULL;"

# Append-only posture
check_bool "trg_deny_billing_usage_events_mutation" "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_deny_billing_usage_events_mutation');"
check_bool "trg_deny_external_proofs_mutation" "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_deny_external_proofs_mutation');"
check_bool "trg_deny_evidence_packs_mutation" "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_deny_evidence_packs_mutation');"
check_bool "trg_deny_evidence_pack_items_mutation" "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_deny_evidence_pack_items_mutation');"
check_bool "billing_subject_zero_or_one_chk" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='billing_usage_events_subject_zero_or_one_chk' AND conrelid='public.billing_usage_events'::regclass);"
check_bool "billing_member_requires_tenant_chk" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='billing_usage_events_member_requires_tenant_chk' AND conrelid='public.billing_usage_events'::regclass);"

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
  "check_id": "DB-BUSINESS-FOUNDATION-HOOKS",
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
  echo "Business foundation hooks verification failed." >&2
  exit 1
fi

echo "Business foundation hooks verification OK. Evidence: $EVIDENCE_OUT"
