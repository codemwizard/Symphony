#!/usr/bin/env bash
# verify_rls_bypass_runtime_isolation.sh
# TSK-P2-RLS-BYPASS-007 — Prove runtime tenant isolation without app.bypass_rls
#
# This verifier:
# 1. Creates a temporary non-superuser role with symphony_app_role grants
# 2. Exercises POSITIVE same-tenant access (must succeed)
# 3. Exercises NEGATIVE cross-tenant access (must be rejected by RLS)
# 4. Cross-checks active policy definitions for absence of app.bypass_rls
# 5. Self-checks that no bypass_rls is used in its own setup
# 6. Emits structured evidence
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase2"
EVIDENCE_FILE="$EVIDENCE_DIR/rls_bypass_runtime_isolation.json"

# ── Self-check: this script must NOT contain app.bypass_rls in any SET command ─
SELF_BYPASS_COUNT=$(grep -cE "set_config\('app\.bypass_rls'" "$0" 2>/dev/null || true)
SELF_BYPASS_COUNT=${SELF_BYPASS_COUNT:-0}
if [[ "$SELF_BYPASS_COUNT" -gt 0 ]]; then
  echo "CRITICAL: This verifier script contains app.bypass_rls set_config calls. INADMISSIBLE." >&2
  exit 1
fi

# ── Self-check: must NOT use session_replication_role in SET commands ──────────
# Check for actual SQL usage (SET session_replication_role), excluding grep/echo/comment lines
SELF_REPL_SET_COUNT=$(grep -E "^[^#]*session_replication_role" "$0" | grep -cvE '(grep|echo|CRITICAL|Self-check|comment)' 2>/dev/null || true)
SELF_REPL_SET_COUNT=${SELF_REPL_SET_COUNT:-0}
if [[ "$SELF_REPL_SET_COUNT" -gt 0 ]]; then
  echo "CRITICAL: This verifier uses session_replication_role in SQL. INADMISSIBLE." >&2
  exit 1
fi

status="PASS"
checks=()
command_outputs=()
positive_test_passed="false"
negative_test_passed="false"
bypass_setting_used="false"
runtime_role_used="UNKNOWN"
policy_cross_check="UNKNOWN"

# ── Determine connection method ──────────────────────────────────────────────
PSQL_CMD="psql"
pg_container=""
if command -v docker >/dev/null 2>&1; then
  pg_container="$(docker ps --format '{{.Names}}' | grep -E 'postgres' | head -n 1 || true)"
fi

run_sql_admin() {
  if [[ -n "$pg_container" ]]; then
    docker exec "$pg_container" psql -U symphony_admin -d symphony -t -A -X -c "$1" 2>&1
  else
    psql "$DATABASE_URL" -t -A -X -c "$1" 2>&1
  fi
}

run_sql_as_role() {
  local role="$1" sql="$2"
  if [[ -n "$pg_container" ]]; then
    docker exec "$pg_container" psql -U symphony_admin -d symphony -t -A -X -c "
      SET LOCAL ROLE $role;
      $sql
    " 2>&1
  else
    psql "$DATABASE_URL" -t -A -X -c "
      SET LOCAL ROLE $role;
      $sql
    " 2>&1
  fi
}

# ── Step 1: Create temporary non-superuser test role ─────────────────────────
TEST_ROLE="rls_test_$(date +%s)"
echo "Creating temporary non-superuser role: $TEST_ROLE"

run_sql_admin "
  DO \$\$
  BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$TEST_ROLE') THEN
      CREATE ROLE $TEST_ROLE NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE;
    END IF;
  END \$\$;
  GRANT symphony_app_role TO $TEST_ROLE;
  GRANT USAGE ON SCHEMA public TO $TEST_ROLE;
"
checks+=("temp_role_created:$TEST_ROLE")
runtime_role_used="$TEST_ROLE"

# Verify role is NOT superuser
is_super=$(run_sql_admin "SELECT rolsuper FROM pg_roles WHERE rolname = '$TEST_ROLE'")
if [[ "$is_super" == "t" ]]; then
  echo "CRITICAL: Test role $TEST_ROLE is superuser. INADMISSIBLE." >&2
  run_sql_admin "DROP ROLE IF EXISTS $TEST_ROLE;"
  exit 1
fi
checks+=("role_not_superuser:PASS")
command_outputs+=("rolsuper=$is_super")

