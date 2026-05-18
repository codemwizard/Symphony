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

compute_privilege_snapshot_json() {
  psql "$1" -X -A -t -q -c "
WITH privilege_rows AS (
  SELECT 'relation'::text AS object_type,
         table_schema AS schema_name,
         table_name AS object_name,
         grantee,
         privilege_type,
         (is_grantable = 'YES') AS is_grantable
  FROM information_schema.role_table_grants
  WHERE table_schema = 'public'
  UNION ALL
  SELECT 'function'::text AS object_type,
         routine_schema AS schema_name,
         routine_name AS object_name,
         grantee,
         privilege_type,
         (is_grantable = 'YES') AS is_grantable
  FROM information_schema.role_routine_grants
  WHERE routine_schema = 'public'
)
SELECT COALESCE(
  json_agg(privilege_rows ORDER BY object_type, schema_name, object_name, grantee, privilege_type, is_grantable)::text,
  '[]'
)
FROM privilege_rows;
"
}

DUMP_CMD=(pg_dump "$DATABASE_URL" --schema-only --no-owner --no-privileges --no-comments --schema=public)
DUMP_SOURCE="host"
PG_DUMP_VERSION="unknown"
PG_SERVER_VERSION="unknown"

if command -v docker >/dev/null 2>&1; then
  pg_container="$(docker ps --format '{{.Names}}' | grep -E 'postgres' | head -n 1 || true)"
  if [[ -n "$pg_container" ]]; then
    DB_URL_IN_CONTAINER="$(python3 - <<'PY' "$DATABASE_URL"
import sys
from urllib.parse import urlparse, urlunparse
u = urlparse(sys.argv[1])
host = (u.hostname or "").strip().lower()
if host in {"localhost", "127.0.0.1", "::1"}:
    host_out = "localhost"
    port_out = 5432
    userinfo = ""
    if u.username:
        userinfo = u.username
        if u.password is not None:
            userinfo += f":{u.password}"
        userinfo += "@"
    netloc = f"{userinfo}{host_out}:{port_out}"
    u = u._replace(netloc=netloc)
print(urlunparse(u))
PY
)"
    DUMP_CMD=(docker exec "$pg_container" pg_dump "$DB_URL_IN_CONTAINER" --schema-only --no-owner --no-privileges --no-comments --schema=public)
    DUMP_SOURCE="container:$pg_container"
    PG_DUMP_VERSION="$(docker exec "$pg_container" pg_dump --version 2>/dev/null || true)"
    PG_SERVER_VERSION="$(docker exec "$pg_container" psql "$DB_URL_IN_CONTAINER" -t -A -X -c "SHOW server_version;" 2>/dev/null || true)"
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
PRIVILEGE_JSON="$(compute_privilege_snapshot_json "$DATABASE_URL")"
PRIVILEGE_HASH="$(printf '%s' "$PRIVILEGE_JSON" | sha256sum | awk '{print $1}')"
PRIVILEGE_JSON_TMP="$(mktemp)"
trap 'rm -f "$PRIVILEGE_JSON_TMP"' EXIT
printf '%s' "$PRIVILEGE_JSON" > "$PRIVILEGE_JSON_TMP"
PRIVILEGE_COUNT="$(python3 - <<'PY' "$PRIVILEGE_JSON_TMP"
import json, sys
from pathlib import Path
print(len(json.loads(Path(sys.argv[1]).read_text())))
PY
)"

# Baseline cutoff = latest migration filename (lexicographic)
CUTOFF="$(ls -1 "$ROOT_DIR/schema/migrations"/*.sql | sort | tail -n 1 | xargs basename)"
echo "$CUTOFF" > "$CUTOFF_OUT"
cp "$CUTOFF_OUT" "$CURRENT_DIR/baseline.cutoff"

python3 - <<PY
import json
from pathlib import Path
from datetime import datetime, timezone
privilege_state = json.loads(Path("$PRIVILEGE_JSON_TMP").read_text())

out = {
  "baseline_date": "$DATE",
  "baseline_path": "$BASELINE_OUT",
  "baseline_cutoff": "$CUTOFF",
  "normalized_schema_sha256": "$HASH",
  "privilege_state_sha256": "$PRIVILEGE_HASH",
  "privilege_entry_count": int("$PRIVILEGE_COUNT"),
  "privilege_state": privilege_state,
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
