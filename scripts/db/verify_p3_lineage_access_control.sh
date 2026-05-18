#!/usr/bin/env bash
# TSK-P3-SUPPORT-SEC-001 verifier: shared access-control model for Phase 3 lineage surfaces.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-SUPPORT-SEC-001"
MIGRATION_PATH="schema/migrations/0210_p3_lineage_access_control.sql"
VERIFIER_PATH="scripts/db/verify_p3_lineage_access_control.sh"
HEAD_PATH="schema/migrations/MIGRATION_HEAD"
ADR_PATH="docs/decisions/ADR-0010-baseline-policy.md"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-SUPPORT-SEC-001/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-SUPPORT-SEC-001/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-SUPPORT-SEC-001/EXEC_LOG.md"

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
if [[ "$HEAD_TOKEN" =~ ^[0-9]{4}$ ]] && (( 10#$HEAD_TOKEN >= 210 )); then
  record_check "migration_head_forward_only" "PASS" "MIGRATION_HEAD=$HEAD_TOKEN (>=0210)"
else
  record_check "migration_head_forward_only" "FAIL" "unexpected MIGRATION_HEAD=$HEAD_TOKEN"
fi

READONLY_SELECT="$(sql "SELECT has_table_privilege('symphony_readonly', 'public.p3_lineage_persistence_manifest', 'SELECT');" 2>/dev/null || echo false)"
AUDITOR_SELECT="$(sql "SELECT has_table_privilege('symphony_auditor', 'public.p3_lineage_persistence_manifest', 'SELECT');" 2>/dev/null || echo false)"
EXECUTOR_INSERT="$(sql "SELECT has_table_privilege('symphony_executor', 'public.p3_lineage_continuity_anchors', 'INSERT');" 2>/dev/null || echo false)"
READONLY_INSERT="$(sql "SELECT has_table_privilege('symphony_readonly', 'public.p3_lineage_continuity_anchors', 'INSERT');" 2>/dev/null || echo false)"
READONLY_EXECUTE_DEP="$(sql "SELECT has_function_privilege('symphony_readonly', 'public.p3_collect_upstream_dependencies(uuid)', 'EXECUTE');" 2>/dev/null || echo false)"
READONLY_EXECUTE_AUTH="$(sql "SELECT has_function_privilege('symphony_readonly', 'public.p3_collect_policy_authority_lineage(uuid)', 'EXECUTE');" 2>/dev/null || echo false)"
PUBLIC_EXECUTE_INTERNAL="$(sql "SELECT has_function_privilege('public', 'public.p3_deny_lineage_mutation()', 'EXECUTE');" 2>/dev/null || echo false)"
record_command "inspect lineage privilege grants for writer/read roles and internal mutation function"

[[ "$READONLY_SELECT" == "t" ]] \
  && record_check "readonly_manifest_read" "PASS" "symphony_readonly can SELECT the unified persistence manifest" \
  || record_check "readonly_manifest_read" "FAIL" "symphony_readonly lacks SELECT on p3_lineage_persistence_manifest"
[[ "$AUDITOR_SELECT" == "t" ]] \
  && record_check "auditor_manifest_read" "PASS" "symphony_auditor can SELECT the unified persistence manifest" \
  || record_check "auditor_manifest_read" "FAIL" "symphony_auditor lacks SELECT on p3_lineage_persistence_manifest"
[[ "$EXECUTOR_INSERT" == "t" ]] \
  && record_check "executor_anchor_insert" "PASS" "symphony_executor can INSERT continuity anchors" \
  || record_check "executor_anchor_insert" "FAIL" "symphony_executor lacks INSERT on p3_lineage_continuity_anchors"
[[ "$READONLY_INSERT" == "f" ]] \
  && record_check "readonly_no_insert" "PASS" "symphony_readonly cannot INSERT continuity anchors" \
  || record_check "readonly_no_insert" "FAIL" "symphony_readonly unexpectedly has INSERT on p3_lineage_continuity_anchors"
[[ "$READONLY_EXECUTE_DEP" == "t" && "$READONLY_EXECUTE_AUTH" == "t" ]] \
  && record_check "readonly_reconstruction_execute" "PASS" "symphony_readonly can execute replay reconstruction functions" \
  || record_check "readonly_reconstruction_execute" "FAIL" "symphony_readonly lacks execute on one or more reconstruction functions"
[[ "$PUBLIC_EXECUTE_INTERNAL" == "f" ]] \
  && record_check "internal_mutation_function_not_public" "PASS" "public cannot EXECUTE p3_deny_lineage_mutation()" \
  || record_check "internal_mutation_function_not_public" "FAIL" "public unexpectedly can EXECUTE p3_deny_lineage_mutation()"

ACCESS_SQL="$(cat <<'SQL'
BEGIN;
DO $$
BEGIN
    BEGIN
        EXECUTE 'SET LOCAL ROLE symphony_readonly';
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
            '10000000-0000-0000-0000-000000000210',
            'P3-SURF-001',
            'dependency_node',
            'readonly.blocked.insert',
            '20000000-0000-0000-0000-000000000210',
            'internal_replay_boundary',
            '{}'::jsonb,
            'compatible-intent-only'
        );
        RAISE EXCEPTION 'NEGATIVE_READONLY_INSERT_MISSED'
            USING ERRCODE = 'P3910';
    EXCEPTION
        WHEN insufficient_privilege THEN
            NULL;
    END;

    RESET ROLE;

    EXECUTE 'SET LOCAL ROLE symphony_executor';
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
        '30000000-0000-0000-0000-000000000210',
        'P3-SURF-001',
        'dependency_node',
        'executor.allowed.insert',
        '40000000-0000-0000-0000-000000000210',
        'internal_replay_boundary',
        '{"ordering":"semantic+provenance"}'::jsonb,
        'compatible-intent-only'
    );

    PERFORM * FROM public.p3_collect_upstream_dependencies('50000000-0000-0000-0000-000000000210');
    RESET ROLE;

    RAISE NOTICE 'ACCESS_OK';
