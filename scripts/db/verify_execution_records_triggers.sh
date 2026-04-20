#!/usr/bin/env bash
set -euo pipefail

# verify_execution_records_triggers.sh
#
# Task: TSK-P2-PREAUTH-003-REM-03
# Casefile: REM-2026-04-20_execution-truth-anchor
#
# Proves migration 0133 trigger installation + hardening + behaviour:
#   - pg_trigger for execution_records_append_only_trigger (BEFORE UPDATE OR DELETE, row-level)
#   - pg_trigger for execution_records_temporal_binding_trigger (BEFORE INSERT, row-level)
#   - pg_proc.proconfig contains search_path=pg_catalog, public for both trigger functions
#   - Driven negative tests: UPDATE -> GF056, DELETE -> GF056, mismatched INSERT -> GF058
#
# Evidence: evidence/phase2/tsk_p2_preauth_003_rem_03.json

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

TASK_ID="TSK-P2-PREAUTH-003-REM-03"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase2/tsk_p2_preauth_003_rem_03.json"
MIGRATION_FILE="schema/migrations/0133_execution_records_triggers.sql"
MIGRATION_HEAD_FILE="schema/migrations/MIGRATION_HEAD"
NEG_APPEND_ONLY="scripts/db/tests/test_execution_records_append_only_negative.sh"
NEG_TEMPORAL="scripts/db/tests/test_execution_records_temporal_binding_negative.sh"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

TS="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"

echo "==> $TASK_ID: execution_records triggers verifier"

# ---- 1. Trigger metadata from pg_trigger
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

declare -A TRIG
while IFS='|' read -r name is_before is_row fires_insert fires_update fires_delete; do
    [[ -z "$name" ]] && continue
    TRIG["$name"]="$is_before|$is_row|$fires_insert|$fires_update|$fires_delete"
done <<< "$TRIG_ROWS"

CHECK_APPEND_TRIGGER="PASS"
CHECK_TEMPORAL_TRIGGER="PASS"

check_trigger() {
    local name="$1" want_before="$2" want_row="$3" want_ins="$4" want_upd="$5" want_del="$6"
    local row="${TRIG[$name]:-}"
    if [[ -z "$row" ]]; then
        echo "  MISSING trigger: $name"
        return 1
    fi
    IFS='|' read -r b r i u d <<< "$row"
    if [[ "$b" == "$want_before" && "$r" == "$want_row" && "$i" == "$want_ins" && "$u" == "$want_upd" && "$d" == "$want_del" ]]; then
        echo "  OK trigger: $name"
        return 0
    fi
    echo "  FAIL trigger shape: $name got=$row want=$want_before|$want_row|$want_ins|$want_upd|$want_del"
    return 1
}

check_trigger "execution_records_append_only_trigger"     "t" "t" "f" "t" "t" || CHECK_APPEND_TRIGGER="FAIL"
check_trigger "execution_records_temporal_binding_trigger" "t" "t" "t" "f" "f" || CHECK_TEMPORAL_TRIGGER="FAIL"

# ---- 2. search_path hardening on both trigger functions
FUNC_ROWS="$(psql "$DATABASE_URL" -X -q -t -A -F '|' -v ON_ERROR_STOP=1 -c "
  SELECT p.proname, COALESCE(array_to_string(p.proconfig, ',','UNSET'),'UNSET') AS proconfig
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname='public'
    AND p.proname IN ('execution_records_append_only','enforce_execution_interpretation_temporal_binding')
  ORDER BY p.proname;")"

declare -A PROCONFIG
while IFS='|' read -r name cfg; do
    [[ -z "$name" ]] && continue
    PROCONFIG["$name"]="$cfg"
done <<< "$FUNC_ROWS"

CHECK_SEARCH_PATH="PASS"
for fn in execution_records_append_only enforce_execution_interpretation_temporal_binding; do
    cfg="${PROCONFIG[$fn]:-UNSET}"
    if [[ "$cfg" != *"search_path=pg_catalog, public"* ]]; then
        CHECK_SEARCH_PATH="FAIL"
        echo "  FAIL search_path: $fn proconfig=$cfg"
    fi
done

# ---- 3. Drive negative tests and capture SQLSTATEs
NEG_SQLSTATES=()
CHECK_NEGATIVE="PASS"

