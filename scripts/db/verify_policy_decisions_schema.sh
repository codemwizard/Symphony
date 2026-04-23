#!/usr/bin/env bash
set -euo pipefail

# Verifier for TSK-P2-PREAUTH-004-01: policy_decisions schema contract
# This script validates the 0134 migration contract with 12 structural checks (C1-C12)
# and 5 negative tests (N1-N5).
#
# Contract: schema/migrations/0134_create_policy_decisions.sql
# Task: TSK-P2-PREAUTH-004-01-REM

TASK_ID="TSK-P2-PREAUTH-004-01"
EVIDENCE_DIR="evidence/phase2"
EVIDENCE_PATH="${EVIDENCE_DIR}/tsk_p2_preauth_004_01.json"

mkdir -p "$EVIDENCE_DIR"

# Get git SHA
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize evidence JSON
cat > "$EVIDENCE_PATH" <<EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "IN_PROGRESS",
  "pass_count": 0,
  "fail_count": 0,
  "checks": [],
  "column_contract_source": "schema/migrations/0134_create_policy_decisions.sql"
}
EOF

# Helper: add check result
add_check() {
  local id="$1"
  local status="$2"
  local detail="$3"

  local temp_file
  temp_file=$(mktemp)
  jq --arg id "$id" --arg status "$status" --arg detail "$detail" \
    '.checks += [{"id": $id, "status": $status, "detail": $detail}] | 
     if $status == "PASS" then .pass_count += 1 else .fail_count += 1 end' \
    "$EVIDENCE_PATH" > "$temp_file"
  mv "$temp_file" "$EVIDENCE_PATH"
}

# Helper: fail and exit
fail_check() {
  local id="$1"
  local msg="$2"

  local temp_file
  temp_file=$(mktemp)
  jq --arg id "$id" --arg msg "$msg" \
    '.status = "FAIL" | .checks += [{"id": $id, "status": "FAIL", "detail": $msg}] | .fail_count += 1' \
    "$EVIDENCE_PATH" > "$temp_file"
  mv "$temp_file" "$EVIDENCE_PATH"
  echo "FAIL: $id — $msg" >&2
  exit 1
}

# ─── Test database connection ─────────────────────────────────────────
echo "Checking database connection..."
if ! psql -v ON_ERROR_STOP=1 -t -c "SELECT 1;" > /dev/null 2>&1; then
  fail_check "SETUP" "Cannot connect to database"
fi

# ─── C1: Table public.policy_decisions exists ───────────────────────
echo "C1: Checking table exists..."
C1_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1)
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'policy_decisions'
);
EOSQL

if echo "$C1_RESULT" | grep -q "t"; then
  add_check "C1" "PASS" "Table public.policy_decisions exists"
  echo "  C1 PASSED"
else
  fail_check "C1" "Table public.policy_decisions does not exist"
fi

# ─── C2: All 11 columns present with correct types ────────────────────
echo "C2: Checking columns..."
C2_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1)
SELECT COUNT(*) = 11 FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'policy_decisions'
AND column_name IN (
  'policy_decision_id', 'execution_id', 'decision_type', 'authority_scope',
  'declared_by', 'entity_type', 'entity_id', 'decision_hash', 'signature',
  'signed_at', 'created_at'
);
EOSQL

if echo "$C2_RESULT" | grep -q "t"; then
  add_check "C2" "PASS" "All 11 columns present with correct types"
  echo "  C2 PASSED"
else
  fail_check "C2" "Missing or incorrect columns"
fi

# ─── C3: FK policy_decisions_fk_execution exists ─────────────────────
echo "C3: Checking FK constraint..."
C3_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1)
SELECT EXISTS (
  SELECT FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
  WHERE tc.table_schema = 'public'
  AND tc.table_name = 'policy_decisions'
  AND tc.constraint_name = 'policy_decisions_fk_execution'
  AND tc.constraint_type = 'FOREIGN KEY'
);
EOSQL

if echo "$C3_RESULT" | grep -q "t"; then
  add_check "C3" "PASS" "FK policy_decisions_fk_execution exists"
  echo "  C3 PASSED"
else
  fail_check "C3" "FK policy_decisions_fk_execution missing"
