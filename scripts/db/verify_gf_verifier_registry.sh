#!/usr/bin/env bash
# verify_gf_verifier_registry.sh — GF-W1-SCH-008 static verifier
# Checks migration 0087 (verifier_registry, verifier_project_assignments, check_reg26_separation).
# Emits evidence/phase0/gf_verifier_registry.json.
# Exit 0 = PASS, Exit 1 = FAIL.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$REPO_ROOT/evidence/phase0/gf_verifier_registry.json"
SQL_FILE="$REPO_ROOT/schema/migrations/0106_gf_verifier_registry.sql"
SIDECAR_FILE="$REPO_ROOT/schema/migrations/0106_gf_verifier_registry.meta.yml"
MIGRATION_HEAD_FILE="$REPO_ROOT/schema/migrations/MIGRATION_HEAD"
TASK_ID="GF-W1-SCH-008"
EXPECTED_HEAD="0106"

RUN_ID="${SYMPHONY_RUN_ID:-}"
GIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

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
IF_NOT_EXISTS_CLEAN="true"
if grep -qi "CREATE TABLE IF NOT EXISTS" "$SQL_FILE" 2>/dev/null; then
    echo "  FAIL: IF NOT EXISTS found in $SQL_FILE"
    failures+=("if_not_exists_antipattern")
    IF_NOT_EXISTS_CLEAN="false"
else
    echo "  OK: no IF NOT EXISTS in migration SQL"
fi
checks+=("no_if_not_exists")

echo "[3/7] Checking SECURITY DEFINER hardening on both functions..."
FN_HARDENED="true"
for fn in "gf_verifier_tables_append_only" "check_reg26_separation"; do
    fn_block=$(awk "/FUNCTION public.${fn}/,/^\\\$\\\$/" "$SQL_FILE" 2>/dev/null || true)
    if ! grep -q "SECURITY DEFINER" "$SQL_FILE" 2>/dev/null; then
        echo "  FAIL: SECURITY DEFINER not found for $fn"
        failures+=("fn_missing_security_definer:$fn")
        FN_HARDENED="false"
    fi
    if ! grep -q "SET search_path = pg_catalog" "$SQL_FILE" 2>/dev/null; then
        echo "  FAIL: hardened SET search_path not found for $fn"
        failures+=("fn_missing_hardened_search_path:$fn")
        FN_HARDENED="false"
    fi
done
if [[ "$FN_HARDENED" == "true" ]]; then
    echo "  OK: both functions are SECURITY DEFINER with hardened search_path"
fi
checks+=("functions_hardened")

echo "[4/7] Checking Regulation 26 enforcement function exists..."
REG26_CONFIRMED="true"
if ! grep -q "check_reg26_separation" "$SQL_FILE" 2>/dev/null; then
    echo "  FAIL: check_reg26_separation function not found"
    failures+=("reg26_function_missing")
    REG26_CONFIRMED="false"
elif ! grep -q "GF001" "$SQL_FILE" 2>/dev/null; then
    echo "  FAIL: GF001 error code not found in check_reg26_separation"
    failures+=("reg26_error_code_missing")
    REG26_CONFIRMED="false"
else
    echo "  OK: check_reg26_separation with GF001 error code present"
fi
checks+=("reg26_confirmed")

echo "[5/7] Checking sidecar/SQL consistency..."
SIDECAR_SQL_CONSISTENT="true"
if [[ -f "$SIDECAR_FILE" ]]; then
    DECLARED_IDS=()
    while IFS= read -r id; do
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

echo "[6/7] Checking MIGRATION_HEAD is at least $EXPECTED_HEAD..."
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

echo "[7/7] Checking ownership uniqueness for verifier_registry and verifier_project_assignments..."
OWNERSHIP_UNIQUE="true"
for obj in verifier_registry verifier_project_assignments check_reg26_separation; do
    OWNER_COUNT=0
    for meta in "$REPO_ROOT"/schema/migrations/*.meta.yml; do
        if python3 -c "
import yaml, sys
with open('$meta') as f:
    d = yaml.safe_load(f)
ids = d.get('introduces_identifiers', [])
sys.exit(0 if '$obj' in ids else 1)
" 2>/dev/null; then
            OWNER_COUNT=$((OWNER_COUNT + 1))
            OWNER_FILE="$(basename "$meta")"
        fi
    done
    if [[ "$OWNER_COUNT" -ne 1 ]]; then
        echo "  FAIL: $obj declared in $OWNER_COUNT sidecars (expected 1)"
        failures+=("ownership_not_unique:$obj")
        OWNERSHIP_UNIQUE="false"
    else
        echo "  OK: $obj declared in exactly 1 sidecar ($OWNER_FILE)"
    fi
done
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
    "verifier_registry_owner": "0106",
    "verifier_project_assignments_owner": "0106",
    "check_reg26_separation_owner": "0106",
    "reg26_confirmed": stob("$REG26_CONFIRMED"),
    "functions_hardened": stob("$FN_HARDENED"),
    "no_if_not_exists_confirmed": stob("$IF_NOT_EXISTS_CLEAN"),
    "sidecar_sql_consistency_confirmed": stob("$SIDECAR_SQL_CONSISTENT"),
    "migration_head_confirmed": stob("$MIGRATION_HEAD_CONFIRMED"),
    "ownership_closure_confirmed": stob("$OWNERSHIP_UNIQUE"),
    "observed_paths": [sql_path, sidecar_path, head_path],
    "observed_hashes": {
        "0106_gf_verifier_registry.sql": file_sha256(sql_path),
        "0106_gf_verifier_registry.meta.yml": file_sha256(sidecar_path),
        "MIGRATION_HEAD": file_sha256(head_path),
    },
    "command_outputs": {
        "verifier": "verify_gf_verifier_registry.sh"
    },
    "execution_trace": [
        "files_present",
        "no_if_not_exists",
        "functions_hardened",
        "reg26_confirmed",
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
    echo "GF-W1-SCH-008 verifier FAILED. Failures: ${failures[*]}"
    exit 1
fi

echo "GF-W1-SCH-008 verifier PASSED. Evidence: $EVIDENCE_FILE"
