#!/usr/bin/env bash
set -euo pipefail

# verify_execution_records_determinism_constraints.sh
#
# Task: TSK-P2-PREAUTH-003-REM-02
# Casefile: REM-2026-04-20_execution-truth-anchor
#
# Proves migration 0132 contract-phase deliverables:
#   - pg_attribute.attnotnull = true for five columns
#   - pg_constraint execution_records_determinism_unique of contype=u over the
#     three-column determinism tuple
#   - Three negative tests: NOT NULL violation on input_hash (SQLSTATE 23502),
#     duplicate determinism tuple rejected (SQLSTATE 23505), NOT NULL violation
#     on interpretation_version_id (SQLSTATE 23502).
#
# Evidence: evidence/phase2/tsk_p2_preauth_003_rem_02.json

if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  exit 1
fi

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
# shellcheck source=scripts/lib/evidence.sh
source "$ROOT_DIR/scripts/lib/evidence.sh"

TASK_ID="TSK-P2-PREAUTH-003-REM-02"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase2/tsk_p2_preauth_003_rem_02.json"
MIGRATION_FILE="schema/migrations/0132_execution_records_determinism_constraints.sql"
MIGRATION_HEAD_FILE="schema/migrations/MIGRATION_HEAD"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

TS="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"

echo "==> $TASK_ID: execution_records determinism-constraints verifier"

# ---- 1. NOT NULL enforcement on the five columns
NOT_NULL_ROWS="$(psql "$DATABASE_URL" -X -q -t -A -F '|' -v ON_ERROR_STOP=1 -c "
  SELECT a.attname, a.attnotnull
  FROM pg_attribute a
  JOIN pg_class c ON c.oid = a.attrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname='public' AND c.relname='execution_records'
    AND a.attname IN ('input_hash','output_hash','runtime_version','tenant_id','interpretation_version_id')
    AND NOT a.attisdropped
  ORDER BY a.attname;")"

declare -A NN_OBSERVED
while IFS='|' read -r col notnull; do
    [[ -z "$col" ]] && continue
    NN_OBSERVED["$col"]="$notnull"
done <<< "$NOT_NULL_ROWS"

CHECK_NOT_NULL="PASS"
NOT_NULL_COLUMNS=()
for col in input_hash output_hash runtime_version tenant_id interpretation_version_id; do
    if [[ "${NN_OBSERVED[$col]:-f}" == "t" ]]; then
        NOT_NULL_COLUMNS+=("$col")
    else
        CHECK_NOT_NULL="FAIL"
    fi
done

# ---- 2. UNIQUE constraint
UNIQUE_DETAIL="$(psql "$DATABASE_URL" -X -q -t -A -F '|' -v ON_ERROR_STOP=1 -c "
  SELECT conname, contype, pg_get_constraintdef(c.oid)
  FROM pg_constraint c
  JOIN pg_class t ON t.oid = c.conrelid
  JOIN pg_namespace n ON n.oid = t.relnamespace
  WHERE n.nspname='public' AND t.relname='execution_records'
    AND c.conname='execution_records_determinism_unique';")"
CHECK_UNIQUE="FAIL"
if [[ -n "$UNIQUE_DETAIL" ]] && echo "$UNIQUE_DETAIL" | grep -qi 'UNIQUE (input_hash, interpretation_version_id, runtime_version)'; then
    CHECK_UNIQUE="PASS"
fi

# ---- 3. FK to interpretation_packs(interpretation_pack_id)
FK_DETAIL="$(psql "$DATABASE_URL" -X -q -t -A -F '|' -v ON_ERROR_STOP=1 -c "
  SELECT conname, pg_get_constraintdef(c.oid)
  FROM pg_constraint c
  JOIN pg_class t ON t.oid = c.conrelid
  JOIN pg_namespace n ON n.oid = t.relnamespace
  WHERE n.nspname='public' AND t.relname='execution_records' AND c.contype='f'
    AND pg_get_constraintdef(c.oid) ILIKE '%interpretation_packs%';")"
