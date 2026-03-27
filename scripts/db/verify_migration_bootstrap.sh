#!/usr/bin/env bash
set -uo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# verify_migration_bootstrap.sh — Full migration chain verification
# TSK-RLS-ARCH-001 v10.1
#
# Verifies migration 0095 applied correctly after full bootstrap.
# ══════════════════════════════════════════════════════════════════════════════

if [ -z "${DATABASE_URL:-}" ]; then
    echo "FATAL: DATABASE_URL not set"
    exit 1
fi

PASS=0
FAIL=0

check() {
    local name="$1" expected="$2" query="$3"
    local result
    result=$(psql "$DATABASE_URL" -X -A -t -c "$query" 2>&1 | tr -d '[:space:]' || true)
    if [ "$expected" = "$result" ]; then
        echo "  ✅ $name"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $name (expected=$expected, got=$result)"
        FAIL=$((FAIL + 1))
    fi
}

echo "═══════════════════════════════════════════════════════"
echo "Migration Bootstrap Verifier"
echo "═══════════════════════════════════════════════════════"

# 1. Config table exists and is populated
check "config_table_exists" "1" \
    "SELECT count(*)::int FROM (SELECT 1 FROM _rls_table_config LIMIT 1) x;"

# 2. Guard exists
check "guard_exists" "1" \
    "SELECT count(*)::int FROM _migration_guards WHERE key = '0095_rls_dual_policy';"

# 3. Post-migration fingerprint exists
check "fingerprint_exists" "1" \
    "SELECT count(*)::int FROM _migration_fingerprints WHERE migration_key = '0095_rls_dual_policy' AND fingerprint_type = 'post_migration';"

# 4. All DIRECT tables have RLS
check "direct_rls_enabled" "0" \
    "SELECT count(*)::int FROM _rls_table_config c WHERE c.isolation_type = 'DIRECT' AND NOT EXISTS (SELECT 1 FROM pg_class pc WHERE pc.relname = c.table_name AND pc.relnamespace = 'public'::regnamespace AND pc.relrowsecurity = true AND pc.relforcerowsecurity = true);"

# 5. All JOIN tables have RLS
check "join_rls_enabled" "0" \
    "SELECT count(*)::int FROM _rls_table_config c WHERE c.isolation_type = 'JOIN' AND NOT EXISTS (SELECT 1 FROM pg_class pc WHERE pc.relname = c.table_name AND pc.relnamespace = 'public'::regnamespace AND pc.relrowsecurity = true AND pc.relforcerowsecurity = true);"

# 6. No coverage gaps
check "no_coverage_gaps" "0" \
    "SELECT count(*)::int FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname NOT LIKE '\_%' AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped) AND c.relname NOT IN (SELECT table_name FROM _rls_table_config);"

# 7. current_tenant_id_or_null exists
check "permissive_getter_exists" "1" \
    "SELECT count(*)::int FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'current_tenant_id_or_null';"

# 8. current_tenant_id exists (strict getter)
check "strict_getter_exists" "1" \
    "SELECT count(*)::int FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'current_tenant_id';"

# 9. set_tenant_context exists (mandatory setter)
check "setter_exists" "1" \
    "SELECT count(*)::int FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public' AND p.proname = 'set_tenant_context';"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    echo "STATUS: ❌ FAIL"
    exit 1
else
    echo "STATUS: ✅ BOOTSTRAP VERIFIED"
    exit 0
fi
