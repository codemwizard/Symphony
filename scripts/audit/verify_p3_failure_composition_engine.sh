#!/usr/bin/env bash
# TSK-P3-WP-005 verifier: failure composition and evidence continuity substrate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-WP-005"
MIGRATION_PATH="schema/migrations/0214_p3_failure_composition_engine.sql"
VERIFIER_PATH="scripts/audit/verify_p3_failure_composition_engine.sh"
HEAD_PATH="schema/migrations/MIGRATION_HEAD"
ADR_PATH="docs/decisions/ADR-0010-baseline-policy.md"
SQLSTATE_MAP_PATH="docs/contracts/sqlstate_map.yml"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-WP-005/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-WP-005/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-WP-005/EXEC_LOG.md"

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
if [[ "$HEAD_TOKEN" =~ ^[0-9]{4}$ ]] && (( 10#$HEAD_TOKEN >= 214 )); then
  record_check "migration_head_forward_only" "PASS" "MIGRATION_HEAD=$HEAD_TOKEN (>=0214)"
else
  record_check "migration_head_forward_only" "FAIL" "unexpected MIGRATION_HEAD=$HEAD_TOKEN"
fi

CONTINUITY_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_provenance_continuity_records')::text, '');")"
FAILURE_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_failure_records')::text, '');")"
COMP_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_failure_continuity_compensations')::text, '');")"
MANIFEST_VIEW="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_failure_composition_manifest')::text, '');")"
ASSERT_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='p3_assert_provenance_continuity';")"
APPEND_FAILURE_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='p3_append_failure_record';")"
APPEND_CONT_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='p3_append_provenance_continuity_record';")"
record_command "inspect failure composition substrate relations and functions"

[[ "$CONTINUITY_TABLE" == "p3_provenance_continuity_records" ]] \
  && record_check "continuity_table_exists" "PASS" "public.p3_provenance_continuity_records exists" \
  || record_check "continuity_table_exists" "FAIL" "public.p3_provenance_continuity_records missing"
[[ "$FAILURE_TABLE" == "p3_failure_records" ]] \
  && record_check "failure_table_exists" "PASS" "public.p3_failure_records exists" \
  || record_check "failure_table_exists" "FAIL" "public.p3_failure_records missing"
[[ "$COMP_TABLE" == "p3_failure_continuity_compensations" ]] \
  && record_check "compensation_table_exists" "PASS" "public.p3_failure_continuity_compensations exists" \
  || record_check "compensation_table_exists" "FAIL" "public.p3_failure_continuity_compensations missing"
[[ "$MANIFEST_VIEW" == "p3_failure_composition_manifest" ]] \
  && record_check "manifest_exists" "PASS" "public.p3_failure_composition_manifest exists" \
  || record_check "manifest_exists" "FAIL" "public.p3_failure_composition_manifest missing"
[[ "$ASSERT_COUNT" == "1" ]] \
  && record_check "assert_function_exists" "PASS" "p3_assert_provenance_continuity exists" \
  || record_check "assert_function_exists" "FAIL" "p3_assert_provenance_continuity missing"
[[ "$APPEND_FAILURE_COUNT" == "1" ]] \
  && record_check "append_failure_exists" "PASS" "p3_append_failure_record exists" \
  || record_check "append_failure_exists" "FAIL" "p3_append_failure_record missing"
[[ "$APPEND_CONT_COUNT" == "1" ]] \
  && record_check "append_continuity_exists" "PASS" "p3_append_provenance_continuity_record exists" \
  || record_check "append_continuity_exists" "FAIL" "p3_append_provenance_continuity_record missing"

CATEGORY_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_failure_category'::regtype;")"
SEVERITY_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_failure_severity'::regtype;")"
BOUNDARY_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_internal_boundary_kind'::regtype;")"
record_command "inspect failure enums and manifest kinds"
[[ "$CATEGORY_COUNT" == "10" ]] \
  && record_check "category_enum_count" "PASS" "p3_failure_category has 10 doctrine-declared values" \
  || record_check "category_enum_count" "FAIL" "expected 10 failure categories, got $CATEGORY_COUNT"
[[ "$SEVERITY_COUNT" == "4" ]] \
  && record_check "severity_enum_count" "PASS" "p3_failure_severity has 4 doctrine-declared values" \
  || record_check "severity_enum_count" "FAIL" "expected 4 failure severities, got $SEVERITY_COUNT"
[[ "$BOUNDARY_COUNT" == "4" ]] \
  && record_check "boundary_enum_count" "PASS" "p3_internal_boundary_kind has 4 declared internal boundaries" \
  || record_check "boundary_enum_count" "FAIL" "expected 4 internal boundaries, got $BOUNDARY_COUNT"

FAILURE_SQL="$(cat <<'SQL'
BEGIN;
DO $$
DECLARE
    v_universe uuid := '10000000-0000-0000-0000-000000000214';
    v_root_auth uuid := '20000000-0000-0000-0000-000000000214';
    v_node_one uuid := '30000000-0000-0000-0000-000000000214';
    v_node_two uuid := '40000000-0000-0000-0000-000000000214';
    v_policy uuid := '50000000-0000-0000-0000-000000000214';
    v_claim_a uuid;
    v_claim_b uuid;
    v_contradiction uuid;
    v_complete_root uuid;
    v_complete_child uuid;
    v_broken uuid;
    v_replacement uuid;
    v_root_failure uuid;
    v_child_failure uuid;
    v_compensation uuid;
    v_root_before timestamptz;
    v_root_after timestamptz;
    v_manifest text;
BEGIN
    INSERT INTO public.p3_dependency_nodes (node_id, node_key, node_kind, lineage_provenance_id)
    VALUES
        (v_node_one, 'p3.failure.node.one', 'decision_record', '80000000-0000-0000-0000-000000000214'),
        (v_node_two, 'p3.failure.node.two', 'decision_record', '81000000-0000-0000-0000-000000000214');

    INSERT INTO public.p3_authority_lineage (
        authority_lineage_id, authority_key, authority_source_kind, source_reference,
        resource_scope, act_scope, effective_from, lineage_provenance_id
    ) VALUES (
        v_root_auth, 'authority.failure.root', 'constitutional_document',
        'constitution://phase3/failure/root', 'asset_batch', 'admissibility_decision',
        '2026-01-01T00:00:00Z', '82000000-0000-0000-0000-000000000214'
    );

    INSERT INTO public.p3_policy_artifacts (
        policy_artifact_id, artifact_key, artifact_class, source_authority_lineage_id, artifact_version,
        effective_from, resource_scope, act_scope, lineage_provenance_id
    ) VALUES (
        v_policy, 'policy.failure.root', 'failure_policy', v_root_auth, 'v1',
        '2026-01-01T00:00:00Z', 'asset_batch', 'admissibility_decision',
        '83000000-0000-0000-0000-000000000214'
    );

    INSERT INTO public.p3_projection_universes (
        projection_universe_id, projection_universe_key, projection_purpose, replay_algorithm_version,
        temporal_evaluation_point, source_record_set, replay_reconstruction_inputs, lineage_provenance_id
    ) VALUES (
        v_universe, 'projection.failure.default', 'admissibility_view', 'phase3-failure-v1',
        '2026-05-01T00:00:00Z', '{"seed":"wave3-failure"}'::jsonb,
        '{"ordering":"ordering_key,tie_break_key","trust_boundary":"persisted-only"}'::jsonb,
        '84000000-0000-0000-0000-000000000214'
    );

    v_claim_a := public.p3_assert_contradiction_claim(
        v_node_one, v_root_auth, v_policy, v_universe,
        'shipment-failure', 'declared_mass', '100', '2026-05-01T00:00:00Z', '2026-05-31T00:00:00Z',
        'asset_batch', 'admissibility_decision', '2026-05-01T00:00:00Z', 'failure-a',
        '85000000-0000-0000-0000-000000000214'
    );

    v_claim_b := public.p3_assert_contradiction_claim(
        v_node_two, v_root_auth, v_policy, v_universe,
        'shipment-failure', 'declared_mass', '120', '2026-06-01T00:00:00Z', NULL,
        'asset_batch', 'admissibility_decision', '2026-06-01T00:00:00Z', 'failure-b',
        '86000000-0000-0000-0000-000000000214'
    );

    v_contradiction := public.p3_append_contradiction_finding(
        'direct', v_claim_a, v_claim_b, 'quarantined',
        'Contradiction routed into failure composition',
        'ctx-failure-direct', '87000000-0000-0000-0000-000000000214',
        'AT-SHARED', 'contradiction_to_failure', 'P3-SURF-005'
    );

    SELECT recorded_at INTO v_root_before
    FROM public.p3_contradiction_records
    WHERE contradiction_record_id = v_contradiction;

    v_complete_root := public.p3_append_provenance_continuity_record(
        'projection_to_failure', 'P3-SURF-003', 'P3-SURF-005',
        'projection://failure/root', NULL, 'complete', 'hash-root',
        '{"phase":"wave3"}'::jsonb, '88000000-0000-0000-0000-000000000214'
    );

    v_complete_child := public.p3_append_provenance_continuity_record(
        'contradiction_to_failure', 'P3-SURF-004', 'P3-SURF-005',
        'contradiction://failure/child', v_complete_root, 'complete', 'hash-child',
        '{"phase":"wave3"}'::jsonb, '89000000-0000-0000-0000-000000000214'
    );

    v_root_failure := public.p3_append_failure_record(
        'contradiction_detected', 'blocking', NULL, v_contradiction,
        v_node_one, v_root_auth, v_policy, v_universe, v_complete_child,
        '{"reason":"direct contradiction"}'::jsonb, 'failure-root',
        '8a000000-0000-0000-0000-000000000214'
    );

    v_child_failure := public.p3_append_failure_record(
        'dependency_illegitimate', 'quarantine', v_root_failure, v_contradiction,
        v_node_two, v_root_auth, v_policy, v_universe, v_complete_child,
        '{"reason":"upstream contradiction"}'::jsonb, 'failure-child',
        '8b000000-0000-0000-0000-000000000214'
    );

    v_replacement := public.p3_append_provenance_continuity_record(
        'lineage_to_failure', 'P3-SURF-001', 'P3-SURF-005',
        'lineage://replacement', NULL, 'complete', 'hash-replacement',
        '{"repair":"true"}'::jsonb, '8c000000-0000-0000-0000-000000000214'
    );

    v_compensation := public.p3_append_continuity_compensation(
        v_complete_root, v_replacement, 'Rebound continuity root after replay-safe repair',
        '8d000000-0000-0000-0000-000000000214'
    );

    SELECT recorded_at INTO v_root_after
    FROM public.p3_contradiction_records
    WHERE contradiction_record_id = v_contradiction;

    IF v_root_before <> v_root_after THEN
        RAISE EXCEPTION 'CONTRADICTION_MUTATED'
            USING ERRCODE = 'P3207';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.p3_failure_records
        WHERE failure_record_id = v_child_failure
          AND root_failure_record_id = v_root_failure
          AND source_contradiction_record_id = v_contradiction
    ) THEN
        RAISE EXCEPTION 'FAILURE_TREE_MISMATCH'
            USING ERRCODE = 'P3207';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.p3_failure_continuity_compensations
        WHERE continuity_compensation_id = v_compensation
          AND prior_continuity_record_id = v_complete_root
          AND replacement_continuity_record_id = v_replacement
    ) THEN
        RAISE EXCEPTION 'COMPENSATION_MISSING'
            USING ERRCODE = 'P3207';
    END IF;

    BEGIN
        v_broken := public.p3_append_provenance_continuity_record(
            'contradiction_to_failure', 'P3-SURF-004', 'P3-SURF-005',
            'contradiction://failure/broken', v_complete_root, 'broken', 'hash-broken',
            '{"broken":"true"}'::jsonb, '8e000000-0000-0000-0000-000000000214'
        );

        PERFORM public.p3_append_failure_record(
            'evidence_lineage_break', 'blocking', NULL, v_contradiction,
            v_node_two, v_root_auth, v_policy, v_universe, v_broken,
            '{"reason":"broken continuity"}'::jsonb, 'failure-broken',
            '8f000000-0000-0000-0000-000000000214'
        );

        RAISE EXCEPTION 'BROKEN_CONTINUITY_NOT_BLOCKED'
            USING ERRCODE = 'P3207';
    EXCEPTION
        WHEN SQLSTATE 'P3007' THEN
            NULL;
    END;

    SELECT string_agg(DISTINCT artifact_kind, ',' ORDER BY artifact_kind)
    INTO v_manifest
    FROM public.p3_failure_composition_manifest
    WHERE artifact_id IN (v_root_failure, v_child_failure, v_complete_root, v_complete_child, v_compensation);

    IF position('failure_record' in v_manifest) = 0
       OR position('continuity_record' in v_manifest) = 0
       OR position('continuity_compensation' in v_manifest) = 0 THEN
        RAISE EXCEPTION 'MANIFEST_KIND_MISMATCH:%', coalesce(v_manifest, 'NULL')
            USING ERRCODE = 'P3207';
    END IF;
