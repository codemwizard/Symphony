#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-SUPPORT-DB-003"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo UNKNOWN)"

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: DATABASE_URL must be set" >&2
  exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
CHECKS_FILE="$TMPDIR/checks.tsv"
: > "$CHECKS_FILE"
PASS=true

record_check() {
  local id="$1" status="$2" detail="$3"
  printf '%s\t%s\t%s\n' "$id" "$status" "$detail" >> "$CHECKS_FILE"
  if [[ "$status" != "PASS" ]]; then
    PASS=false
  fi
}

REPRESENTATIVE_SCRIPTS=(
  "scripts/db/verify_p3_typed_dependency_graph.sh"
  "scripts/db/verify_p3_recursive_legitimacy_engine.sh"
  "scripts/db/verify_p3_policy_authority_lineage.sh"
  "scripts/db/verify_p3_authority_scope_engine.sh"
  "scripts/db/verify_p3_conflict_of_interest_enforcement.sh"
  "scripts/db/verify_p3_spatial_legality_dnsh_gates.sh"
  "scripts/db/verify_p3_contradiction_detection.sh"
)

SILENT_FALLBACKS=0
SAFE_SQL_COUNT=0
for path in "${REPRESENTATIVE_SCRIPTS[@]}"; do
  if rg -n '2>/dev/null \|\| true|2>/dev/null \|\| echo 0' "$ROOT/$path" >/dev/null; then
    SILENT_FALLBACKS=$((SILENT_FALLBACKS + 1))
  fi
  if rg -n '^safe_sql\(\)' "$ROOT/$path" >/dev/null; then
    SAFE_SQL_COUNT=$((SAFE_SQL_COUNT + 1))
  fi
done

[[ "$SILENT_FALLBACKS" == "0" ]] \
  && record_check "silent_fallbacks_removed" "PASS" "representative DB verifiers no longer swallow DB probe failures" \
  || record_check "silent_fallbacks_removed" "FAIL" "representative DB verifiers still contain $SILENT_FALLBACKS silent fallback pattern(s)"

[[ "$SAFE_SQL_COUNT" == "${#REPRESENTATIVE_SCRIPTS[@]}" ]] \
  && record_check "safe_sql_present" "PASS" "representative DB verifiers define fail-closed safe_sql helpers" \
  || record_check "safe_sql_present" "FAIL" "expected ${#REPRESENTATIVE_SCRIPTS[@]} safe_sql helpers, found $SAFE_SQL_COUNT"

BAD_URL="postgresql://invalid:invalid@127.0.0.1:1/symphony_probe_fail"
NEGATIVE_LOG="$TMPDIR/negative.log"
if DATABASE_URL="$BAD_URL" bash "$ROOT/scripts/db/verify_p3_typed_dependency_graph.sh" >"$TMPDIR/negative.json" 2>"$NEGATIVE_LOG"; then
  record_check "negative_probe_failure" "FAIL" "representative verifier unexpectedly passed with invalid DATABASE_URL"
else
  if grep -q 'DB_PROBE_FAILED:' "$NEGATIVE_LOG"; then
    record_check "negative_probe_failure" "PASS" "representative verifier fails closed with explicit DB_PROBE_FAILED diagnostics"
  else
    record_check "negative_probe_failure" "FAIL" "representative verifier failed without explicit DB_PROBE_FAILED diagnostics"
  fi
fi

TEMP_DB="symphony_p3_db003_$(date +%s)_$$"
cleanup_db() {
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "DROP DATABASE IF EXISTS \"$TEMP_DB\";" >/dev/null 2>&1 || true
}
trap 'cleanup_db; rm -rf "$TMPDIR"' EXIT
TEMP_URL="$(python3 - "$DATABASE_URL" "$TEMP_DB" <<'PY'
from urllib.parse import urlparse, urlunparse
import sys
p = urlparse(sys.argv[1])
print(urlunparse((p.scheme, p.netloc, "/" + sys.argv[2], p.params, p.query, p.fragment)))
PY
)"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "DROP DATABASE IF EXISTS \"$TEMP_DB\";" >/dev/null
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "CREATE DATABASE \"$TEMP_DB\";" >/dev/null
SCHEMA_MIGRATION_STRATEGY=migrations DATABASE_URL="$TEMP_URL" bash "$ROOT/scripts/db/migrate.sh" >"$TMPDIR/bootstrap.out" 2>"$TMPDIR/bootstrap.err"

if DATABASE_URL="$TEMP_URL" bash "$ROOT/scripts/db/verify_p3_typed_dependency_graph.sh" >"$TMPDIR/positive.json" 2>"$TMPDIR/positive.err"; then
  record_check "positive_probe_success" "PASS" "representative verifier still passes against the configured proof database"
else
  record_check "positive_probe_success" "FAIL" "representative verifier no longer passes against the configured proof database"
fi

if [[ "$PASS" == "true" ]]; then
  STATUS="PASS"
else
  STATUS="FAIL"
fi

export ROOT TASK_ID TIMESTAMP_UTC GIT_SHA STATUS CHECKS_FILE
python3 - <<'PY'
import hashlib
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT"])
checks = {}
for line in Path(os.environ["CHECKS_FILE"]).read_text(encoding="utf-8").splitlines():
    key, status, detail = line.split("\t", 2)
    checks[key] = {"status": status, "detail": detail}

paths = [
    "scripts/db/verify_p3_typed_dependency_graph.sh",
    "scripts/db/verify_p3_recursive_legitimacy_engine.sh",
    "scripts/db/verify_p3_policy_authority_lineage.sh",
    "scripts/db/verify_p3_authority_scope_engine.sh",
    "scripts/db/verify_p3_conflict_of_interest_enforcement.sh",
    "scripts/db/verify_p3_spatial_legality_dnsh_gates.sh",
    "scripts/db/verify_p3_contradiction_detection.sh",
    "scripts/db/verify_tsk_p3_support_db_003_fail_closed_db_probes.sh",
]

def sha(path: str) -> str:
    return hashlib.sha256((root / path).read_bytes()).hexdigest()

payload = {
    "task_id": os.environ["TASK_ID"],
    "git_sha": os.environ["GIT_SHA"],
    "timestamp_utc": os.environ["TIMESTAMP_UTC"],
    "status": os.environ["STATUS"],
    "checks": checks,
    "observed_paths": paths,
    "observed_hashes": {path: sha(path) for path in paths},
}
print(json.dumps(payload, indent=2))
PY
