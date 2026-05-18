#!/usr/bin/env bash
# TSK-P3-WP-004 verifier: contradiction detection substrate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-WP-004"
MIGRATION_PATH="schema/migrations/0213_p3_contradiction_detection.sql"
VERIFIER_PATH="scripts/db/verify_p3_contradiction_detection.sh"
HEAD_PATH="schema/migrations/MIGRATION_HEAD"
ADR_PATH="docs/decisions/ADR-0010-baseline-policy.md"
SQLSTATE_MAP_PATH="docs/contracts/sqlstate_map.yml"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-WP-004/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-WP-004/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-WP-004/EXEC_LOG.md"

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
if [[ "$HEAD_TOKEN" =~ ^[0-9]{4}$ ]] && (( 10#$HEAD_TOKEN >= 213 )); then
  record_check "migration_head_forward_only" "PASS" "MIGRATION_HEAD=$HEAD_TOKEN (>=0213)"
else
  record_check "migration_head_forward_only" "FAIL" "unexpected MIGRATION_HEAD=$HEAD_TOKEN"
fi

CLAIMS_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_contradiction_claims')::text, '');")"
RECORDS_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_contradiction_records')::text, '');")"
QUARANTINE_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_quarantine_records')::text, '');")"
SUPERSESSION_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_contradiction_supersessions')::text, '');")"
ESCALATION_TABLE="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_contradiction_escalations')::text, '');")"
MANIFEST_VIEW="$(safe_sql "SELECT COALESCE(to_regclass('public.p3_contradiction_manifest')::text, '');")"
ASSERT_FUNCTION_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname='public' AND p.proname='p3_assert_contradiction_claim';")"
APPEND_FUNCTION_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname='public' AND p.proname='p3_append_contradiction_finding';")"
SUPERSEDE_FUNCTION_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname='public' AND p.proname='p3_append_contradiction_supersession';")"
record_command "inspect contradiction substrate relations and functions"

[[ "$CLAIMS_TABLE" == "p3_contradiction_claims" ]] \
  && record_check "claims_table_exists" "PASS" "public.p3_contradiction_claims exists" \
  || record_check "claims_table_exists" "FAIL" "public.p3_contradiction_claims missing"
[[ "$RECORDS_TABLE" == "p3_contradiction_records" ]] \
  && record_check "records_table_exists" "PASS" "public.p3_contradiction_records exists" \
  || record_check "records_table_exists" "FAIL" "public.p3_contradiction_records missing"
[[ "$QUARANTINE_TABLE" == "p3_quarantine_records" ]] \
  && record_check "quarantine_table_exists" "PASS" "public.p3_quarantine_records exists" \
  || record_check "quarantine_table_exists" "FAIL" "public.p3_quarantine_records missing"
[[ "$SUPERSESSION_TABLE" == "p3_contradiction_supersessions" ]] \
  && record_check "supersession_table_exists" "PASS" "public.p3_contradiction_supersessions exists" \
  || record_check "supersession_table_exists" "FAIL" "public.p3_contradiction_supersessions missing"
[[ "$ESCALATION_TABLE" == "p3_contradiction_escalations" ]] \
  && record_check "escalation_table_exists" "PASS" "public.p3_contradiction_escalations exists" \
  || record_check "escalation_table_exists" "FAIL" "public.p3_contradiction_escalations missing"
[[ "$MANIFEST_VIEW" == "p3_contradiction_manifest" ]] \
  && record_check "manifest_exists" "PASS" "public.p3_contradiction_manifest exists" \
  || record_check "manifest_exists" "FAIL" "public.p3_contradiction_manifest missing"
[[ "$ASSERT_FUNCTION_COUNT" == "1" ]] \
  && record_check "assert_function_exists" "PASS" "p3_assert_contradiction_claim exists" \
  || record_check "assert_function_exists" "FAIL" "p3_assert_contradiction_claim missing"
[[ "$APPEND_FUNCTION_COUNT" == "1" ]] \
  && record_check "append_function_exists" "PASS" "p3_append_contradiction_finding exists" \
  || record_check "append_function_exists" "FAIL" "p3_append_contradiction_finding missing"
[[ "$SUPERSEDE_FUNCTION_COUNT" == "1" ]] \
  && record_check "supersede_function_exists" "PASS" "p3_append_contradiction_supersession exists" \
  || record_check "supersede_function_exists" "FAIL" "p3_append_contradiction_supersession missing"

CLASS_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_contradiction_class'::regtype;")"
STATE_ENUM_COUNT="$(safe_sql "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.p3_contradiction_resolution_state'::regtype;")"
record_command "inspect contradiction enums and manifest kinds"
[[ "$CLASS_ENUM_COUNT" == "3" ]] \
  && record_check "class_enum_count" "PASS" "p3_contradiction_class has direct, temporal, authority_scope" \
  || record_check "class_enum_count" "FAIL" "expected 3 contradiction classes, got $CLASS_ENUM_COUNT"
[[ "$STATE_ENUM_COUNT" == "4" ]] \
  && record_check "state_enum_count" "PASS" "p3_contradiction_resolution_state has 4 values" \
  || record_check "state_enum_count" "FAIL" "expected 4 contradiction states, got $STATE_ENUM_COUNT"

CONTRADICTION_SQL="$(cat <<'SQL'
BEGIN;
DO $$
DECLARE
    v_universe uuid := '10000000-0000-0000-0000-000000000213';
    v_root_auth uuid := '20000000-0000-0000-0000-000000000213';
    v_delegate_auth uuid := '30000000-0000-0000-0000-000000000213';
    v_revoked_auth uuid := '40000000-0000-0000-0000-000000000213';
    v_node_one uuid := '50000000-0000-0000-0000-000000000213';
    v_node_two uuid := '60000000-0000-0000-0000-000000000213';
    v_policy uuid := '70000000-0000-0000-0000-000000000213';
    v_claim_a uuid;
    v_claim_b uuid;
    v_record_a uuid;
    v_record_b uuid;
    v_supersession uuid;
    v_quarantine_count integer;
    v_escalation_count integer;
    v_tie_break text;
    v_seen text;
BEGIN
    INSERT INTO public.p3_dependency_nodes (node_id, node_key, node_kind, lineage_provenance_id)
    VALUES
        (v_node_one, 'p3.contradiction.node.one', 'decision_record', '80000000-0000-0000-0000-000000000213'),
        (v_node_two, 'p3.contradiction.node.two', 'decision_record', '81000000-0000-0000-0000-000000000213');

    INSERT INTO public.p3_authority_lineage (
        authority_lineage_id, authority_key, authority_source_kind, source_reference,
        resource_scope, act_scope, effective_from, lineage_provenance_id
    ) VALUES (
        v_root_auth, 'authority.contradiction.root', 'constitutional_document',
        'constitution://phase3/contradiction/root', 'asset_batch', 'admissibility_decision',
        '2026-01-01T00:00:00Z', '82000000-0000-0000-0000-000000000213'
    );

    INSERT INTO public.p3_authority_lineage (
        authority_lineage_id, authority_key, authority_source_kind, source_reference,
        delegated_from_authority_lineage_id, resource_scope, act_scope, effective_from, lineage_provenance_id
    ) VALUES (
        v_delegate_auth, 'authority.contradiction.delegate', 'delegated_authority',
        'delegation://phase3/contradiction/delegate', v_root_auth, 'asset_batch', 'admissibility_decision',
        '2026-01-01T00:00:00Z', '83000000-0000-0000-0000-000000000213'
    );

    INSERT INTO public.p3_authority_lineage (
        authority_lineage_id, authority_key, authority_source_kind, source_reference,
        delegated_from_authority_lineage_id, revoked_by_authority_lineage_id, revocation_lineage_metadata,
        resource_scope, act_scope, effective_from, lineage_provenance_id
    ) VALUES (
        v_revoked_auth, 'authority.contradiction.revoked', 'delegated_authority',
        'delegation://phase3/contradiction/revoked', v_root_auth, v_root_auth, '{"reason":"revoked"}'::jsonb,
        'asset_batch', 'admissibility_decision', '2026-01-01T00:00:00Z', '84000000-0000-0000-0000-000000000213'
    );

    INSERT INTO public.p3_policy_artifacts (
        policy_artifact_id, artifact_key, artifact_class, source_authority_lineage_id, artifact_version,
        effective_from, resource_scope, act_scope, lineage_provenance_id
    ) VALUES (
        v_policy, 'policy.contradiction', 'contradiction_policy', v_root_auth, 'v1',
        '2026-01-01T00:00:00Z', 'asset_batch', 'admissibility_decision',
        '85000000-0000-0000-0000-000000000213'
    );

    INSERT INTO public.p3_projection_universes (
        projection_universe_id, projection_universe_key, projection_purpose, replay_algorithm_version,
        temporal_evaluation_point, source_record_set, replay_reconstruction_inputs, lineage_provenance_id
    ) VALUES (
        v_universe, 'projection.contradiction.default', 'admissibility_view', 'phase3-contradiction-v1',
        '2026-04-01T00:00:00Z', '{"seed":"wave3"}'::jsonb,
        '{"ordering":"declared_order_at,declared_tie_break_key","trust_boundary":"persisted-only"}'::jsonb,
        '86000000-0000-0000-0000-000000000213'
    );

    v_claim_a := public.p3_assert_contradiction_claim(
        v_node_one, v_root_auth, v_policy, v_universe,
        'shipment-42', 'declared_mass', '100', '2026-04-01T00:00:00Z', '2026-04-30T00:00:00Z',
        'asset_batch', 'admissibility_decision', '2026-04-01T00:00:00Z', 'a-1',
        '87000000-0000-0000-0000-000000000213'
    );

    v_claim_b := public.p3_assert_contradiction_claim(
        v_node_two, v_delegate_auth, v_policy, v_universe,
        'shipment-42', 'declared_mass', '120', '2026-05-01T00:00:00Z', NULL,
        'asset_batch', 'admissibility_decision', '2026-05-01T00:00:00Z', 'b-1',
        '88000000-0000-0000-0000-000000000213'
    );

    v_record_a := public.p3_append_contradiction_finding(
        'direct', v_claim_a, v_claim_b, 'quarantined',
        'Direct contradiction retained for quarantine test',
        'ctx-direct-quarantine', '89000000-0000-0000-0000-000000000213',
        'AT-SHARED', 'contradiction_quarantine', NULL
    );

    v_record_b := public.p3_append_contradiction_finding(
        'authority_scope', v_claim_b, v_claim_a, 'escalation_required',
        'Authority contradiction escalated to failure composition',
        'ctx-authority-escalation', '8a000000-0000-0000-0000-000000000213',
        'AT-DELEGATED', 'contradiction_to_failure', 'P3-SURF-005'
    );

    v_supersession := public.p3_append_contradiction_supersession(
        v_record_a, v_record_b, 'Escalated contradiction supersedes quarantine posture',
        '8b000000-0000-0000-0000-000000000213'
    );

    SELECT COUNT(*) INTO v_quarantine_count
    FROM public.p3_quarantine_records
    WHERE contradiction_record_id = v_record_a;

    IF v_quarantine_count <> 1 THEN
        RAISE EXCEPTION 'QUARANTINE_MISSING:%', v_quarantine_count
            USING ERRCODE = 'P3207';
    END IF;

    SELECT COUNT(*) INTO v_escalation_count
    FROM public.p3_contradiction_escalations
    WHERE contradiction_record_id = v_record_b
      AND authority_transfer_mode = 'AT-DELEGATED'
      AND receiving_surface_id = 'P3-SURF-005';

    IF v_escalation_count <> 1 THEN
        RAISE EXCEPTION 'ESCALATION_MISSING:%', v_escalation_count
            USING ERRCODE = 'P3207';
    END IF;

    SELECT tie_break_key INTO v_tie_break
    FROM public.p3_contradiction_records
    WHERE contradiction_record_id = v_record_a;

    IF v_tie_break <> 'a-1::b-1' THEN
        RAISE EXCEPTION 'TIE_BREAK_MISMATCH:%', v_tie_break
            USING ERRCODE = 'P3207';
    END IF;

    SELECT string_agg(DISTINCT artifact_kind, ',' ORDER BY artifact_kind)
    INTO v_seen
    FROM public.p3_contradiction_manifest
    WHERE artifact_id IN (v_record_a, v_record_b, v_supersession)
       OR artifact_kind IN ('quarantine_record', 'escalation_record');

    IF position('contradiction_record' in v_seen) = 0
       OR position('quarantine_record' in v_seen) = 0
       OR position('escalation_record' in v_seen) = 0
       OR position('supersession_record' in v_seen) = 0 THEN
        RAISE EXCEPTION 'MANIFEST_COVERAGE_MISMATCH:%', coalesce(v_seen, 'NULL')
            USING ERRCODE = 'P3207';
    END IF;

    BEGIN
        PERFORM public.p3_assert_contradiction_claim(
            v_node_two, v_root_auth, v_policy, v_universe,
            'shipment-42', 'declared_mass', '999', '2026-04-01T00:00:00Z', '2026-04-30T00:00:00Z',
            'asset_batch', 'admissibility_decision', '2026-04-01T00:00:00Z', 'direct-neg',
            '8c000000-0000-0000-0000-000000000213'
        );
        RAISE EXCEPTION 'DIRECT_NEGATIVE_NOT_BLOCKED'
            USING ERRCODE = 'P3207';
    EXCEPTION
        WHEN SQLSTATE 'P3003' THEN
            NULL;
    END;

    BEGIN
        PERFORM public.p3_assert_contradiction_claim(
            v_node_two, v_root_auth, v_policy, v_universe,
            'shipment-42', 'declared_mass', '130', '2026-04-15T00:00:00Z', NULL,
            'asset_batch', 'admissibility_decision', '2026-04-15T00:00:00Z', 'temporal-neg',
            '8d000000-0000-0000-0000-000000000213'
        );
        RAISE EXCEPTION 'TEMPORAL_NEGATIVE_NOT_BLOCKED'
            USING ERRCODE = 'P3207';
    EXCEPTION
        WHEN SQLSTATE 'P3004' THEN
            NULL;
    END;

    BEGIN
        PERFORM public.p3_assert_contradiction_claim(
            v_node_two, v_revoked_auth, v_policy, v_universe,
            'shipment-99', 'declared_mass', '100', '2026-04-01T00:00:00Z', NULL,
            'asset_batch', 'admissibility_decision', '2026-04-01T00:00:00Z', 'authority-neg',
            '8e000000-0000-0000-0000-000000000213'
        );
        RAISE EXCEPTION 'AUTHORITY_NEGATIVE_NOT_BLOCKED'
            USING ERRCODE = 'P3207';
    EXCEPTION
        WHEN SQLSTATE 'P3005' THEN
            NULL;
    END;
END $$;
ROLLBACK;
SQL
)"
record_command "exercise contradiction negative/positive paths"
if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -q >/dev/null <<<"$CONTRADICTION_SQL"; then
  record_check "contradiction_behavior" "PASS" "direct, temporal, and authority-scope contradictions block with declared SQLSTATEs and append-only contradiction structures expose quarantine, escalation, and supersession artifacts"
