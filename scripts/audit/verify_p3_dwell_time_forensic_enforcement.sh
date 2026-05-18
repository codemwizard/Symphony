#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-WP-010"
MIGRATION_PATH="schema/migrations/0218_p3_dwell_time_forensic_enforcement.sql"
VERIFIER_PATH="scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh"
HEAD_PATH="schema/migrations/MIGRATION_HEAD"
ADR_PATH="docs/decisions/ADR-0010-baseline-policy.md"
SQLSTATE_MAP_PATH="docs/contracts/sqlstate_map.yml"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-WP-010/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-WP-010/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-WP-010/EXEC_LOG.md"

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
if [[ "$HEAD_TOKEN" =~ ^[0-9]{4}$ ]] && (( 10#$HEAD_TOKEN >= 218 )); then
  record_check "migration_head_forward_only" "PASS" "MIGRATION_HEAD=$HEAD_TOKEN (>=0218)"
else
  record_check "migration_head_forward_only" "FAIL" "unexpected MIGRATION_HEAD=$HEAD_TOKEN"
fi

POLICY_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_dwell_time_policy_inputs')::text, '');")"
FINDING_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_dwell_time_findings')::text, '');")"
MANIFEST_VIEW="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_dwell_time_manifest')::text, '');")"
RECORD_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='p3_record_dwell_time_finding';")"
STATE_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_dwell_finding_state'::regtype;")"
record_command "inspect dwell-time relations and function"

[[ "$POLICY_TABLE" == "p3_dwell_time_policy_inputs" ]] && record_check "policy_table_exists" "PASS" "public.p3_dwell_time_policy_inputs exists" || record_check "policy_table_exists" "FAIL" "public.p3_dwell_time_policy_inputs missing"
[[ "$FINDING_TABLE" == "p3_dwell_time_findings" ]] && record_check "finding_table_exists" "PASS" "public.p3_dwell_time_findings exists" || record_check "finding_table_exists" "FAIL" "public.p3_dwell_time_findings missing"
[[ "$MANIFEST_VIEW" == "p3_dwell_time_manifest" ]] && record_check "manifest_exists" "PASS" "public.p3_dwell_time_manifest exists" || record_check "manifest_exists" "FAIL" "public.p3_dwell_time_manifest missing"
[[ "$RECORD_COUNT" == "1" ]] && record_check "record_function_exists" "PASS" "p3_record_dwell_time_finding exists" || record_check "record_function_exists" "FAIL" "p3_record_dwell_time_finding missing"
[[ "$STATE_ENUM_COUNT" == "3" ]] && record_check "finding_state_enum" "PASS" "p3_dwell_finding_state has 3 values" || record_check "finding_state_enum" "FAIL" "expected 3 dwell finding states, got $STATE_ENUM_COUNT"

DWELL_SQL="$(cat <<'SQL'
BEGIN;
DO $$
DECLARE
    v_authority uuid := '10000000-0000-0000-0000-000000000218';
    v_policy uuid := '11000000-0000-0000-0000-000000000218';
    v_policy_input uuid := '12000000-0000-0000-0000-000000000218';
    v_ok uuid;
    v_blocked uuid;
BEGIN
    INSERT INTO public.p3_authority_lineage (
        authority_lineage_id, authority_key, authority_source_kind, source_reference,
        resource_scope, act_scope, effective_from, lineage_provenance_id
    ) VALUES (
        v_authority, 'authority.dwell.root', 'constitutional_document',
        'constitution://phase3/dwell/root', 'decision_record', 'temporal_forensics',
        '2026-01-01T00:00:00Z', '13000000-0000-0000-0000-000000000218'
    );

    INSERT INTO public.p3_policy_artifacts (
        policy_artifact_id, artifact_key, artifact_class, source_authority_lineage_id,
        artifact_version, effective_from, resource_scope, act_scope, lineage_provenance_id
    ) VALUES (
        v_policy, 'policy.dwell.root', 'replay_policy', v_authority,
        'v1', '2026-01-01T00:00:00Z', 'decision_record', 'temporal_forensics',
        '14000000-0000-0000-0000-000000000218'
    );

    INSERT INTO public.p3_dwell_time_policy_inputs (
        dwell_time_policy_input_id, policy_key, max_dwell, breach_state,
        source_authority_lineage_id, source_policy_artifact_id, lineage_provenance_id
    ) VALUES (
        v_policy_input, 'dwell.default', interval '48 hours', 'blocked',
        v_authority, v_policy, '15000000-0000-0000-0000-000000000218'
    );

    v_ok := public.p3_record_dwell_time_finding(
        'dwell.default',
        'decision://dwell/ok',
        'awaiting_review',
        '2026-05-01T00:00:00Z',
        '2026-05-02T00:00:00Z',
        'dwell-ok',
        '16000000-0000-0000-0000-000000000218'
    );

    v_blocked := public.p3_record_dwell_time_finding(
        'dwell.default',
        'decision://dwell/blocked',
        'awaiting_review',
        '2026-05-01T00:00:00Z',
        '2026-05-04T00:00:00Z',
        'dwell-blocked',
        '17000000-0000-0000-0000-000000000218'
    );

    IF NOT EXISTS (
        SELECT 1
        FROM public.p3_dwell_time_findings
        WHERE dwell_time_finding_id = v_ok
          AND finding_state = 'within_window'
    ) THEN
        RAISE EXCEPTION 'WITHIN_WINDOW_FINDING_MISSING'
            USING ERRCODE = 'P3208';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.p3_dwell_time_findings
        WHERE dwell_time_finding_id = v_blocked
          AND finding_state = 'blocked'
          AND elapsed_duration > threshold_duration
    ) THEN
        RAISE EXCEPTION 'BLOCKED_FINDING_MISSING'
            USING ERRCODE = 'P3208';
    END IF;

    BEGIN
        PERFORM public.p3_record_dwell_time_finding(
            'dwell.default',
            'decision://dwell/invalid',
            'awaiting_review',
            '2026-05-03T00:00:00Z',
            '2026-05-02T00:00:00Z',
            'dwell-invalid',
            '18000000-0000-0000-0000-000000000218'
        );
        RAISE EXCEPTION 'TEMPORAL_INPUT_NEGATIVE_MISSED'
            USING ERRCODE = 'P3208';
    EXCEPTION
        WHEN SQLSTATE 'P3012' THEN
            NULL;
    END;

    RAISE NOTICE 'DWELL_OK';
    RAISE NOTICE 'NEGATIVE_OK';
