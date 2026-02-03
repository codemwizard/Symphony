#!/usr/bin/env bash
# ============================================================
# test_no_tx_migrations.sh — Validate no-tx marker handling
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/no_tx_migrations.json"
mkdir -p "$EVIDENCE_DIR"

echo "==> No-tx migration test"

# Unit check: marker detection must match no-tx migration files
if ! grep -qE '^[[:space:]]*--[[:space:]]*symphony:no_tx' \
  "$ROOT_DIR/schema/migrations/0013_outbox_pending_indexes_concurrently.sql"; then
  echo "❌ No-tx marker not detected in 0013_outbox_pending_indexes_concurrently.sql" >&2
  exit 1
fi

# Ensure migrations are applied (idempotent)
"$ROOT_DIR/scripts/db/migrate.sh"

applied="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT EXISTS (SELECT 1 FROM public.schema_migrations WHERE version = '0013_outbox_pending_indexes_concurrently.sql');"
)"

index_exists="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='idx_payment_outbox_pending_due_claim');"
)"

status="pass"
if [[ "$applied" != "t" || "$index_exists" != "t" ]]; then
  status="fail"
fi

python3 - <<PY
import json
from pathlib import Path
out = {"status": "$status", "migration_applied": "$applied", "index_exists": "$index_exists"}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

if [[ "$status" != "pass" ]]; then
  echo "❌ No-tx migration test failed"
  exit 1
fi

echo "✅ No-tx migration test passed"