END $$;
ROLLBACK;
SQL
)"
record_command "exercise failure composition and continuity paths"
if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -q >/dev/null <<<"$FAILURE_SQL"; then
  record_check "failure_behavior" "PASS" "failure tree composition preserves read-only contradiction references and broken internal provenance continuity fails closed with P3007"
else
  record_check "failure_behavior" "FAIL" "behavioral failure-composition proof failed"
fi

if grep -q "P3007" "$ROOT/$SQLSTATE_MAP_PATH"; then
  record_check "sqlstate_map_registration" "PASS" "sqlstate map registers P3007 for provenance continuity failure"
else
  record_check "sqlstate_map_registration" "FAIL" "sqlstate map missing P3007"
fi

if grep -q "0214" "$ROOT/$ADR_PATH" && grep -q "TSK-P3-WP-005" "$ROOT/$ADR_PATH"; then
  record_check "adr_rebaseline_note" "PASS" "ADR-0010 records the failure-composition rebaseline closure"
else
  record_check "adr_rebaseline_note" "FAIL" "ADR-0010 missing failure-composition rebaseline entry"
fi

if grep -q "| TSK-P3-WP-005 |" "$ROOT/$RUNTIME_INDEX_PATH"; then
  record_check "runtime_index_registration" "PASS" "runtime task index contains TSK-P3-WP-005"
