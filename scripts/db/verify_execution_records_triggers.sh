#!/usr/bin/env bash
# ============================================================
# verify_execution_records_triggers.sh
# Task: TSK-P2-PREAUTH-003-REM-03
# Casefile: REM-2026-04-20_execution-truth-anchor
# Invariant: INV-EXEC-TRUTH-001 (enforcement surface #3 + #4)
#
# Proves migration 0133 installed:
#   - execution_records_append_only_trigger (BEFORE UPDATE OR DELETE)
#   - execution_records_temporal_binding_trigger (BEFORE INSERT)
# Both trigger functions are SECURITY DEFINER with search_path hardened,
# EXECUTE revoked from PUBLIC. Drives the two negative-test helpers.
# Emits self-certifying evidence JSON.
# ============================================================
set -Eeuo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIG_FILE="$ROOT_DIR/schema/migrations/0133_execution_records_triggers.sql"
HEAD_FILE="$ROOT_DIR/schema/migrations/MIGRATION_HEAD"
APPEND_ONLY_TEST="$ROOT_DIR/scripts/db/tests/test_execution_records_append_only_negative.sh"
TEMPORAL_TEST="$ROOT_DIR/scripts/db/tests/test_execution_records_temporal_binding_negative.sh"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase2/tsk_p2_preauth_003_rem_03.json"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

TASK_ID="TSK-P2-PREAUTH-003-REM-03"
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TRACE_START="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

# Check 1: migration file exists; MIGRATION_HEAD = 0133
test -f "$MIG_FILE" || { echo "ERR: migration 0133 missing" >&2; exit 1; }
HEAD_VALUE="$(cat "$HEAD_FILE" | tr -d '\n')"
[[ "$HEAD_VALUE" == "0133" ]] || { echo "ERR: MIGRATION_HEAD=$HEAD_VALUE (expected 0133)" >&2; exit 1; }

# Check 2: append-only trigger present with correct event mask
APPEND_TRIGGER="$(psql "$DATABASE_URL" -qAt -c "
SELECT tgname || '|' || tgtype::text
FROM pg_trigger
WHERE tgname = 'execution_records_append_only_trigger'
  AND NOT tgisinternal;")"
[[ -n "$APPEND_TRIGGER" ]] || { echo "ERR: execution_records_append_only_trigger missing" >&2; exit 1; }
# tgtype bits: 1=ROW, 2=BEFORE, 4=INSERT, 8=DELETE, 16=UPDATE, 32=TRUNCATE
# Expected: ROW(1) + BEFORE(2) + DELETE(8) + UPDATE(16) = 27
APPEND_TGTYPE="$(echo "$APPEND_TRIGGER" | awk -F'|' '{print $2}')"
[[ "$APPEND_TGTYPE" == "27" ]] || { echo "ERR: append-only trigger tgtype=$APPEND_TGTYPE (expected 27=ROW+BEFORE+UPDATE+DELETE)" >&2; exit 1; }

# Check 3: temporal-binding trigger present with correct event mask
TEMPORAL_TRIGGER="$(psql "$DATABASE_URL" -qAt -c "
SELECT tgname || '|' || tgtype::text
FROM pg_trigger
WHERE tgname = 'execution_records_temporal_binding_trigger'
  AND NOT tgisinternal;")"
[[ -n "$TEMPORAL_TRIGGER" ]] || { echo "ERR: execution_records_temporal_binding_trigger missing" >&2; exit 1; }
# Expected: ROW(1) + BEFORE(2) + INSERT(4) = 7
TEMPORAL_TGTYPE="$(echo "$TEMPORAL_TRIGGER" | awk -F'|' '{print $2}')"
[[ "$TEMPORAL_TGTYPE" == "7" ]] || { echo "ERR: temporal-binding trigger tgtype=$TEMPORAL_TGTYPE (expected 7=ROW+BEFORE+INSERT)" >&2; exit 1; }

# Check 4: both functions SECURITY DEFINER + search_path hardened
FUNC_INFO="$(psql "$DATABASE_URL" -qAt -c "
SELECT proname,
       prosecdef::text,
       COALESCE(array_to_string(proconfig, ','), '')
FROM pg_proc
WHERE proname IN ('execution_records_append_only','enforce_execution_interpretation_temporal_binding')
  AND pronamespace = 'public'::regnamespace