else
  record_check "contradiction_behavior" "FAIL" "behavioral contradiction proof failed"
fi

if grep -q "P3003" "$ROOT/$SQLSTATE_MAP_PATH" && grep -q "P3004" "$ROOT/$SQLSTATE_MAP_PATH" && grep -q "P3005" "$ROOT/$SQLSTATE_MAP_PATH"; then
  record_check "sqlstate_map_registration" "PASS" "sqlstate map registers P3003, P3004, and P3005"
else
  record_check "sqlstate_map_registration" "FAIL" "sqlstate map missing contradiction codes"
fi

if grep -q "0213" "$ROOT/$ADR_PATH" && grep -q "TSK-P3-WP-004" "$ROOT/$ADR_PATH"; then
  record_check "adr_rebaseline_note" "PASS" "ADR-0010 records the contradiction rebaseline closure"
else
  record_check "adr_rebaseline_note" "FAIL" "ADR-0010 missing contradiction rebaseline entry"
fi

if grep -q "| TSK-P3-WP-004 |" "$ROOT/$RUNTIME_INDEX_PATH"; then
  record_check "runtime_index_registration" "PASS" "runtime task index contains TSK-P3-WP-004"
else
  record_check "runtime_index_registration" "FAIL" "runtime task index missing TSK-P3-WP-004"
