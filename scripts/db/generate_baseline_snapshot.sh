#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DATE="${1:-$(date -u +%Y-%m-%d)}"
BASE_DIR="$ROOT_DIR/schema/baselines/$DATE"
CURRENT_DIR="$ROOT_DIR/schema/baselines/current"
BASELINE_OUT="$BASE_DIR/0001_baseline.sql"
BASELINE_CUR="$CURRENT_DIR/0001_baseline.sql"
BASELINE_CANON="$BASE_DIR/baseline.normalized.sql"
META_OUT="$BASE_DIR/baseline.meta.json"
CUTOFF_OUT="$BASE_DIR/baseline.cutoff"

mkdir -p "$BASE_DIR" "$CURRENT_DIR"

DUMP_CMD=(pg_dump "$DATABASE_URL" --schema-only --no-owner --no-privileges --no-comments --schema=public)
DUMP_SOURCE="host"
PG_DUMP_VERSION="unknown"
PG_SERVER_VERSION="unknown"

if command -v docker >/dev/null 2>&1; then
  pg_container="$(docker ps --format '{{.Names}}' | grep -E 'postgres' | head -n 1 || true)"
  if [[ -n "$pg_container" ]]; then
    DUMP_CMD=(docker exec "$pg_container" pg_dump "$DATABASE_URL" --schema-only --no-owner --no-privileges --no-comments --schema=public)
    DUMP_SOURCE="container:$pg_container"
    PG_DUMP_VERSION="$(docker exec "$pg_container" pg_dump --version 2>/dev/null || true)"
    PG_SERVER_VERSION="$(docker exec "$pg_container" psql "$DATABASE_URL" -t -A -X -c "SHOW server_version;" 2>/dev/null || true)"
  fi
fi

if [[ "$PG_DUMP_VERSION" == "unknown" ]]; then
  PG_DUMP_VERSION="$(pg_dump --version 2>/dev/null || true)"
fi
if [[ "$PG_SERVER_VERSION" == "unknown" ]]; then
  PG_SERVER_VERSION="$(psql "$DATABASE_URL" -t -A -X -c "SHOW server_version;" 2>/dev/null || true)"
fi

"${DUMP_CMD[@]}" > "$BASELINE_OUT"

# Keep current baseline pointers in sync
cp "$BASELINE_OUT" "$BASELINE_CUR"
cp "$BASELINE_OUT" "$ROOT_DIR/schema/baseline.sql"

# Canonicalize for deterministic hashing
"$ROOT_DIR/scripts/db/canonicalize_schema_dump.sh" "$BASELINE_OUT" "$BASELINE_CANON"

HASH="$(sha256sum "$BASELINE_CANON" | awk '{print $1}')"

# Baseline cutoff = latest migration filename (lexicographic)
CUTOFF="$(ls -1 "$ROOT_DIR/schema/migrations"/*.sql | sort | tail -n 1 | xargs basename)"
echo "$CUTOFF" > "$CUTOFF_OUT"
cp "$CUTOFF_OUT" "$CURRENT_DIR/baseline.cutoff"

python3 - <<PY
import json
from pathlib import Path
from datetime import datetime, timezone

out = {
  "baseline_date": "$DATE",
  "baseline_path": "$BASELINE_OUT",
  "baseline_cutoff": "$CUTOFF",
  "normalized_schema_sha256": "$HASH",
  "pg_dump_version": "$PG_DUMP_VERSION",
  "pg_server_version": "$PG_SERVER_VERSION",
  "dump_source": "$DUMP_SOURCE",
  "generated_at_utc": datetime.now(timezone.utc).isoformat()
}
Path("$META_OUT").write_text(json.dumps(out, indent=2))
Path("$CURRENT_DIR/baseline.meta.json").write_text(json.dumps(out, indent=2))
PY

echo "Baseline snapshot written: $BASELINE_OUT"
echo "Canonical hash: $HASH"
echo "Metadata: $META_OUT"