run_expect() {
    local label="$1" expected="$2" sql="$3"
    local output
    output="$(psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "$sql" 2>&1 || true)"
    if echo "$output" | grep -qE "$expected"; then
        NEG_SQLSTATES+=("{\"label\":\"$label\",\"expected\":\"$expected\",\"result\":\"PASS\"}")
    else
        NEG_SQLSTATES+=("{\"label\":\"$label\",\"expected\":\"$expected\",\"result\":\"FAIL\"}")
        CHECK_NEGATIVE="FAIL"
    fi
}

# To fire the row-level append-only trigger we must INSERT a real row first,
# then attempt UPDATE/DELETE on that row inside the same transaction. A new
# project + pack is seeded so the temporal-binding trigger admits the INSERT.
AO_PROJECT_ID="$(psql "$DATABASE_URL" -X -q -t -A -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tail -n1)"
AO_PACK_ID="$(psql "$DATABASE_URL" -X -q -t -A -v ON_ERROR_STOP=1 -c "
  INSERT INTO public.interpretation_packs (jurisdiction_code, pack_type, pack_payload_json, project_id, effective_from)
  VALUES ('ZM', 'rem03_append_only_verify', '{}'::jsonb, '$AO_PROJECT_ID'::uuid, '2020-01-01'::timestamptz)
  RETURNING interpretation_pack_id;" | tail -n1)"

run_expect "update_raises_gf056" "GF056|append-only" "
  BEGIN;
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id, execution_timestamp)
  VALUES ('$AO_PROJECT_ID'::uuid, 'completed', 'ao1', 'ao1', 'v1', gen_random_uuid(), '$AO_PACK_ID'::uuid, '2024-01-01'::timestamptz);
  UPDATE public.execution_records SET status='x' WHERE project_id='$AO_PROJECT_ID'::uuid;
  ROLLBACK;"

run_expect "delete_raises_gf056" "GF056|append-only" "
  BEGIN;
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id, execution_timestamp)
  VALUES ('$AO_PROJECT_ID'::uuid, 'completed', 'ao2', 'ao2', 'v1', gen_random_uuid(), '$AO_PACK_ID'::uuid, '2024-01-01'::timestamptz);
  DELETE FROM public.execution_records WHERE project_id='$AO_PROJECT_ID'::uuid;
  ROLLBACK;"

psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "DELETE FROM public.interpretation_packs WHERE interpretation_pack_id='$AO_PACK_ID';" >/dev/null || true

run_expect "insert_without_resolvable_pack_raises_gf058" "GF058|no interpretation_pack resolvable|temporal binding" "
  BEGIN;
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id, execution_timestamp)
  VALUES (gen_random_uuid(), 'completed', 'h1', 'o1', 'v1', gen_random_uuid(), gen_random_uuid(), NOW());
  ROLLBACK;"

# Case: pack exists but caller supplies wrong interpretation_version_id
PROJECT_ID="$(psql "$DATABASE_URL" -X -q -t -A -v ON_ERROR_STOP=1 -c "SELECT gen_random_uuid();" | tail -n1)"
PACK_ID="$(psql "$DATABASE_URL" -X -q -t -A -v ON_ERROR_STOP=1 -c "
  INSERT INTO public.interpretation_packs (jurisdiction_code, pack_type, pack_payload_json, project_id, effective_from)
  VALUES ('ZM', 'rem03_temporal_verify', '{}'::jsonb, '$PROJECT_ID'::uuid, '2020-01-01'::timestamptz)
  RETURNING interpretation_pack_id;" | tail -n1)"

run_expect "insert_with_wrong_pack_raises_gf058" "GF058|does not match|temporal" "
  BEGIN;
  INSERT INTO public.execution_records (project_id, status, input_hash, output_hash, runtime_version, tenant_id, interpretation_version_id, execution_timestamp)
  VALUES ('$PROJECT_ID'::uuid, 'completed', 'h2', 'o2', 'v1', gen_random_uuid(), gen_random_uuid(), '2024-01-01'::timestamptz);
  ROLLBACK;"

psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "DELETE FROM public.interpretation_packs WHERE interpretation_pack_id='$PACK_ID';" >/dev/null || true

# ---- 4. MIGRATION_HEAD and file presence
MIGRATION_HEAD_VALUE="$(tr -d '\n' < "$MIGRATION_HEAD_FILE")"
CHECK_MIGRATION_HEAD="PASS"
[[ "$MIGRATION_HEAD_VALUE" == "0133" ]] || CHECK_MIGRATION_HEAD="FAIL"

