#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-SUPPORT-DB-004"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo UNKNOWN)"

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: DATABASE_URL must be set" >&2
  exit 1
fi

TMPDIR="$(mktemp -d)"
CHECKS_FILE="$TMPDIR/checks.tsv"
: > "$CHECKS_FILE"
PASS=true

cleanup() {
  if [[ -n "${TEMP_DB:-}" ]]; then
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "DROP DATABASE IF EXISTS \"$TEMP_DB\";" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

record_check() {
  local id="$1" status="$2" detail="$3"
  printf '%s\t%s\t%s\n' "$id" "$status" "$detail" >> "$CHECKS_FILE"
  if [[ "$status" != "PASS" ]]; then
    PASS=false
  fi
}

TEMP_DB="symphony_p3_db004_$(date +%s)_$$"
TEMP_URL="$(python3 - "$DATABASE_URL" "$TEMP_DB" <<'PY'
from urllib.parse import urlparse, urlunparse
import sys
parsed = urlparse(sys.argv[1])
new_path = "/" + sys.argv[2]
print(urlunparse((parsed.scheme, parsed.netloc, new_path, parsed.params, parsed.query, parsed.fragment)))
PY
)"

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "DROP DATABASE IF EXISTS \"$TEMP_DB\";" >/dev/null
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "CREATE DATABASE \"$TEMP_DB\";" >/dev/null

if SCHEMA_MIGRATION_STRATEGY=baseline_then_migrations DATABASE_URL="$TEMP_URL" bash "$ROOT/scripts/db/migrate.sh" >"$TMPDIR/migrate.log" 2>"$TMPDIR/migrate.err"; then
  record_check "baseline_then_migrations_fresh_db" "PASS" "baseline_then_migrations succeeds on a fresh database with default public schema"
else
  record_check "baseline_then_migrations_fresh_db" "FAIL" "baseline_then_migrations failed on a fresh database"
fi

BASELINE_MARKERS="$(psql "$TEMP_URL" -X -t -A -v ON_ERROR_STOP=1 -c "SELECT COUNT(*) FROM public.schema_migrations WHERE version LIKE 'baseline@%';")"
[[ "$BASELINE_MARKERS" == "1" ]] \
  && record_check "baseline_marker_recorded" "PASS" "baseline marker recorded exactly once in schema_migrations" \
  || record_check "baseline_marker_recorded" "FAIL" "expected one baseline marker, found $BASELINE_MARKERS"

if ALLOW_BASELINE_ON_NONEMPTY=1 SCHEMA_MIGRATION_STRATEGY=baseline_then_migrations DATABASE_URL="$TEMP_URL" bash "$ROOT/scripts/db/migrate.sh" >"$TMPDIR/remigrate.log" 2>"$TMPDIR/remigrate.err"; then
  record_check "baseline_then_migrations_reentry" "PASS" "baseline_then_migrations can re-enter cleanly when non-empty baseline reuse is explicitly authorized"
else
  record_check "baseline_then_migrations_reentry" "FAIL" "baseline_then_migrations re-entry failed even with non-empty baseline override"
fi

if rg -n 'apply_baseline_file|schema_migrations_count|schema_migration_checksum' "$ROOT/scripts/db/migrate.sh" >/dev/null; then
  record_check "migrate_strategy_hardened" "PASS" "migrate.sh now separates baseline entry from schema_migrations bootstrap"
else
  record_check "migrate_strategy_hardened" "FAIL" "migrate.sh missing baseline entrypoint hardening helpers"
fi

if [[ "$PASS" == "true" ]]; then STATUS="PASS"; else STATUS="FAIL"; fi
export ROOT TASK_ID TIMESTAMP_UTC GIT_SHA STATUS CHECKS_FILE
python3 - <<'PY'
import hashlib, json, os
from pathlib import Path

root = Path(os.environ["ROOT"])
checks = {}
for line in Path(os.environ["CHECKS_FILE"]).read_text(encoding="utf-8").splitlines():
    key, status, detail = line.split("\t", 2)
    checks[key] = {"status": status, "detail": detail}
paths = [
    "scripts/db/migrate.sh",
    "docs/decisions/ADR-0010-baseline-policy.md",
    "scripts/db/verify_tsk_p3_support_db_004_baseline_entrypoint.sh",
]
payload = {
    "task_id": os.environ["TASK_ID"],
    "git_sha": os.environ["GIT_SHA"],
    "timestamp_utc": os.environ["TIMESTAMP_UTC"],
    "status": os.environ["STATUS"],
    "checks": checks,
    "observed_paths": paths,
    "observed_hashes": {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in paths},
}
print(json.dumps(payload, indent=2))
PY