END;
$$;
ROLLBACK;
SQL
)"
record_command "exercise role-based insert denial for readonly and insert allowance for executor in a rollback transaction"
if ACCESS_OUT="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X 2>&1 <<<"$ACCESS_SQL")"; then
  record_trace "access-control exercise completed"
  if grep -q 'ACCESS_OK' <<<"$ACCESS_OUT"; then
    record_check "role_enforcement" "PASS" "readonly insert is denied and executor insert succeeds"
  else
    record_check "role_enforcement" "FAIL" "access-control exercise did not emit ACCESS_OK"
  fi
else
  record_trace "access-control exercise failed"
  record_check "role_enforcement" "FAIL" "psql access-control exercise failed"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-SUPPORT-SEC-001 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-SUPPORT-SEC-001' "$ROOT/$REGISTRY_PATH" || true)"
ADR_MATCHES="$(grep -c '0210' "$ROOT/$ADR_PATH" || true)"
record_command "inspect runtime task index, phase3 task registry, and ADR-0010 record"
[[ "$RUNTIME_INDEX_MATCHES" -ge 1 ]] \
  && record_check "runtime_index_registered" "PASS" "PHASE3 runtime index contains TSK-P3-SUPPORT-SEC-001" \
  || record_check "runtime_index_registered" "FAIL" "TSK-P3-SUPPORT-SEC-001 missing from PHASE3 runtime index"
[[ "$REGISTRY_MATCHES" -ge 1 ]] \
  && record_check "phase3_registry_registered" "PASS" "phase3_task_registry.yml contains TSK-P3-SUPPORT-SEC-001" \
  || record_check "phase3_registry_registered" "FAIL" "TSK-P3-SUPPORT-SEC-001 missing from phase3_task_registry.yml"
[[ "$ADR_MATCHES" -ge 1 ]] \
  && record_check "adr_rebaseline_recorded" "PASS" "ADR-0010 references MIGRATION_HEAD 0210" \
  || record_check "adr_rebaseline_recorded" "FAIL" "ADR-0010 missing 0210 baseline note"

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
