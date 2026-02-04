#!/usr/bin/env bash
# ============================================================
# migrate.sh — Forward-only DB-MIG migration runner
# ============================================================
# Usage: scripts/db/migrate.sh
# Requires: DATABASE_URL environment variable
#
# Behavior:
# - Ensures public.schema_migrations exists
# - Applies new migrations in order (schema/migrations/*.sql)
# - Wraps each migration in its own transaction
# - Supports no-tx migrations via marker: -- symphony:no_tx
# - Records checksum in schema_migrations
# - Fails hard on checksum mismatch (immutability)
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIG_DIR="$ROOT_DIR/schema/migrations"

if [[ ! -d "$MIG_DIR" ]]; then
  echo "Migration directory not found: $MIG_DIR" >&2
  exit 1
fi

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<'SQL'
CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version TEXT PRIMARY KEY,
  checksum TEXT NOT NULL,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
REVOKE ALL ON TABLE public.schema_migrations FROM PUBLIC;
SQL

echo "🧭 Running migrations from: $MIG_DIR"

# Ensure stable ordering
mapfile -t files < <(ls -1 "$MIG_DIR"/*.sql 2>/dev/null | sort)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No migrations found in $MIG_DIR" >&2
  exit 1
fi

for file in "${files[@]}"; do
  version="$(basename "$file")"

  # sha256 checksum
  checksum="$(sha256sum "$file" | awk '{print $1}')"

  existing_checksum="$(psql "$DATABASE_URL" -X -t -A -v ON_ERROR_STOP=1 \
    -c "SELECT checksum FROM public.schema_migrations WHERE version = '$version'")"

  if [[ -n "$existing_checksum" ]]; then
    if [[ "$existing_checksum" != "$checksum" ]]; then
      echo "❌ Checksum mismatch for $version" >&2
      echo "   applied: $existing_checksum" >&2
      echo "   current: $checksum" >&2
      exit 1
    fi
    echo "✅ Skipping already applied migration: $version"
    continue
  fi

  echo "➡️  Applying migration: $version"

  no_tx=0
  # Marker must appear near the top to be unambiguous
  if head -n 50 "$file" | grep -Eq '^\s*--\s*symphony:no_tx\s*$' || grep -qiE "CREATE INDEX[[:space:]]+CONCURRENTLY" "$file"; then
    no_tx=1
  fi
  if [[ "$version" == *"concurrently"* ]]; then
    no_tx=1
  fi

  if [[ "$no_tx" -eq 1 ]]; then
    echo "   ↪ no-tx migration detected (-- symphony:no_tx / CONCURRENTLY / filename)."
    # Run outside explicit transaction (required for CONCURRENTLY).
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -f "$file"
    # Record migration after success (idempotent).
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X \
      -c "INSERT INTO public.schema_migrations(version, checksum) VALUES ('$version', '$checksum') ON CONFLICT (version) DO NOTHING;"

    existing_checksum="$(psql "$DATABASE_URL" -X -t -A -v ON_ERROR_STOP=1 \
      -c "SELECT checksum FROM public.schema_migrations WHERE version = '$version'")"
    if [[ -n "$existing_checksum" && "$existing_checksum" != "$checksum" ]]; then
      echo "❌ Checksum mismatch for $version after no-tx apply" >&2
      echo "   applied: $existing_checksum" >&2
      echo "   current: $checksum" >&2
      exit 1
    fi
  else
    # Apply inside a transaction; forbid top-level BEGIN/COMMIT in files via lint script
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X \
      -v version="$version" -v checksum="$checksum" -v file="$file" <<'SQL'
BEGIN;
\i :file
INSERT INTO public.schema_migrations(version, checksum) VALUES (:'version', :'checksum');
COMMIT;
SQL
  fi

  echo "✅ Applied: $version"
done

echo "🔎 Checking for invalid indexes..."
invalid_count="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT COUNT(*) FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND (i.indisvalid = false OR i.indisready = false);"
)"
if [[ "$invalid_count" != "0" ]]; then
  echo "❌ Invalid or unready indexes detected in public schema: $invalid_count" >&2
  exit 1
fi

echo "🏁 All migrations applied."
