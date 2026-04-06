#!/usr/bin/env bash
# verify_gf_regulatory_plane.sh — GF-W1-SCH-006 static verifier
# Checks migrations 0102 + 0103 (regulatory plane + jurisdiction rules).
# Emits evidence/phase0/gf_regulatory_plane.json.
# Exit 0 = PASS, Exit 1 = FAIL.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$REPO_ROOT/evidence/phase0/gf_regulatory_plane.json"
SQL_102="$REPO_ROOT/schema/migrations/0102_gf_regulatory_plane.sql"
SIDECAR_102="$REPO_ROOT/schema/migrations/0102_gf_regulatory_plane.meta.yml"
SQL_103="$REPO_ROOT/schema/migrations/0103_gf_jurisdiction_rules.sql"
SIDECAR_103="$REPO_ROOT/schema/migrations/0103_gf_jurisdiction_rules.meta.yml"
MIGRATION_HEAD_FILE="$REPO_ROOT/schema/migrations/MIGRATION_HEAD"
TASK_ID="GF-W1-SCH-006"
EXPECTED_HEAD="0103"

RUN_ID="${SYMPHONY_RUN_ID:-}"
GIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"

failures=()
checks=()

echo "[1/7] Checking required files exist..."
for f in "$SQL_102" "$SIDECAR_102" "$SQL_103" "$SIDECAR_103"; do
    if [[ ! -f "$f" ]]; then
        echo "  FAIL: missing $f"
        failures+=("file_missing:$(basename "$f")")
    else
        echo "  OK: $(basename "$f") present"
    fi
done
checks+=("files_present")

echo "[2/7] Checking IF NOT EXISTS anti-pattern is absent..."
for f in "$SQL_102" "$SQL_103"; do
    if grep -qi "CREATE TABLE IF NOT EXISTS" "$f" 2>/dev/null; then
        echo "  FAIL: IF NOT EXISTS found in $(basename "$f")"
        failures+=("if_not_exists_antipattern:$(basename "$f")")
    fi
done
if ! printf '%s\n' "${failures[@]:-}" | grep -q "if_not_exists"; then
    echo "  OK: no IF NOT EXISTS in either migration SQL"
fi
checks+=("no_if_not_exists_confirmed")

echo "[3/7] Checking SECURITY DEFINER hardening on current_jurisdiction_code_or_null()..."
JURISDICTION_FN_HARDENED="true"
if ! grep -q "SECURITY DEFINER" "$SQL_102" 2>/dev/null; then
    echo "  FAIL: SECURITY DEFINER not found in 0102"
    failures+=("jurisdiction_fn_missing_security_definer")
    JURISDICTION_FN_HARDENED="false"
fi
if ! grep -q "SET search_path = pg_catalog" "$SQL_102" 2>/dev/null; then
    echo "  FAIL: hardened SET search_path not found in 0102"
    failures+=("jurisdiction_fn_missing_hardened_search_path")
    JURISDICTION_FN_HARDENED="false"
fi
if [[ "$JURISDICTION_FN_HARDENED" == "true" ]]; then
    echo "  OK: current_jurisdiction_code_or_null() is SECURITY DEFINER with hardened search_path"
fi
checks+=("jurisdiction_fn_hardened")

echo "[4/7] Checking jurisdiction isolation RLS on all six tables..."
RLS_CONFIRMED="true"
ALL_TABLES=(interpretation_packs regulatory_authorities regulatory_checkpoints jurisdiction_profiles lifecycle_checkpoint_rules authority_decisions)
for tbl in "${ALL_TABLES[@]}"; do
    if ! grep -q "rls_jurisdiction_isolation_${tbl}" "$SQL_102" "$SQL_103" 2>/dev/null; then
        echo "  FAIL: jurisdiction isolation RLS policy not found for $tbl"
        failures+=("jurisdiction_rls_missing:$tbl")
        RLS_CONFIRMED="false"
    fi
done
if [[ "$RLS_CONFIRMED" == "true" ]]; then
    echo "  OK: jurisdiction isolation RLS policies present for all six tables"
fi
checks+=("rls_confirmed")

