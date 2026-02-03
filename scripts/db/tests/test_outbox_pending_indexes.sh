#!/usr/bin/env bash
# ============================================================
# test_outbox_pending_indexes.sh — Verify due-claim index
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/outbox_pending_indexes.json"
mkdir -p "$EVIDENCE_DIR"

echo "==> Outbox pending index test"

indexdef="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT indexdef FROM pg_indexes WHERE schemaname='public' AND indexname='idx_payment_outbox_pending_due_claim';"
)"

status="pass"
if [[ -z "$indexdef" || "$indexdef" != *"(next_attempt_at"* || "$indexdef" != *"created_at"* ]]; then
  status="fail"
fi

python3 - <<PY
import json
from pathlib import Path
out = {"status": "$status", "indexdef": "$indexdef"}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

if [[ "$status" != "pass" ]]; then
  echo "❌ Outbox pending index test failed"
  exit 1
fi

echo "✅ Outbox pending index test passed"
