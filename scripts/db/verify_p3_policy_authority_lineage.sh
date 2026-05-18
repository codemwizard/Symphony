#!/usr/bin/env bash
# TSK-P3-WP-002 verifier: policy artifact and authority lineage substrate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-WP-002"
MIGRATION_PATH="schema/migrations/0208_p3_policy_authority_lineage.sql"
VERIFIER_PATH="scripts/db/verify_p3_policy_authority_lineage.sh"
HEAD_PATH="schema/migrations/MIGRATION_HEAD"
ADR_PATH="docs/decisions/ADR-0010-baseline-policy.md"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-WP-002/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-WP-002/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-WP-002/EXEC_LOG.md"

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
if [[ "$HEAD_TOKEN" =~ ^[0-9]{4}$ ]] && (( 10#$HEAD_TOKEN >= 208 )); then
  record_check "migration_head_forward_only" "PASS" "MIGRATION_HEAD=$HEAD_TOKEN (>=0208)"
else
  record_check "migration_head_forward_only" "FAIL" "unexpected MIGRATION_HEAD=$HEAD_TOKEN"
fi

AUTH_TABLE_EXISTS="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_authority_lineage')::text, '');")"
POLICY_TABLE_EXISTS="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_policy_artifacts')::text, '');")"
PROJECTION_VIEW_EXISTS="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_policy_authority_lineage_projection')::text, '');")"
FUNCTION_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'p3_collect_policy_authority_lineage';")"
record_command "inspect policy/authority lineage relations and reconstruction function"

[[ "$AUTH_TABLE_EXISTS" == "p3_authority_lineage" ]] \
  && record_check "authority_table_exists" "PASS" "public.p3_authority_lineage exists" \
  || record_check "authority_table_exists" "FAIL" "public.p3_authority_lineage missing"
[[ "$POLICY_TABLE_EXISTS" == "p3_policy_artifacts" ]] \
  && record_check "policy_table_exists" "PASS" "public.p3_policy_artifacts exists" \
  || record_check "policy_table_exists" "FAIL" "public.p3_policy_artifacts missing"
[[ "$PROJECTION_VIEW_EXISTS" == "p3_policy_authority_lineage_projection" ]] \
  && record_check "projection_view_exists" "PASS" "public.p3_policy_authority_lineage_projection exists" \
  || record_check "projection_view_exists" "FAIL" "public.p3_policy_authority_lineage_projection missing"
[[ "$FUNCTION_COUNT" == "1" ]] \
  && record_check "reconstruction_function_exists" "PASS" "p3_collect_policy_authority_lineage(uuid) exists" \
  || record_check "reconstruction_function_exists" "FAIL" "p3_collect_policy_authority_lineage(uuid) missing"

POLICY_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_policy_artifact_class'::regtype;")"
AUTH_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_authority_source_kind'::regtype;")"
record_command "inspect enum cardinalities for policy artifact and authority source kinds"
[[ "$POLICY_ENUM_COUNT" == "8" ]] \
  && record_check "policy_artifact_class_enum" "PASS" "p3_policy_artifact_class has 8 doctrine-aligned values" \
  || record_check "policy_artifact_class_enum" "FAIL" "p3_policy_artifact_class count=$POLICY_ENUM_COUNT"
[[ "$AUTH_ENUM_COUNT" == "4" ]] \
  && record_check "authority_source_kind_enum" "PASS" "p3_authority_source_kind has 4 substrate values" \
  || record_check "authority_source_kind_enum" "FAIL" "p3_authority_source_kind count=$AUTH_ENUM_COUNT"

PROVENANCE_COLUMNS="$(safe_sql "
SELECT COUNT(*)
FROM information_schema.columns
WHERE table_schema = 'public'
  AND (
    (table_name = 'p3_authority_lineage' AND column_name = 'lineage_provenance_id' AND is_nullable = 'NO')
    OR
    (table_name = 'p3_policy_artifacts' AND column_name = 'lineage_provenance_id' AND is_nullable = 'NO')
  );
