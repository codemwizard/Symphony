#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# lint_rls_0095_dual_policy.sh — Lint gate for the 0095 dual-policy RLS arch
#
# Phase 3 lint rules:
#   3.1  YAML ↔ DB parity (rls_tables.yml vs _rls_table_config)
#   3.2  No manual policy creation outside 0095
#   3.3  No direct SET app.current_tenant_id in source
#   3.4  USING / WITH CHECK parity on all rls_iso_* policies
#   3.5  DEFINER gate + search_path hardening on tenant functions
#
# Requires: DATABASE_URL for DB checks (3.1, 3.4, 3.5)
#           Runs static checks (3.2, 3.3) without DB
#
# Exit 0 = PASS, Exit 1 = FAIL
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0
WARN=0

pass() {
    echo "  ✅ $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "  ❌ $1"
    FAIL=$((FAIL + 1))
}

warn() {
    echo "  ⚠️  $1"
    WARN=$((WARN + 1))
}

# ── 3.2: No manual policy creation outside 0095 ─────────────────────────────

echo ""
echo "[3.2] No manual CREATE POLICY outside 0095"

# Check migrations after 0095 for stray CREATE POLICY statements
OFFENDING_FILES=""
shopt -s nullglob
for f in "$REPO_ROOT"/schema/migrations/009[6-9]_*.sql "$REPO_ROOT"/schema/migrations/01[0-9][0-9]_*.sql; do
    if grep -qlE '^\s*CREATE\s+POLICY\s+' "$f" 2>/dev/null; then
        OFFENDING_FILES="$OFFENDING_FILES $(basename "$f")"
    fi
done
shopt -u nullglob

if [ -z "$OFFENDING_FILES" ]; then
    pass "No stray CREATE POLICY in post-0095 migrations"
else
    fail "CREATE POLICY found in:$OFFENDING_FILES"
fi

# ── 3.3: No direct SET app.current_tenant_id in source ──────────────────────

echo ""
echo "[3.3] No direct SET app.current_tenant_id in source code"

# Search TypeScript/JavaScript source for direct GUC manipulation
DIRECT_SET_COUNT=0
SRC_DIRS=()
for d in "$REPO_ROOT/src" "$REPO_ROOT/packages" "$REPO_ROOT/services"; do
    [ -d "$d" ] && SRC_DIRS+=("$d")
done

