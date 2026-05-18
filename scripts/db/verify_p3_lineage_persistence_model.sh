#!/usr/bin/env bash
# TSK-P3-SUPPORT-DB-001 verifier: shared persistence model for Phase 3 lineage surfaces.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-SUPPORT-DB-001"
MIGRATION_PATH="schema/migrations/0209_p3_lineage_persistence_model.sql"
VERIFIER_PATH="scripts/db/verify_p3_lineage_persistence_model.sh"
HEAD_PATH="schema/migrations/MIGRATION_HEAD"
ADR_PATH="docs/decisions/ADR-0010-baseline-policy.md"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-SUPPORT-DB-001/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-SUPPORT-DB-001/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-SUPPORT-DB-001/EXEC_LOG.md"

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

record_trace "start verifier for $TASK_ID"

HEAD_TOKEN="$(tr -d '\n\r[:space:]' < "$ROOT/$HEAD_PATH")"
record_command "read $HEAD_PATH => $HEAD_TOKEN"
if [[ "$HEAD_TOKEN" =~ ^[0-9]{4}$ ]] && (( 10#$HEAD_TOKEN >= 209 )); then
  record_check "migration_head_forward_only" "PASS" "MIGRATION_HEAD=$HEAD_TOKEN (>=0209)"
else
  record_check "migration_head_forward_only" "FAIL" "unexpected MIGRATION_HEAD=$HEAD_TOKEN"
fi

ANCHOR_TABLE_EXISTS="$(sql "SELECT COALESCE(to_regclass('public.p3_lineage_continuity_anchors')::text, '');" 2>/dev/null || true)"
MANIFEST_VIEW_EXISTS="$(sql "SELECT COALESCE(to_regclass('public.p3_lineage_persistence_manifest')::text, '');" 2>/dev/null || true)"
FUNCTION_COUNT="$(sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'p3_deny_lineage_mutation';" 2>/dev/null || echo 0)"
TRIGGER_COUNT="$(sql "SELECT COUNT(*) FROM pg_trigger WHERE NOT tgisinternal AND tgname IN ('trg_deny_p3_dependency_nodes_mutation', 'trg_deny_p3_dependency_edges_mutation', 'trg_deny_p3_authority_lineage_mutation', 'trg_deny_p3_policy_artifacts_mutation', 'trg_deny_p3_lineage_continuity_anchors_mutation');" 2>/dev/null || echo 0)"
record_command "inspect shared lineage persistence relations, function, and append-only triggers"

[[ "$ANCHOR_TABLE_EXISTS" == "p3_lineage_continuity_anchors" ]] \
  && record_check "continuity_anchor_table_exists" "PASS" "public.p3_lineage_continuity_anchors exists" \
  || record_check "continuity_anchor_table_exists" "FAIL" "public.p3_lineage_continuity_anchors missing"
[[ "$MANIFEST_VIEW_EXISTS" == "p3_lineage_persistence_manifest" ]] \
  && record_check "persistence_manifest_exists" "PASS" "public.p3_lineage_persistence_manifest exists" \
  || record_check "persistence_manifest_exists" "FAIL" "public.p3_lineage_persistence_manifest missing"
[[ "$FUNCTION_COUNT" == "1" ]] \
  && record_check "append_only_function_exists" "PASS" "p3_deny_lineage_mutation() exists" \
  || record_check "append_only_function_exists" "FAIL" "p3_deny_lineage_mutation() missing"
[[ "$TRIGGER_COUNT" == "5" ]] \
  && record_check "append_only_triggers_exist" "PASS" "five append-only triggers protect lineage persistence tables" \
  || record_check "append_only_triggers_exist" "FAIL" "expected 5 append-only triggers, got $TRIGGER_COUNT"

ANCHOR_COLUMNS="$(sql "
SELECT COUNT(*)
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'p3_lineage_continuity_anchors'
  AND column_name IN ('surface_id', 'artifact_kind', 'artifact_locator', 'lineage_provenance_id', 'continuity_scope', 'replay_reconstruction_inputs', 'phase2_compatibility_intent');
" 2>/dev/null || echo 0)"
SURFACE_ENUM_COUNT="$(sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_lineage_surface_id'::regtype;" 2>/dev/null || echo 0)"
record_command "inspect continuity-anchor columns and surface enum"
[[ "$ANCHOR_COLUMNS" == "7" ]] \
  && record_check "continuity_anchor_columns" "PASS" "continuity anchor table exposes required persistence fields" \
  || record_check "continuity_anchor_columns" "FAIL" "expected 7 required continuity anchor columns, got $ANCHOR_COLUMNS"
[[ "$SURFACE_ENUM_COUNT" == "2" ]] \
  && record_check "surface_enum" "PASS" "p3_lineage_surface_id has 2 wave-1 surface values" \
  || record_check "surface_enum" "FAIL" "p3_lineage_surface_id count=$SURFACE_ENUM_COUNT"

PERSISTENCE_SQL="$(cat <<'SQL'
BEGIN;
DO $$
DECLARE
    v_node uuid := '10000000-0000-0000-0000-000000000209';
    v_authority uuid := '20000000-0000-0000-0000-000000000209';
    v_policy uuid := '30000000-0000-0000-0000-000000000209';
    v_anchor uuid := '40000000-0000-0000-0000-000000000209';
    v_rows text[];
