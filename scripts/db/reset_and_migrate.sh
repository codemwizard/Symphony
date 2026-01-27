#!/usr/bin/env bash
# ============================================================
# reset_and_migrate.sh — Reset schema + apply migrations
# ============================================================
# Usage: scripts/db/reset_and_migrate.sh
# Requires: DATABASE_URL environment variable
#
# Dev/CI ONLY. Never use in staging/production.
# Posture: PUBLIC has NO CREATE on schema public (no runtime DDL).
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "💣 Resetting database schema (public)..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<'SQL'
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- Hardening: PUBLIC must not have CREATE on schema public.
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
SQL

echo "🧱 Applying migrations..."
"$SCRIPT_DIR/migrate.sh"

echo "✅ Reset + migrate complete."
