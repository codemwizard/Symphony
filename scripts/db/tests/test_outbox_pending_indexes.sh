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
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

echo "==> Outbox pending index test"

indexdef="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT indexdef FROM pg_indexes WHERE schemaname='public' AND indexname='idx_payment_outbox_pending_due_claim';"
)"

status="PASS"
if [[ -z "$indexdef" || "$indexdef" != *"(next_attempt_at"* || "$indexdef" != *"created_at"* ]]; then
  status="FAIL"
fi

python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "DB-OUTBOX-PENDING-INDEXES",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status": "$status",
  "indexdef": "$indexdef",
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

if [[ "$status" != "PASS" ]]; then
  echo "❌ Outbox pending index test failed"
  exit 1
fi

echo "✅ Outbox pending index test passed"
