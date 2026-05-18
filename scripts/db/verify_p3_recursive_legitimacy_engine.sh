#!/usr/bin/env bash
# TSK-P3-WP-003 verifier: recursive legitimacy projection substrate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-WP-003"
MIGRATION_PATH="schema/migrations/0211_p3_recursive_legitimacy_engine.sql"
VERIFIER_PATH="scripts/db/verify_p3_recursive_legitimacy_engine.sh"
HEAD_PATH="schema/migrations/MIGRATION_HEAD"
ADR_PATH="docs/decisions/ADR-0010-baseline-policy.md"
SQLSTATE_MAP_PATH="docs/contracts/sqlstate_map.yml"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-WP-003/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-WP-003/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-WP-003/EXEC_LOG.md"

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: DATABASE_URL must be set" >&2
  exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
CHECKS_FILE="$TMPDIR/checks.tsv"
COMMANDS_FILE="$TMPDIR/commands.log"
TRACE_FILE="$TMPDIR/trace.log"
: > "$CHECKS_FILE"
: > "$COMMANDS_FILE"
: > "$TRACE_FILE"

PASS=true
GIT_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo UNKNOWN)"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

record_check() {
  local id="$1"
  local status="$2"
  local detail="$3"
  printf '%s\t%s\t%s\n' "$id" "$status" "$detail" >> "$CHECKS_FILE"
  if [[ "$status" != "PASS" ]]; then
    PASS=false
    echo "✗ $id :: $detail" >&2
  else
    echo "✓ $id :: $detail" >&2
  fi
}

record_command() {
  printf '%s\n' "$1" >> "$COMMANDS_FILE"
}

record_trace() {
  printf '%s\n' "$1" >> "$TRACE_FILE"
}

sql() {
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -t -A -c "$1"
}

sanitize_probe_error() {
  printf '%s' "$1" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//'
}

safe_sql() {
  local query="$1" out
  if ! out="$(sql "$query" 2>&1)"; then
    echo "DB_PROBE_FAILED: $(sanitize_probe_error "$out")" >&2
    exit 1
  fi
  printf '%s' "$out"
}

record_trace "start verifier for $TASK_ID"

HEAD_TOKEN="$(tr -d '\n\r[:space:]' < "$ROOT/$HEAD_PATH")"
record_command "read $HEAD_PATH => $HEAD_TOKEN"
if [[ "$HEAD_TOKEN" =~ ^[0-9]{4}$ ]] && (( 10#$HEAD_TOKEN >= 211 )); then
  record_check "migration_head_forward_only" "PASS" "MIGRATION_HEAD=$HEAD_TOKEN (>=0211)"
else
  record_check "migration_head_forward_only" "FAIL" "unexpected MIGRATION_HEAD=$HEAD_TOKEN"
fi

UNIVERSE_TABLE_EXISTS="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_projection_universes')::text, '');")"
RECORD_TABLE_EXISTS="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_legitimacy_projection_records')::text, '');")"
MANIFEST_VIEW_EXISTS="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_legitimacy_projection_manifest')::text, '');")"
EVALUATE_FUNCTION_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'p3_evaluate_legitimacy_projection';")"
ASSERT_FUNCTION_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'p3_assert_legitimacy_projection';")"
record_command "inspect legitimacy projection relations and functions"

[[ "$UNIVERSE_TABLE_EXISTS" == "p3_projection_universes" ]] \
  && record_check "projection_universe_table_exists" "PASS" "public.p3_projection_universes exists" \
  || record_check "projection_universe_table_exists" "FAIL" "public.p3_projection_universes missing"
[[ "$RECORD_TABLE_EXISTS" == "p3_legitimacy_projection_records" ]] \
  && record_check "projection_record_table_exists" "PASS" "public.p3_legitimacy_projection_records exists" \
  || record_check "projection_record_table_exists" "FAIL" "public.p3_legitimacy_projection_records missing"
[[ "$MANIFEST_VIEW_EXISTS" == "p3_legitimacy_projection_manifest" ]] \
  && record_check "projection_manifest_exists" "PASS" "public.p3_legitimacy_projection_manifest exists" \
  || record_check "projection_manifest_exists" "FAIL" "public.p3_legitimacy_projection_manifest missing"
[[ "$EVALUATE_FUNCTION_COUNT" == "1" ]] \
  && record_check "evaluate_function_exists" "PASS" "p3_evaluate_legitimacy_projection(text, uuid) exists" \
  || record_check "evaluate_function_exists" "FAIL" "p3_evaluate_legitimacy_projection(text, uuid) missing"
