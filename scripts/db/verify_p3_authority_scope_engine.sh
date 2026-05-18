#!/usr/bin/env bash
# TSK-P3-WP-006 verifier: authority scope and delegation enforcement substrate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-WP-006"
MIGRATION_PATH="schema/migrations/0212_p3_authority_scope_engine.sql"
VERIFIER_PATH="scripts/db/verify_p3_authority_scope_engine.sh"
HEAD_PATH="schema/migrations/MIGRATION_HEAD"
ADR_PATH="docs/decisions/ADR-0010-baseline-policy.md"
SQLSTATE_MAP_PATH="docs/contracts/sqlstate_map.yml"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-WP-006/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-WP-006/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-WP-006/EXEC_LOG.md"

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
if [[ "$HEAD_TOKEN" =~ ^[0-9]{4}$ ]] && (( 10#$HEAD_TOKEN >= 212 )); then
  record_check "migration_head_forward_only" "PASS" "MIGRATION_HEAD=$HEAD_TOKEN (>=0212)"
else
  record_check "migration_head_forward_only" "FAIL" "unexpected MIGRATION_HEAD=$HEAD_TOKEN"
fi

SCOPE_TABLE_EXISTS="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_authority_scope_records')::text, '');")"
MANIFEST_VIEW_EXISTS="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_authority_scope_manifest')::text, '');")"
EVALUATE_FUNCTION_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'p3_evaluate_authority_scope';")"
ASSERT_FUNCTION_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'p3_assert_authority_scope';")"
record_command "inspect authority scope relations and functions"

[[ "$SCOPE_TABLE_EXISTS" == "p3_authority_scope_records" ]] \
  && record_check "authority_scope_table_exists" "PASS" "public.p3_authority_scope_records exists" \
  || record_check "authority_scope_table_exists" "FAIL" "public.p3_authority_scope_records missing"
[[ "$MANIFEST_VIEW_EXISTS" == "p3_authority_scope_manifest" ]] \
  && record_check "authority_scope_manifest_exists" "PASS" "public.p3_authority_scope_manifest exists" \
  || record_check "authority_scope_manifest_exists" "FAIL" "public.p3_authority_scope_manifest missing"
[[ "$EVALUATE_FUNCTION_COUNT" == "1" ]] \
  && record_check "evaluate_function_exists" "PASS" "p3_evaluate_authority_scope(uuid, text, text, timestamptz) exists" \
  || record_check "evaluate_function_exists" "FAIL" "p3_evaluate_authority_scope(uuid, text, text, timestamptz) missing"
[[ "$ASSERT_FUNCTION_COUNT" == "1" ]] \
  && record_check "assert_function_exists" "PASS" "p3_assert_authority_scope(uuid, text, text, timestamptz) exists" \
  || record_check "assert_function_exists" "FAIL" "p3_assert_authority_scope(uuid, text, text, timestamptz) missing"

STATE_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_authority_enforcement_state'::regtype;")"
TRACEABILITY_COLUMNS="$(safe_sql "
SELECT COUNT(*)
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'p3_authority_scope_records'
  AND column_name IN ('supporting_policy_artifact_id', 'supporting_dependency_node_id', 'claimed_resource_scope', 'claimed_act_scope', 'revocation_lineage_snapshot', 'delegation_depth');
")"
record_command "inspect authority enforcement enum and traceability columns"
[[ "$STATE_ENUM_COUNT" == "4" ]] \
  && record_check "authority_state_enum" "PASS" "p3_authority_enforcement_state has 4 values" \
  || record_check "authority_state_enum" "FAIL" "p3_authority_enforcement_state count=$STATE_ENUM_COUNT"
[[ "$TRACEABILITY_COLUMNS" == "6" ]] \
  && record_check "authority_traceability_columns" "PASS" "authority scope records preserve policy/dependency traceability and revocation metadata" \
  || record_check "authority_traceability_columns" "FAIL" "expected 6 authority traceability columns, got $TRACEABILITY_COLUMNS"

AUTHORITY_SQL="$(cat <<'SQL'
BEGIN;
DO $$
DECLARE
    v_root uuid := '10000000-0000-0000-0000-000000000212';
    v_delegate uuid := '20000000-0000-0000-0000-000000000212';
    v_revoked uuid := '30000000-0000-0000-0000-000000000212';
    v_dependency uuid := '40000000-0000-0000-0000-000000000212';
    v_policy uuid := '50000000-0000-0000-0000-000000000212';
    v_state public.p3_authority_enforcement_state;
    v_root_authority uuid;
    v_depth integer;
    v_revoked_state public.p3_authority_enforcement_state;
    v_out_of_scope_state public.p3_authority_enforcement_state;
    v_overflow_state public.p3_authority_enforcement_state;