")"
JSON_COLUMNS="$(safe_sql "
SELECT COUNT(*)
FROM information_schema.columns
WHERE table_schema = 'public'
  AND data_type = 'jsonb'
  AND (
    (table_name = 'p3_authority_lineage' AND column_name = 'revocation_lineage_metadata')
    OR
    (table_name = 'p3_policy_artifacts' AND column_name = 'replay_reconstruction_hints')
  );
")"
record_command "inspect provenance and replay/revocation metadata columns"
[[ "$PROVENANCE_COLUMNS" == "2" ]] \
  && record_check "provenance_columns_present" "PASS" "lineage_provenance_id columns are NOT NULL on both lineage tables" \
  || record_check "provenance_columns_present" "FAIL" "expected 2 lineage_provenance_id NOT NULL columns, got $PROVENANCE_COLUMNS"
[[ "$JSON_COLUMNS" == "2" ]] \
  && record_check "replay_revocation_metadata_present" "PASS" "jsonb replay/revocation metadata columns exist on both lineage tables" \
  || record_check "replay_revocation_metadata_present" "FAIL" "expected 2 replay/revocation jsonb columns, got $JSON_COLUMNS"

RECONSTRUCTION_SQL="$(cat <<'SQL'
BEGIN;
DO $$
DECLARE
    v_root uuid := '10000000-0000-0000-0000-000000000208';
    v_delegate uuid := '20000000-0000-0000-0000-000000000208';
    v_policy uuid := '30000000-0000-0000-0000-000000000208';
    v_rows text[];
BEGIN
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
        'authority.root',
        'constitutional_document',
        'constitution://phase3/authority/root',
        'asset_batch',
        'admissibility_decision',
        '2026-01-01T00:00:00Z',
        '40000000-0000-0000-0000-000000000208'
    );

    INSERT INTO public.p3_authority_lineage (
        authority_lineage_id,
        authority_key,
        authority_source_kind,
        source_reference,
        delegated_from_authority_lineage_id,
        revocation_lineage_metadata,
        resource_scope,
        act_scope,
        effective_from,
        lineage_provenance_id
    ) VALUES (
        v_delegate,
        'authority.delegate',
        'delegated_authority',
        'delegation://phase3/authority/delegate',
        v_root,
        '{"revocable": true, "mechanic": "supersession"}'::jsonb,
        'asset_batch',
        'admissibility_decision',
        '2026-02-01T00:00:00Z',
        '50000000-0000-0000-0000-000000000208'
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
        replay_reconstruction_hints,
        lineage_provenance_id
    ) VALUES (
        v_policy,
        'policy.constraint.demo',
        'constraint_policy',
        v_delegate,
        'v1',
        '2026-03-01T00:00:00Z',
        'asset_batch',
        'admissibility_decision',
        '{"replay_path": "policy.constraint.demo/v1"}'::jsonb,
        '60000000-0000-0000-0000-000000000208'
    );

    SELECT array_agg(format('%s:%s:%s', depth, authority_source_kind::text, authority_key) ORDER BY depth, authority_key, authority_lineage_id)
    INTO v_rows
    FROM public.p3_collect_policy_authority_lineage(v_policy);

    IF v_rows IS DISTINCT FROM ARRAY[
        '1:delegated_authority:authority.delegate',
        '2:constitutional_document:authority.root'
    ] THEN
        RAISE EXCEPTION 'RECONSTRUCTION_MISMATCH:%', coalesce(array_to_string(v_rows, ','), 'NULL')
            USING ERRCODE = 'P3208';
    END IF;

    BEGIN
        INSERT INTO public.p3_authority_lineage (
            authority_lineage_id,
            authority_key,
            authority_source_kind,
            source_reference,
            resource_scope,
            act_scope,
            effective_from
        ) VALUES (
            '70000000-0000-0000-0000-000000000208',
            'authority.self_cycle',
            'delegated_authority',
            'delegation://phase3/authority/self-cycle',
            'asset_batch',
            'admissibility_decision',
            '2026-04-01T00:00:00Z'
        );

        UPDATE public.p3_authority_lineage
        SET delegated_from_authority_lineage_id = authority_lineage_id
        WHERE authority_key = 'authority.self_cycle';

        RAISE EXCEPTION 'NEGATIVE_SELF_DELEGATION_MISSED'
            USING ERRCODE = 'P3208';
    EXCEPTION
        WHEN check_violation THEN
            NULL;
    END;

    BEGIN
        INSERT INTO public.p3_policy_artifacts (
            artifact_key,
            artifact_class,
            source_authority_lineage_id,
            artifact_version,
            effective_from,
            resource_scope,
            act_scope
        ) VALUES (
            'policy.invalid.missing-authority',
            'authority_policy',
            '80000000-0000-0000-0000-000000000208',
            'v1',
            '2026-04-01T00:00:00Z',
            'asset_batch',
            'admissibility_decision'
        );
        RAISE EXCEPTION 'NEGATIVE_MISSING_AUTHORITY_MISSED'
            USING ERRCODE = 'P3208';
    EXCEPTION
        WHEN foreign_key_violation THEN
            NULL;
    END;

    RAISE NOTICE 'RECONSTRUCTION_OK';
    RAISE NOTICE 'NEGATIVE_OK';