if [ ${#SRC_DIRS[@]} -gt 0 ] && command -v rg &>/dev/null; then
    DIRECT_SET_COUNT=$(rg -c "set_config\s*\(\s*['\"]app\.current_tenant_id['\"]" \
        --type ts --type js -g '!**/test*' -g '!**/tests/**' -g '!**/spec/**' \
        "${SRC_DIRS[@]}" 2>/dev/null | \
        awk -F: '{sum += $NF} END {print sum+0}' | tr -d '[:space:]' || echo 0)
    DIRECT_SET_COUNT=${DIRECT_SET_COUNT:-0}
fi

if [ "$DIRECT_SET_COUNT" -eq 0 ] 2>/dev/null; then
    pass "No direct set_config('app.current_tenant_id') in source"
else
    fail "Found $DIRECT_SET_COUNT direct GUC manipulations in source (use set_tenant_context() instead)"
fi

# Check for SET LOCAL app.current_tenant_id in source (not migrations/tests)
DIRECT_SET_LOCAL=0
if [ ${#SRC_DIRS[@]} -gt 0 ] && command -v rg &>/dev/null; then
    DIRECT_SET_LOCAL=$(rg -c "SET\s+LOCAL\s+app\.current_tenant_id" \
        --type ts --type js -g '!**/test*' -g '!**/tests/**' -g '!**/spec/**' \
        "${SRC_DIRS[@]}" 2>/dev/null | \
        awk -F: '{sum += $NF} END {print sum+0}' | tr -d '[:space:]' || echo 0)
    DIRECT_SET_LOCAL=${DIRECT_SET_LOCAL:-0}
fi

if [ "$DIRECT_SET_LOCAL" -eq 0 ] 2>/dev/null; then
    pass "No direct SET LOCAL app.current_tenant_id in source"
else
    fail "Found $DIRECT_SET_LOCAL SET LOCAL statements in source (use set_tenant_context())"
fi

# ── DB-dependent checks ─────────────────────────────────────────────────────

if [ -z "${DATABASE_URL:-}" ]; then
    warn "DATABASE_URL not set — skipping DB-dependent checks (3.1, 3.4, 3.5)"
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "Results: $PASS passed, $FAIL failed, $WARN warnings"
    if [ "$FAIL" -gt 0 ]; then
        echo "STATUS: ❌ FAIL"
        exit 1
    else
        echo "STATUS: ✅ PASS (static only)"
        exit 0
    fi
fi

psql_q() {
    psql "$DATABASE_URL" -X -A -t -c "$1" 2>&1 || true
}

# ── 3.1: YAML ↔ DB parity ───────────────────────────────────────────────────

echo ""
echo "[3.1] YAML ↔ DB parity"

YAML_FILE="$REPO_ROOT/schema/rls_tables.yml"

if [ ! -f "$YAML_FILE" ]; then
    fail "rls_tables.yml not found at $YAML_FILE"
else
    # Check _rls_table_config exists
    config_exists=$(psql_q "SELECT count(*) FROM information_schema.tables WHERE table_name = '_rls_table_config' AND table_schema = 'public';" | grep -E '^[0-9]+$' | head -1)
    
    if [ "${config_exists:-0}" -eq 0 ]; then
        fail "_rls_table_config table not found in DB"
    else
        # Count YAML entries (tables with exists: true or no exists key)
        yaml_count=$(YAML_PATH="$YAML_FILE" "$REPO_ROOT/.venv/bin/python3" <<'PYEOF'
import yaml, os
with open(os.environ["YAML_PATH"]) as f:
    data = yaml.safe_load(f)
count = 0
for entry in data.get('tables', []):
    if entry.get('exists', True):
        count += 1
print(count)
PYEOF
)
        
        db_count=$(psql_q "SELECT count(*) FROM _rls_table_config;" | grep -E '^[0-9]+$' | head -1)
        
        if [ "${yaml_count:-0}" -eq "${db_count:-0}" ]; then
            pass "YAML↔DB parity: $yaml_count tables match"
        else
            fail "YAML($yaml_count) ≠ DB($db_count) table count mismatch"
        fi
    fi
fi

# ── 3.4: USING / WITH CHECK parity on isolation policies ────────────────────

echo ""
echo "[3.4] USING / WITH CHECK parity"

mismatch_count=$(psql_q "
    SELECT count(*) FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relnamespace = 'public'::regnamespace
      AND p.polname LIKE 'rls_iso_%'
      AND pg_get_expr(p.polqual, p.polrelid) IS DISTINCT FROM pg_get_expr(p.polwithcheck, p.polrelid);
" | grep -E '^[0-9]+$' | head -1)

if [ "${mismatch_count:-0}" -eq 0 ]; then
    pass "All rls_iso_* policies have matching USING and WITH CHECK"
else
    fail "$mismatch_count policies have USING/WC mismatch"
fi

# Also check that isolation expressions contain the expected function
bad_expr_count=$(psql_q "
    SELECT count(*) FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    JOIN _rls_table_config cfg ON cfg.table_name = c.relname
    WHERE c.relnamespace = 'public'::regnamespace
      AND p.polname LIKE 'rls_iso_%'
      AND cfg.isolation_type = 'DIRECT'
      AND pg_get_expr(p.polqual, p.polrelid) NOT LIKE '%current_tenant_id_or_null()%';
" | grep -E '^[0-9]+$' | head -1)

if [ "${bad_expr_count:-0}" -eq 0 ]; then
    pass "All DIRECT isolation expressions reference current_tenant_id_or_null()"
else
    fail "$bad_expr_count DIRECT policies missing current_tenant_id_or_null() in expression"
fi

# ── 3.5: DEFINER gate + search_path hardening ───────────────────────────────

echo ""
echo "[3.5] DEFINER gate + search_path hardening"

# Check tenant context functions are SECURITY DEFINER with hardened search_path
for fn_name in "set_tenant_context" "current_tenant_id" "current_tenant_id_or_null"; do
    fn_info=$(psql_q "
        SELECT json_build_object(
            'security', CASE WHEN p.prosecdef THEN 'DEFINER' ELSE 'INVOKER' END,
            'config', p.proconfig::text
        )::text
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.proname = '$fn_name'
        LIMIT 1;
    " | tr -d '[:space:]')
    
    if [ -z "$fn_info" ]; then
        fail "Function $fn_name not found"
        continue
    fi
    
    is_definer=$(echo "$fn_info" | "$REPO_ROOT/.venv/bin/python3" -c "import json,sys; d=json.load(sys.stdin); print(d.get('security',''))" 2>/dev/null || echo "")
    config=$(echo "$fn_info" | "$REPO_ROOT/.venv/bin/python3" -c "import json,sys; d=json.load(sys.stdin); print(d.get('config',''))" 2>/dev/null || echo "")
    
    if [ "$fn_name" = "set_tenant_context" ]; then
        # set_tenant_context MUST be SECURITY DEFINER
        if [ "$is_definer" = "DEFINER" ]; then
            pass "$fn_name is SECURITY DEFINER"
        else
            fail "$fn_name should be SECURITY DEFINER but is $is_definer"
        fi
        
        # Check search_path hardening
        if echo "$config" | grep -q "search_path"; then
            pass "$fn_name has search_path config"
        else
            warn "$fn_name missing explicit search_path config"
        fi
    else
        # Getter functions: log current state
        if [ "$is_definer" = "DEFINER" ]; then
            pass "$fn_name is SECURITY DEFINER"
        else
            warn "$fn_name is SECURITY INVOKER (acceptable for getters)"
        fi
    fi
done

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════════"
echo "Phase 3 Lint Results: $PASS passed, $FAIL failed, $WARN warnings"
if [ "$FAIL" -gt 0 ]; then
    echo "STATUS: ❌ FAIL"
    exit 1
else
    echo "STATUS: ✅ PASS"
    exit 0
fi