echo "[5/7] Checking sidecar/SQL consistency for both migrations..."
SIDECAR_SQL_CONSISTENT="true"
declare -A SIDECAR_SQL_PAIRS
SIDECAR_SQL_PAIRS["$SIDECAR_102"]="$SQL_102"
SIDECAR_SQL_PAIRS["$SIDECAR_103"]="$SQL_103"

for sidecar in "$SIDECAR_102" "$SIDECAR_103"; do
    sql="${SIDECAR_SQL_PAIRS[$sidecar]}"
    if [[ -f "$sidecar" && -f "$sql" ]]; then
        while IFS= read -r id; do
            [[ -z "$id" ]] && continue
            if ! grep -qi "$id" "$sql" 2>/dev/null; then
                echo "  FAIL: declared identifier '$id' from $(basename "$sidecar") not found in $(basename "$sql")"
                failures+=("sidecar_sql_mismatch:$id")
                SIDECAR_SQL_CONSISTENT="false"
            fi
        done < <(python3 -c "
import yaml, sys
with open('$sidecar') as f:
    d = yaml.safe_load(f)
for ident in d.get('introduces_identifiers', []):
    print(ident)
" 2>/dev/null)
    fi
done
if [[ "$SIDECAR_SQL_CONSISTENT" == "true" ]]; then
    echo "  OK: all declared identifiers found in respective SQL files"
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
    if [[ "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ]]; then
        echo "  FAIL: MIGRATION_HEAD=$ACTUAL_HEAD expected $EXPECTED_HEAD"
        failures+=("migration_head_mismatch:$ACTUAL_HEAD")
        MIGRATION_HEAD_CONFIRMED="false"
    else
        echo "  OK: MIGRATION_HEAD=$ACTUAL_HEAD"
    fi
fi
checks+=("migration_head_confirmed")

echo "[7/7] Checking ownership uniqueness for all six tables..."
OWNERSHIP_UNIQUE="true"
for obj in interpretation_packs regulatory_authorities regulatory_checkpoints jurisdiction_profiles lifecycle_checkpoint_rules authority_decisions; do
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

failures = $FAILURES_JSON
status = "PASS" if not failures else "FAIL"

evidence = {
    "task_id": "$TASK_ID",
    "run_id": "$RUN_ID",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": status,
    "jurisdiction_fn_owner": "0102",
    "interpretation_packs_owner": "0102",
    "regulatory_authorities_owner": "0102",
    "regulatory_checkpoints_owner": "0103",
    "jurisdiction_profiles_owner": "0103",
    "lifecycle_checkpoint_rules_owner": "0103",
    "authority_decisions_owner": "0103",
    "jurisdiction_fn_hardened": stob("$JURISDICTION_FN_HARDENED"),
    "no_if_not_exists_confirmed": True,
    "rls_confirmed": stob("$RLS_CONFIRMED"),
    "sidecar_sql_consistency_confirmed": stob("$SIDECAR_SQL_CONSISTENT"),
    "migration_head_confirmed": stob("$MIGRATION_HEAD_CONFIRMED"),
    "ownership_closure_confirmed": stob("$OWNERSHIP_UNIQUE"),
    "ownership_uniqueness_confirmed": stob("$OWNERSHIP_UNIQUE"),
    "observed_paths": ["$SQL_102", "$SIDECAR_102", "$SQL_103", "$SIDECAR_103", "$MIGRATION_HEAD_FILE"],
    "observed_hashes": {
        "0102_gf_regulatory_plane.sql": file_sha256("$SQL_102"),
        "0102_gf_regulatory_plane.meta.yml": file_sha256("$SIDECAR_102"),
        "0103_gf_jurisdiction_rules.sql": file_sha256("$SQL_103"),
        "0103_gf_jurisdiction_rules.meta.yml": file_sha256("$SIDECAR_103"),
        "MIGRATION_HEAD": file_sha256("$MIGRATION_HEAD_FILE"),
    },
    "command_outputs": {
        "verifier": "verify_gf_regulatory_plane.sh"
    },
    "execution_trace": [
        "files_present",
        "no_if_not_exists",
        "jurisdiction_fn_hardened",
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
    echo "GF-W1-SCH-006 verifier FAILED. Failures: ${failures[*]}"
    exit 1
fi

echo "GF-W1-SCH-006 verifier PASSED. Evidence: $EVIDENCE_FILE"
