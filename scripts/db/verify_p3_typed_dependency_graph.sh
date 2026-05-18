#!/usr/bin/env bash
# TSK-P3-WP-001 verifier: typed dependency graph substrate and deterministic traversal.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-WP-001"
MIGRATION_PATH="schema/migrations/0207_p3_typed_dependency_graph.sql"
VERIFIER_PATH="scripts/db/verify_p3_typed_dependency_graph.sh"
HEAD_PATH="schema/migrations/MIGRATION_HEAD"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-WP-001/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-WP-001/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-WP-001/EXEC_LOG.md"

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
if [[ "$HEAD_TOKEN" =~ ^[0-9]{4}$ ]] && (( 10#$HEAD_TOKEN >= 207 )); then
  record_check "migration_head_forward_only" "PASS" "MIGRATION_HEAD=$HEAD_TOKEN (>=0207)"
else
  record_check "migration_head_forward_only" "FAIL" "unexpected MIGRATION_HEAD=$HEAD_TOKEN"
fi

NODE_TABLE_EXISTS="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_dependency_nodes')::text, '');")"
EDGE_TABLE_EXISTS="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_dependency_edges')::text, '');")"
ADJ_VIEW_EXISTS="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_typed_dependency_adjacency')::text, '');")"
FUNCTION_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'p3_collect_upstream_dependencies';")"
record_command "inspect typed dependency graph relations and traversal function"

[[ "$NODE_TABLE_EXISTS" == "p3_dependency_nodes" ]] \
  && record_check "node_table_exists" "PASS" "public.p3_dependency_nodes exists" \
  || record_check "node_table_exists" "FAIL" "public.p3_dependency_nodes missing"
[[ "$EDGE_TABLE_EXISTS" == "p3_dependency_edges" ]] \
  && record_check "edge_table_exists" "PASS" "public.p3_dependency_edges exists" \
  || record_check "edge_table_exists" "FAIL" "public.p3_dependency_edges missing"
[[ "$ADJ_VIEW_EXISTS" == "p3_typed_dependency_adjacency" ]] \
  && record_check "adjacency_view_exists" "PASS" "public.p3_typed_dependency_adjacency exists" \
  || record_check "adjacency_view_exists" "FAIL" "public.p3_typed_dependency_adjacency missing"
[[ "$FUNCTION_COUNT" == "1" ]] \
  && record_check "closure_function_exists" "PASS" "p3_collect_upstream_dependencies(uuid) exists" \
  || record_check "closure_function_exists" "FAIL" "p3_collect_upstream_dependencies(uuid) missing"

NODE_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_dependency_node_kind'::regtype;")"
EDGE_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_dependency_edge_kind'::regtype;")"
record_command "inspect enum cardinalities for dependency node and edge kinds"
[[ "$NODE_ENUM_COUNT" == "2" ]] \
  && record_check "node_kind_enum" "PASS" "p3_dependency_node_kind has 2 values" \
  || record_check "node_kind_enum" "FAIL" "p3_dependency_node_kind count=$NODE_ENUM_COUNT"
[[ "$EDGE_ENUM_COUNT" == "5" ]] \
  && record_check "edge_kind_enum" "PASS" "p3_dependency_edge_kind has 5 values" \
  || record_check "edge_kind_enum" "FAIL" "p3_dependency_edge_kind count=$EDGE_ENUM_COUNT"

PROVENANCE_CONSTRAINTS="$(safe_sql "
SELECT COUNT(*)
FROM information_schema.columns
WHERE table_schema = 'public'
  AND (
    (table_name = 'p3_dependency_nodes' AND column_name = 'lineage_provenance_id' AND is_nullable = 'NO')
    OR
    (table_name = 'p3_dependency_edges' AND column_name = 'lineage_provenance_id' AND is_nullable = 'NO')
  );
")"
record_command "inspect provenance identifier nullability constraints"
[[ "$PROVENANCE_CONSTRAINTS" == "2" ]] \
  && record_check "provenance_columns_present" "PASS" "lineage_provenance_id columns are NOT NULL on nodes and edges" \
  || record_check "provenance_columns_present" "FAIL" "expected 2 lineage_provenance_id NOT NULL columns, got $PROVENANCE_CONSTRAINTS"

TRAVERSAL_SQL="$(cat <<'SQL'
BEGIN;
DO $$
DECLARE
    v_root uuid := '10000000-0000-0000-0000-000000000207';
    v_parent uuid := '20000000-0000-0000-0000-000000000207';
    v_fact uuid := '30000000-0000-0000-0000-000000000207';
    v_rows text[];
