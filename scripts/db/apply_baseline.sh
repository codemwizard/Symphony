#!/usr/bin/env bash
# ============================================================
# apply_baseline.sh — Apply baseline schema to fresh database
# ============================================================
# Usage: scripts/db/apply_baseline.sh
# Requires: DATABASE_URL environment variable
#
# NOTE: This applies baseline.sql directly. For fresh DB only.
# For existing DBs, use scripts/db/migrate.sh instead.
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

# Resolve script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🧱 Applying baseline schema..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -f "$REPO_ROOT/schema/baseline.sql"

echo "✅ Baseline applied."
