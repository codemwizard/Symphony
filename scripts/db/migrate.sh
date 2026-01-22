#!/usr/bin/env bash
# ============================================================
# migrate.sh — Industry-standard forward-only migration runner
# ============================================================
# Usage: scripts/db/migrate.sh
# Requires: DATABASE_URL environment variable
#
# Features:
#   - Ledger table (public.schema_migrations)
#   - Ordered application (0001_*.sql, 0002_*.sql, etc.)
#   - Checksum immutability enforcement
#   - Transaction-per-migration
#
# Contract:
#   - Migrations are applied forward-only
#   - Once applied, migrations are immutable (checksum enforced)
#   - Re-running safely skips already-applied migrations
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIG_DIR="${MIG_DIR:-$REPO_ROOT/schema/migrations}"

if [ ! -d "$MIG_DIR" ]; then
  echo "::error::Migration directory not found: $MIG_DIR"
  exit 1
fi

echo "🗃️  Running migrations from: $MIG_DIR"

# ------------------------------------------------------------
# Ensure ledger table exists (idempotent)
# ------------------------------------------------------------
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<'SQL'
CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version          TEXT PRIMARY KEY,
  description      TEXT NOT NULL,
  checksum_sha256  TEXT NOT NULL,
  applied_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.schema_migrations IS
  'Migration ledger: tracks applied migrations with checksums for immutability enforcement.';
SQL

# ------------------------------------------------------------
# Collect and sort migration files
# ------------------------------------------------------------
shopt -s nullglob
FILES=("$MIG_DIR"/*.sql)

if [ ${#FILES[@]} -eq 0 ]; then
  echo "⚠️  No migration files found in $MIG_DIR"
  echo "✅ Nothing to apply."
  exit 0
fi

# Sort lexicographically for deterministic ordering
IFS=$'\n' FILES_SORTED=($(printf "%s\n" "${FILES[@]}" | sort))
unset IFS

# ------------------------------------------------------------
# Apply migrations in order
# ------------------------------------------------------------
APPLIED_COUNT=0
SKIPPED_COUNT=0

for file in "${FILES_SORTED[@]}"; do
  base="$(basename "$file")"

  # Validate filename format: NNNN_description.sql
  if [[ "$base" != *.sql ]] || [[ "$base" != *_* ]]; then
    echo "::error::Invalid migration filename: $base (expected NNNN_description.sql)"
    exit 1
  fi

  version="${base%%_*}"
  desc="${base#*_}"
  desc="${desc%.sql}"

  # Validate version prefix is numeric (4+ digits)
  if ! [[ "$version" =~ ^[0-9]{4,}$ ]]; then
    echo "::error::Invalid migration version prefix in: $base (expected 4+ digits like 0001)"
    exit 1
  fi

  # Compute SHA-256 checksum
  checksum="$(sha256sum "$file" | awk '{print $1}')"

  # Check if already applied
  applied_checksum="$(
    psql "$DATABASE_URL" -tA -X -v ON_ERROR_STOP=1 \
      -c "SELECT checksum_sha256 FROM public.schema_migrations WHERE version = '$version';" 2>/dev/null || echo ""
  )"

  if [ -n "$applied_checksum" ]; then
    # Already applied — verify checksum hasn't changed
    if [ "$applied_checksum" != "$checksum" ]; then
      echo "::error::Checksum mismatch for applied migration: $base"
      echo "  Applied checksum: $applied_checksum"
      echo "  Current checksum: $checksum"
      echo ""
      echo "Migrations are immutable once applied."
      echo "To fix: create a new migration instead of editing this one."
      exit 1
    fi
    echo "⏭️  Skipping already-applied: $base"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  echo "➡️  Applying: $base"

  # Apply migration in a transaction
  # Note: CREATE INDEX CONCURRENTLY cannot run in a transaction.
  # For those, use a *_notx.sql naming convention (future enhancement).
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<SQL
BEGIN;
\i $file
INSERT INTO public.schema_migrations(version, description, checksum_sha256)
VALUES ('$version', '$desc', '$checksum');
COMMIT;
SQL

  echo "✅ Applied: $base"
  APPLIED_COUNT=$((APPLIED_COUNT + 1))
done

echo ""
echo "🎉 Migrations complete."
echo "   Applied: $APPLIED_COUNT"
echo "   Skipped: $SKIPPED_COUNT"