[[ "$ASSERT_FUNCTION_COUNT" == "1" ]] \
  && record_check "assert_function_exists" "PASS" "p3_assert_legitimacy_projection(text, uuid) exists" \
  || record_check "assert_function_exists" "FAIL" "p3_assert_legitimacy_projection(text, uuid) missing"

PURPOSE_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_projection_purpose'::regtype;")"
STATE_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_legitimacy_projection_state'::regtype;")"
MUTABILITY_DEFAULTS="$(safe_sql "
SELECT COUNT(*)
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'p3_legitimacy_projection_records'
  AND column_name = 'mutability_class'
  AND column_default LIKE '%supersedable_projection%';
")"
record_command "inspect legitimacy projection enums and mutability defaults"
[[ "$PURPOSE_ENUM_COUNT" == "2" ]] \
  && record_check "projection_purpose_enum" "PASS" "p3_projection_purpose has 2 values" \
  || record_check "projection_purpose_enum" "FAIL" "p3_projection_purpose count=$PURPOSE_ENUM_COUNT"
[[ "$STATE_ENUM_COUNT" == "4" ]] \
  && record_check "projection_state_enum" "PASS" "p3_legitimacy_projection_state has 4 values" \
  || record_check "projection_state_enum" "FAIL" "p3_legitimacy_projection_state count=$STATE_ENUM_COUNT"
[[ "$MUTABILITY_DEFAULTS" == "1" ]] \
  && record_check "projection_mutability_default" "PASS" "projection records default to supersedable_projection" \
  || record_check "projection_mutability_default" "FAIL" "projection mutability default missing"

LEGITIMACY_SQL="$(cat <<'SQL'
BEGIN;
DO $$
DECLARE
    v_universe uuid := '10000000-0000-0000-0000-000000000211';
    v_root uuid := '20000000-0000-0000-0000-000000000211';
    v_parent uuid := '30000000-0000-0000-0000-000000000211';
    v_child uuid := '40000000-0000-0000-0000-000000000211';
    v_clean uuid := '50000000-0000-0000-0000-000000000211';
    v_authority uuid := '60000000-0000-0000-0000-000000000211';
    v_policy uuid := '70000000-0000-0000-0000-000000000211';
    v_state public.p3_legitimacy_projection_state;
    v_blocking uuid;
    v_count integer;
