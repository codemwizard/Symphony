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

TMP_INFO="$(
  ROOT_DIR="$ROOT_DIR" DATABASE_URL="$DATABASE_URL" python3 - <<'PY'
import os
import time
from urllib.parse import urlparse, urlunparse

url = os.environ["DATABASE_URL"]
root = os.environ["ROOT_DIR"]
parts = urlparse(url)
db_name = parts.path.lstrip("/") or "postgres"
temp_db = f"symphony_test_no_tx_{int(time.time())}"

def with_db(db: str) -> str:
    return urlunparse(parts._replace(path=f"/{db}"))

temp_url = with_db(temp_db)
admin_url = with_db("postgres")
print(temp_db)
print(temp_url)
print(admin_url)
PY
)"

TEMP_DB="$(echo "$TMP_INFO" | sed -n '1p')"
TEMP_URL="$(echo "$TMP_INFO" | sed -n '2p')"
ADMIN_URL="$(echo "$TMP_INFO" | sed -n '3p')"

cleanup() {
  psql "$ADMIN_URL" -X -v ON_ERROR_STOP=1 -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$TEMP_DB' AND pid <> pg_backend_pid();" >/dev/null 2>&1 || true
  psql "$ADMIN_URL" -X -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS \"$TEMP_DB\";" >/dev/null 2>&1 || true
}
trap cleanup EXIT

psql "$ADMIN_URL" -X -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$TEMP_DB\" TEMPLATE template0;" >/dev/null 2>&1 || \
psql "$ADMIN_URL" -X -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$TEMP_DB\";" >/dev/null

# Run migrations against a throwaway DB to ensure CONCURRENTLY path is exercised
DATABASE_URL="$TEMP_URL" "$ROOT_DIR/scripts/db/migrate.sh"

applied="$(
  psql "$TEMP_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT EXISTS (SELECT 1 FROM public.schema_migrations WHERE version = '0013_outbox_pending_indexes_concurrently.sql');"
)"

index_exists="$(
  psql "$TEMP_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='idx_payment_outbox_pending_due_claim');"
)"

index_validity="$(
  psql "$TEMP_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT indexrelid::regclass::text || '|' || indisvalid || '|' || indisready FROM pg_index JOIN pg_class ON pg_class.oid=indexrelid WHERE relname = 'idx_payment_outbox_pending_due_claim';"
)"

status="pass"
if [[ "$applied" != "t" || "$index_exists" != "t" ]]; then
  status="fail"
fi
if [[ -z "$index_validity" || "$index_validity" != *"|t|t" ]]; then
  status="fail"
fi

python3 - <<PY
import json
from pathlib import Path
out = {
  "status": "$status",
  "migration_applied": "$applied",
  "index_exists": "$index_exists",
  "index_validity": "$index_validity",
  "temp_db": "$TEMP_DB"
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

if [[ "$status" != "pass" ]]; then
  echo "❌ No-tx migration test failed"
  exit 1
fi

echo "✅ No-tx migration test passed"