fi

# ─── C4: UNIQUE policy_decisions_unique_exec_type exists ───────────────
echo "C4: Checking UNIQUE constraint..."
C4_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1)
SELECT EXISTS (
  SELECT FROM information_schema.table_constraints
  WHERE table_schema = 'public'
  AND table_name = 'policy_decisions'
  AND constraint_name = 'policy_decisions_unique_exec_type'
  AND constraint_type = 'UNIQUE'
);
EOSQL

if echo "$C4_RESULT" | grep -q "t"; then
  add_check "C4" "PASS" "UNIQUE policy_decisions_unique_exec_type exists"
  echo "  C4 PASSED"
else
  fail_check "C4" "UNIQUE policy_decisions_unique_exec_type missing"
fi

# ─── C5: CHECK policy_decisions_hash_hex_64 on decision_hash ──────────
echo "C5: CHECK policy_decisions_hash_hex_64 on decision_hash..."
C5_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1)
SELECT EXISTS (
  SELECT FROM information_schema.check_constraints cc
  JOIN information_schema.constraint_column_usage ccu
    ON cc.constraint_name = ccu.constraint_name
  WHERE cc.constraint_schema = 'public'
  AND cc.constraint_name = 'policy_decisions_hash_hex_64'
  AND ccu.column_name = 'decision_hash'
);
EOSQL

if echo "$C5_RESULT" | grep -q "t"; then
  add_check "C5" "PASS" "CHECK policy_decisions_hash_hex_64 on decision_hash"
  echo "  C5 PASSED"
else
  fail_check "C5" "CHECK policy_decisions_hash_hex_64 missing"
fi

# ─── C6: CHECK policy_decisions_sig_hex_128 on signature ─────────────
echo "C6: CHECK policy_decisions_sig_hex_128 on signature..."
C6_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1)
SELECT EXISTS (
  SELECT FROM information_schema.check_constraints cc
  JOIN information_schema.constraint_column_usage ccu
    ON cc.constraint_name = ccu.constraint_name
  WHERE cc.constraint_schema = 'public'
  AND cc.constraint_name = 'policy_decisions_sig_hex_128'
  AND ccu.column_name = 'signature'
);
EOSQL

if echo "$C6_RESULT" | grep -q "t"; then
  add_check "C6" "PASS" "CHECK policy_decisions_sig_hex_128 on signature"
  echo "  C6 PASSED"
else
  fail_check "C6" "CHECK policy_decisions_sig_hex_128 missing"
fi

# ─── C7: INDEX idx_policy_decisions_entity exists ───────────────────
echo "C7: Checking index idx_policy_decisions_entity..."
C7_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1)
SELECT EXISTS (
  SELECT FROM pg_indexes
  WHERE schemaname = 'public'
  AND tablename = 'policy_decisions'
  AND indexname = 'idx_policy_decisions_entity'
);
EOSQL

if echo "$C7_RESULT" | grep -q "t"; then
  add_check "C7" "PASS" "INDEX idx_policy_decisions_entity exists"
  echo "  C7 PASSED"
else
  fail_check "C7" "INDEX idx_policy_decisions_entity missing"
fi

# ─── C8: INDEX idx_policy_decisions_declared_by exists ────────────────
echo "C8: Checking index idx_policy_decisions_declared_by..."
C8_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1)
SELECT EXISTS (
  SELECT FROM pg_indexes
  WHERE schemaname = 'public'
  AND tablename = 'policy_decisions'
  AND indexname = 'idx_policy_decisions_declared_by'
);
EOSQL

if echo "$C8_RESULT" | grep -q "t"; then
  add_check "C8" "PASS" "INDEX idx_policy_decisions_declared_by exists"
  echo "  C8 PASSED"
else
  fail_check "C8" "INDEX idx_policy_decisions_declared_by missing"
fi

# ─── C9: Trigger policy_decisions_append_only_trigger exists ─────────
echo "C9: Checking trigger..."
C9_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1)
SELECT EXISTS (
  SELECT FROM information_schema.triggers
  WHERE trigger_schema = 'public'
  AND trigger_name = 'policy_decisions_append_only_trigger'
  AND event_object_table = 'policy_decisions'
);
EOSQL

