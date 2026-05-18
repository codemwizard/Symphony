#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASELINE="$ROOT_DIR/schema/baseline.sql"
if [[ -f "$ROOT_DIR/schema/baselines/current/0001_baseline.sql" ]]; then
  BASELINE="$ROOT_DIR/schema/baselines/current/0001_baseline.sql"
fi
CANON_SCRIPT="$ROOT_DIR/scripts/db/canonicalize_schema_dump.sh"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/baseline_drift.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

if [[ ! -f "$BASELINE" ]]; then
  echo "Missing baseline: $BASELINE" >&2
  exit 1
fi

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is required" >&2
  exit 1
fi

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

# Normalize baseline (canonicalize for deterministic diff)
if [[ ! -x "$CANON_SCRIPT" ]]; then
  echo "Missing canonicalizer: $CANON_SCRIPT" >&2
  exit 1
fi
"$CANON_SCRIPT" "$BASELINE" "/tmp/symphony_baseline_norm.sql"
BASELINE_HASH="$(sha256sum /tmp/symphony_baseline_norm.sql | awk '{print $1}')"

# Prefer pg_dump from a running DB container to avoid version mismatch
DUMP_CMD=(pg_dump "$DATABASE_URL" --schema-only --no-owner --no-privileges --no-comments --schema=public)
DUMP_SOURCE="host"
PG_DUMP_VERSION="$(pg_dump --version 2>/dev/null || true)"
PG_SERVER_VERSION="$(psql "$DATABASE_URL" -t -A -X -c "SHOW server_version;" 2>/dev/null || true)"

if command -v docker >/dev/null 2>&1; then
  pg_container="$(docker ps --format '{{.Names}}' | grep -E 'postgres' | head -n 1 || true)"
  if [[ -n "$pg_container" ]]; then
    DB_URL_IN_CONTAINER="$(python3 - <<'PY' "$DATABASE_URL"
import sys
from urllib.parse import urlparse, urlunparse
u = urlparse(sys.argv[1])
host = (u.hostname or "").strip().lower()
if host in {"localhost", "127.0.0.1", "::1"}:
    # Inside the postgres container, connect to local postmaster port.
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

"${DUMP_CMD[@]}" > /tmp/symphony_schema_dump_raw.sql
"$CANON_SCRIPT" "/tmp/symphony_schema_dump_raw.sql" "/tmp/symphony_schema_dump.sql"
DUMP_HASH="$(sha256sum /tmp/symphony_schema_dump.sql | awk '{print $1}')"
CURRENT_PRIVILEGE_JSON="$(compute_privilege_snapshot_json "$DATABASE_URL")"
CURRENT_PRIVILEGE_HASH="$(printf '%s' "$CURRENT_PRIVILEGE_JSON" | sha256sum | awk '{print $1}')"
BASELINE_PRIVILEGE_HASH="$(python3 - <<'PY' "$ROOT_DIR/schema/baselines/current/baseline.meta.json"
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
if not p.exists():
    print("")
else:
    print(json.loads(p.read_text()).get("privilege_state_sha256", ""))
PY
)"

SCHEMA_DRIFT=0
PRIVILEGE_DRIFT=0
if ! diff -q /tmp/symphony_baseline_norm.sql /tmp/symphony_schema_dump.sql >/dev/null; then
  SCHEMA_DRIFT=1
fi
if [[ -z "$BASELINE_PRIVILEGE_HASH" || "$BASELINE_PRIVILEGE_HASH" != "$CURRENT_PRIVILEGE_HASH" ]]; then
  PRIVILEGE_DRIFT=1
fi

if [[ "$SCHEMA_DRIFT" -ne 0 || "$PRIVILEGE_DRIFT" -ne 0 ]]; then
  python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "DB-BASELINE-DRIFT",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status":"FAIL",
  "reason":"baseline drift",
  "schema_drift": bool($SCHEMA_DRIFT),
  "privilege_drift": bool($PRIVILEGE_DRIFT),
  "baseline_path":"$BASELINE",
  "baseline_hash":"$BASELINE_HASH",
  "current_hash":"$DUMP_HASH",
  "baseline_privilege_hash":"$BASELINE_PRIVILEGE_HASH",
  "current_privilege_hash":"$CURRENT_PRIVILEGE_HASH",
  "pg_dump_version":"$PG_DUMP_VERSION",
  "pg_server_version":"$PG_SERVER_VERSION",
  "dump_source":"$DUMP_SOURCE"
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY
  echo "Baseline drift detected" >&2
  exit 1
fi

python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "DB-BASELINE-DRIFT",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status":"PASS",
  "baseline_path":"$BASELINE",
  "baseline_hash":"$BASELINE_HASH",
  "current_hash":"$DUMP_HASH",
  "baseline_privilege_hash":"$BASELINE_PRIVILEGE_HASH",
  "current_privilege_hash":"$CURRENT_PRIVILEGE_HASH",
  "pg_dump_version":"$PG_DUMP_VERSION",
  "pg_server_version":"$PG_SERVER_VERSION",
  "dump_source":"$DUMP_SOURCE"
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

echo "Baseline drift check passed. Evidence: $EVIDENCE_FILE"
