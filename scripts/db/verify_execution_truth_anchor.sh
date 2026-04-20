#!/usr/bin/env bash
# ============================================================
# verify_execution_truth_anchor.sh
# Task: TSK-P2-PREAUTH-003-REM-05
# Casefile: REM-2026-04-20_execution-truth-anchor
# Invariant: INV-EXEC-TRUTH-001 (anchor verifier across all 4 enforcement surfaces)
#
# Single-integrity verifier closing INV-EXEC-TRUTH-001. Inspects seven proof
# surfaces on live DB state (no re-implementation of REM-01/02/03 logic):
#   1. NOT NULL on 5 determinism columns         -> not_null_enforced
#   2. UNIQUE(tenant_id, input_hash, interp_vid, runtime) -> unique_enforced
#   3. FK interpretation_version_id              -> fk_verified
#   4. Append-only trigger (BEFORE UPDATE|DELETE)-> append_only_enforced
#   5. Temporal-binding trigger (BEFORE INSERT)  -> temporal_binding_enforced
#   6. Both functions SECURITY DEFINER           -> sd_hardened (aggregate)
#   7. search_path=pg_catalog,public on both     -> search_path_hardened
#
# Emits self-certifying evidence with three verifier-integrity fields:
#   - verification_tool_version   SHA-256 of this script
#   - verification_input_snapshot SHA-256 of canonicalised probe outputs
#   - verification_run_hash       SHA-256 of (tool_version||snapshot||checks)
#
# CI wiring is owned by REM-05B (SECURITY_GUARDIAN); this script MUST NOT
# edit scripts/dev/** or scripts/audit/**.
# ============================================================
set -Eeuo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase2/tsk_p2_preauth_003_rem_05.json"
MIG_0131="$ROOT_DIR/schema/migrations/0131_execution_records_determinism_columns.sql"
MIG_0132="$ROOT_DIR/schema/migrations/0132_execution_records_determinism_constraints.sql"
MIG_0133="$ROOT_DIR/schema/migrations/0133_execution_records_triggers.sql"
HEAD_FILE="$ROOT_DIR/schema/migrations/MIGRATION_HEAD"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

TASK_ID="TSK-P2-PREAUTH-003-REM-05"
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TRACE_START="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

psql_qat() { psql "$DATABASE_URL" -qAt -c "$1"; }

fail() { echo "ERR: $1" >&2; exit 1; }

# ─── Probe 1: NOT NULL × 5 ───────────────────────────────────────────
NOT_NULL_ROWS="$(psql_qat "
SELECT attname
FROM pg_attribute
WHERE attrelid='public.execution_records'::regclass
  AND attname IN ('input_hash','output_hash','runtime_version','tenant_id','interpretation_version_id')
  AND attnotnull = true
ORDER BY attname;")"
NOT_NULL_COUNT="$(echo "$NOT_NULL_ROWS" | grep -c . || true)"
[[ "$NOT_NULL_COUNT" == "5" ]] || fail "not_null count=$NOT_NULL_COUNT (expected 5)"

# ─── Probe 2: UNIQUE determinism constraint ──────────────────────────
UNIQUE_ROW="$(psql_qat "
SELECT conname || '|' || pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid='public.execution_records'::regclass
  AND contype='u'
  AND conname='execution_records_determinism_unique';")"
[[ -n "$UNIQUE_ROW" ]] || fail "UNIQUE execution_records_determinism_unique missing"
echo "$UNIQUE_ROW" | grep -q 'tenant_id'                 || fail "UNIQUE missing tenant_id (multi-tenant audit isolation)"
echo "$UNIQUE_ROW" | grep -q 'input_hash'                || fail "UNIQUE missing input_hash"
echo "$UNIQUE_ROW" | grep -q 'interpretation_version_id' || fail "UNIQUE missing interpretation_version_id"
echo "$UNIQUE_ROW" | grep -q 'runtime_version'           || fail "UNIQUE missing runtime_version"

# ─── Probe 3: FK to interpretation_packs ─────────────────────────────
FK_ROW="$(psql_qat "
SELECT conname || '|' || confrelid::regclass::text
FROM pg_constraint
WHERE conrelid='public.execution_records'::regclass
  AND contype='f'
  AND conname='execution_records_interpretation_version_id_fkey';")"