END;
$$;
ROLLBACK;
SQL
)"
record_command "exercise deterministic authority reconstruction and negative lineage constraints in a rollback transaction"
if RECONSTRUCTION_OUT="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X 2>&1 <<<"$RECONSTRUCTION_SQL")"; then
  record_trace "reconstruction exercise completed"
  if grep -q 'RECONSTRUCTION_OK' <<<"$RECONSTRUCTION_OUT"; then
    record_check "authority_reconstruction" "PASS" "policy artifact resolves to deterministic authority lineage chain"
  else
    record_check "authority_reconstruction" "FAIL" "reconstruction exercise did not emit RECONSTRUCTION_OK"
  fi

  if grep -q 'NEGATIVE_OK' <<<"$RECONSTRUCTION_OUT"; then
    record_check "malformed_lineage_rejected" "PASS" "self-delegation and missing source authority fail transactionally"
  else
    record_check "malformed_lineage_rejected" "FAIL" "negative lineage checks did not emit NEGATIVE_OK"
  fi
else
  record_trace "reconstruction exercise failed"
  record_check "authority_reconstruction" "FAIL" "psql reconstruction exercise failed"
  record_check "malformed_lineage_rejected" "FAIL" "psql negative lineage exercise failed"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-WP-002 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-WP-002' "$ROOT/$REGISTRY_PATH" || true)"
ADR_MATCHES="$(grep -c '0208' "$ROOT/$ADR_PATH" || true)"
record_command "inspect runtime task index, phase3 task registry, and ADR-0010 record"
[[ "$RUNTIME_INDEX_MATCHES" -ge 1 ]] \
  && record_check "runtime_index_registered" "PASS" "PHASE3 runtime index contains TSK-P3-WP-002" \
  || record_check "runtime_index_registered" "FAIL" "TSK-P3-WP-002 missing from PHASE3 runtime index"
[[ "$REGISTRY_MATCHES" -ge 1 ]] \
  && record_check "phase3_registry_registered" "PASS" "phase3_task_registry.yml contains TSK-P3-WP-002" \
  || record_check "phase3_registry_registered" "FAIL" "TSK-P3-WP-002 missing from phase3_task_registry.yml"
[[ "$ADR_MATCHES" -ge 1 ]] \
  && record_check "adr_rebaseline_recorded" "PASS" "ADR-0010 references MIGRATION_HEAD 0208" \
  || record_check "adr_rebaseline_recorded" "FAIL" "ADR-0010 missing 0208 baseline note"

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
