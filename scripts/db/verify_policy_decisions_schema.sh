#!/usr/bin/env bash
# ============================================================
# verify_policy_decisions_schema.sh
# Task: TSK-P2-PREAUTH-004-01
# Wave: Wave 4 — Authority Binding
# Contract: docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md + 004-01/PLAN.md
#
# Proves migration 0134 materialised:
#   - public.policy_decisions with the 11 contracted columns
#   - PRIMARY KEY on policy_decision_id
#   - UNIQUE (execution_id, decision_type)
#   - FK execution_id -> execution_records(execution_id)
#   - CHECK (decision_hash ~ '^[0-9a-f]{64}$')
#   - CHECK (signature ~ '^[0-9a-f]{128}$')
#   - idx_policy_decisions_entity on (entity_type, entity_id)
#   - idx_policy_decisions_declared_by on (declared_by)
#   - enforce_policy_decisions_append_only trigger (BEFORE UPDATE OR DELETE)
#   - enforce_policy_decisions_append_only() function is SECURITY DEFINER
#     with search_path=pg_catalog,public and EXECUTE revoked from PUBLIC
#
# Drives scripts/db/tests/test_policy_decisions_negative.sh (N1-N6).
# Emits self-certifying evidence JSON at evidence/phase2/tsk_p2_preauth_004_01.json.
# ============================================================
set -Eeuo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIG_FILE="$ROOT_DIR/schema/migrations/0134_policy_decisions.sql"
HEAD_FILE="$ROOT_DIR/schema/migrations/MIGRATION_HEAD"
NEG_TEST="$ROOT_DIR/scripts/db/tests/test_policy_decisions_negative.sh"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase2/tsk_p2_preauth_004_01.json"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

TASK_ID="TSK-P2-PREAUTH-004-01"
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TRACE_START="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

# Check 1: migration file exists + MIGRATION_HEAD = 0134
test -f "$MIG_FILE" || { echo "ERR: migration 0134 missing" >&2; exit 1; }
HEAD_VALUE="$(tr -d '\n' < "$HEAD_FILE")"
[[ "$HEAD_VALUE" == "0134" ]] || { echo "ERR: MIGRATION_HEAD=$HEAD_VALUE (expected 0134)" >&2; exit 1; }

# Check 2: 11 columns with expected types + NOT NULL posture
# Expected shape (ordinal_position, column_name, data_type, is_nullable):
#   1 policy_decision_id uuid NO
#   2 execution_id       uuid NO
#   3 decision_type      text NO
#   4 authority_scope    text NO
#   5 declared_by        uuid NO
#   6 entity_type        text NO
#   7 entity_id          uuid NO
#   8 decision_hash      text NO
#   9 signature          text NO
#  10 signed_at          timestamp with time zone NO
#  11 created_at         timestamp with time zone NO
COLUMNS_OUT="$(psql "$DATABASE_URL" -qAt -c "
SELECT ordinal_position || '|' || column_name || '|' || data_type || '|' || is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'policy_decisions'
ORDER BY ordinal_position;")"

EXPECTED_COLS=(
  "1|policy_decision_id|uuid|NO"
  "2|execution_id|uuid|NO"
  "3|decision_type|text|NO"
  "4|authority_scope|text|NO"
  "5|declared_by|uuid|NO"
  "6|entity_type|text|NO"
  "7|entity_id|uuid|NO"
  "8|decision_hash|text|NO"
  "9|signature|text|NO"
  "10|signed_at|timestamp with time zone|NO"
  "11|created_at|timestamp with time zone|NO"
)
ACTUAL_COLS="$(printf '%s\n' "$COLUMNS_OUT")"
for expected in "${EXPECTED_COLS[@]}"; do
    echo "$ACTUAL_COLS" | grep -Fxq "$expected" || {
        echo "ERR: policy_decisions column mismatch; expected line '$expected' not present" >&2
        echo "Actual columns:" >&2
        echo "$ACTUAL_COLS" >&2
        exit 1
    }
done

# Check 3: PRIMARY KEY on policy_decision_id
PK_OUT="$(psql "$DATABASE_URL" -qAt -c "
SELECT tc.constraint_name || '|' || kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name = 'policy_decisions'
  AND tc.constraint_type = 'PRIMARY KEY';")"
echo "$PK_OUT" | grep -q '|policy_decision_id$' || { echo "ERR: PRIMARY KEY missing on policy_decision_id (got: $PK_OUT)" >&2; exit 1; }

# Check 4: UNIQUE (execution_id, decision_type)
UNIQUE_OUT="$(psql "$DATABASE_URL" -qAt -c "
SELECT string_agg(kcu.column_name, ',' ORDER BY kcu.ordinal_position)
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name = 'policy_decisions'
  AND tc.constraint_type = 'UNIQUE'