BEGIN
    INSERT INTO public.p3_dependency_nodes (
        node_id,
        node_key,
        node_kind,
        lineage_provenance_id
    ) VALUES (
        v_dependency,
        'p3.authority.scope.dependency',
        'decision_record',
        '60000000-0000-0000-0000-000000000212'
    );

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
        v_root,
        'authority.scope.root',
        'constitutional_document',
        'constitution://phase3/authority/scope-root',
        'asset_batch',
        'admissibility_decision',
        '2026-01-01T00:00:00Z',
        '61000000-0000-0000-0000-000000000212'
    );

    INSERT INTO public.p3_authority_lineage (
        authority_lineage_id,
        authority_key,
        authority_source_kind,
        source_reference,
        delegated_from_authority_lineage_id,
        resource_scope,
        act_scope,
        effective_from,
        lineage_provenance_id
    ) VALUES (
        v_delegate,
        'authority.scope.delegate',
        'delegated_authority',
        'delegation://phase3/authority/scope-delegate',
        v_root,
        'asset_batch',
        'admissibility_decision',
        '2026-02-01T00:00:00Z',
        '62000000-0000-0000-0000-000000000212'
    );

    INSERT INTO public.p3_authority_lineage (
        authority_lineage_id,
        authority_key,
        authority_source_kind,
        source_reference,
        delegated_from_authority_lineage_id,
        revoked_by_authority_lineage_id,
        revocation_lineage_metadata,
        resource_scope,
        act_scope,
        effective_from,
        lineage_provenance_id
    ) VALUES (
        v_revoked,
        'authority.scope.revoked',
        'delegated_authority',
        'delegation://phase3/authority/scope-revoked',
        v_root,
        v_root,
        '{"reason":"root-revoked"}'::jsonb,
        'asset_batch',
        'admissibility_decision',
        '2026-02-01T00:00:00Z',
        '63000000-0000-0000-0000-000000000212'
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
        'policy.authority.scope',
        'authority_policy',
        v_root,
        'v1',
        '2026-01-01T00:00:00Z',
        'asset_batch',
        'admissibility_decision',
        '64000000-0000-0000-0000-000000000212'
    );

    SELECT
        enforcement_state,
        resolved_root_authority_lineage_id,
        delegation_depth
    INTO
        v_state,
        v_root_authority,
        v_depth
    FROM public.p3_evaluate_authority_scope(
        v_delegate,
        'asset_batch',
        'admissibility_decision',
        '2026-03-01T00:00:00Z'
    );

    IF v_state <> 'authorized' THEN
        RAISE EXCEPTION 'AUTHORIZED_STATE_MISMATCH:%', v_state
            USING ERRCODE = 'P3208';
    END IF;

    IF v_root_authority <> v_root THEN
        RAISE EXCEPTION 'ROOT_AUTHORITY_MISMATCH:%', coalesce(v_root_authority::text, 'NULL')
            USING ERRCODE = 'P3208';
    END IF;

    IF v_depth <> 2 THEN
        RAISE EXCEPTION 'DELEGATION_DEPTH_MISMATCH:%', v_depth
            USING ERRCODE = 'P3208';
    END IF;

    SELECT enforcement_state
    INTO v_revoked_state
    FROM public.p3_evaluate_authority_scope(
        v_revoked,
        'asset_batch',
        'admissibility_decision',
        '2026-03-01T00:00:00Z'
    );

    IF v_revoked_state <> 'revoked' THEN
        RAISE EXCEPTION 'REVOKED_STATE_MISMATCH:%', v_revoked_state
            USING ERRCODE = 'P3208';
    END IF;

    SELECT enforcement_state
    INTO v_out_of_scope_state
    FROM public.p3_evaluate_authority_scope(
        v_root,
        'other_scope',
        'admissibility_decision',
        '2026-03-01T00:00:00Z'
    );

    IF v_out_of_scope_state <> 'out_of_scope' THEN
        RAISE EXCEPTION 'OUT_OF_SCOPE_MISMATCH:%', v_out_of_scope_state
            USING ERRCODE = 'P3208';
    END IF;

    SELECT enforcement_state
    INTO v_overflow_state
    FROM public.p3_evaluate_authority_scope(
        v_delegate,
        'other_scope',
        'admissibility_decision',
        '2026-03-01T00:00:00Z'
    );

    IF v_overflow_state <> 'delegation_overflow' THEN
        RAISE EXCEPTION 'OVERFLOW_MISMATCH:%', v_overflow_state
            USING ERRCODE = 'P3208';
    END IF;

    BEGIN
        PERFORM public.p3_assert_authority_scope(
            v_root,
            'other_scope',
            'admissibility_decision',
            '2026-03-01T00:00:00Z'
        );
        RAISE EXCEPTION 'NEGATIVE_OUT_OF_SCOPE_MISSED'
            USING ERRCODE = 'P3208';
    EXCEPTION
        WHEN SQLSTATE 'P3006' THEN
            NULL;
    END;

    BEGIN
        PERFORM public.p3_assert_authority_scope(
            v_delegate,
            'other_scope',
            'admissibility_decision',
            '2026-03-01T00:00:00Z'
        );
        RAISE EXCEPTION 'NEGATIVE_OVERFLOW_MISSED'
            USING ERRCODE = 'P3208';
    EXCEPTION
        WHEN SQLSTATE 'P3006' THEN
            NULL;
    END;

    BEGIN
        PERFORM public.p3_assert_authority_scope(
            v_revoked,
            'asset_batch',
            'admissibility_decision',
            '2026-03-01T00:00:00Z'
        );
        RAISE EXCEPTION 'NEGATIVE_REVOKED_MISSED'
            USING ERRCODE = 'P3208';
    EXCEPTION
        WHEN SQLSTATE 'P3006' THEN
            NULL;
    END;

    INSERT INTO public.p3_authority_scope_records (
        authority_scope_record_id,
        authority_lineage_id,
        supporting_policy_artifact_id,
        supporting_dependency_node_id,
        claimed_resource_scope,
        claimed_act_scope,
        evaluated_effective_at,
        enforcement_state,
        resolved_root_authority_lineage_id,
        delegation_depth,
        revocation_lineage_snapshot,
        lineage_provenance_id
    ) VALUES (
        '65000000-0000-0000-0000-000000000212',
        v_delegate,
        v_policy,
        v_dependency,
        'asset_batch',
        'admissibility_decision',
        '2026-03-01T00:00:00Z',
        'authorized',
        v_root,
        2,
        '{}'::jsonb,
        '66000000-0000-0000-0000-000000000212'
    );

    RAISE NOTICE 'AUTHORITY_OK';
    RAISE NOTICE 'NEGATIVE_OK';