else
  record_check "runtime_index_registration" "FAIL" "runtime task index missing TSK-P3-WP-005"
fi

if grep -q "task_id: TSK-P3-WP-005" "$ROOT/$REGISTRY_PATH" && grep -A6 "task_id: TSK-P3-WP-005" "$ROOT/$REGISTRY_PATH" | grep -q "status: completed"; then
  record_check "registry_registration" "PASS" "phase3 task registry marks TSK-P3-WP-005 completed"
else
  record_check "registry_registration" "FAIL" "phase3 task registry missing completed TSK-P3-WP-005"
fi

python3 - "$CHECKS_FILE" "$COMMANDS_FILE" "$TRACE_FILE" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

checks_path = Path(sys.argv[1])
commands_path = Path(sys.argv[2])
trace_path = Path(sys.argv[3])

root = Path.cwd()
task_id = "TSK-P3-WP-005"
git_sha = Path(".git/HEAD").read_text().strip() if Path(".git/HEAD").exists() else "UNKNOWN"
if git_sha.startswith("ref: "):
    ref = git_sha.split(" ", 1)[1]
    git_sha = (Path(".git") / ref).read_text().strip()

checks = []
for line in checks_path.read_text().splitlines():
    cid, result, detail = line.split("\t", 2)
    checks.append({"id": cid, "result": result, "detail": detail})

