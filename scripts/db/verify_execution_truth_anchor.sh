#!/usr/bin/env bash
set -euo pipefail

# verify_execution_truth_anchor.sh
#
# Task: TSK-P2-PREAUTH-003-REM-05
# Casefile: REM-2026-04-20_execution-truth-anchor
# Invariant (declared by REM-04 once this verifier emits fresh evidence):
#   INV-EXEC-TRUTH-001 -- execution_records is a NOT-NULL-bound, append-only,
#   deterministically-keyed, temporally-bound truth anchor.
#
# Proof surfaces (all guarded by || exit 1):
#   1. pg_attribute.attnotnull=true for input_hash, output_hash, runtime_version,
#      tenant_id, interpretation_version_id.
#   2. pg_constraint UNIQUE (input_hash, interpretation_version_id, runtime_version)
#      named execution_records_determinism_unique.
#   3. pg_constraint FOREIGN KEY interpretation_version_id -> interpretation_packs(interpretation_pack_id).
#   4. pg_trigger execution_records_append_only_trigger BEFORE UPDATE OR DELETE, row-level.
#   5. pg_trigger execution_records_temporal_binding_trigger BEFORE INSERT, row-level.
#   6. pg_proc.proconfig SET search_path = pg_catalog, public for execution_records_append_only
#      and enforce_execution_interpretation_temporal_binding.
#   7. Negative test: inserting a row whose interpretation_version_id !=
#      resolve_interpretation_pack(project_id, execution_timestamp) raises SQLSTATE GF058
#      and is rolled back.
#
# Self-certifying evidence carries the three verifier-integrity fields:
#   - verification_tool_version  (SHA-256 of this script)
#   - verification_input_snapshot (SHA-256 of a canonicalised dump of the pg_*
#                                  rows read above)
#   - verification_run_hash      (SHA-256 of the input snapshot + check results)

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

TASK_ID="TSK-P2-PREAUTH-003-REM-05"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase2/tsk_p2_preauth_003_rem_05.json"
mkdir -p "$(dirname "$EVIDENCE_FILE")"
TS="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"

echo "==> $TASK_ID: execution_records truth-anchor integrity verifier"

# ---- 1. NOT NULL on five determinism-bearing columns
NOT_NULL_ROWS="$(psql "$DATABASE_URL" -X -q -t -A -F '|' -v ON_ERROR_STOP=1 -c "
  SELECT a.attname, a.attnotnull
  FROM pg_attribute a
  JOIN pg_class c ON c.oid = a.attrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname='public' AND c.relname='execution_records'
    AND a.attname IN ('input_hash','output_hash','runtime_version','tenant_id','interpretation_version_id')
    AND a.attnum > 0 AND NOT a.attisdropped
  ORDER BY a.attname;")"

CHECK_NOT_NULL="PASS"
declare -A NOT_NULL_MAP
while IFS='|' read -r col nn; do
    [[ -z "$col" ]] && continue
    NOT_NULL_MAP["$col"]="$nn"
    if [[ "$nn" != "t" ]]; then
        CHECK_NOT_NULL="FAIL"
    fi
done <<< "$NOT_NULL_ROWS"
for col in input_hash output_hash runtime_version tenant_id interpretation_version_id; do
    [[ "${NOT_NULL_MAP[$col]:-f}" == "t" ]] || CHECK_NOT_NULL="FAIL"
done

# ---- 2. UNIQUE (input_hash, interpretation_version_id, runtime_version)
UNIQUE_DEF="$(psql "$DATABASE_URL" -X -q -t -A -v ON_ERROR_STOP=1 -c "
  SELECT pg_get_constraintdef(con.oid)
  FROM pg_constraint con
  JOIN pg_class c ON c.oid = con.conrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname='public' AND c.relname='execution_records'
    AND con.conname='execution_records_determinism_unique';")"
CHECK_UNIQUE="PASS"
if ! echo "$UNIQUE_DEF" | grep -qE 'UNIQUE \(input_hash, interpretation_version_id, runtime_version\)'; then
    CHECK_UNIQUE="FAIL"
fi

# ---- 3. FK interpretation_version_id -> interpretation_packs(interpretation_pack_id)
FK_DEF="$(psql "$DATABASE_URL" -X -q -t -A -v ON_ERROR_STOP=1 -c "
  SELECT pg_get_constraintdef(con.oid)
  FROM pg_constraint con
  JOIN pg_class c ON c.oid = con.conrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname='public' AND c.relname='execution_records'
    AND con.contype='f'
    AND con.conname LIKE '%interpretation_version_id%';")"
