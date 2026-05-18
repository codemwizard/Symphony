#!/usr/bin/env bash
# ============================================================
# migrate.sh — Forward-only DB-MIG migration runner
# ============================================================
# Usage: scripts/db/migrate.sh
# Requires: DATABASE_URL environment variable
#
# Behavior:
# - Ensures public.schema_migrations exists when required by the selected strategy
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
STRATEGY="${SCHEMA_MIGRATION_STRATEGY:-migrations}"
BASELINE_PATH="${SCHEMA_BASELINE_PATH:-$ROOT_DIR/schema/baselines/current/0001_baseline.sql}"
BASELINE_CUTOFF="${SCHEMA_BASELINE_CUTOFF:-}"
if [[ -z "$BASELINE_CUTOFF" && -f "$ROOT_DIR/schema/baselines/current/baseline.cutoff" ]]; then
  BASELINE_CUTOFF="$(cat "$ROOT_DIR/schema/baselines/current/baseline.cutoff" | tr -d '\n' || true)"
fi

if [[ ! -d "$MIG_DIR" ]]; then
  echo "Migration directory not found: $MIG_DIR" >&2
  exit 1
fi

if [[ "$STRATEGY" != "migrations" ]]; then
  if [[ ! -f "$BASELINE_PATH" ]]; then
    echo "Baseline file not found: $BASELINE_PATH" >&2
    exit 1
  fi
fi

ensure_schema_migrations_table() {
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<'SQL'
CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version TEXT PRIMARY KEY,
  checksum TEXT NOT NULL,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
REVOKE ALL ON TABLE public.schema_migrations FROM PUBLIC;
SQL
}

schema_migrations_exists() {
  psql "$DATABASE_URL" -X -t -A -v ON_ERROR_STOP=1 \
    -c "SELECT CASE WHEN to_regclass('public.schema_migrations') IS NULL THEN 0 ELSE 1 END;"
}

schema_migrations_count() {
  if [[ "$(schema_migrations_exists)" == "1" ]]; then
    psql "$DATABASE_URL" -X -t -A -v ON_ERROR_STOP=1 \
      -c "SELECT COUNT(*) FROM public.schema_migrations"
  else
    echo "0"
  fi
}

schema_migration_checksum() {
  local version="$1"
  if [[ "$(schema_migrations_exists)" == "1" ]]; then
    psql "$DATABASE_URL" -X -t -A -v ON_ERROR_STOP=1 \
      -c "SELECT COALESCE((SELECT checksum FROM public.schema_migrations WHERE version = '$version'), '')"
  else
    printf ''
  fi
}

apply_baseline_file() {
  sed '/^CREATE SCHEMA public;$/d' "$BASELINE_PATH" | \
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X
}

ensure_baseline_extensions() {
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<'SQL'
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public;
SQL
}

if [[ "$STRATEGY" == "migrations" ]]; then
  ensure_schema_migrations_table
fi

echo "🧭 Running migrations from: $MIG_DIR"

# Ensure stable ordering
mapfile -t files < <(ls -1 "$MIG_DIR"/*.sql 2>/dev/null | sort)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No migrations found in $MIG_DIR" >&2
  exit 1
fi

if [[ "$STRATEGY" == "baseline" || "$STRATEGY" == "baseline_then_migrations" ]]; then
  echo "🧱 Baseline strategy: $STRATEGY"
  baseline_version="baseline@$(basename "$(dirname "$BASELINE_PATH")")"
  baseline_checksum="$(sha256sum "$BASELINE_PATH" | awk '{print $1}')"

  existing_count="$(schema_migrations_count)"
  if [[ "$existing_count" != "0" && "${ALLOW_BASELINE_ON_NONEMPTY:-0}" != "1" ]]; then
    echo "❌ Baseline strategy requires an empty schema_migrations table (set ALLOW_BASELINE_ON_NONEMPTY=1 to override)" >&2
    exit 1
  fi

  existing_checksum="$(schema_migration_checksum "$baseline_version")"

  if [[ -n "$existing_checksum" ]]; then
    if [[ "$existing_checksum" != "$baseline_checksum" ]]; then
      echo "❌ Baseline checksum mismatch for $baseline_version" >&2
      echo "   applied: $existing_checksum" >&2
      echo "   current: $baseline_checksum" >&2
      exit 1
    fi
    echo "✅ Baseline already applied: $baseline_version"
  else
    echo "➡️  Applying baseline: $baseline_version"
    ensure_baseline_extensions
    apply_baseline_file
    ensure_schema_migrations_table
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X \
      -c "INSERT INTO public.schema_migrations(version, checksum) VALUES ('$baseline_version', '$baseline_checksum');"
    echo "✅ Baseline applied: $baseline_version"
  fi

  if [[ "$STRATEGY" == "baseline" ]]; then
    echo "🏁 Baseline-only strategy complete."
    exit 0
  fi
fi

for file in "${files[@]}"; do
  version="$(basename "$file")"

  if [[ "$STRATEGY" == "baseline_then_migrations" && -n "$BASELINE_CUTOFF" ]]; then
    if [[ "$version" < "$BASELINE_CUTOFF" || "$version" == "$BASELINE_CUTOFF" ]]; then
      echo "⏭️  Skipping pre-baseline migration: $version"
      continue
    fi
  fi

  # sha256 checksum
  checksum="$(sha256sum "$file" | awk '{print $1}')"

  existing_checksum="$(schema_migration_checksum "$version")"

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
  # Marker must appear near the top to be unambiguous (strip UTF-8 BOM if present)
  if head -n 50 "$file" | sed '1s/^\xEF\xBB\xBF//' | grep -Eq '^[[:space:]]*--[[:space:]]*symphony:no_tx' || grep -qiE "CREATE INDEX[[:space:]]+CONCURRENTLY" "$file"; then
    no_tx=1
  fi
  if [[ "$version" == *"concurrently"* ]]; then
    no_tx=1
  fi

  # Hard fail if a CONCURRENTLY migration would run inside a transaction
  echo "MIGRATE: $version no_tx=$no_tx file=$file"

  if grep -qiE "CREATE INDEX[[:space:]]+CONCURRENTLY" "$file" && [[ "$no_tx" -ne 1 ]]; then
    echo "❌ CONCURRENTLY detected but no-tx not set for $version" >&2
    exit 1
  fi

  if [[ "$no_tx" -eq 1 ]]; then
    echo "   ↪ no-tx migration detected (-- symphony:no_tx / CONCURRENTLY / filename)."
    # Run outside explicit transaction (required for CONCURRENTLY).
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -f "$file"
    # Record migration after success (idempotent).
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X \
      -c "INSERT INTO public.schema_migrations(version, checksum) VALUES ('$version', '$checksum') ON CONFLICT (version) DO NOTHING;"

    existing_checksum="$(schema_migration_checksum "$version")"
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