BEGIN
    INSERT INTO public.p3_dependency_nodes (
        node_id,
        node_key,
        node_kind,
        lineage_provenance_id
    ) VALUES (
        v_node,
        'p3.persistence.node',
        'decision_record',
        '50000000-0000-0000-0000-000000000209'
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
        v_authority,
        'authority.persistence.root',
        'constitutional_document',
        'constitution://phase3/persistence/root',
        'asset_batch',
        'admissibility_decision',
        '2026-01-01T00:00:00Z',
        '60000000-0000-0000-0000-000000000209'
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
        'policy.persistence.demo',
        'replay_policy',
        v_authority,
        'v1',
        '2026-01-02T00:00:00Z',
        'asset_batch',
        'admissibility_decision',
        '70000000-0000-0000-0000-000000000209'
    );

    INSERT INTO public.p3_lineage_continuity_anchors (
        continuity_anchor_id,
        surface_id,
        artifact_kind,
        artifact_locator,
        lineage_provenance_id,
        continuity_scope,
        replay_reconstruction_inputs,
        phase2_compatibility_intent
    ) VALUES (
        v_anchor,
        'P3-SURF-002',
        'policy_artifact',
        'policy.persistence.demo@v1',
        '70000000-0000-0000-0000-000000000209',
        'internal_replay_boundary',
        '{"package_schema_version":"v1","ordering":"semantic+provenance"}'::jsonb,
        'compatible-intent-only'
    );

    SELECT array_agg(surface_id::text || ':' || artifact_kind ORDER BY surface_id::text, artifact_kind, primary_record_id)
    INTO v_rows
    FROM public.p3_lineage_persistence_manifest
    WHERE primary_record_id IN (v_node, v_authority, v_policy, v_anchor);

    IF v_rows IS DISTINCT FROM ARRAY[
        'P3-SURF-001:dependency_node',
        'P3-SURF-002:authority_lineage',
        'P3-SURF-002:continuity_anchor',
        'P3-SURF-002:policy_artifact'
    ] THEN
        RAISE EXCEPTION 'MANIFEST_MISMATCH:%', coalesce(array_to_string(v_rows, ','), 'NULL')
            USING ERRCODE = 'P3902';
    END IF;

    BEGIN
        UPDATE public.p3_dependency_nodes
        SET node_key = 'p3.persistence.node.mutated'
        WHERE node_id = v_node;
        RAISE EXCEPTION 'NEGATIVE_NODE_UPDATE_MISSED'
            USING ERRCODE = 'P3902';
    EXCEPTION
        WHEN SQLSTATE 'P3901' THEN
            NULL;
    END;

    BEGIN
        DELETE FROM public.p3_lineage_continuity_anchors
        WHERE continuity_anchor_id = v_anchor;
        RAISE EXCEPTION 'NEGATIVE_ANCHOR_DELETE_MISSED'
            USING ERRCODE = 'P3902';
    EXCEPTION
        WHEN SQLSTATE 'P3901' THEN
            NULL;
    END;

    RAISE NOTICE 'MANIFEST_OK';
    RAISE NOTICE 'NEGATIVE_OK';
END;
$$;
ROLLBACK;
SQL
)"
record_command "exercise persistence manifest and append-only enforcement in a rollback transaction"
if PERSISTENCE_OUT="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X 2>&1 <<<"$PERSISTENCE_SQL")"; then
  record_trace "persistence exercise completed"
  if grep -q 'MANIFEST_OK' <<<"$PERSISTENCE_OUT"; then
    record_check "persistence_manifest" "PASS" "shared manifest spans both owning surfaces and continuity anchors"
  else
    record_check "persistence_manifest" "FAIL" "persistence exercise did not emit MANIFEST_OK"
  fi

  if grep -q 'NEGATIVE_OK' <<<"$PERSISTENCE_OUT"; then
    record_check "append_only_enforced" "PASS" "append-only persistence blocks updates and deletes transactionally"
  else
    record_check "append_only_enforced" "FAIL" "append-only negative tests did not emit NEGATIVE_OK"
  fi
else
  record_trace "persistence exercise failed"
  record_check "persistence_manifest" "FAIL" "psql persistence exercise failed"
  record_check "append_only_enforced" "FAIL" "psql append-only exercise failed"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-SUPPORT-DB-001 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-SUPPORT-DB-001' "$ROOT/$REGISTRY_PATH" || true)"
ADR_MATCHES="$(grep -c '0209' "$ROOT/$ADR_PATH" || true)"
record_command "inspect runtime task index, phase3 task registry, and ADR-0010 record"
[[ "$RUNTIME_INDEX_MATCHES" -ge 1 ]] \
  && record_check "runtime_index_registered" "PASS" "PHASE3 runtime index contains TSK-P3-SUPPORT-DB-001" \
  || record_check "runtime_index_registered" "FAIL" "TSK-P3-SUPPORT-DB-001 missing from PHASE3 runtime index"
[[ "$REGISTRY_MATCHES" -ge 1 ]] \
  && record_check "phase3_registry_registered" "PASS" "phase3_task_registry.yml contains TSK-P3-SUPPORT-DB-001" \
  || record_check "phase3_registry_registered" "FAIL" "TSK-P3-SUPPORT-DB-001 missing from phase3_task_registry.yml"
[[ "$ADR_MATCHES" -ge 1 ]] \
  && record_check "adr_rebaseline_recorded" "PASS" "ADR-0010 references MIGRATION_HEAD 0209" \
  || record_check "adr_rebaseline_recorded" "FAIL" "ADR-0010 missing 0209 baseline note"

if [[ "$PASS" == "true" ]]; then
  STATUS="PASS"
  PASS_FLAG="true"
else
  STATUS="FAIL"
  PASS_FLAG="false"
fi

export ROOT TASK_ID GIT_SHA TIMESTAMP_UTC STATUS PASS_FLAG CHECKS_FILE COMMANDS_FILE TRACE_FILE
export MIGRATION_PATH VERIFIER_PATH HEAD_PATH ADR_PATH RUNTIME_INDEX_PATH REGISTRY_PATH META_PATH PLAN_PATH EXEC_LOG_PATH

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
