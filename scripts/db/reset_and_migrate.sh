#!/usr/bin/env bash
# ============================================================
# reset_and_migrate.sh — Reset schema + apply migrations
# ============================================================
# Usage: scripts/db/reset_and_migrate.sh
# Requires: DATABASE_URL environment variable
#
# This script:
#   1. Drops and recreates the public schema
#   2. Runs the migration system (scripts/db/migrate.sh)
#
# Use for: Dev/CI only. Never use in staging/production.
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "💣 Resetting database schema (public)..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<'SQL'
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO PUBLIC;
SQL

echo "🧱 Applying migrations..."
"$SCRIPT_DIR/migrate.sh"

echo "✅ Reset + migrate complete."