fi

if grep -q "task_id: TSK-P3-WP-004" "$ROOT/$REGISTRY_PATH" && grep -A6 "task_id: TSK-P3-WP-004" "$ROOT/$REGISTRY_PATH" | grep -q "status: completed"; then
  record_check "registry_registration" "PASS" "phase3 task registry marks TSK-P3-WP-004 completed"
else
  record_check "registry_registration" "FAIL" "phase3 task registry missing completed TSK-P3-WP-004"
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
task_id = "TSK-P3-WP-004"
git_sha = Path(".git/HEAD").read_text().strip() if Path(".git/HEAD").exists() else "UNKNOWN"
if git_sha.startswith("ref: "):
    ref = git_sha.split(" ", 1)[1]
    git_sha = (Path(".git") / ref).read_text().strip()

checks = []
for line in checks_path.read_text().splitlines():
    cid, result, detail = line.split("\t", 2)
    checks.append({"id": cid, "result": result, "detail": detail})

observed_paths = [
    "schema/migrations/0213_p3_contradiction_detection.sql",
    "scripts/db/verify_p3_contradiction_detection.sh",
    "schema/migrations/MIGRATION_HEAD",
    "docs/contracts/sqlstate_map.yml",
    "docs/decisions/ADR-0010-baseline-policy.md",
    "docs/tasks/PHASE3_RUNTIME_TASKS.md",
    "docs/PHASE3/phase3_task_registry.yml",
    "tasks/TSK-P3-WP-004/meta.yml",
    "docs/plans/phase3/TSK-P3-WP-004/PLAN.md",
    "docs/plans/phase3/TSK-P3-WP-004/EXEC_LOG.md",
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
