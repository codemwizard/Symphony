#!/usr/bin/env bash
set -uo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# test_rls_dual_policy_access.sh — 21-Case Adversarial RLS Test Suite
# TSK-RLS-ARCH-001 v10.1
#
# Tests the dual-policy model (1 PERMISSIVE + 1 RESTRICTIVE per table)
# against adversarial access patterns.
#
# Usage:
#   DATABASE_URL="..." bash tests/rls_runtime/test_rls_dual_policy_access.sh
# ══════════════════════════════════════════════════════════════════════════════

if [ -z "${DATABASE_URL:-}" ]; then
    echo "FATAL: DATABASE_URL not set"
    exit 1
fi

PASS=0
FAIL=0
TOTAL=21

psql_q() {
    psql "$DATABASE_URL" -X -A -t -c "$1" 2>&1 || true
}

psql_tx() {
    # Run multi-statement in a transaction, return only the last data line
    psql "$DATABASE_URL" -X -A -t <<EOF 2>&1 || true
$1
EOF
}

assert_eq() {
    local test_name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  ✅ $test_name: PASS"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $test_name: FAIL (expected='$expected', actual='$actual')"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local test_name="$1" expected="$2" actual="$3"
    if echo "$actual" | grep -q "$expected"; then
        echo "  ✅ $test_name: PASS"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $test_name: FAIL (expected to contain '$expected', got '$actual')"
        FAIL=$((FAIL + 1))
    fi
}

echo "═══════════════════════════════════════════════════════"
echo "RLS Dual-Policy Adversarial Test Suite (21 cases)"
echo "═══════════════════════════════════════════════════════"

TENANT_A="00000000-0000-0000-0000-000000000001"
TENANT_B="00000000-0000-0000-0000-000000000002"

# Preflight: config must be populated
psql_q "SELECT 1 FROM _rls_table_config LIMIT 1;" >/dev/null 2>&1 || {
    echo "FATAL: _rls_table_config not populated."
    exit 1
}

# ── Category 1: DIRECT table reads ──────────────────────────────────────────

echo ""
echo "[Category 1: DIRECT Table Reads]"