END;
$$;
ROLLBACK;
SQL
)"
record_command "exercise authority scope evaluation, revocation blocking, and out-of-scope blocking in a rollback transaction"
if AUTHORITY_OUT="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X 2>&1 <<<"$AUTHORITY_SQL")"; then
  record_trace "authority exercise completed"
  if grep -q 'AUTHORITY_OK' <<<"$AUTHORITY_OUT"; then
    record_check "authority_scope_evaluation" "PASS" "authority scope evaluation authorizes in-scope delegated authority and preserves root lineage traceability"
  else
    record_check "authority_scope_evaluation" "FAIL" "authority exercise did not emit AUTHORITY_OK"
  fi

  if grep -q 'NEGATIVE_OK' <<<"$AUTHORITY_OUT"; then
    record_check "out_of_scope_and_revoked_blocking" "PASS" "out-of-scope and revoked authority claims fail closed with SQLSTATE P3006"
  else
    record_check "out_of_scope_and_revoked_blocking" "FAIL" "authority negative tests did not emit NEGATIVE_OK"
  fi
else
  record_trace "authority exercise failed"
  record_check "authority_scope_evaluation" "FAIL" "psql authority exercise failed"
  record_check "out_of_scope_and_revoked_blocking" "FAIL" "psql authority negative tests failed"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-WP-006 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-WP-006' "$ROOT/$REGISTRY_PATH" || true)"
ADR_MATCHES="$(grep -c '0212' "$ROOT/$ADR_PATH" || true)"
SQLSTATE_MATCHES="$(grep -c '"P3006"' "$ROOT/$SQLSTATE_MAP_PATH" || true)"
record_command "inspect runtime task index, phase3 task registry, ADR-0010, and sqlstate map"
[[ "$RUNTIME_INDEX_MATCHES" -ge 1 ]] \
  && record_check "runtime_index_registered" "PASS" "PHASE3 runtime index contains TSK-P3-WP-006" \
  || record_check "runtime_index_registered" "FAIL" "TSK-P3-WP-006 missing from PHASE3 runtime index"
[[ "$REGISTRY_MATCHES" -ge 1 ]] \
  && record_check "phase3_registry_registered" "PASS" "phase3_task_registry.yml contains TSK-P3-WP-006" \
  || record_check "phase3_registry_registered" "FAIL" "TSK-P3-WP-006 missing from phase3_task_registry.yml"
[[ "$ADR_MATCHES" -ge 1 ]] \
  && record_check "adr_rebaseline_recorded" "PASS" "ADR-0010 references MIGRATION_HEAD 0212" \
  || record_check "adr_rebaseline_recorded" "FAIL" "ADR-0010 missing 0212 baseline note"
[[ "$SQLSTATE_MATCHES" -ge 1 ]] \
  && record_check "sqlstate_registered" "PASS" "sqlstate map contains P3006 for authority scope blocking" \
  || record_check "sqlstate_registered" "FAIL" "sqlstate map missing P3006"

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
