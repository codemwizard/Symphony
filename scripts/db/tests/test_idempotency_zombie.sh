#!/usr/bin/env bash
# ============================================================
# test_idempotency_zombie.sh — Idempotency + zombie replay test
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

echo "==> Idempotency zombie simulation"

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

instruction_id="test_zombie_$(date +%s%N)"
participant_id="test_zombie_participant"
idempotency_key="test_zombie_key_$(date +%s%N)"
rail_type="TEST"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/idempotency_zombie.json"
mkdir -p "$EVIDENCE_DIR"

# Clean pending (append-only attempts must not be deleted)
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "DELETE FROM public.payment_outbox_pending;"

# Enqueue twice
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c \
  "SELECT (enqueue_payment_outbox('$instruction_id','$participant_id','$idempotency_key','$rail_type','{}'::jsonb)).outbox_id;"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c \
  "SELECT (enqueue_payment_outbox('$instruction_id','$participant_id','$idempotency_key','$rail_type','{}'::jsonb)).outbox_id;"

# 1) Idempotency check (pending count == 1, attempts == 0)
run_test "enqueue is idempotent" \
  "SELECT CASE WHEN (SELECT COUNT(*) FROM public.payment_outbox_pending WHERE instruction_id = '$instruction_id' AND idempotency_key = '$idempotency_key') = 1
        AND (SELECT COUNT(*) FROM public.payment_outbox_attempts WHERE instruction_id = '$instruction_id' AND idempotency_key = '$idempotency_key') = 0
        THEN 'PASS' ELSE 'FAIL' END;"

# 2) Claim with short lease (must return 1 row)
run_test "claim_outbox_batch returns row" \
  "SELECT CASE WHEN (SELECT COUNT(*) FROM claim_outbox_batch(1, 'worker_a', 1)) = 1 THEN 'PASS' ELSE 'FAIL' END;"

# 3) Sleep to expire lease
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "SELECT pg_sleep(3);"

# 4) Repair expired leases; should append zombie attempt and requeue
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "SELECT * FROM repair_expired_leases(10, 'reaper');"

run_test "repair_expired_leases appends attempt" \
  "SELECT CASE WHEN (SELECT COUNT(*) FROM public.payment_outbox_attempts WHERE instruction_id = '$instruction_id' AND state = 'ZOMBIE_REQUEUE') >= 1
        AND (SELECT COUNT(*) FROM public.payment_outbox_pending WHERE instruction_id = '$instruction_id') = 1
        THEN 'PASS' ELSE 'FAIL' END;"

# 5) Re-enqueue after zombie should still be idempotent (same outbox_id)
run_test "re-enqueue after zombie is idempotent" \
  "WITH existing AS (SELECT outbox_id FROM public.payment_outbox_pending WHERE instruction_id = '$instruction_id'),
        again AS (SELECT (enqueue_payment_outbox('$instruction_id','$participant_id','$idempotency_key','$rail_type','{}'::jsonb)).outbox_id AS id)
   SELECT CASE WHEN (SELECT outbox_id FROM existing) = (SELECT id FROM again)
        THEN 'PASS' ELSE 'FAIL' END;"

# Summary

echo ""
echo "Summary: $PASS passed, $FAIL failed"

if [[ $FAIL -gt 0 ]]; then
  echo "exit code 1"
  exit 1
fi

python3 - <<PY
import json
from pathlib import Path
out = {"status": "pass", "tests_passed": $PASS, "tests_failed": $FAIL}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

echo "exit code 0"
