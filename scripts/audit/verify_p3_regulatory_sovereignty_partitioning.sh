#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-WP-007"
MIGRATION_PATH="schema/migrations/0215_p3_regulatory_sovereignty_partitioning.sql"
VERIFIER_PATH="scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh"
HEAD_PATH="schema/migrations/MIGRATION_HEAD"
ADR_PATH="docs/decisions/ADR-0010-baseline-policy.md"
SQLSTATE_MAP_PATH="docs/contracts/sqlstate_map.yml"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-WP-007/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-WP-007/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-WP-007/EXEC_LOG.md"

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
if [[ "$HEAD_TOKEN" =~ ^[0-9]{4}$ ]] && (( 10#$HEAD_TOKEN >= 215 )); then
  record_check "migration_head_forward_only" "PASS" "MIGRATION_HEAD=$HEAD_TOKEN (>=0215)"
else
  record_check "migration_head_forward_only" "FAIL" "unexpected MIGRATION_HEAD=$HEAD_TOKEN"
fi

REGIME_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_regulator_regimes')::text, '');")"
RULE_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_regulator_precedence_rules')::text, '');")"
FINDING_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_regulator_partition_findings')::text, '');")"
MANIFEST_VIEW="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_regulator_partition_manifest')::text, '');")"
APPLICABILITY_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='p3_assert_regulator_rule_applicability';")"
APPEND_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='p3_append_regulator_partition_finding';")"
RESOLVE_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='p3_resolve_regulator_precedence';")"
STATE_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_regulator_partition_state'::regtype;")"
record_command "inspect regulator partition relations and functions"

[[ "$REGIME_TABLE" == "p3_regulator_regimes" ]] \
  && record_check "regime_table_exists" "PASS" "public.p3_regulator_regimes exists" \
  || record_check "regime_table_exists" "FAIL" "public.p3_regulator_regimes missing"
[[ "$RULE_TABLE" == "p3_regulator_precedence_rules" ]] \
  && record_check "rule_table_exists" "PASS" "public.p3_regulator_precedence_rules exists" \
  || record_check "rule_table_exists" "FAIL" "public.p3_regulator_precedence_rules missing"
[[ "$FINDING_TABLE" == "p3_regulator_partition_findings" ]] \
  && record_check "finding_table_exists" "PASS" "public.p3_regulator_partition_findings exists" \
  || record_check "finding_table_exists" "FAIL" "public.p3_regulator_partition_findings missing"
[[ "$MANIFEST_VIEW" == "p3_regulator_partition_manifest" ]] \
  && record_check "manifest_exists" "PASS" "public.p3_regulator_partition_manifest exists" \
  || record_check "manifest_exists" "FAIL" "public.p3_regulator_partition_manifest missing"
[[ "$APPLICABILITY_COUNT" == "1" ]] \
  && record_check "applicability_function_exists" "PASS" "p3_assert_regulator_rule_applicability exists" \
  || record_check "applicability_function_exists" "FAIL" "p3_assert_regulator_rule_applicability missing"
[[ "$APPEND_COUNT" == "1" ]] \
  && record_check "append_function_exists" "PASS" "p3_append_regulator_partition_finding exists" \
  || record_check "append_function_exists" "FAIL" "p3_append_regulator_partition_finding missing"
[[ "$RESOLVE_COUNT" == "1" ]] \
  && record_check "resolve_function_exists" "PASS" "p3_resolve_regulator_precedence exists" \
  || record_check "resolve_function_exists" "FAIL" "p3_resolve_regulator_precedence missing"
[[ "$STATE_ENUM_COUNT" == "3" ]] \
  && record_check "partition_state_enum" "PASS" "p3_regulator_partition_state has 3 doctrine-declared values" \
  || record_check "partition_state_enum" "FAIL" "expected 3 partition states, got $STATE_ENUM_COUNT"

REGULATOR_SQL="$(cat <<'SQL'
BEGIN;
DO $$
DECLARE
    v_authority uuid := '10000000-0000-0000-0000-000000000215';
    v_policy uuid := '11000000-0000-0000-0000-000000000215';
    v_regime_a uuid := '12000000-0000-0000-0000-000000000215';
    v_regime_b uuid := '13000000-0000-0000-0000-000000000215';
    v_regime_c uuid := '14000000-0000-0000-0000-000000000215';
    v_rule uuid := '15000000-0000-0000-0000-000000000215';
    v_precedence_finding uuid;
    v_gap_finding uuid;
BEGIN
    INSERT INTO public.p3_authority_lineage (
        authority_lineage_id, authority_key, authority_source_kind, source_reference,
        resource_scope, act_scope, effective_from, lineage_provenance_id
    ) VALUES (
        v_authority, 'authority.regulator.root', 'constitutional_document',
        'constitution://phase3/regulator/root', 'decision_record', 'regulator_partition',
        '2026-01-01T00:00:00Z', '16000000-0000-0000-0000-000000000215'
    );

    INSERT INTO public.p3_policy_artifacts (
        policy_artifact_id, artifact_key, artifact_class, source_authority_lineage_id,
        artifact_version, effective_from, resource_scope, act_scope, lineage_provenance_id
    ) VALUES (
        v_policy, 'policy.regulator.partition', 'precedence_policy', v_authority,
        'v1', '2026-01-01T00:00:00Z', 'decision_record', 'regulator_partition',
        '17000000-0000-0000-0000-000000000215'
    );

    INSERT INTO public.p3_regulator_regimes (
        regulator_regime_id, regime_key, sovereign_domain, source_authority_lineage_id,
        source_policy_artifact_id, lineage_provenance_id
    ) VALUES
        (v_regime_a, 'regulator_a', 'domain_a', v_authority, v_policy, '18000000-0000-0000-0000-000000000215'),
        (v_regime_b, 'regulator_b', 'domain_b', v_authority, v_policy, '19000000-0000-0000-0000-000000000215'),
        (v_regime_c, 'regulator_c', 'domain_c', v_authority, v_policy, '1a000000-0000-0000-0000-000000000215');

    INSERT INTO public.p3_regulator_precedence_rules (
        precedence_rule_id, higher_regime_id, lower_regime_id, source_authority_lineage_id,
        source_policy_artifact_id, canonical_order_at, tie_break_key, lineage_provenance_id
    ) VALUES (
        v_rule, v_regime_a, v_regime_b, v_authority, v_policy,
        '2026-04-01T00:00:00Z', 'precedence-a-over-b',
        '1b000000-0000-0000-0000-000000000215'
    );

    PERFORM public.p3_assert_regulator_rule_applicability('regulator_a', 'regulator_a');

    BEGIN
        PERFORM public.p3_assert_regulator_rule_applicability('regulator_b', 'regulator_a');
        RAISE EXCEPTION 'CROSS_REGIME_NEGATIVE_MISSED'
            USING ERRCODE = 'P3207';
    EXCEPTION
        WHEN SQLSTATE 'P3001' THEN
            NULL;
    END;

    PERFORM public.p3_append_regulator_partition_finding(
        'decision://regulator/a-only',
        'regulator_a',
        'regulator_a',
        '2026-04-02T00:00:00Z',
        'finding-a',
        '1c000000-0000-0000-0000-000000000215'
    );

    v_precedence_finding := public.p3_resolve_regulator_precedence(
        'decision://regulator/precedence',
        'regulator_a',
        'regulator_b',
        '2026-04-03T00:00:00Z',
        'precedence-resolution',
        '1d000000-0000-0000-0000-000000000215'
    );

    IF NOT EXISTS (
        SELECT 1
        FROM public.p3_regulator_partition_findings
        WHERE regulator_partition_finding_id = v_precedence_finding
          AND partition_state = 'precedence_applied'
          AND precedence_rule_id = v_rule
    ) THEN
        RAISE EXCEPTION 'PRECEDENCE_APPLICATION_MISSING'
            USING ERRCODE = 'P3207';
    END IF;

    v_gap_finding := public.p3_resolve_regulator_precedence(
        'decision://regulator/gap',
        'regulator_a',
        'regulator_c',
        '2026-04-04T00:00:00Z',
        'gap-resolution',
        '1e000000-0000-0000-0000-000000000215'
    );

    IF NOT EXISTS (
        SELECT 1
        FROM public.p3_regulator_partition_findings
        WHERE regulator_partition_finding_id = v_gap_finding
          AND partition_state = 'doctrine_gap'
          AND doctrine_gap_reason = 'undeclared_precedence'
    ) THEN
        RAISE EXCEPTION 'DOCTRINE_GAP_FINDING_MISSING'
            USING ERRCODE = 'P3207';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM public.p3_regulator_partition_findings
        WHERE subject_key = 'decision://regulator/gap'
          AND partition_state = 'independent_finding'
    ) <> 2 THEN
        RAISE EXCEPTION 'INDEPENDENT_FINDINGS_NOT_PRESERVED'
            USING ERRCODE = 'P3207';
    END IF;

    RAISE NOTICE 'REGULATOR_OK';
    RAISE NOTICE 'NEGATIVE_OK';