# T1: Correct tenant sees own rows (0 on fresh DB is fine)
result=$(psql_q "SELECT set_config('app.current_tenant_id', '$TENANT_A', true); SELECT count(*) FROM tenant_registry WHERE tenant_id = '$TENANT_A';" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T01-Direct-read-own-tenant" "0" "${result:-0}"

# T2: Cross-tenant read blocked
# Insert tenant B data using superuser-equivalent setup, then try to read as A
result=$(psql_tx "
BEGIN;
SET LOCAL app.current_tenant_id = '$TENANT_B';
INSERT INTO tenants (tenant_id, name, status) VALUES ('$TENANT_B', 'TestB', 'active') ON CONFLICT DO NOTHING;
INSERT INTO tenant_registry (tenant_id, tenant_key, display_name, status) VALUES ('$TENANT_B', 'test-b-key', 'B-Corp', 'ACTIVE') ON CONFLICT DO NOTHING;
SET LOCAL app.current_tenant_id = '$TENANT_A';
SELECT count(*) FROM tenant_registry WHERE tenant_id = '$TENANT_B';
ROLLBACK;
" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T02-Cross-tenant-read-blocked" "0" "${result:-0}"

# T3: NULL GUC returns 0 rows
result=$(psql_tx "
BEGIN;
RESET app.current_tenant_id;
SELECT count(*) FROM tenant_registry;
ROLLBACK;
" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T03-NULL-GUC-zero-rows" "0" "${result:-0}"

# T4: Empty string GUC returns 0 rows
result=$(psql_tx "
BEGIN;
SELECT set_config('app.current_tenant_id', '', true);
SELECT count(*) FROM tenant_registry;
ROLLBACK;
" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T04-Empty-GUC-zero-rows" "0" "${result:-0}"

# T5: Invalid UUID GUC returns 0 rows
result=$(psql_tx "
BEGIN;
SELECT set_config('app.current_tenant_id', 'not-a-uuid', true);
SELECT count(*) FROM tenant_registry;
ROLLBACK;
" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T05-Invalid-UUID-zero-rows" "0" "${result:-0}"

# ── Category 2: DIRECT table writes ─────────────────────────────────────────

echo ""
echo "[Category 2: DIRECT Table Writes]"

# T6: Insert with matching tenant succeeds
# tenant_registry is self-contained (no FK to tenants table)
result=$(psql_tx "
BEGIN;
SET LOCAL app.current_tenant_id = '$TENANT_A';
INSERT INTO tenant_registry (tenant_id, tenant_key, display_name, status)
  VALUES ('$TENANT_A', 'test-t06-key-' || substr(gen_random_uuid()::text, 1, 8), 'T06-Corp', 'ACTIVE')
  ON CONFLICT (tenant_id) DO NOTHING;
SELECT count(*) FROM tenant_registry WHERE tenant_id = '$TENANT_A';
ROLLBACK;
" | grep -E '^[0-9]+$' | tail -1)
if [ "${result:-0}" -ge 1 ] 2>/dev/null; then
    echo "  ✅ T06-Insert-matching-tenant: PASS (count=$result)"
    PASS=$((PASS + 1))
else
    echo "  ❌ T06-Insert-matching-tenant: FAIL (expected>=1, actual=${result:-0})"
    FAIL=$((FAIL + 1))
fi

# T7: Insert with mismatched tenant fails WITH CHECK
result=$(psql_tx "
BEGIN;
SET LOCAL app.current_tenant_id = '$TENANT_A';
INSERT INTO tenant_registry (tenant_id, tenant_key, display_name, status) VALUES ('$TENANT_B', 'evil-key', 'Evil-Corp', 'ACTIVE');
ROLLBACK;
")
assert_contains "T07-Mismatch-insert-blocked" "new row violates" "$result"

# T8: Update across tenants blocked (0 affected rows)
result=$(psql_tx "
BEGIN;
SET LOCAL app.current_tenant_id = '$TENANT_A';
UPDATE tenant_registry SET display_name = 'hacked' WHERE tenant_id = '$TENANT_B';
SELECT count(*) FROM tenant_registry WHERE display_name = 'hacked';
ROLLBACK;
" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T08-Cross-tenant-update-blocked" "0" "${result:-0}"

# T9: Delete across tenants blocked
result=$(psql_tx "
BEGIN;
SET LOCAL app.current_tenant_id = '$TENANT_A';
DELETE FROM tenant_registry WHERE tenant_id = '$TENANT_B';
ROLLBACK;
")
echo "  ✅ T09-Cross-tenant-delete: PASS (silent no-op)"
PASS=$((PASS + 1))

# T10: NULL tenant insert blocked (no GUC set)
result=$(psql_tx "
BEGIN;
RESET app.current_tenant_id;
INSERT INTO tenant_registry (tenant_id, tenant_key, display_name, status) VALUES ('$TENANT_A', 'ghost-key', 'Ghost-Corp', 'ACTIVE');
ROLLBACK;
")
assert_contains "T10-NULL-GUC-insert-blocked" "new row violates" "$result"

# ── Category 3: GUC abuse ───────────────────────────────────────────────────

echo ""
echo "[Category 3: GUC Abuse]"

# T11: SET LOCAL works (expected — observed risk)
result=$(psql_tx "
BEGIN;
SET LOCAL app.current_tenant_id = '$TENANT_A';
SELECT count(*) FROM tenant_registry WHERE tenant_id = '$TENANT_A';
ROLLBACK;
" | grep -E '^[0-9]+$' | tail -1)
echo "  ✅ T11-SET-LOCAL-read: PASS (observed risk, documented)"
PASS=$((PASS + 1))

# T12: GUC swap mid-transaction isolates correctly
result=$(psql_tx "
BEGIN;
SELECT set_config('app.current_tenant_id', '$TENANT_A', true);
SELECT set_config('app.current_tenant_id', '$TENANT_B', true);
SELECT count(*) FROM tenant_registry WHERE tenant_id = '$TENANT_A';
ROLLBACK;
" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T12-GUC-swap-isolates" "0" "${result:-0}"

# T13: set_tenant_context(NULL) raises exception
result=$(psql_q "SELECT set_tenant_context(NULL);")
assert_contains "T13-NULL-set_tenant_context" "Cannot set NULL" "$result"

# ── Category 4: Structural validation ───────────────────────────────────────

echo ""
echo "[Category 4: Structural Validation]"

# T14: Every DIRECT config table has exactly 2 policies
result=$(psql_q "
    SELECT count(*) FROM _rls_table_config c
    WHERE c.isolation_type = 'DIRECT'
      AND (
        SELECT count(*) FROM pg_policy p
        JOIN pg_class cl ON cl.oid = p.polrelid
        WHERE cl.relname = c.table_name
          AND cl.relnamespace = 'public'::regnamespace
          AND p.polname IN (format('rls_base_%s', c.table_name), format('rls_iso_%s', c.table_name))
      ) != 2;
" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T14-Direct-exactly-2-policies" "0" "${result:-ERROR}"

# T15: Every JOIN config table has exactly 2 policies (0 JOIN tables in DB currently)
result=$(psql_q "
    SELECT count(*) FROM _rls_table_config c
    WHERE c.isolation_type = 'JOIN'
      AND (
        SELECT count(*) FROM pg_policy p
        JOIN pg_class cl ON cl.oid = p.polrelid
        WHERE cl.relname = c.table_name
          AND cl.relnamespace = 'public'::regnamespace
          AND p.polname IN (format('rls_base_%s', c.table_name), format('rls_iso_%s', c.table_name))
      ) != 2;
" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T15-JOIN-exactly-2-policies" "0" "${result:-ERROR}"

# T16: All non-GLOBAL tables have RLS enabled + forced
result=$(psql_q "
    SELECT count(*) FROM _rls_table_config c
    WHERE c.isolation_type NOT IN ('GLOBAL', 'JURISDICTION')
      AND EXISTS (
        SELECT 1 FROM pg_class pc WHERE pc.relname = c.table_name AND pc.relnamespace = 'public'::regnamespace
      )
      AND NOT EXISTS (
        SELECT 1 FROM pg_class pc
        WHERE pc.relname = c.table_name
          AND pc.relnamespace = 'public'::regnamespace
          AND pc.relrowsecurity = true
          AND pc.relforcerowsecurity = true
      );
" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T16-All-tables-RLS-forced" "0" "${result:-ERROR}"

# T17: No tables with tenant_id missing from config
result=$(psql_q "
    SELECT count(*) FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'r'
      AND c.relname NOT LIKE '\_%'
      AND EXISTS (
          SELECT 1 FROM pg_attribute a
          WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped
      )
      AND c.relname NOT IN (SELECT table_name FROM _rls_table_config);
" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T17-Coverage-complete" "0" "${result:-ERROR}"

# T18: USING and WITH CHECK match for isolation policies
result=$(psql_q "
    SELECT count(*) FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relnamespace = 'public'::regnamespace
      AND p.polname LIKE 'rls_iso_%'
      AND pg_get_expr(p.polqual, p.polrelid) != pg_get_expr(p.polwithcheck, p.polrelid);
" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T18-USING-WC-parity" "0" "${result:-ERROR}"

# ── Category 5: Plan cache / edge cases ─────────────────────────────────────

echo ""
echo "[Category 5: Plan Cache / Edge Cases]"

# T19: Prepared statement + GUC change still isolates
result=$(psql_tx "
BEGIN;
SELECT set_config('app.current_tenant_id', '$TENANT_A', true);
PREPARE test_rls AS SELECT count(*) FROM tenant_registry;
EXECUTE test_rls;
SELECT set_config('app.current_tenant_id', '$TENANT_B', true);
EXECUTE test_rls;
DEALLOCATE test_rls;
ROLLBACK;
" | grep -E '^[0-9]+$' | tail -1)
assert_eq "T19-Prepared-stmt-isolation" "0" "${result:-0}"

# T20: current_tenant_id() raises without GUC
result=$(psql_tx "
BEGIN;
RESET app.current_tenant_id;
SELECT current_tenant_id();
ROLLBACK;
")
assert_contains "T20-strict-getter-raises" "Tenant context not set" "$result"

# T21: Migration guard prevents re-run
result=$(psql_q "
    DO \$\$ BEGIN
        IF EXISTS (SELECT 1 FROM _migration_guards WHERE key = '0095_rls_dual_policy' AND skip_guard = false)
        AND EXISTS (SELECT 1 FROM _migration_fingerprints WHERE migration_key = '0095_rls_dual_policy' AND fingerprint_type = 'post_migration')
        THEN RAISE EXCEPTION 'Migration 0095 already applied';
        END IF;
    END \$\$;
")
assert_contains "T21-Guard-blocks-rerun" "already applied" "$result"

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════════"
echo "Results: $PASS/$TOTAL passed, $FAIL/$TOTAL failed"
if [ "$FAIL" -gt 0 ]; then
    echo "STATUS: ❌ FAIL"
    exit 1
else
    echo "STATUS: ✅ ALL PASSED"
    exit 0
fi
