#!/usr/bin/env bash
# ============================================================
# verify_execution_records_determinism_constraints.sh
# Task: TSK-P2-PREAUTH-003-REM-02
# Casefile: REM-2026-04-20_execution-truth-anchor
# Invariant: INV-EXEC-TRUTH-001 (contract phase proof)
#
# Proves migration 0132 tightened five columns to NOT NULL and
# installed the determinism UNIQUE constraint. Emits self-certifying
# evidence JSON (observed_paths, observed_hashes, command_outputs).
# ============================================================
set -Eeuo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIG_FILE="$ROOT_DIR/schema/migrations/0132_execution_records_determinism_constraints.sql"
BACKFILL_FILE="$ROOT_DIR/scripts/db/backfill_execution_records_determinism.sql"
HEAD_FILE="$ROOT_DIR/schema/migrations/MIGRATION_HEAD"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase2/tsk_p2_preauth_003_rem_02.json"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

TASK_ID="TSK-P2-PREAUTH-003-REM-02"
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TRACE_START="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

# Check 0: migration file must not contain \i (B6 — checksum bypass forbidden)
grep -Eq '^[[:space:]]*\\i[[:space:]]' "$MIG_FILE" && {
    echo "ERR: migration 0132 contains \\i (checksum bypass)" >&2; exit 1; }

# Check 1: migration file exists; MIGRATION_HEAD = 0132
test -f "$MIG_FILE" || { echo "ERR: migration 0132 missing" >&2; exit 1; }
HEAD_VALUE="$(cat "$HEAD_FILE" | tr -d '\n')"
[[ "$HEAD_VALUE" == "0132" ]] || { echo "ERR: MIGRATION_HEAD=$HEAD_VALUE (expected 0132)" >&2; exit 1; }

# Check 2: five NOT NULL columns
NOT_NULL_RAW="$(psql "$DATABASE_URL" -qAt -c "
SELECT attname
FROM pg_attribute
WHERE attrelid = 'public.execution_records'::regclass
  AND attnum > 0
  AND NOT attisdropped
  AND attnotnull = true
  AND attname IN ('input_hash','output_hash','runtime_version','tenant_id','interpretation_version_id')
ORDER BY attname;")"
EXPECTED_NN=("input_hash" "interpretation_version_id" "output_hash" "runtime_version" "tenant_id")
for col in "${EXPECTED_NN[@]}"; do
  echo "$NOT_NULL_RAW" | grep -Fxq "$col" || { echo "ERR: column $col is not NOT NULL" >&2; exit 1; }
done

# Check 3: UNIQUE constraint on (input_hash, interpretation_version_id, runtime_version)
UNIQUE_DEF="$(psql "$DATABASE_URL" -qAt -c "
SELECT pg_get_constraintdef(c.oid)
FROM pg_constraint c
JOIN pg_class t ON t.oid = c.conrelid
WHERE t.relname = 'execution_records'
  AND c.conname = 'execution_records_determinism_unique'
  AND c.contype = 'u';")"
[[ -n "$UNIQUE_DEF" ]] || { echo "ERR: execution_records_determinism_unique missing" >&2; exit 1; }
echo "$UNIQUE_DEF" | grep -q "input_hash" || { echo "ERR: UNIQUE does not include input_hash" >&2; exit 1; }
echo "$UNIQUE_DEF" | grep -q "interpretation_version_id" || { echo "ERR: UNIQUE does not include interpretation_version_id" >&2; exit 1; }
echo "$UNIQUE_DEF" | grep -q "runtime_version" || { echo "ERR: UNIQUE does not include runtime_version" >&2; exit 1; }

# Check 4: FK on interpretation_version_id targets interpretation_packs(interpretation_pack_id)
FK_TARGET="$(psql "$DATABASE_URL" -qAt -c "
SELECT ft.relname || '(' || string_agg(fa.attname, ',') || ')'
FROM pg_constraint c
JOIN pg_class t  ON t.oid  = c.conrelid
JOIN pg_class ft ON ft.oid = c.confrelid
JOIN pg_attribute fa ON fa.attrelid = c.confrelid AND fa.attnum = ANY (c.confkey)
WHERE t.relname = 'execution_records' AND c.contype = 'f'
GROUP BY ft.relname;")"
[[ "$FK_TARGET" == "interpretation_packs(interpretation_pack_id)" ]] || {
    echo "ERR: FK target is '$FK_TARGET' (expected interpretation_packs(interpretation_pack_id))" >&2; exit 1; }

# Check 5: backfill file has the \i-rejecting comment pattern and a DO block with GF059
test -f "$BACKFILL_FILE" || { echo "ERR: backfill script missing" >&2; exit 1; }
grep -q 'GF059' "$BACKFILL_FILE" || { echo "ERR: backfill script missing GF059 ERRCODE" >&2; exit 1; }
grep -q 'GF059' "$MIG_FILE" || { echo "ERR: migration 0132 missing inline GF059 precondition block" >&2; exit 1; }

# Observed hashes
MIG_SHA="$(sha256sum "$MIG_FILE" | awk '{print $1}')"
BACKFILL_SHA="$(sha256sum "$BACKFILL_FILE" | awk '{print $1}')"
HEAD_SHA="$(sha256sum "$HEAD_FILE" | awk '{print $1}')"

TRACE_END="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": [
    {"name": "no_psql_include_directive", "result": "pass"},
    {"name": "migration_file_and_head_match", "result": "pass"},
    {"name": "five_columns_not_null", "result": "pass"},
    {"name": "determinism_unique_constraint_present", "result": "pass"},
    {"name": "fk_target_interpretation_packs", "result": "pass"},
    {"name": "backfill_and_inline_gf059_present", "result": "pass"}
  ],
  "observed_paths": [
    "schema/migrations/0132_execution_records_determinism_constraints.sql",
    "scripts/db/backfill_execution_records_determinism.sql",
    "schema/migrations/MIGRATION_HEAD"
  ],
  "observed_hashes": {
    "migration_0132_sha256": "$MIG_SHA",
    "backfill_sha256": "$BACKFILL_SHA",
    "migration_head_sha256": "$HEAD_SHA"
  },
  "command_outputs": {
    "not_null_columns": $(echo "$NOT_NULL_RAW" | jq -R -s -c 'split("\n") | map(select(length>0))'),
    "unique_constraint_def": $(echo "$UNIQUE_DEF" | jq -R -s -c '.'),
    "fk_target": "$FK_TARGET"
  },
  "execution_trace": {
    "start_utc": "$TRACE_START",
    "end_utc": "$TRACE_END"
  },
  "not_null_enforced": true,
  "unique_enforced": true,
  "fk_not_null_enforced": true,
  "migration_head_value": "$HEAD_VALUE"
}
EOF

echo "PASS: REM-02 determinism constraints enforced; MIGRATION_HEAD=$HEAD_VALUE; evidence: $EVIDENCE_FILE"