CHECK_FK="PASS"
if ! echo "$FK_DEF" | grep -qE 'FOREIGN KEY \(interpretation_version_id\) REFERENCES interpretation_packs\(interpretation_pack_id\)'; then
    CHECK_FK="FAIL"
fi

# ---- 4 + 5. Trigger shape
TRIG_ROWS="$(psql "$DATABASE_URL" -X -q -t -A -F '|' -v ON_ERROR_STOP=1 -c "
  SELECT t.tgname,
         (t.tgtype & 2) <> 0  AS is_before,
         (t.tgtype & 1) <> 0  AS is_row_level,
         (t.tgtype & 4) <> 0  AS fires_insert,
         (t.tgtype & 16) <> 0 AS fires_update,
         (t.tgtype & 8) <> 0  AS fires_delete
  FROM pg_trigger t
  JOIN pg_class c ON c.oid = t.tgrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname='public' AND c.relname='execution_records' AND NOT t.tgisinternal
  ORDER BY t.tgname;")"

declare -A TRIG_MAP
while IFS='|' read -r name is_before is_row f_ins f_upd f_del; do
    [[ -z "$name" ]] && continue
    TRIG_MAP["$name"]="$is_before|$is_row|$f_ins|$f_upd|$f_del"
done <<< "$TRIG_ROWS"

CHECK_APPEND_ONLY="PASS"
CHECK_TEMPORAL="PASS"
[[ "${TRIG_MAP[execution_records_append_only_trigger]:-}"     == "t|t|f|t|t" ]] || CHECK_APPEND_ONLY="FAIL"
[[ "${TRIG_MAP[execution_records_temporal_binding_trigger]:-}" == "t|t|t|f|f" ]] || CHECK_TEMPORAL="FAIL"

# ---- 6. search_path hardening on both trigger functions
FUNC_CONFIG="$(psql "$DATABASE_URL" -X -q -t -A -F '|' -v ON_ERROR_STOP=1 -c "
  SELECT p.proname, COALESCE(array_to_string(p.proconfig, ','), 'UNSET')
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname='public'
    AND p.proname IN ('execution_records_append_only','enforce_execution_interpretation_temporal_binding')
  ORDER BY p.proname;")"

CHECK_SEARCH_PATH="PASS"
declare -A PROC_MAP
while IFS='|' read -r name cfg; do
    [[ -z "$name" ]] && continue
    PROC_MAP["$name"]="$cfg"
    [[ "$cfg" == *"search_path=pg_catalog, public"* ]] || CHECK_SEARCH_PATH="FAIL"
done <<< "$FUNC_CONFIG"

# ---- 7. Behavioural negative test: temporal binding rejects wrong pack
CHECK_BEHAVIOUR="PASS"
NEG_OUTPUT="$(psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "
  BEGIN;
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id, execution_timestamp)
  VALUES (gen_random_uuid(), 'completed', 'ta1', 'ta1', 'v1', gen_random_uuid(), gen_random_uuid(), NOW());
  ROLLBACK;" 2>&1 || true)"
echo "$NEG_OUTPUT" | grep -qE "GF058|temporal binding|no interpretation_pack resolvable" || CHECK_BEHAVIOUR="FAIL"

# ---- Consolidate check status + input snapshot
INPUT_SNAPSHOT_RAW="$(printf '%s\n%s\n%s\n%s\n%s' "$NOT_NULL_ROWS" "$UNIQUE_DEF" "$FK_DEF" "$TRIG_ROWS" "$FUNC_CONFIG")"
VERIFICATION_INPUT_SNAPSHOT="$(printf '%s' "$INPUT_SNAPSHOT_RAW" | sha256sum | awk '{print $1}')"
VERIFICATION_TOOL_VERSION="$(sha256sum "$0" | awk '{print $1}')"

STATUS="PASS"
for c in "$CHECK_NOT_NULL" "$CHECK_UNIQUE" "$CHECK_FK" "$CHECK_APPEND_ONLY" "$CHECK_TEMPORAL" "$CHECK_SEARCH_PATH" "$CHECK_BEHAVIOUR"; do
    [[ "$c" != "PASS" ]] && STATUS="FAIL"
done

VERIFICATION_RUN_HASH="$(printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s' \
    "$VERIFICATION_TOOL_VERSION" \
    "$VERIFICATION_INPUT_SNAPSHOT" \
    "$CHECK_NOT_NULL" "$CHECK_UNIQUE" "$CHECK_FK" \
    "$CHECK_APPEND_ONLY" "$CHECK_TEMPORAL" "$CHECK_SEARCH_PATH" \
    "$CHECK_BEHAVIOUR" "$STATUS" | sha256sum | awk '{print $1}')"