END;
$$;
ROLLBACK;
SQL
)"
record_command "exercise within-window, blocked, and invalid temporal-input dwell cases in a rollback transaction"
if DWELL_OUT="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X 2>&1 <<<"$DWELL_SQL")"; then
  if grep -q 'DWELL_OK' <<<"$DWELL_OUT"; then
    record_check "dwell_time_enforcement" "PASS" "dwell-time findings are replay-derived from declared policy inputs"
  else
    record_check "dwell_time_enforcement" "FAIL" "dwell exercise did not emit DWELL_OK"
  fi
  if grep -q 'NEGATIVE_OK' <<<"$DWELL_OUT"; then
    record_check "dwell_negative" "PASS" "invalid temporal inputs fail closed with P3012 and threshold breaches are recorded as blocked"
  else
    record_check "dwell_negative" "FAIL" "dwell negative test did not emit NEGATIVE_OK"
  fi
else
  record_check "dwell_time_enforcement" "FAIL" "psql dwell exercise failed"
  record_check "dwell_negative" "FAIL" "psql dwell negative test failed"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-WP-010 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-WP-010' "$ROOT/$REGISTRY_PATH" || true)"
ADR_MATCHES="$(grep -c '0218' "$ROOT/$ADR_PATH" || true)"
SQLSTATE_P3012="$(grep -c '"P3012"' "$ROOT/$SQLSTATE_MAP_PATH" || true)"
SQLSTATE_P3017="$(grep -c '"P3017"' "$ROOT/$SQLSTATE_MAP_PATH" || true)"
META_STATUS="$(awk -F': ' '/^status:/ {print $2; exit}' "$ROOT/$META_PATH" || true)"
record_command "inspect runtime task index, phase3 task registry, ADR-0010, sqlstate map, and task meta"
[[ "$RUNTIME_INDEX_MATCHES" -ge 1 ]] && record_check "runtime_index_registered" "PASS" "PHASE3 runtime index contains TSK-P3-WP-010" || record_check "runtime_index_registered" "FAIL" "TSK-P3-WP-010 missing from PHASE3 runtime index"
[[ "$REGISTRY_MATCHES" -ge 1 ]] && record_check "phase3_registry_registered" "PASS" "phase3_task_registry.yml contains TSK-P3-WP-010" || record_check "phase3_registry_registered" "FAIL" "TSK-P3-WP-010 missing from phase3_task_registry.yml"
[[ "$ADR_MATCHES" -ge 1 ]] && record_check "adr_rebaseline_recorded" "PASS" "ADR-0010 references MIGRATION_HEAD 0218" || record_check "adr_rebaseline_recorded" "FAIL" "ADR-0010 missing 0218 baseline note"
[[ "$SQLSTATE_P3012" -ge 1 && "$SQLSTATE_P3017" -ge 1 ]] && record_check "sqlstate_registered" "PASS" "sqlstate map contains P3012 and P3017" || record_check "sqlstate_registered" "FAIL" "sqlstate map missing P3012 or P3017"
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
