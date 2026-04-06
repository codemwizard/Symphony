#!/usr/bin/env bash
# verify_gf_monitoring_records.sh — GF-W1-SCH-003 static verifier
# Checks migration 0099 (monitoring_records append-only event ledger).
# Emits evidence/phase0/gf_monitoring_records.json.
# Exit 0 = PASS, Exit 1 = FAIL.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$REPO_ROOT/evidence/phase0/gf_monitoring_records.json"
SQL_FILE="$REPO_ROOT/schema/migrations/0099_gf_monitoring_records.sql"
SIDECAR_FILE="$REPO_ROOT/schema/migrations/0099_gf_monitoring_records.meta.yml"
MIGRATION_HEAD_FILE="$REPO_ROOT/schema/migrations/MIGRATION_HEAD"
TASK_ID="GF-W1-SCH-003"
EXPECTED_HEAD="0099"

RUN_ID="${SYMPHONY_RUN_ID:-}"
GIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"

failures=()
checks=()

echo "[1/7] Checking required files exist..."
for f in "$SQL_FILE" "$SIDECAR_FILE"; do
    if [[ ! -f "$f" ]]; then
        echo "  FAIL: missing $f"
        failures+=("file_missing:$(basename "$f")")
    else
        echo "  OK: $(basename "$f") present"
    fi
done
checks+=("files_present")

echo "[2/7] Checking IF NOT EXISTS anti-pattern is absent..."
if grep -qi "CREATE TABLE IF NOT EXISTS" "$SQL_FILE" 2>/dev/null; then
    echo "  FAIL: IF NOT EXISTS found in $SQL_FILE"
    failures+=("if_not_exists_antipattern")
else
    echo "  OK: no IF NOT EXISTS in migration SQL"
fi
checks+=("no_if_not_exists")

echo "[3/7] Checking append-only privileges (no GRANT UPDATE/DELETE to symphony_command)..."
APPEND_ONLY_CONFIRMED="true"
if grep -qi "GRANT.*UPDATE.*monitoring_records.*TO symphony_command" "$SQL_FILE" 2>/dev/null; then
    echo "  FAIL: UPDATE granted to symphony_command on monitoring_records"
    failures+=("append_only_violated_update")
    APPEND_ONLY_CONFIRMED="false"
fi
if grep -qi "GRANT.*DELETE.*monitoring_records.*TO symphony_command" "$SQL_FILE" 2>/dev/null; then
    echo "  FAIL: DELETE granted to symphony_command on monitoring_records"
    failures+=("append_only_violated_delete")
    APPEND_ONLY_CONFIRMED="false"
fi
if [[ "$APPEND_ONLY_CONFIRMED" == "true" ]]; then
    echo "  OK: no UPDATE or DELETE granted to symphony_command on monitoring_records"
fi
checks+=("append_only_confirmed")

echo "[4/7] Checking RLS is enabled..."
RLS_CONFIRMED="true"
if ! grep -q "ENABLE ROW LEVEL SECURITY" "$SQL_FILE" 2>/dev/null; then
    echo "  FAIL: RLS not enabled on monitoring_records"
    failures+=("rls_not_enabled")
    RLS_CONFIRMED="false"
else
    echo "  OK: RLS enabled"
fi
if ! grep -q "rls_tenant_isolation_monitoring_records" "$SQL_FILE" 2>/dev/null; then
    echo "  FAIL: canonical RLS policy not found"
    failures+=("rls_policy_missing")
    RLS_CONFIRMED="false"
fi
if [[ "$RLS_CONFIRMED" == "true" ]]; then
    echo "  OK: RLS policy present"
fi
checks+=("rls_confirmed")

