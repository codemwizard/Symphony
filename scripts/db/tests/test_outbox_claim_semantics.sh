#!/usr/bin/env bash
# ============================================================
# test_outbox_claim_semantics.sh — Claim semantics tests
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

echo "==> Outbox claim semantics tests"

PASS=0
FAIL=0

run_test() {
  local name="$1"
  local sql="$2"
  echo -n "  $name: "
  if result=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -t -A -c "$sql" 2>&1); then
    if [[ "$result" == "PASS" ]]; then
      echo "✅ PASS"
      PASS=$((PASS+1))
    else
      echo "❌ FAIL (got: $result)"
      FAIL=$((FAIL+1))
    fi
  else
    echo "❌ ERROR: $result"
    FAIL=$((FAIL+1))
  fi
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/outbox_claim_semantics.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

# Clean pending (attempts table is append-only; do not delete attempts)
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "DELETE FROM public.payment_outbox_pending;"

instruction_id="test_claim_sem_$(date +%s%N)"
participant_id="test_claim_sem_participant"
idempotency_key="test_claim_sem_key_$(date +%s%N)"

# Create one row that is NOT due yet (next_attempt_at in the future); it must not be claimable.
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c \
  "SELECT (enqueue_payment_outbox('$instruction_id','$participant_id','$idempotency_key','TEST','{}'::jsonb)).outbox_id;"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c \
  "UPDATE public.payment_outbox_pending SET next_attempt_at = NOW() + INTERVAL '1 hour', lease_expires_at = NULL, claimed_by = NULL, lease_token = NULL;"

run_test "not due rows are not claimable" \
  "SELECT CASE WHEN (SELECT COUNT(*) FROM claim_outbox_batch(10, 'worker_claim_sem', 10)) = 0 THEN 'PASS' ELSE 'FAIL' END;"

# Make it due and verify a claim returns a row.
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c \
  "UPDATE public.payment_outbox_pending SET next_attempt_at = NOW() - INTERVAL '1 second', lease_expires_at = NULL, claimed_by = NULL, lease_token = NULL;"

run_test "due rows are claimable" \
  "SELECT CASE WHEN (SELECT COUNT(*) FROM claim_outbox_batch(10, 'worker_claim_sem', 10)) = 1 THEN 'PASS' ELSE 'FAIL' END;"

# Lease gating: if lease is not expired, the same row must not be claimable by another worker.
run_test "leased rows are not claimable until expiry" \
  "SELECT CASE WHEN (SELECT COUNT(*) FROM claim_outbox_batch(10, 'other_worker', 10)) = 0 THEN 'PASS' ELSE 'FAIL' END;"

# Structural (definitional) check: claim function must include SKIP LOCKED to preserve concurrency safety.
run_test "claim uses SKIP LOCKED (definitional)" \
  "SELECT CASE WHEN position('SKIP LOCKED' in upper(pg_get_functiondef('public.claim_outbox_batch(int,text,int)'::regprocedure))) > 0 THEN 'PASS' ELSE 'FAIL' END;"

echo ""
echo "Summary: $PASS passed, $FAIL failed"

status="PASS"
if [[ $FAIL -gt 0 ]]; then
  status="FAIL"
fi

python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "DB-OUTBOX-CLAIM-SEMANTICS",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status": "${status}",
  "tests_passed": $PASS,
  "tests_failed": $FAIL,
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2) + "\n")
PY

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