observed_paths = [
    "schema/migrations/0214_p3_failure_composition_engine.sql",
    "scripts/audit/verify_p3_failure_composition_engine.sh",
    "schema/migrations/MIGRATION_HEAD",
    "docs/contracts/sqlstate_map.yml",
    "docs/decisions/ADR-0010-baseline-policy.md",
    "docs/tasks/PHASE3_RUNTIME_TASKS.md",
    "docs/PHASE3/phase3_task_registry.yml",
    "tasks/TSK-P3-WP-005/meta.yml",
    "docs/plans/phase3/TSK-P3-WP-005/PLAN.md",
    "docs/plans/phase3/TSK-P3-WP-005/EXEC_LOG.md",
]
observed_hashes = {}
for rel in observed_paths:
    path = root / rel
    if path.exists():
        observed_hashes[rel] = hashlib.sha256(path.read_bytes()).hexdigest()

status = "PASS" if all(c["result"] == "PASS" for c in checks) else "FAIL"
payload = {
    "task_id": task_id,
    "git_sha": git_sha,
    "timestamp_utc": __import__("datetime").datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
    "status": status,
    "checks": checks,
    "observed_hashes": observed_hashes,
    "command_outputs": commands_path.read_text().splitlines(),
    "execution_trace": trace_path.read_text().splitlines(),
}
print(json.dumps(payload, indent=2))
sys.exit(0 if status == "PASS" else 1)
PY
