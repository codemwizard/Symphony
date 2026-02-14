#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/anchor_sync_operational_invariant.json"

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

check_bool "table_anchor_sync_operations" "SELECT to_regclass('public.anchor_sync_operations') IS NOT NULL;"
check_bool "constraint_anchor_sync_state_chk" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='anchor_sync_operations_state_check' AND conrelid='public.anchor_sync_operations'::regclass);"
check_bool "function_ensure_anchor_sync_operation" "SELECT to_regprocedure('public.ensure_anchor_sync_operation(uuid,text)') IS NOT NULL;"
check_bool "function_claim_anchor_sync_operation" "SELECT to_regprocedure('public.claim_anchor_sync_operation(text,integer)') IS NOT NULL;"
check_bool "function_mark_anchor_sync_anchored" "SELECT to_regprocedure('public.mark_anchor_sync_anchored(uuid,uuid,text,text,text)') IS NOT NULL;"
check_bool "function_complete_anchor_sync_operation" "SELECT to_regprocedure('public.complete_anchor_sync_operation(uuid,uuid,text)') IS NOT NULL;"
check_bool "function_repair_expired_anchor_sync_leases" "SELECT to_regprocedure('public.repair_expired_anchor_sync_leases(text)') IS NOT NULL;"
check_bool "index_anchor_sync_state_due" "SELECT to_regclass('public.idx_anchor_sync_operations_state_due') IS NOT NULL;"
check_bool "public_no_privs_anchor_sync_operations" "SELECT NOT (has_table_privilege('public','public.anchor_sync_operations','SELECT') OR has_table_privilege('public','public.anchor_sync_operations','INSERT') OR has_table_privilege('public','public.anchor_sync_operations','UPDATE') OR has_table_privilege('public','public.anchor_sync_operations','DELETE') OR has_table_privilege('public','public.anchor_sync_operations','TRUNCATE') OR has_table_privilege('public','public.anchor_sync_operations','REFERENCES') OR has_table_privilege('public','public.anchor_sync_operations','TRIGGER'));"

status="PASS"
if [[ ${#failures[@]} -gt 0 ]]; then
  status="FAIL"
fi

CHECKS_JOINED="$(printf '%s\n' "${checks[@]}")"
FAILURES_JOINED="$(printf '%s\n' "${failures[@]}")"

CHECKS_JOINED="$CHECKS_JOINED" FAILURES_JOINED="$FAILURES_JOINED" python3 - <<PY
import json
import os
from pathlib import Path

checks = [c for c in os.environ.get("CHECKS_JOINED", "").split("\n") if c]
failures = [c for c in os.environ.get("FAILURES_JOINED", "").split("\n") if c]

out = {
  "schema_version": "1.0",
  "check_id": "DB-ANCHOR-SYNC-OPERATIONAL-INVARIANT",
  "gate_id": "INT-G29",
  "invariant_id": "INV-113",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status": "${status}",
  "details": {
    "checks": checks,
    "failures": failures,
  },
}

Path("${EVIDENCE_FILE}").write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
PY

if [[ "$status" != "PASS" ]]; then
  echo "Anchor-sync operational invariant verification failed." >&2
  exit 1
fi

echo "Anchor-sync operational invariant verification OK. Evidence: $EVIDENCE_FILE"