BEGIN
    INSERT INTO public.p3_dependency_nodes (
        node_id,
        node_key,
        node_kind,
        lineage_provenance_id
    ) VALUES
        (v_root, 'p3.legitimacy.root', 'decision_record', '80000000-0000-0000-0000-000000000211'),
        (v_parent, 'p3.legitimacy.parent', 'decision_record', '81000000-0000-0000-0000-000000000211'),
        (v_child, 'p3.legitimacy.child', 'decision_record', '82000000-0000-0000-0000-000000000211'),
        (v_clean, 'p3.legitimacy.clean', 'decision_record', '83000000-0000-0000-0000-000000000211');

    INSERT INTO public.p3_dependency_edges (
        edge_id,
        downstream_node_id,
        upstream_node_id,
        dependency_kind,
        lineage_provenance_id
    ) VALUES
        ('84000000-0000-0000-0000-000000000211', v_child, v_parent, 'decision_input', '85000000-0000-0000-0000-000000000211'),
        ('86000000-0000-0000-0000-000000000211', v_parent, v_root, 'decision_input', '87000000-0000-0000-0000-000000000211');

    INSERT INTO public.p3_authority_lineage (
        authority_lineage_id,
        authority_key,
        authority_source_kind,
        source_reference,
        resource_scope,
        act_scope,
        effective_from,
        lineage_provenance_id
    ) VALUES (
        v_authority,
        'authority.legitimacy.root',
        'constitutional_document',
        'constitution://phase3/legitimacy/root',
        'asset_batch',
        'admissibility_decision',
        '2026-01-01T00:00:00Z',
        '88000000-0000-0000-0000-000000000211'
    );

    INSERT INTO public.p3_policy_artifacts (
        policy_artifact_id,
        artifact_key,
        artifact_class,
        source_authority_lineage_id,
        artifact_version,
        effective_from,
        resource_scope,
        act_scope,
        lineage_provenance_id
    ) VALUES (
        v_policy,
        'policy.legitimacy.root',
        'projection_policy',
        v_authority,
        'v1',
        '2026-01-01T00:00:00Z',
        'asset_batch',
        'admissibility_decision',
        '89000000-0000-0000-0000-000000000211'
    );

    INSERT INTO public.p3_projection_universes (
        projection_universe_id,
        projection_universe_key,
        projection_purpose,
        replay_algorithm_version,
        temporal_evaluation_point,
        source_record_set,
        replay_reconstruction_inputs,
        lineage_provenance_id
    ) VALUES (
        v_universe,
        'projection.legitimacy.default',
        'legitimacy_view',
        'phase3-legitimacy-v1',
        '2026-02-01T00:00:00Z',
        '{"root_node_key":"p3.legitimacy.child"}'::jsonb,
        '{"ordering":"depth,node_key,node_id","trust_boundary":"persisted-only"}'::jsonb,
        '8a000000-0000-0000-0000-000000000211'
    );

    INSERT INTO public.p3_legitimacy_projection_records (
        legitimacy_projection_record_id,
        projection_universe_id,
        subject_node_id,
        source_policy_artifact_id,
        source_authority_lineage_id,
        derived_state,
        blocking_ancestor_node_id,
        projection_context_hash,
        replay_reconstruction_inputs,
        projection_metadata,
        lineage_provenance_id,
        evaluated_at
    ) VALUES (
        '8b000000-0000-0000-0000-000000000211',
        v_universe,
        v_root,
        v_policy,
        v_authority,
        'illegitimate',
        v_root,
        'ctx-hash-root-illegitimate',
        '{"source":"seed"}'::jsonb,
        '{"reason":"ancestor-invalid"}'::jsonb,
        '8c000000-0000-0000-0000-000000000211',
        '2026-02-01T00:01:00Z'
    );

    SELECT
        derived_state,
        blocking_ancestor_node_id,
        traversed_node_count
    INTO
        v_state,
        v_blocking,
        v_count
    FROM public.p3_evaluate_legitimacy_projection(
        'projection.legitimacy.default',
        v_child
    );

    IF v_state <> 'blocked' THEN
        RAISE EXCEPTION 'STATE_MISMATCH:%', v_state
            USING ERRCODE = 'P3207';
    END IF;

    IF v_blocking <> v_root THEN
        RAISE EXCEPTION 'BLOCKING_MISMATCH:%', coalesce(v_blocking::text, 'NULL')
            USING ERRCODE = 'P3207';
    END IF;

    IF v_count <> 3 THEN
        RAISE EXCEPTION 'TRAVERSAL_COUNT_MISMATCH:%', v_count
            USING ERRCODE = 'P3207';
    END IF;

    PERFORM public.p3_assert_legitimacy_projection(
        'projection.legitimacy.default',
        v_clean
    );

    BEGIN
        PERFORM public.p3_assert_legitimacy_projection(
            'projection.legitimacy.default',
            v_child
        );
        RAISE EXCEPTION 'NEGATIVE_ILLEGITIMATE_ANCESTOR_MISSED'
            USING ERRCODE = 'P3207';
    EXCEPTION
        WHEN SQLSTATE 'P3002' THEN
            NULL;
    END;

    RAISE NOTICE 'LEGITIMACY_OK';
    RAISE NOTICE 'NEGATIVE_OK';
END;
$$;
ROLLBACK;
SQL
)"
record_command "exercise recursive legitimacy evaluation and illegitimate-ancestor blocking in a rollback transaction"
if LEGITIMACY_OUT="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X 2>&1 <<<"$LEGITIMACY_SQL")"; then
  record_trace "legitimacy exercise completed"
  if grep -q 'LEGITIMACY_OK' <<<"$LEGITIMACY_OUT"; then
    record_check "recursive_legitimacy_projection" "PASS" "recursive legitimacy evaluation identifies illegitimate ancestors deterministically"
  else
    record_check "recursive_legitimacy_projection" "FAIL" "legitimacy exercise did not emit LEGITIMACY_OK"
  fi

  if grep -q 'NEGATIVE_OK' <<<"$LEGITIMACY_OUT"; then
    record_check "illegitimate_ancestor_blocking" "PASS" "illegitimate-ancestor assertion fails closed with SQLSTATE P3002"
  else
    record_check "illegitimate_ancestor_blocking" "FAIL" "legitimacy negative test did not emit NEGATIVE_OK"
  fi