[[ -n "$FK_ROW" ]] || fail "FK execution_records_interpretation_version_id_fkey missing"
echo "$FK_ROW" | grep -q 'interpretation_packs' || fail "FK does not target interpretation_packs"

# ─── Probe 4: append-only trigger ────────────────────────────────────
APPEND_ROW="$(psql_qat "
SELECT tgname || '|' || tgtype::text
FROM pg_trigger
WHERE tgrelid='public.execution_records'::regclass
  AND tgname='execution_records_append_only_trigger'
  AND NOT tgisinternal;")"
[[ -n "$APPEND_ROW" ]] || fail "execution_records_append_only_trigger missing"
APPEND_TGTYPE="$(echo "$APPEND_ROW" | awk -F'|' '{print $2}')"
# ROW(1)+BEFORE(2)+DELETE(8)+UPDATE(16) = 27
[[ "$APPEND_TGTYPE" == "27" ]] || fail "append-only tgtype=$APPEND_TGTYPE (expected 27)"

# ─── Probe 5: temporal-binding trigger ───────────────────────────────
TEMPORAL_ROW="$(psql_qat "
SELECT tgname || '|' || tgtype::text
FROM pg_trigger
WHERE tgrelid='public.execution_records'::regclass
  AND tgname='execution_records_temporal_binding_trigger'
  AND NOT tgisinternal;")"
[[ -n "$TEMPORAL_ROW" ]] || fail "execution_records_temporal_binding_trigger missing"
TEMPORAL_TGTYPE="$(echo "$TEMPORAL_ROW" | awk -F'|' '{print $2}')"
# ROW(1)+BEFORE(2)+INSERT(4) = 7
[[ "$TEMPORAL_TGTYPE" == "7" ]] || fail "temporal-binding tgtype=$TEMPORAL_TGTYPE (expected 7)"

# ─── Probe 6+7: SECURITY DEFINER + search_path hardening ─────────────
SD_ROWS="$(psql_qat "
SELECT proname || '|' || prosecdef::text || '|' || COALESCE(array_to_string(proconfig, ';;'), '')
FROM pg_proc
WHERE proname IN ('execution_records_append_only','enforce_execution_interpretation_temporal_binding')
  AND pronamespace='public'::regnamespace
ORDER BY proname;")"
SD_COUNT="$(echo "$SD_ROWS" | grep -c . || true)"
[[ "$SD_COUNT" == "2" ]] || fail "SECURITY DEFINER function count=$SD_COUNT (expected 2)"
SD_OK=true
SEARCH_PATH_OK=true
while IFS='|' read -r fn secdef config; do
    [[ "$secdef" == "true" || "$secdef" == "t" ]] || SD_OK=false
    echo "$config" | grep -q 'search_path=pg_catalog, public' || SEARCH_PATH_OK=false
done <<< "$SD_ROWS"
[[ "$SD_OK" == "true" ]] || fail "prosecdef not true on both functions"
[[ "$SEARCH_PATH_OK" == "true" ]] || fail "search_path not hardened on both functions"

# ─── Behavioural temporal-binding negative probe ─────────────────────
# Expect GF058 on a deliberately-mismatched INSERT.
set +e
TB_ERR="$(psql "$DATABASE_URL" -v VERBOSITY=verbose -v ON_ERROR_STOP=0 -c "
INSERT INTO public.execution_records
    (project_id, execution_timestamp, interpretation_version_id, input_hash, output_hash, runtime_version, tenant_id)
VALUES (gen_random_uuid(), NOW(), gen_random_uuid(), 'anchor_in', 'anchor_out', 'anchor_rt', gen_random_uuid());" 2>&1 >/dev/null)"
TB_RC=$?
set -e
[[ $TB_RC -ne 0 ]] || fail "behavioural temporal-binding probe succeeded (expected GF058)"
echo "$TB_ERR" | grep -Eq '(^|[^A-Za-z0-9])GF058([^A-Za-z0-9]|$)' || fail "behavioural probe raised but SQLSTATE != GF058"

TRACE_END="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