GROUP BY tc.constraint_name
HAVING string_agg(kcu.column_name, ',' ORDER BY kcu.ordinal_position) = 'execution_id,decision_type';")"
[[ "$UNIQUE_OUT" == "execution_id,decision_type" ]] || { echo "ERR: UNIQUE (execution_id, decision_type) missing (got: $UNIQUE_OUT)" >&2; exit 1; }

# Check 5: FK execution_id -> execution_records(execution_id)
FK_OUT="$(psql "$DATABASE_URL" -qAt -c "
SELECT kcu.column_name || '->' || ccu.table_name || '.' || ccu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name = 'policy_decisions'
  AND tc.constraint_type = 'FOREIGN KEY';")"
echo "$FK_OUT" | grep -Fxq 'execution_id->execution_records.execution_id' || { echo "ERR: FK execution_id -> execution_records(execution_id) missing (got: $FK_OUT)" >&2; exit 1; }

# Check 6: CHECK regexes on decision_hash and signature
CHECK_OUT="$(psql "$DATABASE_URL" -qAt -c "
SELECT pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.policy_decisions'::regclass
  AND contype = 'c';")"
echo "$CHECK_OUT" | grep -q "decision_hash ~ '\^\[0-9a-f\]{64}\$'" || { echo "ERR: CHECK decision_hash regex missing (got: $CHECK_OUT)" >&2; exit 1; }
echo "$CHECK_OUT" | grep -q "signature ~ '\^\[0-9a-f\]{128}\$'" || { echo "ERR: CHECK signature regex missing (got: $CHECK_OUT)" >&2; exit 1; }

# Check 7: two expected indexes
INDEX_OUT="$(psql "$DATABASE_URL" -qAt -c "
SELECT indexname
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'policy_decisions'
ORDER BY indexname;")"
echo "$INDEX_OUT" | grep -Fxq 'idx_policy_decisions_entity'      || { echo "ERR: idx_policy_decisions_entity missing" >&2; exit 1; }
echo "$INDEX_OUT" | grep -Fxq 'idx_policy_decisions_declared_by' || { echo "ERR: idx_policy_decisions_declared_by missing" >&2; exit 1; }

# Check 8: append-only trigger present + correct event mask
# tgtype bits: 1=ROW, 2=BEFORE, 4=INSERT, 8=DELETE, 16=UPDATE, 32=TRUNCATE
# Expected: ROW(1) + BEFORE(2) + DELETE(8) + UPDATE(16) = 27
TRIGGER_ROW="$(psql "$DATABASE_URL" -qAt -c "
SELECT tgname || '|' || tgtype::text
FROM pg_trigger
WHERE tgrelid = 'public.policy_decisions'::regclass
  AND tgname = 'enforce_policy_decisions_append_only'
  AND NOT tgisinternal;")"
[[ -n "$TRIGGER_ROW" ]] || { echo "ERR: enforce_policy_decisions_append_only trigger missing on policy_decisions" >&2; exit 1; }
TGTYPE="$(echo "$TRIGGER_ROW" | awk -F'|' '{print $2}')"
[[ "$TGTYPE" == "27" ]] || { echo "ERR: append-only trigger tgtype=$TGTYPE (expected 27=ROW+BEFORE+UPDATE+DELETE)" >&2; exit 1; }

# Check 9: function is SECURITY DEFINER + search_path hardened
FUNC_INFO="$(psql "$DATABASE_URL" -qAt -c "
SELECT prosecdef::text || '|' || COALESCE(array_to_string(proconfig, ','), '')
FROM pg_proc
WHERE proname = 'enforce_policy_decisions_append_only'
  AND pronamespace = 'public'::regnamespace;")"
echo "$FUNC_INFO" | grep -q '^true|' || { echo "ERR: enforce_policy_decisions_append_only prosecdef != true (got: $FUNC_INFO)" >&2; exit 1; }
echo "$FUNC_INFO" | grep -q 'search_path=pg_catalog, public' || { echo "ERR: enforce_policy_decisions_append_only proconfig lacks search_path=pg_catalog, public (got: $FUNC_INFO)" >&2; exit 1; }

# Check 10: EXECUTE revoked from PUBLIC
PUBLIC_GRANT="$(psql "$DATABASE_URL" -qAt -c "
SELECT has_function_privilege('public', p.oid, 'EXECUTE')::text
FROM pg_proc p
WHERE p.proname = 'enforce_policy_decisions_append_only'
  AND p.pronamespace = 'public'::regnamespace;")"