ORDER BY proname;")"
echo "$FUNC_INFO" | while IFS='|' read -r fn secdef config; do
    [[ "$secdef" == "true" || "$secdef" == "t" ]] || { echo "ERR: $fn prosecdef=$secdef (expected true)" >&2; exit 1; }
    echo "$config" | grep -q 'search_path=' || { echo "ERR: $fn missing search_path config" >&2; exit 1; }
    echo "$config" | grep -q 'pg_catalog' || { echo "ERR: $fn search_path does not include pg_catalog" >&2; exit 1; }
done

# Check 5: EXECUTE revoked from PUBLIC on both functions
PUBLIC_GRANTS="$(psql "$DATABASE_URL" -qAt -c "
SELECT proname
FROM pg_proc p
WHERE p.proname IN ('execution_records_append_only','enforce_execution_interpretation_temporal_binding')
  AND p.pronamespace = 'public'::regnamespace
  AND has_function_privilege('public', p.oid, 'EXECUTE');")"
if [[ -n "$PUBLIC_GRANTS" ]]; then
    echo "ERR: EXECUTE still granted to PUBLIC on: $PUBLIC_GRANTS" >&2; exit 1
fi

# Check 6: drive negative test harnesses
NEG1_OUT="$(bash "$APPEND_ONLY_TEST" 2>&1 | tr '\n' '|' | sed 's/|$//')"
NEG2_OUT="$(bash "$TEMPORAL_TEST"      2>&1 | tr '\n' '|' | sed 's/|$//')"
echo "$NEG1_OUT" | grep -q "PASS" || { echo "ERR: append-only negative test failed: $NEG1_OUT" >&2; exit 1; }
echo "$NEG2_OUT" | grep -q "PASS" || { echo "ERR: temporal-binding negative test failed: $NEG2_OUT" >&2; exit 1; }

# Observed hashes
MIG_SHA="$(sha256sum "$MIG_FILE" | awk '{print $1}')"
HEAD_SHA="$(sha256sum "$HEAD_FILE" | awk '{print $1}')"
APPEND_TEST_SHA="$(sha256sum "$APPEND_ONLY_TEST" | awk '{print $1}')"
TEMPORAL_TEST_SHA="$(sha256sum "$TEMPORAL_TEST" | awk '{print $1}')"
VERIFIER_SHA="$(sha256sum "${BASH_SOURCE[0]}" | awk '{print $1}')"

TRACE_END="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": [
    {"name": "migration_file_and_head_match", "result": "pass"},
    {"name": "append_only_trigger_tgtype_27", "result": "pass"},
    {"name": "temporal_binding_trigger_tgtype_7", "result": "pass"},
    {"name": "both_functions_security_definer_search_path_hardened", "result": "pass"},
    {"name": "execute_revoked_from_public", "result": "pass"},
    {"name": "negative_tests_pass_gf056_gf058", "result": "pass"}
  ],
  "observed_paths": [
    "schema/migrations/0133_execution_records_triggers.sql",
    "schema/migrations/MIGRATION_HEAD",
    "scripts/db/tests/test_execution_records_append_only_negative.sh",
    "scripts/db/tests/test_execution_records_temporal_binding_negative.sh"
  ],
  "observed_hashes": {
    "migration_0133_sha256": "$MIG_SHA",
    "migration_head_sha256": "$HEAD_SHA",
    "append_only_test_sha256": "$APPEND_TEST_SHA",
    "temporal_binding_test_sha256": "$TEMPORAL_TEST_SHA",
    "verifier_sha256": "$VERIFIER_SHA"
  },
  "command_outputs": {
    "append_only_trigger_row": $(echo "$APPEND_TRIGGER" | jq -R -s -c '.'),
    "temporal_binding_trigger_row": $(echo "$TEMPORAL_TRIGGER" | jq -R -s -c '.'),
    "function_info_rows": $(echo "$FUNC_INFO" | jq -R -s -c 'split("\n") | map(select(length>0))'),
    "append_only_negative_test_output": $(echo "$NEG1_OUT" | jq -R -s -c '.'),
    "temporal_binding_negative_test_output": $(echo "$NEG2_OUT" | jq -R -s -c '.')
  },
  "execution_trace": {
    "start_utc": "$TRACE_START",
    "end_utc": "$TRACE_END"
  },
  "triggers_installed": true,
  "search_path_hardened": true,
  "negative_test_sqlstates": ["GF056", "GF058"],
  "trigger_definer_functions": [
    "public.execution_records_append_only",
    "public.enforce_execution_interpretation_temporal_binding"
  ],
  "migration_head_value": "$HEAD_VALUE"
}
EOF

echo "PASS: REM-03 triggers installed; MIGRATION_HEAD=$HEAD_VALUE; evidence: $EVIDENCE_FILE"
