#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-WP-009"
MIGRATION_PATH="schema/migrations/0217_p3_spatial_legality_dnsh_gates.sql"
VERIFIER_PATH="scripts/db/verify_p3_spatial_legality_dnsh_gates.sh"
HEAD_PATH="schema/migrations/MIGRATION_HEAD"
ADR_PATH="docs/decisions/ADR-0010-baseline-policy.md"
SQLSTATE_MAP_PATH="docs/contracts/sqlstate_map.yml"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-WP-009/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-WP-009/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-WP-009/EXEC_LOG.md"

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
if [[ "$HEAD_TOKEN" =~ ^[0-9]{4}$ ]] && (( 10#$HEAD_TOKEN >= 217 )); then
  record_check "migration_head_forward_only" "PASS" "MIGRATION_HEAD=$HEAD_TOKEN (>=0217)"
else
  record_check "migration_head_forward_only" "FAIL" "unexpected MIGRATION_HEAD=$HEAD_TOKEN"
fi

DECL_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_spatial_dataset_declarations')::text, '');")"
FINDING_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_spatial_legality_findings')::text, '');")"
MANIFEST_VIEW="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_spatial_legality_manifest')::text, '');")"
ASSERT_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='p3_assert_spatial_legality';")"
STATE_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_spatial_gate_state'::regtype;")"
record_command "inspect spatial legality relations and function"

[[ "$DECL_TABLE" == "p3_spatial_dataset_declarations" ]] && record_check "declaration_table_exists" "PASS" "public.p3_spatial_dataset_declarations exists" || record_check "declaration_table_exists" "FAIL" "public.p3_spatial_dataset_declarations missing"
[[ "$FINDING_TABLE" == "p3_spatial_legality_findings" ]] && record_check "finding_table_exists" "PASS" "public.p3_spatial_legality_findings exists" || record_check "finding_table_exists" "FAIL" "public.p3_spatial_legality_findings missing"
[[ "$MANIFEST_VIEW" == "p3_spatial_legality_manifest" ]] && record_check "manifest_exists" "PASS" "public.p3_spatial_legality_manifest exists" || record_check "manifest_exists" "FAIL" "public.p3_spatial_legality_manifest missing"
[[ "$ASSERT_COUNT" == "1" ]] && record_check "assert_function_exists" "PASS" "p3_assert_spatial_legality exists" || record_check "assert_function_exists" "FAIL" "p3_assert_spatial_legality missing"
[[ "$STATE_ENUM_COUNT" == "3" ]] && record_check "gate_state_enum" "PASS" "p3_spatial_gate_state has 3 values" || record_check "gate_state_enum" "FAIL" "expected 3 spatial gate states, got $STATE_ENUM_COUNT"

SPATIAL_SQL="$(cat <<'SQL'
BEGIN;
DO $$
DECLARE
    v_authority uuid := '10000000-0000-0000-0000-000000000217';
    v_policy uuid := '11000000-0000-0000-0000-000000000217';
    v_factor uuid := '12000000-0000-0000-0000-000000000217';
    v_admissible uuid;
BEGIN
    INSERT INTO public.p3_authority_lineage (
        authority_lineage_id, authority_key, authority_source_kind, source_reference,
        resource_scope, act_scope, effective_from, lineage_provenance_id
    ) VALUES (
        v_authority, 'authority.spatial.root', 'constitutional_document',
        'constitution://phase3/spatial/root', 'asset_batch', 'admissibility_decision',
        '2026-01-01T00:00:00Z', '13000000-0000-0000-0000-000000000217'
    );

    INSERT INTO public.p3_policy_artifacts (
        policy_artifact_id, artifact_key, artifact_class, source_authority_lineage_id,
        artifact_version, effective_from, resource_scope, act_scope, lineage_provenance_id
    ) VALUES (
        v_policy, 'policy.spatial.root', 'spatial_policy', v_authority,
        'v1', '2026-01-01T00:00:00Z', 'asset_batch', 'admissibility_decision',
        '14000000-0000-0000-0000-000000000217'
    );

    INSERT INTO public.factor_registry (factor_id, factor_code, factor_name, unit)
    VALUES (v_factor, 'P3_SPATIAL_DNSH', 'Phase 3 spatial DNSH dataset', 'dataset');

    INSERT INTO public.protected_areas (
        protected_area_id, source_version_id, geom, effective_from
    ) VALUES (
        '15000000-0000-0000-0000-000000000217',
        v_factor,
        ST_GeomFromText('POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))', 4326),
        '2026-01-01T00:00:00Z'
    );

    INSERT INTO public.p3_spatial_dataset_declarations (
        spatial_dataset_declaration_id, dataset_key, dataset_version, source_table_name,
        comparison_rule, doctrine_gap_blocking, source_authority_lineage_id,
        source_policy_artifact_id, replay_metadata, lineage_provenance_id
    ) VALUES
    (
        '16000000-0000-0000-0000-000000000217',
        'spatial_dns_harm', 'v1', 'public.protected_areas',
        'ST_Intersects(subject_geometry, protected_area_geom)', false, v_authority,
        v_policy, '{"dataset_kind":"protected_areas"}'::jsonb,
        '17000000-0000-0000-0000-000000000217'
    ),
    (
        '18000000-0000-0000-0000-000000000217',
        'spatial_dns_harm', 'gap', 'public.protected_areas',
        'ST_Intersects(subject_geometry, protected_area_geom)', true, v_authority,
        v_policy, '{"dataset_kind":"protected_areas"}'::jsonb,
        '19000000-0000-0000-0000-000000000217'
    );

    v_admissible := public.p3_assert_spatial_legality(
        'decision://spatial/admissible',
        ST_GeomFromText('POLYGON((20 20, 20 22, 22 22, 22 20, 20 20))', 4326),
        'spatial_dns_harm',
        'v1',
        'policy.spatial.root',
        'spatial-admissible',
        '1a000000-0000-0000-0000-000000000217'
    );

    IF NOT EXISTS (
        SELECT 1
        FROM public.p3_spatial_legality_findings
        WHERE spatial_legality_finding_id = v_admissible
          AND gate_state = 'admissible'
    ) THEN
        RAISE EXCEPTION 'ADMISSIBLE_FINDING_MISSING'
            USING ERRCODE = 'P3208';
    END IF;

    BEGIN
        PERFORM public.p3_assert_spatial_legality(
            'decision://spatial/blocked',
            ST_GeomFromText('POLYGON((1 1, 1 2, 2 2, 2 1, 1 1))', 4326),
            'spatial_dns_harm',
            'v1',
            'policy.spatial.root',
            'spatial-blocked',
            '1b000000-0000-0000-0000-000000000217'
        );
        RAISE EXCEPTION 'DNSH_NEGATIVE_MISSED'
            USING ERRCODE = 'P3208';
    EXCEPTION
        WHEN SQLSTATE 'GF057' THEN
            NULL;
    END;

    BEGIN
        PERFORM public.p3_assert_spatial_legality(
            'decision://spatial/gap',
            ST_GeomFromText('POLYGON((20 20, 20 22, 22 22, 22 20, 20 20))', 4326),
            'spatial_dns_harm',
            'gap',
            'policy.spatial.root',
            'spatial-gap',
            '1c000000-0000-0000-0000-000000000217'
        );
        RAISE EXCEPTION 'DOCTRINE_GAP_NEGATIVE_MISSED'
            USING ERRCODE = 'P3208';
    EXCEPTION
        WHEN SQLSTATE 'P3011' THEN
            NULL;
    END;

    RAISE NOTICE 'SPATIAL_OK';
    RAISE NOTICE 'NEGATIVE_OK';
END;
$$;
ROLLBACK;
SQL
)"
record_command "exercise admissible, DNSH-blocked, and doctrine-gap spatial cases in a rollback transaction"
if SPATIAL_OUT="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X 2>&1 <<<"$SPATIAL_SQL")"; then
  if grep -q 'SPATIAL_OK' <<<"$SPATIAL_OUT"; then
    record_check "spatial_gate_enforcement" "PASS" "spatial legality substrate preserves admissible findings with declared datasets"
  else
    record_check "spatial_gate_enforcement" "FAIL" "spatial exercise did not emit SPATIAL_OK"
  fi
  if grep -q 'NEGATIVE_OK' <<<"$SPATIAL_OUT"; then
    record_check "spatial_negative" "PASS" "DNSH overlap and doctrine-gap cases fail closed with GF057 and P3011"
  else
    record_check "spatial_negative" "FAIL" "spatial negative test did not emit NEGATIVE_OK"
  fi