# ─── Observed hashes ─────────────────────────────────────────────────
sha_of() { sha256sum "$1" | awk '{print $1}'; }
HASH_0131="$(sha_of "$MIG_0131")"
HASH_0132="$(sha_of "$MIG_0132")"
HASH_0133="$(sha_of "$MIG_0133")"
HASH_HEAD="$(sha_of "$HEAD_FILE")"
HASH_VERIFIER="$(sha_of "${BASH_SOURCE[0]}")"

# ─── Verifier-integrity self-certification ──────────────────────────
INPUT_SNAPSHOT_RAW="$(printf '%s\n' \
    "$NOT_NULL_ROWS" \
    "$UNIQUE_ROW" \
    "$FK_ROW" \
    "$APPEND_ROW" \
    "$TEMPORAL_ROW" \
    "$SD_ROWS")"
VERIFICATION_TOOL_VERSION="$HASH_VERIFIER"
VERIFICATION_INPUT_SNAPSHOT="$(printf '%s' "$INPUT_SNAPSHOT_RAW" | sha256sum | awk '{print $1}')"

CHECKS_JSON="$(cat <<JSON
[
  {"name":"not_null_enforced","result":"pass","observed":5,"expected":5},
  {"name":"unique_enforced","result":"pass","constraint":"execution_records_determinism_unique"},
  {"name":"fk_verified","result":"pass","target":"interpretation_packs"},
  {"name":"append_only_enforced","result":"pass","tgtype":27},
  {"name":"temporal_binding_enforced","result":"pass","tgtype":7},
  {"name":"security_definer_hardened","result":"pass","functions":2},
  {"name":"search_path_hardened","result":"pass","value":"pg_catalog, public"},
  {"name":"behavioural_temporal_binding_probe","result":"pass","sqlstate":"GF058"}
]
JSON
)"

VERIFICATION_RUN_HASH="$(printf '%s' "${VERIFICATION_TOOL_VERSION}${VERIFICATION_INPUT_SNAPSHOT}${CHECKS_JSON}" | sha256sum | awk '{print $1}')"

cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": $CHECKS_JSON,
  "observed_paths": [
    "schema/migrations/0131_execution_records_determinism_columns.sql",
    "schema/migrations/0132_execution_records_determinism_constraints.sql",
    "schema/migrations/0133_execution_records_triggers.sql",
    "schema/migrations/MIGRATION_HEAD",
    "scripts/db/verify_execution_truth_anchor.sh"
  ],
  "observed_hashes": {
    "migration_0131_sha256": "$HASH_0131",
    "migration_0132_sha256": "$HASH_0132",
    "migration_0133_sha256": "$HASH_0133",
    "migration_head_sha256": "$HASH_HEAD",
    "verifier_sha256": "$HASH_VERIFIER"
  },
  "command_outputs": {
    "not_null_rows": $(printf '%s' "$NOT_NULL_ROWS" | jq -R -s -c '.'),
    "unique_row": $(printf '%s' "$UNIQUE_ROW" | jq -R -s -c '.'),
    "fk_row": $(printf '%s' "$FK_ROW" | jq -R -s -c '.'),
    "append_only_trigger_row": $(printf '%s' "$APPEND_ROW" | jq -R -s -c '.'),
    "temporal_binding_trigger_row": $(printf '%s' "$TEMPORAL_ROW" | jq -R -s -c '.'),
    "security_definer_rows": $(printf '%s' "$SD_ROWS" | jq -R -s -c '.'),
    "behavioural_probe_stderr_tail": $(printf '%s' "$TB_ERR" | tail -5 | jq -R -s -c '.')
  },
  "execution_trace": {
    "start_utc": "$TRACE_START",
    "end_utc": "$TRACE_END"
  },
  "not_null_enforced": true,
  "fk_verified": true,
  "unique_enforced": true,
  "append_only_enforced": true,
  "temporal_binding_enforced": true,
  "columns_verified": ["input_hash","output_hash","runtime_version","tenant_id","interpretation_version_id"],
  "verification_tool_version": "$VERIFICATION_TOOL_VERSION",
  "verification_input_snapshot": "$VERIFICATION_INPUT_SNAPSHOT",
  "verification_run_hash": "$VERIFICATION_RUN_HASH"
}
EOF

echo "PASS: REM-05 truth anchor verified; evidence: $EVIDENCE_FILE"