CHECK_MIGRATION_FILE="PASS"
if [[ ! -f "$MIGRATION_FILE" ]] || ! grep -q 'execution_records_append_only_trigger' "$MIGRATION_FILE" || ! grep -q 'execution_records_temporal_binding_trigger' "$MIGRATION_FILE"; then
    CHECK_MIGRATION_FILE="FAIL"
fi

# ---- 5. Verifier integrity / provenance
MIG_HASH="$(sha256sum "$MIGRATION_FILE" | awk '{print $1}')"
MIG_HEAD_HASH="$(sha256sum "$MIGRATION_HEAD_FILE" | awk '{print $1}')"
NEG_APPEND_HASH="$(sha256sum "$NEG_APPEND_ONLY" | awk '{print $1}')"
NEG_TEMPORAL_HASH="$(sha256sum "$NEG_TEMPORAL" | awk '{print $1}')"
SELF_HASH="$(sha256sum "$0" | awk '{print $1}')"

STATUS="PASS"
for c in "$CHECK_APPEND_TRIGGER" "$CHECK_TEMPORAL_TRIGGER" "$CHECK_SEARCH_PATH" "$CHECK_NEGATIVE" "$CHECK_MIGRATION_HEAD" "$CHECK_MIGRATION_FILE"; do
    [[ "$c" != "PASS" ]] && STATUS="FAIL"
done

NEG_JSON="$(IFS=,; echo "${NEG_SQLSTATES[*]}")"

python3 - "$EVIDENCE_FILE" "$TASK_ID" "$STATUS" "$GIT_SHA" "$TS" \
    "$CHECK_APPEND_TRIGGER" "$CHECK_TEMPORAL_TRIGGER" "$CHECK_SEARCH_PATH" "$CHECK_NEGATIVE" "$CHECK_MIGRATION_HEAD" "$CHECK_MIGRATION_FILE" \
    "$MIG_HASH" "$MIG_HEAD_HASH" "$NEG_APPEND_HASH" "$NEG_TEMPORAL_HASH" "$SELF_HASH" \
    "$MIGRATION_HEAD_VALUE" "$NEG_JSON" <<'PY'
import json, os, sys
(out, task, status, sha, ts,
 c_append, c_temporal, c_sp, c_neg, c_head, c_file,
 mig_hash, mig_head_hash, neg_a_hash, neg_t_hash, self_hash,
 mig_head_value, neg_json) = sys.argv[1:19]
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
        "append_only_trigger_installed": c_append,
        "temporal_binding_trigger_installed": c_temporal,
        "search_path_hardened": c_sp,
        "negative_tests": c_neg,
        "migration_head_advanced": c_head,
        "migration_file_present": c_file,
    },
    "observed_paths": [
        "schema/migrations/0133_execution_records_triggers.sql",
        "schema/migrations/MIGRATION_HEAD",
        "scripts/db/tests/test_execution_records_append_only_negative.sh",
        "scripts/db/tests/test_execution_records_temporal_binding_negative.sh",
        "scripts/db/verify_execution_records_triggers.sh",
    ],
    "observed_hashes": {
        "schema/migrations/0133_execution_records_triggers.sql": mig_hash,
        "schema/migrations/MIGRATION_HEAD": mig_head_hash,
        "scripts/db/tests/test_execution_records_append_only_negative.sh": neg_a_hash,
        "scripts/db/tests/test_execution_records_temporal_binding_negative.sh": neg_t_hash,
        "scripts/db/verify_execution_records_triggers.sh": self_hash,
    },
    "command_outputs": {
        "pg_trigger": "queried by tgname for execution_records_append_only_trigger and execution_records_temporal_binding_trigger",
        "pg_proc": "queried proconfig for execution_records_append_only and enforce_execution_interpretation_temporal_binding",
    },
    "execution_trace": [
        "step_01_probe_pg_trigger",
        "step_02_probe_pg_proc_search_path",
        "step_03_negative_test_update_delete_gf056",
        "step_04_negative_test_insert_gf058",
        "step_05_check_migration_head_and_file",
    ],
    "triggers_installed": {
        "execution_records_append_only_trigger": c_append == "PASS",
        "execution_records_temporal_binding_trigger": c_temporal == "PASS",
    },
    "search_path_hardened": c_sp == "PASS",
    "negative_test_sqlstates": neg_tests,
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
