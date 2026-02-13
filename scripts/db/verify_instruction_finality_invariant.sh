#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/instruction_finality_invariant.json"

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

check_bool "table_instruction_settlement_finality" "SELECT to_regclass('public.instruction_settlement_finality') IS NOT NULL;"
check_bool "col_instruction_id" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='instruction_settlement_finality' AND column_name='instruction_id' AND is_nullable='NO');"
check_bool "col_final_state" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='instruction_settlement_finality' AND column_name='final_state' AND is_nullable='NO');"
check_bool "col_reversal_of_instruction_id" "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='instruction_settlement_finality' AND column_name='reversal_of_instruction_id');"
check_bool "constraint_reversal_fk" "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='instruction_settlement_finality_reversal_fk' AND conrelid='public.instruction_settlement_finality'::regclass);"
check_bool "index_one_reversal_per_original" "SELECT to_regclass('public.ux_instruction_settlement_finality_one_reversal_per_original') IS NOT NULL;"
check_bool "trigger_enforce_reversal_source" "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_enforce_instruction_reversal_source');"
check_bool "trigger_deny_final_mutation" "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_deny_final_instruction_mutation');"
check_bool "function_enforce_reversal_source" "SELECT to_regprocedure('public.enforce_instruction_reversal_source()') IS NOT NULL;"
check_bool "function_deny_final_mutation" "SELECT to_regprocedure('public.deny_final_instruction_mutation()') IS NOT NULL;"
check_bool "public_no_privs_instruction_settlement_finality" "SELECT NOT (has_table_privilege('public','public.instruction_settlement_finality','SELECT') OR has_table_privilege('public','public.instruction_settlement_finality','INSERT') OR has_table_privilege('public','public.instruction_settlement_finality','UPDATE') OR has_table_privilege('public','public.instruction_settlement_finality','DELETE') OR has_table_privilege('public','public.instruction_settlement_finality','TRUNCATE') OR has_table_privilege('public','public.instruction_settlement_finality','REFERENCES') OR has_table_privilege('public','public.instruction_settlement_finality','TRIGGER'));"

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
  "check_id": "DB-INSTRUCTION-FINALITY-INVARIANT",
  "gate_id": "INT-G25",
  "invariant_id": "INV-114",
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
  echo "Instruction finality invariant verification failed." >&2
  exit 1
fi

echo "Instruction finality invariant verification OK. Evidence: $EVIDENCE_FILE"