END;
$$;
ROLLBACK;
SQL
)"
record_command "exercise cross-regime rejection, precedence application, and doctrine-gap preservation in a rollback transaction"
if REGULATOR_OUT="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X 2>&1 <<<"$REGULATOR_SQL")"; then
  if grep -q 'REGULATOR_OK' <<<"$REGULATOR_OUT"; then
    record_check "regulator_partition_resolution" "PASS" "regulator partitioning preserves sovereignty separation and doctrine-declared precedence"
  else
    record_check "regulator_partition_resolution" "FAIL" "regulator exercise did not emit REGULATOR_OK"
  fi
  if grep -q 'NEGATIVE_OK' <<<"$REGULATOR_OUT"; then
    record_check "cross_regime_negative" "PASS" "cross-regime rule application fails closed with SQLSTATE P3001"
  else
    record_check "cross_regime_negative" "FAIL" "regulator negative test did not emit NEGATIVE_OK"
  fi
else
  record_check "regulator_partition_resolution" "FAIL" "psql regulator exercise failed"
  record_check "cross_regime_negative" "FAIL" "psql regulator negative test failed"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-WP-007 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-WP-007' "$ROOT/$REGISTRY_PATH" || true)"
ADR_MATCHES="$(grep -c '0215' "$ROOT/$ADR_PATH" || true)"
SQLSTATE_P3001="$(grep -c '"P3001"' "$ROOT/$SQLSTATE_MAP_PATH" || true)"
SQLSTATE_P3014="$(grep -c '"P3014"' "$ROOT/$SQLSTATE_MAP_PATH" || true)"
META_STATUS="$(awk -F': ' '/^status:/ {print $2; exit}' "$ROOT/$META_PATH" || true)"
record_command "inspect runtime task index, phase3 task registry, ADR-0010, sqlstate map, and task meta"
[[ "$RUNTIME_INDEX_MATCHES" -ge 1 ]] && record_check "runtime_index_registered" "PASS" "PHASE3 runtime index contains TSK-P3-WP-007" || record_check "runtime_index_registered" "FAIL" "TSK-P3-WP-007 missing from PHASE3 runtime index"
[[ "$REGISTRY_MATCHES" -ge 1 ]] && record_check "phase3_registry_registered" "PASS" "phase3_task_registry.yml contains TSK-P3-WP-007" || record_check "phase3_registry_registered" "FAIL" "TSK-P3-WP-007 missing from phase3_task_registry.yml"
[[ "$ADR_MATCHES" -ge 1 ]] && record_check "adr_rebaseline_recorded" "PASS" "ADR-0010 references MIGRATION_HEAD 0215" || record_check "adr_rebaseline_recorded" "FAIL" "ADR-0010 missing 0215 baseline note"
[[ "$SQLSTATE_P3001" -ge 1 && "$SQLSTATE_P3014" -ge 1 ]] && record_check "sqlstate_registered" "PASS" "sqlstate map contains P3001 and P3014" || record_check "sqlstate_registered" "FAIL" "sqlstate map missing P3001 or P3014"
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