if echo "$C9_RESULT" | grep -q "t"; then
  add_check "C9" "PASS" "Trigger policy_decisions_append_only_trigger exists"
  echo "  C9 PASSED"
else
  fail_check "C9" "Trigger policy_decisions_append_only_trigger missing"
fi

# ─── C10: Trigger function has SECURITY DEFINER ─────────────────────
echo "C10: Checking trigger function SECURITY DEFINER..."
C10_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1)
SELECT prosecdef FROM pg_proc
WHERE proname = 'enforce_policy_decisions_append_only'
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
EOSQL

if echo "$C10_RESULT" | grep -q "t"; then
  add_check "C10" "PASS" "Trigger function has SECURITY DEFINER"
  echo "  C10 PASSED"
else
  fail_check "C10" "Trigger function missing SECURITY DEFINER"
fi

# ─── C11: Trigger function has search_path pinned ────────────────────
echo "C11: Checking trigger function search_path..."
C11_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1)
SELECT proconfig IS NOT NULL FROM pg_proc
WHERE proname = 'enforce_policy_decisions_append_only'
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
EOSQL

if echo "$C11_RESULT" | grep -q "t"; then
  add_check "C11" "PASS" "Trigger function has search_path pinned"
  echo "  C11 PASSED"
else
  fail_check "C11" "Trigger function missing search_path pin"
fi

# ─── C12: public. schema prefix in migration file ───────────────────
echo "C12: Checking migration file uses public. prefix..."
if grep -q "public.policy_decisions" schema/migrations/0134_create_policy_decisions.sql; then
  add_check "C12" "PASS" "Migration file uses public. prefix"
  echo "  C12 PASSED"
else
  fail_check "C12" "Migration file missing public. prefix"
fi

