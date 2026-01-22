#!/usr/bin/env bash
# ============================================================
# reset_db.sh — Drop/recreate public schema + apply baseline
# ============================================================
# Usage: scripts/db/reset_db.sh
# Requires: DATABASE_URL environment variable
#
# WARNING: This script destroys all data. Dev/CI only.
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

# Resolve script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "💣 Resetting database schema (public)..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<'SQL'
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO PUBLIC;
SQL

echo "🧱 Applying baseline..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -f "$REPO_ROOT/schema/baseline.sql"

echo "✅ Reset complete."