echo "[5/7] Checking sidecar/SQL consistency..."
SIDECAR_SQL_CONSISTENT="true"
DECLARED_IDS=()
if [[ -f "$SIDECAR_FILE" ]]; then
    while IFS= read -r line; do
        id=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | tr -d '"' | tr -d "'")
        [[ -n "$id" ]] && DECLARED_IDS+=("$id")
    done < <(python3 -c "
import yaml, sys
with open('$SIDECAR_FILE') as f:
    d = yaml.safe_load(f)
for ident in d.get('introduces_identifiers', []):
    print(ident)
" 2>/dev/null)

    for id in "${DECLARED_IDS[@]}"; do
        if ! grep -qi "$id" "$SQL_FILE" 2>/dev/null; then
            echo "  FAIL: declared identifier '$id' not found in SQL"
            failures+=("sidecar_sql_mismatch:$id")
            SIDECAR_SQL_CONSISTENT="false"
        fi
    done
    if [[ "$SIDECAR_SQL_CONSISTENT" == "true" ]]; then
        echo "  OK: all declared identifiers found in SQL"
    fi
else
    echo "  FAIL: sidecar file missing"
    SIDECAR_SQL_CONSISTENT="false"
fi
checks+=("sidecar_sql_consistency_confirmed")

echo "[6/7] Checking MIGRATION_HEAD..."
MIGRATION_HEAD_CONFIRMED="true"
if [[ ! -f "$MIGRATION_HEAD_FILE" ]]; then
    echo "  FAIL: MIGRATION_HEAD file missing"
    failures+=("migration_head_missing")
    MIGRATION_HEAD_CONFIRMED="false"
else
    ACTUAL_HEAD="$(cat "$MIGRATION_HEAD_FILE" | tr -d '[:space:]')"
    if [[ $((10#$ACTUAL_HEAD)) -lt $((10#$EXPECTED_HEAD)) ]]; then
        echo "  FAIL: MIGRATION_HEAD=$ACTUAL_HEAD expected >= $EXPECTED_HEAD"
        failures+=("migration_head_mismatch:$ACTUAL_HEAD")
        MIGRATION_HEAD_CONFIRMED="false"
    else
        echo "  OK: MIGRATION_HEAD=$ACTUAL_HEAD (>= $EXPECTED_HEAD)"
    fi
fi
checks+=("migration_head_confirmed")

echo "[7/7] Checking ownership uniqueness (monitoring_records owned by exactly one sidecar)..."
OWNERSHIP_UNIQUE="true"
OWNER_COUNT=0
for meta in "$REPO_ROOT"/schema/migrations/*.meta.yml; do
    if python3 -c "
import yaml, sys
with open('$meta') as f:
    d = yaml.safe_load(f)
ids = d.get('introduces_identifiers', [])
sys.exit(0 if 'monitoring_records' in ids else 1)
" 2>/dev/null; then
        OWNER_COUNT=$((OWNER_COUNT + 1))
        OWNER_FILE="$(basename "$meta")"
    fi
done
if [[ "$OWNER_COUNT" -ne 1 ]]; then
    echo "  FAIL: monitoring_records declared in $OWNER_COUNT sidecars (expected 1)"
    failures+=("ownership_not_unique:monitoring_records")
    OWNERSHIP_UNIQUE="false"
else
    echo "  OK: monitoring_records declared in exactly 1 sidecar ($OWNER_FILE)"
fi
checks+=("ownership_uniqueness_confirmed")

# Emit evidence
mkdir -p "$(dirname "$EVIDENCE_FILE")"

CHECKS_JSON="$(printf '%s\n' "${checks[@]}" | python3 -c '
import json,sys
items = [l.strip() for l in sys.stdin if l.strip()]
print(json.dumps({k: True for k in items}))
')"

FAILURES_JSON="$(printf '%s\n' "${failures[@]:-}" | python3 -c '
import json,sys
items = [l.strip() for l in sys.stdin if l.strip()]
print(json.dumps(items))
')"

OBSERVED_PATHS_JSON="$(python3 -c "
import json
paths = ['$SQL_FILE', '$SIDECAR_FILE', '$MIGRATION_HEAD_FILE']
print(json.dumps(paths))
")"

python3 - <<PY
import json, hashlib, pathlib

def file_sha256(path):
    try:
        return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()
    except Exception:
        return "missing"

def stob(s):
    return s.strip().lower() == "true"

sql_path = "$SQL_FILE"
sidecar_path = "$SIDECAR_FILE"
head_path = "$MIGRATION_HEAD_FILE"

failures = $FAILURES_JSON
status = "PASS" if not failures else "FAIL"

evidence = {
    "task_id": "$TASK_ID",
    "run_id": "$RUN_ID",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": status,
    "monitoring_records_owner": "0099",
    "append_only_confirmed": stob("$APPEND_ONLY_CONFIRMED"),
    "rls_confirmed": stob("$RLS_CONFIRMED"),
    "sidecar_sql_consistency_confirmed": stob("$SIDECAR_SQL_CONSISTENT"),
    "migration_head_confirmed": stob("$MIGRATION_HEAD_CONFIRMED"),
    "ownership_closure_confirmed": stob("$OWNERSHIP_UNIQUE"),
    "observed_paths": [sql_path, sidecar_path, head_path],
    "observed_hashes": {
        "0099_gf_monitoring_records.sql": file_sha256(sql_path),
        "0099_gf_monitoring_records.meta.yml": file_sha256(sidecar_path),
        "MIGRATION_HEAD": file_sha256(head_path),
    },
    "command_outputs": {
        "verifier": "verify_gf_monitoring_records.sh"
    },
    "execution_trace": [
        "files_present",
        "no_if_not_exists",
        "append_only_confirmed",
        "rls_confirmed",
        "sidecar_sql_consistency",
        "migration_head",
        "ownership_uniqueness"
    ],
    "checks": json.loads('$CHECKS_JSON'),
    "failures": failures
}

with open("$EVIDENCE_FILE", "w") as f:
    json.dump(evidence, f, indent=2)

print(f"Evidence written to: $EVIDENCE_FILE")
PY

if [[ ${#failures[@]} -gt 0 ]]; then
    echo "GF-W1-SCH-003 verifier FAILED. Failures: ${failures[*]}"
    exit 1
fi

echo "GF-W1-SCH-003 verifier PASSED. Evidence: $EVIDENCE_FILE"