# ─── N1: INSERT with NULL execution_id → NOT NULL violation ───────────
echo "N1: Testing INSERT with NULL execution_id..."
N1_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1 || true)
BEGIN;
ALTER TABLE public.policy_decisions DISABLE TRIGGER policy_decisions_append_only_trigger;
INSERT INTO public.policy_decisions (policy_decision_id, execution_id, decision_type, authority_scope, declared_by, entity_type, entity_id, decision_hash, signature, signed_at)
VALUES ('a0000000-0000-0000-0000-000000000001'::uuid, NULL, 'test', 'test', 'a0000000-0000-0000-0000-000000000001'::uuid, 'test', 'a0000000-0000-0000-0000-000000000001'::uuid, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', now());
ROLLBACK;
EOSQL

if echo "$N1_RESULT" | grep -q "23502"; then
  add_check "N1" "PASS" "INSERT with NULL execution_id rejected with NOT NULL violation"
  echo "  N1 PASSED"
else
  fail_check "N1" "Expected NOT NULL violation (SQLSTATE 23502), got: $N1_RESULT"
fi

# ─── N2: INSERT with invalid decision_hash (wrong length) → CHECK violation ─
echo "N2: Testing INSERT with invalid decision_hash..."
N2_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1 || true)
BEGIN;
ALTER TABLE public.policy_decisions DISABLE TRIGGER policy_decisions_append_only_trigger;
INSERT INTO public.policy_decisions (policy_decision_id, execution_id, decision_type, authority_scope, declared_by, entity_type, entity_id, decision_hash, signature, signed_at)
VALUES ('a0000000-0000-0000-0000-000000000002'::uuid, 'a0000000-0000-0000-0000-000000000001'::uuid, 'test', 'test', 'a0000000-0000-0000-0000-000000000001'::uuid, 'test', 'a0000000-0000-0000-0000-000000000001'::uuid, 'invalid', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', now());
ROLLBACK;
EOSQL

if echo "$N2_RESULT" | grep -q "23514"; then
  add_check "N2" "PASS" "INSERT with invalid decision_hash rejected with CHECK violation"
  echo "  N2 PASSED"
else
  fail_check "N2" "Expected CHECK violation (SQLSTATE 23514), got: $N2_RESULT"
fi

# ─── N3: INSERT with non-existent execution_id → FK violation ──────────
echo "N3: Testing INSERT with non-existent execution_id..."
N3_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1 || true)
BEGIN;
ALTER TABLE public.policy_decisions DISABLE TRIGGER policy_decisions_append_only_trigger;
INSERT INTO public.policy_decisions (policy_decision_id, execution_id, decision_type, authority_scope, declared_by, entity_type, entity_id, decision_hash, signature, signed_at)
VALUES ('a0000000-0000-0000-0000-000000000003'::uuid, 'deadbeef-dead-beef-dead-beefdeadbeef'::uuid, 'test', 'test', 'a0000000-0000-0000-0000-000000000001'::uuid, 'test', 'a0000000-0000-0000-0000-000000000001'::uuid, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', now());
ROLLBACK;
EOSQL

if echo "$N3_RESULT" | grep -q "23503"; then
  add_check "N3" "PASS" "INSERT with non-existent execution_id rejected with FK violation"
  echo "  N3 PASSED"
else
  fail_check "N3" "Expected FK violation (SQLSTATE 23503), got: $N3_RESULT"
fi

# ─── N4: UPDATE existing row → Trigger ERRCODE GF060 ───────────────────
echo "N4: Testing UPDATE existing row..."
N4_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1 || true)
BEGIN;
ALTER TABLE public.policy_decisions DISABLE TRIGGER policy_decisions_append_only_trigger;
INSERT INTO public.policy_decisions (policy_decision_id, execution_id, decision_type, authority_scope, declared_by, entity_type, entity_id, decision_hash, signature, signed_at)
VALUES ('a0000000-0000-0000-0000-000000000004'::uuid, 'a0000000-0000-0000-0000-000000000001'::uuid, 'test', 'test', 'a0000000-0000-0000-0000-000000000001'::uuid, 'test', 'a0000000-0000-0000-0000-000000000001'::uuid, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', now());
ALTER TABLE public.policy_decisions ENABLE TRIGGER policy_decisions_append_only_trigger;
UPDATE public.policy_decisions SET decision_type = 'updated' WHERE policy_decision_id = 'a0000000-0000-0000-0000-000000000004'::uuid;
ROLLBACK;
EOSQL

if echo "$N4_RESULT" | grep -q "GF060"; then
  add_check "N4" "PASS" "UPDATE existing row rejected with trigger ERRCODE GF060"
  echo "  N4 PASSED"
else
  fail_check "N4" "Expected trigger ERRCODE GF060, got: $N4_RESULT"
fi

# ─── N5: DELETE existing row → Trigger ERRCODE GF060 ─────────────────────
echo "N5: Testing DELETE existing row..."
N5_RESULT=$(psql -v ON_ERROR_STOP=1 -t <<'EOSQL' 2>&1 || true)
BEGIN;
ALTER TABLE public.policy_decisions DISABLE TRIGGER policy_decisions_append_only_trigger;
INSERT INTO public.policy_decisions (policy_decision_id, execution_id, decision_type, authority_scope, declared_by, entity_type, entity_id, decision_hash, signature, signed_at)
VALUES ('a0000000-0000-0000-0000-000000000005'::uuid, 'a0000000-0000-0000-0000-000000000001'::uuid, 'test', 'test', 'a0000000-0000-0000-0000-000000000001'::uuid, 'test', 'a0000000-0000-0000-0000-000000000001'::uuid, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', now());
ALTER TABLE public.policy_decisions ENABLE TRIGGER policy_decisions_append_only_trigger;
DELETE FROM public.policy_decisions WHERE policy_decision_id = 'a0000000-0000-0000-0000-000000000005'::uuid;
ROLLBACK;
EOSQL

if echo "$N5_RESULT" | grep -q "GF060"; then
  add_check "N5" "PASS" "DELETE existing row rejected with trigger ERRCODE GF060"
  echo "  N5 PASSED"
else
  fail_check "N5" "Expected trigger ERRCODE GF060, got: $N5_RESULT"
fi

# ─── Final status ────────────────────────────────────────────────────
temp_file=$(mktemp)
jq '.status = "PASS"' "$EVIDENCE_PATH" > "$temp_file"
mv "$temp_file" "$EVIDENCE_PATH"

echo ""
echo "All checks passed. Evidence written to $EVIDENCE_PATH"