# Observed hashes for dependent artefacts
MIG_0131_HASH="$(sha256sum schema/migrations/0131_execution_records_determinism_columns.sql | awk '{print $1}')"
MIG_0132_HASH="$(sha256sum schema/migrations/0132_execution_records_determinism_constraints.sql | awk '{print $1}')"
MIG_0133_HASH="$(sha256sum schema/migrations/0133_execution_records_triggers.sql | awk '{print $1}')"
MIG_HEAD_HASH="$(sha256sum schema/migrations/MIGRATION_HEAD | awk '{print $1}')"

python3 - "$EVIDENCE_FILE" "$TASK_ID" "$STATUS" "$GIT_SHA" "$TS" \
    "$CHECK_NOT_NULL" "$CHECK_UNIQUE" "$CHECK_FK" "$CHECK_APPEND_ONLY" "$CHECK_TEMPORAL" "$CHECK_SEARCH_PATH" "$CHECK_BEHAVIOUR" \
    "$VERIFICATION_TOOL_VERSION" "$VERIFICATION_INPUT_SNAPSHOT" "$VERIFICATION_RUN_HASH" \
    "$MIG_0131_HASH" "$MIG_0132_HASH" "$MIG_0133_HASH" "$MIG_HEAD_HASH" <<'PY'
import json, os, sys
(out, task, status, sha, ts,
 c_nn, c_uq, c_fk, c_ao, c_tp, c_sp, c_bh,
 v_tool, v_input, v_run,
 h131, h132, h133, h_head) = sys.argv[1:21]
data = {
    "task_id": task,
    "status": status,
    "git_sha": sha,
    "timestamp_utc": ts,
    "checks": {
        "not_null_enforced": c_nn,
        "unique_enforced": c_uq,
        "fk_verified": c_fk,
        "append_only_enforced": c_ao,
        "temporal_binding_enforced": c_tp,
        "search_path_hardened": c_sp,
        "behavioural_temporal_rejection": c_bh,
    },
    "not_null_enforced": c_nn == "PASS",
    "fk_verified": c_fk == "PASS",
    "unique_enforced": c_uq == "PASS",
    "append_only_enforced": c_ao == "PASS",
    "temporal_binding_enforced": c_tp == "PASS",
    "search_path_hardened": c_sp == "PASS",
    "columns_verified": [
        "input_hash", "output_hash", "runtime_version", "tenant_id", "interpretation_version_id"
    ],
    "observed_paths": [
        "schema/migrations/0131_execution_records_determinism_columns.sql",
        "schema/migrations/0132_execution_records_determinism_constraints.sql",
        "schema/migrations/0133_execution_records_triggers.sql",
        "schema/migrations/MIGRATION_HEAD",
        "scripts/db/verify_execution_truth_anchor.sh",
    ],
    "observed_hashes": {
        "schema/migrations/0131_execution_records_determinism_columns.sql": h131,
        "schema/migrations/0132_execution_records_determinism_constraints.sql": h132,
        "schema/migrations/0133_execution_records_triggers.sql": h133,
        "schema/migrations/MIGRATION_HEAD": h_head,
    },
    "command_outputs": {
        "pg_attribute": "queried attnotnull for 5 determinism columns on public.execution_records",
        "pg_constraint_unique": "queried pg_get_constraintdef for execution_records_determinism_unique",
        "pg_constraint_fk": "queried pg_get_constraintdef for FK on interpretation_version_id",
        "pg_trigger": "queried tgname, tgtype for execution_records triggers",
        "pg_proc": "queried proconfig for execution_records_append_only, enforce_execution_interpretation_temporal_binding",
        "behavioural_insert": "driven INSERT with unresolvable pack; asserted SQLSTATE GF058 surfaced in rolled-back transaction",
    },
    "execution_trace": [
        "step_01_probe_not_null_five_columns",
        "step_02_probe_unique_constraint",
        "step_03_probe_fk_interpretation_packs",
        "step_04_probe_trigger_shape_append_only",
        "step_05_probe_trigger_shape_temporal_binding",
        "step_06_probe_search_path_hardening",
        "step_07_behavioural_negative_insert_gf058",
        "step_08_compute_verifier_integrity_hashes",
    ],
    "verification_tool_version": v_tool,
    "verification_input_snapshot": v_input,
    "verification_run_hash": v_run,
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
