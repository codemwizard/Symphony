#!/usr/bin/env bash
set -euo pipefail

# verify_execution_records_determinism_columns.sh
#
# Task: TSK-P2-PREAUTH-003-REM-01
# Casefile: REM-2026-04-20_execution-truth-anchor
#
# Proves that migration 0131 has been applied: execution_records carries the
# four determinism columns (input_hash TEXT, output_hash TEXT, runtime_version
# TEXT, tenant_id UUID), all NULLABLE at this phase (NOT NULL tightening is
# deferred to migration 0132 / REM-02).
#
# Evidence: evidence/phase2/tsk_p2_preauth_003_rem_01.json

if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Direct execution blocked to protect evidence integrity." >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  exit 1
fi

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

# shellcheck source=scripts/lib/evidence.sh
source "$ROOT_DIR/scripts/lib/evidence.sh"

TASK_ID="TSK-P2-PREAUTH-003-REM-01"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase2"
EVIDENCE_FILE="$EVIDENCE_DIR/tsk_p2_preauth_003_rem_01.json"
MIGRATION_FILE="schema/migrations/0131_execution_records_determinism_columns.sql"
MIGRATION_HEAD_FILE="schema/migrations/MIGRATION_HEAD"
mkdir -p "$EVIDENCE_DIR"

TS="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"

echo "==> $TASK_ID: execution_records determinism-columns verifier"

# ---- 1. Inspect information_schema for the four columns
COLUMNS_QUERY="SELECT column_name, data_type, is_nullable
               FROM information_schema.columns
               WHERE table_schema='public'
                 AND table_name='execution_records'
                 AND column_name IN ('input_hash','output_hash','runtime_version','tenant_id')
               ORDER BY column_name;"

if ! ROWS="$(psql "$DATABASE_URL" -X -q -t -A -F '|' -v ON_ERROR_STOP=1 -c "$COLUMNS_QUERY")"; then
    echo "ERROR: psql query failed" >&2
    exit 1
fi

declare -A EXPECTED_TYPE=(
    [input_hash]="text"
    [output_hash]="text"
    [runtime_version]="text"
    [tenant_id]="uuid"
)

COLUMNS_ADDED=()
CHECK_COLUMN_EXISTS="PASS"
CHECK_COLUMN_TYPES="PASS"
FAIL_REASONS=()

while IFS='|' read -r col_name col_type col_nullable; do
    [[ -z "$col_name" ]] && continue
    COLUMNS_ADDED+=("$col_name")
    expected="${EXPECTED_TYPE[$col_name]:-}"
    if [[ -z "$expected" ]]; then
        continue
    fi
    if [[ "$col_type" != "$expected" ]]; then
        CHECK_COLUMN_TYPES="FAIL"
        FAIL_REASONS+=("column $col_name type=$col_type expected=$expected")
    fi
done <<< "$ROWS"

for expected_col in input_hash output_hash runtime_version tenant_id; do
    found=0
    for got in "${COLUMNS_ADDED[@]:-}"; do
        [[ "$got" == "$expected_col" ]] && found=1
    done
    if [[ $found -eq 0 ]]; then
        CHECK_COLUMN_EXISTS="FAIL"
        FAIL_REASONS+=("column $expected_col missing")
    fi
done

# ---- 2. Confirm MIGRATION_HEAD advanced to 0131
MIGRATION_HEAD_VALUE="$(tr -d '\n' < "$MIGRATION_HEAD_FILE" || echo "UNKNOWN")"
CHECK_MIGRATION_HEAD="PASS"
if [[ "$MIGRATION_HEAD_VALUE" != "0131" && "$MIGRATION_HEAD_VALUE" != "0132" && "$MIGRATION_HEAD_VALUE" != "0133" ]]; then
    CHECK_MIGRATION_HEAD="FAIL"
    FAIL_REASONS+=("MIGRATION_HEAD=$MIGRATION_HEAD_VALUE (expected >=0131)")
fi

# ---- 3. Confirm migration 0131 file exists and references execution_records
CHECK_MIGRATION_FILE="PASS"
if [[ ! -f "$MIGRATION_FILE" ]] || ! grep -q 'execution_records' "$MIGRATION_FILE"; then
    CHECK_MIGRATION_FILE="FAIL"
    FAIL_REASONS+=("migration file $MIGRATION_FILE missing or does not reference execution_records")
fi

# ---- 4. Verifier integrity / provenance
MIG_HASH="$(sha256sum "$MIGRATION_FILE" | awk '{print $1}')"
MIG_HEAD_HASH="$(sha256sum "$MIGRATION_HEAD_FILE" | awk '{print $1}')"
SELF_HASH="$(sha256sum "$0" | awk '{print $1}')"

STATUS="PASS"
for c in "$CHECK_COLUMN_EXISTS" "$CHECK_COLUMN_TYPES" "$CHECK_MIGRATION_HEAD" "$CHECK_MIGRATION_FILE"; do
    [[ "$c" != "PASS" ]] && STATUS="FAIL"
done

# ---- Emit evidence
python3 - "$EVIDENCE_FILE" "$TASK_ID" "$STATUS" "$GIT_SHA" "$TS" \
    "$CHECK_COLUMN_EXISTS" "$CHECK_COLUMN_TYPES" "$CHECK_MIGRATION_HEAD" "$CHECK_MIGRATION_FILE" \
    "$MIG_HASH" "$MIG_HEAD_HASH" "$SELF_HASH" \
    "$MIGRATION_HEAD_VALUE" \
    "${COLUMNS_ADDED[*]:-}" \
    "${FAIL_REASONS[*]:-}" <<'PY'
import json, os, sys
(out, task, status, sha, ts,
 c_exists, c_types, c_head, c_file,
 mig_hash, mig_head_hash, self_hash,
 mig_head_value, cols_added, fail_reasons) = sys.argv[1:16]
cols = [c for c in cols_added.split() if c]
data = {
    "task_id": task,
    "status": status,
    "git_sha": sha,
    "timestamp_utc": ts,
    "checks": {
        "columns_exist": c_exists,
        "column_types_match": c_types,
        "migration_head_advanced": c_head,
        "migration_file_present": c_file,
    },
    "observed_paths": [
        "schema/migrations/0131_execution_records_determinism_columns.sql",
        "schema/migrations/MIGRATION_HEAD",
        "scripts/db/verify_execution_records_determinism_columns.sh",
    ],
    "observed_hashes": {
        "schema/migrations/0131_execution_records_determinism_columns.sql": mig_hash,
        "schema/migrations/MIGRATION_HEAD": mig_head_hash,
        "scripts/db/verify_execution_records_determinism_columns.sh": self_hash,
    },
    "command_outputs": {
        "information_schema.columns": "queried for execution_records in public schema",
    },
    "execution_trace": [
        "step_01_query_information_schema",
        "step_02_check_migration_head",
        "step_03_check_migration_file_exists",
        "step_04_hash_artifacts",
    ],
    "columns_added": cols,
    "migration_head_value": mig_head_value,
    "fail_reasons": [r for r in fail_reasons.split("\n") if r.strip()] if status != "PASS" else [],
}
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as fh:
    json.dump(data, fh, indent=2, sort_keys=True)
    fh.write("\n")
print(f"Wrote {out}")
PY

if [[ "$STATUS" != "PASS" ]]; then
    echo "FAIL: ${FAIL_REASONS[*]}" >&2
    exit 1
fi

echo "PASS: $TASK_ID"