else
  record_check "spatial_gate_enforcement" "FAIL" "psql spatial exercise failed"
  record_check "spatial_negative" "FAIL" "psql spatial negative test failed"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-WP-009 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-WP-009' "$ROOT/$REGISTRY_PATH" || true)"
ADR_MATCHES="$(grep -c '0217' "$ROOT/$ADR_PATH" || true)"
SQLSTATE_P3011="$(grep -c '"P3011"' "$ROOT/$SQLSTATE_MAP_PATH" || true)"
SQLSTATE_P3016="$(grep -c '"P3016"' "$ROOT/$SQLSTATE_MAP_PATH" || true)"
META_STATUS="$(awk -F': ' '/^status:/ {print $2; exit}' "$ROOT/$META_PATH" || true)"
record_command "inspect runtime task index, phase3 task registry, ADR-0010, sqlstate map, and task meta"
[[ "$RUNTIME_INDEX_MATCHES" -ge 1 ]] && record_check "runtime_index_registered" "PASS" "PHASE3 runtime index contains TSK-P3-WP-009" || record_check "runtime_index_registered" "FAIL" "TSK-P3-WP-009 missing from PHASE3 runtime index"
[[ "$REGISTRY_MATCHES" -ge 1 ]] && record_check "phase3_registry_registered" "PASS" "phase3_task_registry.yml contains TSK-P3-WP-009" || record_check "phase3_registry_registered" "FAIL" "TSK-P3-WP-009 missing from phase3_task_registry.yml"
[[ "$ADR_MATCHES" -ge 1 ]] && record_check "adr_rebaseline_recorded" "PASS" "ADR-0010 references MIGRATION_HEAD 0217" || record_check "adr_rebaseline_recorded" "FAIL" "ADR-0010 missing 0217 baseline note"
[[ "$SQLSTATE_P3011" -ge 1 && "$SQLSTATE_P3016" -ge 1 ]] && record_check "sqlstate_registered" "PASS" "sqlstate map contains P3011 and P3016 while DNSH overlap continues to fail closed with legacy GF057" || record_check "sqlstate_registered" "FAIL" "sqlstate map missing P3011 or P3016"
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
