#!/usr/bin/env bash
# ============================================================
# smoke_baseline.sh — Minimal schema smoke test
# ============================================================
# Usage: scripts/db/smoke_baseline.sh
# Requires: DATABASE_URL environment variable
# ============================================================
set -euo pipefail
: "${DATABASE_URL:?DATABASE_URL is required}"

echo "🔍 Smoke test: checking core tables exist..."
psql "$DATABASE_URL" -tA -X -v ON_ERROR_STOP=1 <<'SQL'
SELECT 'payment_outbox_pending' WHERE EXISTS (
  SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_outbox_pending'
);
SELECT 'payment_outbox_attempts' WHERE EXISTS (
  SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_outbox_attempts'
);
SELECT 'schema_migrations' WHERE EXISTS (
  SELECT 1 FROM information_schema.tables WHERE table_name = 'schema_migrations'
);
SQL

echo "✅ Smoke test passed."