BEGIN
    INSERT INTO public.p3_dependency_nodes (node_id, node_key, node_kind, lineage_provenance_id)
    VALUES
        (v_root, 'p3.demo.root', 'decision_record', '40000000-0000-0000-0000-000000000207'),
        (v_parent, 'p3.demo.parent', 'decision_record', '50000000-0000-0000-0000-000000000207'),
        (v_fact, 'p3.demo.fact', 'fact_record', '60000000-0000-0000-0000-000000000207');

    INSERT INTO public.p3_dependency_edges (edge_id, downstream_node_id, upstream_node_id, dependency_kind, lineage_provenance_id)
    VALUES
        ('70000000-0000-0000-0000-000000000207', v_root, v_parent, 'decision_input', '71000000-0000-0000-0000-000000000207'),
        ('72000000-0000-0000-0000-000000000207', v_parent, v_fact, 'fact_input', '73000000-0000-0000-0000-000000000207');

    SELECT array_agg(format('%s:%s:%s', depth, dependency_kind::text, upstream_node_key) ORDER BY depth, dependency_kind::text, upstream_node_key)
    INTO v_rows
    FROM public.p3_collect_upstream_dependencies(v_root);

    IF v_rows IS DISTINCT FROM ARRAY['1:decision_input:p3.demo.parent', '2:fact_input:p3.demo.fact'] THEN
        RAISE EXCEPTION 'TRAVERSAL_MISMATCH:%', coalesce(array_to_string(v_rows, ','), 'NULL')
            USING ERRCODE = 'P3207';
    END IF;

    BEGIN
        INSERT INTO public.p3_dependency_edges (downstream_node_id, upstream_node_id)
        VALUES (v_root, v_parent);
        RAISE EXCEPTION 'NEGATIVE_NOT_NULL_MISSED'
            USING ERRCODE = 'P3207';
    EXCEPTION
        WHEN not_null_violation THEN
            NULL;
    END;

    BEGIN
        INSERT INTO public.p3_dependency_edges (downstream_node_id, upstream_node_id, dependency_kind)
        VALUES (v_root, '90000000-0000-0000-0000-000000000207', 'fact_input');
        RAISE EXCEPTION 'NEGATIVE_FK_MISSED'
            USING ERRCODE = 'P3207';
    EXCEPTION
        WHEN foreign_key_violation THEN
            NULL;
    END;

    RAISE NOTICE 'TRAVERSAL_OK';
    RAISE NOTICE 'NEGATIVE_OK';
END;
$$;
ROLLBACK;
SQL
)"
record_command "exercise deterministic traversal and negative insertion constraints in a rollback transaction"
if TRAVERSAL_OUT="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X 2>&1 <<<"$TRAVERSAL_SQL")"; then
  record_trace "traversal exercise completed"
  if grep -q 'TRAVERSAL_OK' <<<"$TRAVERSAL_OUT"; then
    record_check "deterministic_traversal" "PASS" "recursive closure returns ordered upstream lineage"
  else
    record_check "deterministic_traversal" "FAIL" "recursive closure did not emit TRAVERSAL_OK"
  fi

  if grep -q 'NEGATIVE_OK' <<<"$TRAVERSAL_OUT"; then
    record_check "incomplete_dependency_rejected" "PASS" "NOT NULL and FK failures raised transactionally"
  else
    record_check "incomplete_dependency_rejected" "FAIL" "negative insertion checks did not emit NEGATIVE_OK"
  fi
else
  record_trace "traversal exercise failed"
  record_check "deterministic_traversal" "FAIL" "psql traversal exercise failed"
  record_check "incomplete_dependency_rejected" "FAIL" "psql negative insertion exercise failed"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-WP-001 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-WP-001' "$ROOT/$REGISTRY_PATH" || true)"
record_command "inspect runtime task index and phase3 task registry entries"
[[ "$RUNTIME_INDEX_MATCHES" -ge 1 ]] \
  && record_check "runtime_index_registered" "PASS" "PHASE3 runtime index contains TSK-P3-WP-001" \
  || record_check "runtime_index_registered" "FAIL" "TSK-P3-WP-001 missing from PHASE3 runtime index"
[[ "$REGISTRY_MATCHES" -ge 1 ]] \
  && record_check "phase3_registry_registered" "PASS" "phase3_task_registry.yml contains TSK-P3-WP-001" \
  || record_check "phase3_registry_registered" "FAIL" "TSK-P3-WP-001 missing from phase3_task_registry.yml"

if [[ "$PASS" == "true" ]]; then
  STATUS="PASS"
  PASS_FLAG="true"
else
  STATUS="FAIL"
  PASS_FLAG="false"
fi

export ROOT TASK_ID GIT_SHA TIMESTAMP_UTC STATUS PASS_FLAG CHECKS_FILE COMMANDS_FILE TRACE_FILE
export MIGRATION_PATH VERIFIER_PATH HEAD_PATH RUNTIME_INDEX_PATH REGISTRY_PATH META_PATH PLAN_PATH EXEC_LOG_PATH

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
