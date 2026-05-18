#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-GOV-006"
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
  "scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh"
  "scripts/audit/verify_p3_failure_composition_engine.sh"
  "scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh"
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

if rg -n 'DB-facing verifier contract|bootstrap failure' "$ROOT/docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md" >/dev/null; then
  record_check "process_doc_updated" "PASS" "implementation process doc distinguishes DB/bootstrap failure from schema-state failure"
else
  record_check "process_doc_updated" "FAIL" "implementation process doc missing DB/bootstrap failure contract language"
fi

[[ "$SILENT_FALLBACKS" == "0" ]] \
  && record_check "silent_fallbacks_removed" "PASS" "representative audit-side DB verifiers no longer swallow DB probe failures" \
  || record_check "silent_fallbacks_removed" "FAIL" "representative audit-side DB verifiers still contain $SILENT_FALLBACKS silent fallback pattern(s)"

[[ "$SAFE_SQL_COUNT" == "${#REPRESENTATIVE_SCRIPTS[@]}" ]] \
  && record_check "safe_sql_present" "PASS" "representative audit-side verifiers define fail-closed safe_sql helpers" \
  || record_check "safe_sql_present" "FAIL" "expected ${#REPRESENTATIVE_SCRIPTS[@]} safe_sql helpers, found $SAFE_SQL_COUNT"

BAD_URL="postgresql://invalid:invalid@127.0.0.1:1/symphony_probe_fail"
NEGATIVE_LOG="$TMPDIR/negative.log"
if DATABASE_URL="$BAD_URL" bash "$ROOT/scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh" >"$TMPDIR/negative.json" 2>"$NEGATIVE_LOG"; then
  record_check "negative_probe_failure" "FAIL" "audit-side representative verifier unexpectedly passed with invalid DATABASE_URL"
else
  if grep -q 'DB_PROBE_FAILED:' "$NEGATIVE_LOG"; then
    record_check "negative_probe_failure" "PASS" "audit-side representative verifier fails closed with explicit DB_PROBE_FAILED diagnostics"
  else
    record_check "negative_probe_failure" "FAIL" "audit-side representative verifier failed without explicit DB_PROBE_FAILED diagnostics"
  fi
fi

TEMP_DB="symphony_p3_gov006_$(date +%s)_$$"
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

if DATABASE_URL="$TEMP_URL" bash "$ROOT/scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh" >"$TMPDIR/positive.json" 2>"$TMPDIR/positive.err"; then
  record_check "positive_probe_success" "PASS" "audit-side representative verifier still passes against the configured proof database"
else
  record_check "positive_probe_success" "FAIL" "audit-side representative verifier no longer passes against the configured proof database"
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
    "docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md",
    "scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh",
    "scripts/audit/verify_p3_failure_composition_engine.sh",
    "scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh",
    "scripts/audit/verify_tsk_p3_gov_006_db_probe_contract.sh",
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
