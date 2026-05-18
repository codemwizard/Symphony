#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-WP-008"
MIGRATION_PATH="schema/migrations/0216_p3_conflict_of_interest_enforcement.sql"
VERIFIER_PATH="scripts/db/verify_p3_conflict_of_interest_enforcement.sh"
HEAD_PATH="schema/migrations/MIGRATION_HEAD"
ADR_PATH="docs/decisions/ADR-0010-baseline-policy.md"
SQLSTATE_MAP_PATH="docs/contracts/sqlstate_map.yml"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-WP-008/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-WP-008/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-WP-008/EXEC_LOG.md"

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

record_command() { printf '%s\n' "$1" >> "$COMMANDS_FILE"; }
record_trace() { printf '%s\n' "$1" >> "$TRACE_FILE"; }
sql() { psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -t -A -c "$1"; }
sanitize_probe_error() { printf '%s' "$1" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//'; }
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
if [[ "$HEAD_TOKEN" =~ ^[0-9]{4}$ ]] && (( 10#$HEAD_TOKEN >= 216 )); then
  record_check "migration_head_forward_only" "PASS" "MIGRATION_HEAD=$HEAD_TOKEN (>=0216)"
else
  record_check "migration_head_forward_only" "FAIL" "unexpected MIGRATION_HEAD=$HEAD_TOKEN"
fi

REL_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_conflict_relationships')::text, '');")"
REC_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_verifier_independence_records')::text, '');")"
MANIFEST_VIEW="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_verifier_independence_manifest')::text, '');")"
DECLARE_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='p3_declare_conflict_relationship';")"
ASSERT_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='p3_assert_verifier_independence';")"
KIND_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_conflict_relationship_kind'::regtype;")"
STATE_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_verifier_independence_state'::regtype;")"
record_command "inspect COI relations and functions"

[[ "$REL_TABLE" == "p3_conflict_relationships" ]] && record_check "relationship_table_exists" "PASS" "public.p3_conflict_relationships exists" || record_check "relationship_table_exists" "FAIL" "public.p3_conflict_relationships missing"
[[ "$REC_TABLE" == "p3_verifier_independence_records" ]] && record_check "independence_table_exists" "PASS" "public.p3_verifier_independence_records exists" || record_check "independence_table_exists" "FAIL" "public.p3_verifier_independence_records missing"
[[ "$MANIFEST_VIEW" == "p3_verifier_independence_manifest" ]] && record_check "manifest_exists" "PASS" "public.p3_verifier_independence_manifest exists" || record_check "manifest_exists" "FAIL" "public.p3_verifier_independence_manifest missing"
[[ "$DECLARE_COUNT" == "1" ]] && record_check "declare_function_exists" "PASS" "p3_declare_conflict_relationship exists" || record_check "declare_function_exists" "FAIL" "p3_declare_conflict_relationship missing"
[[ "$ASSERT_COUNT" == "1" ]] && record_check "assert_function_exists" "PASS" "p3_assert_verifier_independence exists" || record_check "assert_function_exists" "FAIL" "p3_assert_verifier_independence missing"
[[ "$KIND_ENUM_COUNT" == "3" ]] && record_check "relationship_kind_enum" "PASS" "p3_conflict_relationship_kind has 3 values" || record_check "relationship_kind_enum" "FAIL" "expected 3 conflict relationship kinds, got $KIND_ENUM_COUNT"
[[ "$STATE_ENUM_COUNT" == "2" ]] && record_check "independence_state_enum" "PASS" "p3_verifier_independence_state has 2 values" || record_check "independence_state_enum" "FAIL" "expected 2 verifier-independence states, got $STATE_ENUM_COUNT"

COI_SQL="$(cat <<'SQL'
BEGIN;
DO $$
DECLARE
    v_authority uuid := '10000000-0000-0000-0000-000000000216';
    v_policy uuid := '11000000-0000-0000-0000-000000000216';
    v_submitter uuid := '12000000-0000-0000-0000-000000000216';
    v_verifier uuid := '13000000-0000-0000-0000-000000000216';
    v_conflicting uuid := '14000000-0000-0000-0000-000000000216';
    v_ok uuid;
BEGIN
    INSERT INTO public.p3_authority_lineage (
        authority_lineage_id, authority_key, authority_source_kind, source_reference,
        resource_scope, act_scope, effective_from, lineage_provenance_id
    ) VALUES (
        v_authority, 'authority.coi.root', 'constitutional_document',
        'constitution://phase3/coi/root', 'asset_batch', 'verification_decision',
        '2026-01-01T00:00:00Z', '15000000-0000-0000-0000-000000000216'
    );

    INSERT INTO public.p3_policy_artifacts (
        policy_artifact_id, artifact_key, artifact_class, source_authority_lineage_id,
        artifact_version, effective_from, resource_scope, act_scope, lineage_provenance_id
    ) VALUES (
        v_policy, 'policy.coi.root', 'authority_policy', v_authority,
        'v1', '2026-01-01T00:00:00Z', 'asset_batch', 'verification_decision',
        '16000000-0000-0000-0000-000000000216'
    );

    v_ok := public.p3_assert_verifier_independence(
        'decision://coi/ok',
        'asset://coi/ok',
        v_submitter,
        v_verifier,
        v_authority,
        v_policy,
        'coi-ok',
        '17000000-0000-0000-0000-000000000216'
    );

    IF NOT EXISTS (
        SELECT 1
        FROM public.p3_verifier_independence_records
        WHERE verifier_independence_record_id = v_ok
          AND independence_state = 'independent'
    ) THEN
        RAISE EXCEPTION 'INDEPENDENCE_RECORD_MISSING'
            USING ERRCODE = 'P3208';
    END IF;

    BEGIN
        PERFORM public.p3_assert_verifier_independence(
            'decision://coi/same',
            'asset://coi/same',
            v_submitter,
            v_submitter,
            v_authority,
            v_policy,
            'coi-same',
            '18000000-0000-0000-0000-000000000216'
        );
        RAISE EXCEPTION 'SAME_ACTOR_NEGATIVE_MISSED'
            USING ERRCODE = 'P3208';
    EXCEPTION
        WHEN SQLSTATE 'GF001' THEN
            NULL;
    END;

    PERFORM public.p3_declare_conflict_relationship(
        v_verifier,
        v_conflicting,
        'declared_relationship_conflict',
        'asset://coi/conflict',
        v_authority,
        v_policy,
        '{"reason":"shared beneficial ownership"}'::jsonb,
        '19000000-0000-0000-0000-000000000216'
    );

    BEGIN
        PERFORM public.p3_assert_verifier_independence(
            'decision://coi/conflict',
            'asset://coi/conflict',
            v_verifier,
            v_conflicting,
            v_authority,
            v_policy,
            'coi-conflict',
            '1a000000-0000-0000-0000-000000000216'
        );
        RAISE EXCEPTION 'DECLARED_CONFLICT_NEGATIVE_MISSED'
            USING ERRCODE = 'P3208';
    EXCEPTION
        WHEN SQLSTATE 'GF001' THEN
            NULL;
    END;

    RAISE NOTICE 'COI_OK';
    RAISE NOTICE 'NEGATIVE_OK';
END;
$$;
ROLLBACK;
SQL
)"
record_command "exercise positive verifier-independence path and GF001 conflict rejections in a rollback transaction"
if COI_OUT="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X 2>&1 <<<"$COI_SQL")"; then
  if grep -q 'COI_OK' <<<"$COI_OUT"; then
    record_check "coi_enforcement" "PASS" "submitter/verifier separation is anchored to persisted relationship records"
  else
    record_check "coi_enforcement" "FAIL" "COI exercise did not emit COI_OK"
  fi
  if grep -q 'NEGATIVE_OK' <<<"$COI_OUT"; then
    record_check "coi_negative" "PASS" "same-actor and declared-conflict verification paths fail closed with GF001"
  else
    record_check "coi_negative" "FAIL" "COI negative test did not emit NEGATIVE_OK"
  fi
else
  record_check "coi_enforcement" "FAIL" "psql COI exercise failed"
  record_check "coi_negative" "FAIL" "psql COI negative test failed"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-WP-008 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-WP-008' "$ROOT/$REGISTRY_PATH" || true)"
ADR_MATCHES="$(grep -c '0216' "$ROOT/$ADR_PATH" || true)"
SQLSTATE_P3015="$(grep -c '"P3015"' "$ROOT/$SQLSTATE_MAP_PATH" || true)"
META_STATUS="$(awk -F': ' '/^status:/ {print $2; exit}' "$ROOT/$META_PATH" || true)"
record_command "inspect runtime task index, phase3 task registry, ADR-0010, sqlstate map, and task meta"
[[ "$RUNTIME_INDEX_MATCHES" -ge 1 ]] && record_check "runtime_index_registered" "PASS" "PHASE3 runtime index contains TSK-P3-WP-008" || record_check "runtime_index_registered" "FAIL" "TSK-P3-WP-008 missing from PHASE3 runtime index"
[[ "$REGISTRY_MATCHES" -ge 1 ]] && record_check "phase3_registry_registered" "PASS" "phase3_task_registry.yml contains TSK-P3-WP-008" || record_check "phase3_registry_registered" "FAIL" "TSK-P3-WP-008 missing from phase3_task_registry.yml"
[[ "$ADR_MATCHES" -ge 1 ]] && record_check "adr_rebaseline_recorded" "PASS" "ADR-0010 references MIGRATION_HEAD 0216" || record_check "adr_rebaseline_recorded" "FAIL" "ADR-0010 missing 0216 baseline note"
[[ "$SQLSTATE_P3015" -ge 1 ]] && record_check "sqlstate_registered" "PASS" "sqlstate map contains P3015 and COI negative tests still fail closed with GF001" || record_check "sqlstate_registered" "FAIL" "sqlstate map missing P3015"
[[ "$META_STATUS" =~ ^(ready|completed)$ ]] && record_check "meta_proof_state" "PASS" "task meta status is $META_STATUS (proof-compatible)" || record_check "meta_proof_state" "FAIL" "task meta status is $META_STATUS"

if [[ "$PASS" == "true" ]]; then STATUS="PASS"; PASS_FLAG="true"; else STATUS="FAIL"; PASS_FLAG="false"; fi

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
    return hashlib.sha256((root / rel_path).read_bytes()).hexdigest()

checks = {}
for line in Path(os.environ["CHECKS_FILE"]).read_text(encoding="utf-8").splitlines():
    if line.strip():
        key, status, detail = line.split("\t", 2)
        checks[key] = {"status": status, "detail": detail}

command_outputs = [{"command": line, "status": "recorded"} for line in Path(os.environ["COMMANDS_FILE"]).read_text(encoding="utf-8").splitlines() if line.strip()]
execution_trace = [line for line in Path(os.environ["TRACE_FILE"]).read_text(encoding="utf-8").splitlines() if line.strip()]

print(json.dumps({
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
}, indent=2))
PY