[[ "$PUBLIC_GRANT" == "false" ]] || { echo "ERR: EXECUTE still granted to PUBLIC on enforce_policy_decisions_append_only (got: $PUBLIC_GRANT)" >&2; exit 1; }

# Check 11: drive the negative-test harness (N1-N6)
NEG_OUT="$(bash "$NEG_TEST" 2>&1 | tr '\n' '|' | sed 's/|$//')"
echo "$NEG_OUT" | grep -q 'PASS: 004-01 negative tests (N1-N6)' || { echo "ERR: negative-test harness did not report 004-01 PASS banner: $NEG_OUT" >&2; exit 1; }

# Hashes for evidence
MIG_SHA="$(sha256sum "$MIG_FILE" | awk '{print $1}')"
HEAD_SHA="$(sha256sum "$HEAD_FILE" | awk '{print $1}')"
NEG_SHA="$(sha256sum "$NEG_TEST" | awk '{print $1}')"
VERIFIER_SHA="$(sha256sum "${BASH_SOURCE[0]}" | awk '{print $1}')"

COLUMNS_JSON="$(printf '%s\n' "$COLUMNS_OUT" | jq -R -s -c 'split("\n") | map(select(length>0))')"
CHECK_JSON="$(printf '%s\n' "$CHECK_OUT" | jq -R -s -c 'split("\n") | map(select(length>0))')"
INDEX_JSON="$(printf '%s\n' "$INDEX_OUT" | jq -R -s -c 'split("\n") | map(select(length>0))')"

TRACE_END="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": [
    {"name": "migration_file_and_head_match_0134", "result": "pass"},
    {"name": "eleven_columns_present_with_correct_types_and_not_null", "result": "pass"},
    {"name": "primary_key_on_policy_decision_id", "result": "pass"},
    {"name": "unique_execution_id_decision_type", "result": "pass"},
    {"name": "fk_execution_id_to_execution_records", "result": "pass"},
    {"name": "check_decision_hash_and_signature_regex", "result": "pass"},
    {"name": "two_expected_indexes_present", "result": "pass"},
    {"name": "append_only_trigger_tgtype_27", "result": "pass"},
    {"name": "function_security_definer_search_path_hardened", "result": "pass"},
    {"name": "execute_revoked_from_public", "result": "pass"},
    {"name": "negative_tests_n1_to_n6_pass", "result": "pass"}
  ],
  "observed_paths": [
    "schema/migrations/0134_policy_decisions.sql",
    "schema/migrations/MIGRATION_HEAD",
    "scripts/db/tests/test_policy_decisions_negative.sh"
  ],
  "observed_hashes": {
    "migration_0134_sha256": "$MIG_SHA",
    "migration_head_sha256": "$HEAD_SHA",
    "negative_test_sha256":  "$NEG_SHA",
    "verifier_sha256":       "$VERIFIER_SHA"
  },
  "command_outputs": {
    "columns_rows": $COLUMNS_JSON,
    "check_constraints": $CHECK_JSON,
    "indexes": $INDEX_JSON,
    "append_only_trigger_row": $(echo "$TRIGGER_ROW" | jq -R -s -c '.'),
    "function_info_row": $(echo "$FUNC_INFO" | jq -R -s -c '.'),
    "negative_test_output": $(echo "$NEG_OUT" | jq -R -s -c '.')
  },
  "execution_trace": {
    "start_utc": "$TRACE_START",
    "end_utc": "$TRACE_END"
  },
  "columns_present": $COLUMNS_JSON,
  "constraints_present": {
    "primary_key": "policy_decision_id",
    "unique": ["execution_id", "decision_type"],
    "foreign_key": "execution_id -> execution_records.execution_id",
    "checks": $CHECK_JSON
  },
  "triggers_present": [
    "enforce_policy_decisions_append_only (BEFORE UPDATE OR DELETE, tgtype=27)"
  ],
  "function_security_posture": {
    "function": "public.enforce_policy_decisions_append_only()",
    "security_definer": true,
    "search_path_hardened": true,
    "public_execute_revoked": true,
    "sqlstate_raised_on_violation": "GF061"
  },
  "migration_head_value": "$HEAD_VALUE"
}
EOF

# Schema validation of emitted evidence (self-check)
jq -e '.task_id and .git_sha and .timestamp_utc and .status == "PASS" and .observed_hashes and .migration_head_value' \
    "$EVIDENCE_FILE" > /dev/null \
    || { echo "ERR: evidence JSON failed self-validation" >&2; exit 1; }

echo "PASS: TSK-P2-PREAUTH-004-01 schema verifier; MIGRATION_HEAD=$HEAD_VALUE; evidence: $EVIDENCE_FILE"