else
  record_trace "legitimacy exercise failed"
  record_check "recursive_legitimacy_projection" "FAIL" "psql legitimacy exercise failed"
  record_check "illegitimate_ancestor_blocking" "FAIL" "psql legitimacy negative test failed"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-WP-003 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-WP-003' "$ROOT/$REGISTRY_PATH" || true)"
ADR_MATCHES="$(grep -c '0211' "$ROOT/$ADR_PATH" || true)"
SQLSTATE_MATCHES="$(grep -c '"P3002"' "$ROOT/$SQLSTATE_MAP_PATH" || true)"
record_command "inspect runtime task index, phase3 task registry, ADR-0010, and sqlstate map"
[[ "$RUNTIME_INDEX_MATCHES" -ge 1 ]] \
  && record_check "runtime_index_registered" "PASS" "PHASE3 runtime index contains TSK-P3-WP-003" \
  || record_check "runtime_index_registered" "FAIL" "TSK-P3-WP-003 missing from PHASE3 runtime index"
[[ "$REGISTRY_MATCHES" -ge 1 ]] \
  && record_check "phase3_registry_registered" "PASS" "phase3_task_registry.yml contains TSK-P3-WP-003" \
  || record_check "phase3_registry_registered" "FAIL" "TSK-P3-WP-003 missing from phase3_task_registry.yml"
[[ "$ADR_MATCHES" -ge 1 ]] \
  && record_check "adr_rebaseline_recorded" "PASS" "ADR-0010 references MIGRATION_HEAD 0211" \
  || record_check "adr_rebaseline_recorded" "FAIL" "ADR-0010 missing 0211 baseline note"
[[ "$SQLSTATE_MATCHES" -ge 1 ]] \
  && record_check "sqlstate_registered" "PASS" "sqlstate map contains P3002 for recursive legitimacy blocking" \
  || record_check "sqlstate_registered" "FAIL" "sqlstate map missing P3002"

if [[ "$PASS" == "true" ]]; then
  STATUS="PASS"
  PASS_FLAG="true"
else
  STATUS="FAIL"
  PASS_FLAG="false"
fi

export ROOT TASK_ID GIT_SHA TIMESTAMP_UTC STATUS PASS_FLAG CHECKS_FILE COMMANDS_FILE TRACE_FILE
export MIGRATION_PATH VERIFIER_PATH HEAD_PATH ADR_PATH SQLSTATE_MAP_PATH RUNTIME_INDEX_PATH REGISTRY_PATH META_PATH PLAN_PATH EXEC_LOG_PATH

python3 - <<'PY'
import hashlib
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT"])
paths = [
    os.environ["MIGRATION_PATH"],
    os.environ["VERIFIER_PATH"],
    os.environ["HEAD_PATH"],
    os.environ["ADR_PATH"],
    os.environ["SQLSTATE_MAP_PATH"],
    os.environ["RUNTIME_INDEX_PATH"],
    os.environ["REGISTRY_PATH"],
    os.environ["META_PATH"],
    os.environ["PLAN_PATH"],
    os.environ["EXEC_LOG_PATH"],
]

def sha256_for(rel_path: str) -> str:
    data = (root / rel_path).read_bytes()
    return hashlib.sha256(data).hexdigest()

checks = {}
for line in Path(os.environ["CHECKS_FILE"]).read_text(encoding="utf-8").splitlines():
    if not line.strip():
        continue
    key, status, detail = line.split("\t", 2)
    checks[key] = {"status": status, "detail": detail}

command_outputs = [{"command": line, "status": "recorded"} for line in Path(os.environ["COMMANDS_FILE"]).read_text(encoding="utf-8").splitlines() if line.strip()]
execution_trace = [line for line in Path(os.environ["TRACE_FILE"]).read_text(encoding="utf-8").splitlines() if line.strip()]

payload = {
    "task_id": os.environ["TASK_ID"],
    "git_sha": os.environ["GIT_SHA"],
    "timestamp_utc": os.environ["TIMESTAMP_UTC"],
    "status": os.environ["STATUS"],
    "pass": os.environ["PASS_FLAG"].lower() == "true",
    "checks": checks,
    "observed_paths": paths,
    "observed_hashes": {path: sha256_for(path) for path in paths},
    "command_outputs": command_outputs,
    "execution_trace": execution_trace,
}
print(json.dumps(payload, indent=2))
PY