CHECK_FK="FAIL"
if [[ -n "$FK_DETAIL" ]] && echo "$FK_DETAIL" | grep -qi 'REFERENCES interpretation_packs(interpretation_pack_id)'; then
    CHECK_FK="PASS"
fi

# ---- 4. Negative tests (NOT NULL + UNIQUE violations)
NEG_LOG=()

run_neg() {
    local label="$1" expected_sqlstate="$2" sql="$3"
    local output rc
    output="$(psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "$sql" 2>&1 || true)"
    if echo "$output" | grep -q "SQLSTATE=$expected_sqlstate\|ERRCODE=$expected_sqlstate"; then
        rc="PASS"
    elif echo "$output" | grep -q "SQLSTATE\|ERROR:"; then
        if [[ "$expected_sqlstate" == "23502" && "$output" =~ (null value|not-null) ]]; then
            rc="PASS"
        elif [[ "$expected_sqlstate" == "23505" && "$output" =~ (duplicate key|unique constraint) ]]; then
            rc="PASS"
        else
            rc="FAIL"
        fi
    else
        rc="FAIL"
    fi
    NEG_LOG+=("{\"label\":\"$label\",\"expected_sqlstate\":\"$expected_sqlstate\",\"result\":\"$rc\"}")
    [[ "$rc" == "PASS" ]]
}

# Prepare a valid interpretation_pack_id for the UNIQUE-violation test (tenant_id, project_id)
# Use a BEGIN/ROLLBACK so nothing persists.
CHECK_NEGATIVE_TESTS="PASS"

# Neg 1: NULL input_hash -> 23502
run_neg "null_input_hash" "23502" "
  BEGIN;
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id)
  VALUES (gen_random_uuid(), 'completed', NULL, 'x', 'v1', gen_random_uuid(), gen_random_uuid());
  ROLLBACK;" || CHECK_NEGATIVE_TESTS="FAIL"

# Neg 2: NULL interpretation_version_id -> 23502
run_neg "null_interpretation_version_id" "23502" "
  BEGIN;
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id)
  VALUES (gen_random_uuid(), 'completed', 'h', 'o', 'v1', gen_random_uuid(), NULL);
  ROLLBACK;" || CHECK_NEGATIVE_TESTS="FAIL"

# Neg 3: Duplicate (input_hash, interpretation_version_id, runtime_version) -> 23505
# We need a real interpretation_pack_id because interpretation_version_id has FK constraint.
PACK_ID="$(psql "$DATABASE_URL" -X -q -t -A -v ON_ERROR_STOP=1 -c "
  INSERT INTO public.interpretation_packs (jurisdiction_code, pack_type, pack_payload_json, project_id, effective_from)
  VALUES ('ZM', 'rem02_neg_test', '{}'::jsonb, gen_random_uuid(), NOW())
  RETURNING interpretation_pack_id;" 2>/dev/null | tail -n1)"

if [[ -n "$PACK_ID" ]]; then
    run_neg "duplicate_determinism_tuple" "23505" "
      BEGIN;
      INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id)
      VALUES (gen_random_uuid(), 'completed', 'rem02_h', 'o1', 'rem02_rt', gen_random_uuid(), '$PACK_ID'::uuid);
      INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id)
      VALUES (gen_random_uuid(), 'completed', 'rem02_h', 'o2', 'rem02_rt', gen_random_uuid(), '$PACK_ID'::uuid);
      ROLLBACK;" || CHECK_NEGATIVE_TESTS="FAIL"
    # Cleanup the synthetic pack
    psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "DELETE FROM public.interpretation_packs WHERE interpretation_pack_id='$PACK_ID';" >/dev/null
else
    NEG_LOG+=("{\"label\":\"duplicate_determinism_tuple\",\"expected_sqlstate\":\"23505\",\"result\":\"SKIP_NO_PACK\"}")
    CHECK_NEGATIVE_TESTS="FAIL"
fi

# ---- 5. MIGRATION_HEAD >= 0132
MIGRATION_HEAD_VALUE="$(tr -d '\n' < "$MIGRATION_HEAD_FILE")"
CHECK_MIGRATION_HEAD="PASS"
case "$MIGRATION_HEAD_VALUE" in
    0132|0133) ;;
    *) CHECK_MIGRATION_HEAD="FAIL" ;;