# ── Step 2: Get a real tenant_id for positive testing ────────────────────────
TENANT_A=$(run_sql_admin "SELECT tenant_id FROM tenant_registry LIMIT 1")
if [[ -z "$TENANT_A" || "$TENANT_A" == "" ]]; then
  echo "WARN: No tenants in tenant_registry, inserting test data"
  TENANT_A="a0000000-0000-0000-0000-000000000001"
  run_sql_admin "
    INSERT INTO tenant_registry (tenant_id, tenant_key, display_name, status)
    VALUES ('$TENANT_A', 'rls-test-a', 'RLS Test Tenant A', 'ACTIVE')
    ON CONFLICT (tenant_id) DO NOTHING;
  "
fi
checks+=("tenant_a_exists:$TENANT_A")

# Create a second tenant for cross-tenant testing
TENANT_B="b0000000-0000-0000-0000-000000000002"
run_sql_admin "
  INSERT INTO tenant_registry (tenant_id, tenant_key, display_name, status)
  VALUES ('$TENANT_B', 'rls-test-b', 'RLS Test Tenant B', 'ACTIVE')
  ON CONFLICT (tenant_id) DO NOTHING;
"
checks+=("tenant_b_exists:$TENANT_B")

# ── Step 3: POSITIVE TEST — Same-tenant read with proper context ─────────────
echo "Running positive test: same-tenant read with app.current_tenant_id=$TENANT_A"
positive_result=$(run_sql_as_role "$TEST_ROLE" "
  SELECT set_config('app.current_tenant_id', '$TENANT_A', true);
  SELECT count(*) FROM tenant_registry;
")
# Parse the count — second line from result
positive_count=$(echo "$positive_result" | tail -1)
command_outputs+=("positive_same_tenant_count=$positive_count")

if [[ "$positive_count" =~ ^[0-9]+$ ]] && [[ "$positive_count" -ge 1 ]]; then
  positive_test_passed="true"
  checks+=("positive_same_tenant_read:PASS:count=$positive_count")
else
  status="FAIL"
  checks+=("positive_same_tenant_read:FAIL:count=$positive_count")
fi

# ── Step 4: NEGATIVE TEST — Cross-tenant read must return 0 rows ─────────────
echo "Running negative test: cross-tenant read (context=$TENANT_B, reading tenant_A data)"
negative_result=$(run_sql_as_role "$TEST_ROLE" "
  SELECT set_config('app.current_tenant_id', '$TENANT_B', true);
  SELECT count(*) FROM tenant_registry WHERE tenant_id = '$TENANT_A';
")
negative_count=$(echo "$negative_result" | tail -1)
command_outputs+=("negative_cross_tenant_count=$negative_count")

if [[ "$negative_count" == "0" ]]; then
  negative_test_passed="true"
  checks+=("negative_cross_tenant_read:PASS:count=0")
else
  status="FAIL"
  negative_test_passed="false"
  checks+=("negative_cross_tenant_read:FAIL:count=$negative_count")
fi

# ── Step 4b: NEGATIVE TEST — Cross-tenant write must fail ────────────────────
echo "Running negative test: cross-tenant write attempt"
write_result=$(run_sql_as_role "$TEST_ROLE" "
  SELECT set_config('app.current_tenant_id', '$TENANT_B', true);
  UPDATE tenant_registry SET display_name = 'HACKED' WHERE tenant_id = '$TENANT_A';
" 2>&1 || true)
write_affected=$(echo "$write_result" | grep -oP 'UPDATE \K[0-9]+' || echo "0")
command_outputs+=("negative_cross_tenant_write_affected=$write_affected")

if [[ "$write_affected" == "0" ]]; then
  checks+=("negative_cross_tenant_write:PASS:rows_affected=0")
else
  status="FAIL"
  negative_test_passed="false"
  checks+=("negative_cross_tenant_write:FAIL:rows_affected=$write_affected")
fi

# ── Step 4c: NEGATIVE TEST — No-context read returns 0 rows ──────────────────
echo "Running negative test: read with no tenant context set"
no_ctx_result=$(run_sql_as_role "$TEST_ROLE" "
  SELECT set_config('app.current_tenant_id', '', true);
  SELECT count(*) FROM tenant_registry;
")
no_ctx_count=$(echo "$no_ctx_result" | tail -1)
command_outputs+=("negative_no_context_count=$no_ctx_count")

if [[ "$no_ctx_count" == "0" ]]; then
  checks+=("negative_no_context_read:PASS:count=0")
else
  status="FAIL"
  negative_test_passed="false"
  checks+=("negative_no_context_read:FAIL:count=$no_ctx_count")
fi

# ── Step 5: Cross-check active policies for bypass_rls ───────────────────────
echo "Cross-checking active policies for app.bypass_rls"
bypass_policies=$(run_sql_admin "
  SELECT count(*)
  FROM pg_policies
  WHERE qual::text LIKE '%bypass_rls%'
    AND tablename IN ('tenant_registry','programme_registry','programme_policy_binding');
")
bypass_policies=${bypass_policies:-0}
command_outputs+=("bypass_rls_in_active_policies=$bypass_policies")

if [[ "$bypass_policies" == "0" ]]; then
  policy_cross_check="CLEAN"
  checks+=("policy_cross_check:PASS:bypass_policies=0")
else
  status="FAIL"
  policy_cross_check="CONTAMINATED:$bypass_policies"
  checks+=("policy_cross_check:FAIL:bypass_policies=$bypass_policies")
fi

# ── Step 6: Verify app.bypass_rls was NOT set during testing ─────────────────
bypass_check=$(run_sql_as_role "$TEST_ROLE" "
  SELECT current_setting('app.bypass_rls', true);
")
bypass_check=$(echo "$bypass_check" | tr -d '[:space:]')
if [[ -z "$bypass_check" || "$bypass_check" == "" ]]; then
  checks+=("bypass_not_set_during_test:PASS")
else
  if [[ "$bypass_check" == "on" ]]; then
    status="FAIL"
    bypass_setting_used="true"
    checks+=("bypass_not_set_during_test:FAIL:value=$bypass_check")
  else
    checks+=("bypass_not_set_during_test:PASS:value=$bypass_check")
  fi
fi

# ── Cleanup: drop temporary role ─────────────────────────────────────────────
echo "Cleaning up temporary role: $TEST_ROLE"
run_sql_admin "
  REVOKE symphony_app_role FROM $TEST_ROLE;
  DROP ROLE IF EXISTS $TEST_ROLE;
" >/dev/null 2>&1 || true
checks+=("temp_role_cleaned")

# ── Emit evidence ────────────────────────────────────────────────────────────
mkdir -p "$EVIDENCE_DIR"

"$ROOT_DIR/.venv/bin/python3" - "$EVIDENCE_FILE" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" \
  "$status" "$runtime_role_used" "$bypass_setting_used" "$positive_test_passed" \
  "$negative_test_passed" "$policy_cross_check" \
  <<PYEOF "$(IFS='|'; echo "${checks[*]}")" "$(IFS='|'; echo "${command_outputs[*]}")"
import json, os, sys

evidence_file = sys.argv[1]
ts = sys.argv[2]
git_sha = sys.argv[3]
status = sys.argv[4]
runtime_role = sys.argv[5]
bypass_used = sys.argv[6] == 'true'
pos_pass = sys.argv[7] == 'true'
neg_pass = sys.argv[8] == 'true'
policy_xcheck = sys.argv[9]
checks = [c for c in sys.argv[10].split('|') if c]
cmd_outputs = [c for c in sys.argv[11].split('|') if c]

evidence = {
    'task_id': 'TSK-P2-RLS-BYPASS-007',
    'git_sha': git_sha,
    'timestamp_utc': ts,
    'status': status,
    'checks': checks,
    'runtime_role_used': runtime_role,
    'bypass_setting_used': bypass_used,
    'positive_test_passed': pos_pass,
    'negative_test_passed': neg_pass,
    'policy_cross_check': policy_xcheck,
    'observed_paths': [
        'scripts/audit/verify_rls_bypass_runtime_isolation.sh',
    ],
    'observed_hashes': {},
    'command_outputs': cmd_outputs,
    'execution_trace': [
        f'scan_started={ts}',
        f'runtime_role={runtime_role}',
        f'positive_test_passed={pos_pass}',
        f'negative_test_passed={neg_pass}',
        f'bypass_setting_used={bypass_used}',
        f'policy_cross_check={policy_xcheck}',
        f'status={status}',
    ],
}

# Add self-hash
import hashlib
script_path = os.path.join(os.environ.get('ROOT_DIR', '.'), 'scripts/audit/verify_rls_bypass_runtime_isolation.sh')
if os.path.isfile(script_path):
    with open(script_path, 'rb') as f:
        evidence['observed_hashes'][os.path.basename(script_path)] = hashlib.sha256(f.read()).hexdigest()

os.makedirs(os.path.dirname(evidence_file), exist_ok=True)
with open(evidence_file, 'w') as out:
    json.dump(evidence, out, indent=2)
    out.write('\n')

print(f"Evidence: {evidence_file}")
print(f"  Status: {status}")
print(f"  Runtime role: {runtime_role}")
print(f"  Bypass used: {bypass_used}")
print(f"  Positive test: {pos_pass}")
print(f"  Negative test: {neg_pass}")
print(f"  Policy cross-check: {policy_xcheck}")

if status != 'PASS':
    sys.exit(1)
PYEOF

echo "TSK-P2-RLS-BYPASS-007 verification: $status"
if [[ "$status" != "PASS" ]]; then
  exit 1
fi
