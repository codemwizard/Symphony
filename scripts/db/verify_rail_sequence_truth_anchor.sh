#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/rail_sequence_truth_anchor.json"

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

check_bool "table_rail_dispatch_truth_anchor" "SELECT to_regclass('public.rail_dispatch_truth_anchor') IS NOT NULL;"
check_bool "constraint_attempt_fk" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='rail_truth_anchor_attempt_fk' AND conrelid='public.rail_dispatch_truth_anchor'::regclass);"
check_bool "constraint_state_chk" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='rail_truth_anchor_state_chk' AND conrelid='public.rail_dispatch_truth_anchor'::regclass);"
check_bool "constraint_attempt_unique" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='ux_rail_truth_anchor_attempt_id' AND conrelid='public.rail_dispatch_truth_anchor'::regclass);"
check_bool "constraint_sequence_scope_unique" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='ux_rail_truth_anchor_sequence_scope' AND conrelid='public.rail_dispatch_truth_anchor'::regclass);"
check_bool "trigger_anchor_dispatched_outbox_attempt" "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_anchor_dispatched_outbox_attempt');"
check_bool "trigger_deny_rail_dispatch_truth_anchor_mutation" "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_deny_rail_dispatch_truth_anchor_mutation');"
check_bool "function_anchor_dispatched_outbox_attempt" "SELECT to_regprocedure('public.anchor_dispatched_outbox_attempt()') IS NOT NULL;"
check_bool "public_no_privs_rail_dispatch_truth_anchor" "SELECT NOT (has_table_privilege('public','public.rail_dispatch_truth_anchor','SELECT') OR has_table_privilege('public','public.rail_dispatch_truth_anchor','INSERT') OR has_table_privilege('public','public.rail_dispatch_truth_anchor','UPDATE') OR has_table_privilege('public','public.rail_dispatch_truth_anchor','DELETE') OR has_table_privilege('public','public.rail_dispatch_truth_anchor','TRUNCATE') OR has_table_privilege('public','public.rail_dispatch_truth_anchor','REFERENCES') OR has_table_privilege('public','public.rail_dispatch_truth_anchor','TRIGGER'));"

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
  "check_id": "DB-RAIL-SEQUENCE-TRUTH-ANCHOR",
  "gate_id": "INT-G27",
  "invariant_id": "INV-116",
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
  echo "Rail sequence truth-anchor verification failed." >&2
  exit 1
fi

echo "Rail sequence truth-anchor verification OK. Evidence: $EVIDENCE_FILE"