esac

# ---- 6. Verifier integrity / provenance hashes
MIG_HASH="$(sha256sum "$MIGRATION_FILE" | awk '{print $1}')"
MIG_HEAD_HASH="$(sha256sum "$MIGRATION_HEAD_FILE" | awk '{print $1}')"
BACKFILL_HASH="$(sha256sum scripts/db/backfill_execution_records_determinism.sql | awk '{print $1}')"
SELF_HASH="$(sha256sum "$0" | awk '{print $1}')"

STATUS="PASS"
for c in "$CHECK_NOT_NULL" "$CHECK_UNIQUE" "$CHECK_FK" "$CHECK_NEGATIVE_TESTS" "$CHECK_MIGRATION_HEAD"; do
    [[ "$c" != "PASS" ]] && STATUS="FAIL"
done

NEG_JSON="$(IFS=,; echo "${NEG_LOG[*]}")"

python3 - "$EVIDENCE_FILE" "$TASK_ID" "$STATUS" "$GIT_SHA" "$TS" \
    "$CHECK_NOT_NULL" "$CHECK_UNIQUE" "$CHECK_FK" "$CHECK_NEGATIVE_TESTS" "$CHECK_MIGRATION_HEAD" \
    "$MIG_HASH" "$MIG_HEAD_HASH" "$BACKFILL_HASH" "$SELF_HASH" \
    "$MIGRATION_HEAD_VALUE" "$UNIQUE_DETAIL" "$FK_DETAIL" \
    "${NOT_NULL_COLUMNS[*]:-}" "$NEG_JSON" <<'PY'
import json, os, sys
(out, task, status, sha, ts,
 c_nn, c_uq, c_fk, c_neg, c_head,
 mig_hash, mig_head_hash, backfill_hash, self_hash,
 mig_head_value, unique_detail, fk_detail,
 nn_cols, neg_json) = sys.argv[1:20]
try:
    neg_tests = json.loads("[" + neg_json + "]") if neg_json.strip() else []
except json.JSONDecodeError:
    neg_tests = []
data = {
    "task_id": task,
    "status": status,
    "git_sha": sha,
    "timestamp_utc": ts,
    "checks": {
        "not_null_enforced": c_nn,
        "unique_enforced": c_uq,
        "fk_verified": c_fk,
        "negative_tests": c_neg,
        "migration_head_advanced": c_head,
    },
    "observed_paths": [
        "schema/migrations/0132_execution_records_determinism_constraints.sql",
        "schema/migrations/MIGRATION_HEAD",
        "scripts/db/backfill_execution_records_determinism.sql",
        "scripts/db/verify_execution_records_determinism_constraints.sh",
    ],
    "observed_hashes": {
        "schema/migrations/0132_execution_records_determinism_constraints.sql": mig_hash,
        "schema/migrations/MIGRATION_HEAD": mig_head_hash,
        "scripts/db/backfill_execution_records_determinism.sql": backfill_hash,
        "scripts/db/verify_execution_records_determinism_constraints.sh": self_hash,
    },
    "command_outputs": {
        "unique_constraint_definition": unique_detail,
        "fk_constraint_definition": fk_detail,
    },
    "execution_trace": [
        "step_01_probe_not_null",
        "step_02_probe_unique_constraint",
        "step_03_probe_fk_to_interpretation_packs",
        "step_04_negative_tests_23502_and_23505",
        "step_05_check_migration_head",
    ],
    "columns_not_null": [c for c in nn_cols.split() if c],
    "negative_tests": neg_tests,
    "migration_head_value": mig_head_value,
}
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as fh:
    json.dump(data, fh, indent=2, sort_keys=True)
    fh.write("\n")
print(f"Wrote {out}")
PY

if [[ "$STATUS" != "PASS" ]]; then
    echo "FAIL: $TASK_ID (see $EVIDENCE_FILE)" >&2
    exit 1
fi
echo "PASS: $TASK_ID"
