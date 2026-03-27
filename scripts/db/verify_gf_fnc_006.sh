#!/usr/bin/env bash
set -euo pipefail

echo "==> GF-W1-FNC-006 Verifier Read Token Functions Verification"

# Check if migration exists
if [[ ! -f "schema/migrations/0093_gf_fn_verifier_read_token.sql" ]]; then
    echo "❌ FAIL: Migration file 0093_gf_fn_verifier_read_token.sql not found"
    exit 1
fi

echo "✅ PASS: Migration file exists"

# Check if gf_verifier_read_tokens table exists
echo ""
echo "=== Table Checks ==="

if grep -q "CREATE TABLE.*gf_verifier_read_tokens" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: gf_verifier_read_tokens table created"
else
    echo "❌ FAIL: gf_verifier_read_tokens table not found"
    exit 1
fi

# Check functions exist
echo ""
echo "=== Function Checks ==="

FUNCTIONS=(
    "issue_verifier_read_token"
    "revoke_verifier_read_token"
    "verify_verifier_read_token"
    "list_verifier_tokens"
    "cleanup_expired_verifier_tokens"
)

for func in "${FUNCTIONS[@]}"; do
    if grep -q "CREATE OR REPLACE FUNCTION.*$func" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
        echo "✅ PASS: Function $func exists"
    else
        echo "❌ FAIL: Function $func missing"
        exit 1
    fi
done

# Check SECURITY DEFINER posture
echo ""
echo "=== Security Checks ==="

if grep -q "SECURITY DEFINER" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Functions are SECURITY DEFINER"
else
    echo "❌ FAIL: Functions not SECURITY DEFINER"
    exit 1
fi

if grep -q "SET search_path = pg_catalog, public" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Hardened search_path present"
else
    echo "❌ FAIL: Hardened search_path missing"
    exit 1
fi

# Check for Regulation 26 enforcement
echo ""
echo "=== Regulation 26 Enforcement Checks ==="

if grep -q "check_reg26_separation" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Regulation 26 separation check present"
else
    echo "❌ FAIL: Regulation 26 separation check missing"
    exit 1
fi

if grep -q "VERIFIER" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: VERIFIER role parameter passed to Reg26 check"
else
    echo "❌ FAIL: VERIFIER role parameter missing"
    exit 1
fi

# Check for token security (hash storage, not plaintext)
echo ""
echo "=== Token Security Checks ==="

if grep -q "verifier_id.*REFERENCES" schema/migrations/0093_gf_fn_verifier_read_token.sql && grep -q "verifier_registry" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: FK verifier_id present"
else
    echo "❌ FAIL: FK verifier_id missing"
    exit 1
fi

if grep -q "crypt" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Token hashing with crypt() present"
else
    echo "❌ FAIL: Token hashing missing"
    exit 1
fi

if grep -q "gen_random_bytes" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Cryptographically random token generation present"
else
    echo "❌ FAIL: Random token generation missing"
    exit 1
fi

# Check for append-only behavior
echo ""
echo "=== Append-Only Behavior Checks ==="

if grep -q "gf_verifier_read_tokens_append_only" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Append-only trigger present"
else
    echo "❌ FAIL: Append-only trigger missing"
    exit 1
fi

if grep -q "DELETE.*not allowed" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: DELETE operations blocked"
else
    echo "❌ FAIL: DELETE operations not blocked"
    exit 1
fi

if grep -q "revoked_at.*now" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Revocation sets revoked_at timestamp"
else
    echo "❌ FAIL: Revocation timestamp setting missing"
    exit 1
fi

# Check for RLS
echo ""
echo "=== RLS Checks ==="

if grep -q "gf_verifier_read_tokens.*ENABLE ROW LEVEL SECURITY" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: RLS enabled on gf_verifier_read_tokens"
else
    echo "❌ FAIL: RLS not enabled on gf_verifier_read_tokens"
    exit 1
fi

if grep -q "CREATE POLICY.*gf_verifier_read_tokens_tenant_isolation" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Tenant isolation policy present"
else
    echo "❌ FAIL: Tenant isolation policy missing"
    exit 1
fi

# Check for scoped tables definition
echo ""
echo "=== Scoped Tables Checks ==="

SCOPED_TABLES=(
    "evidence_nodes"
    "monitoring_records"
    "asset_batches"
    "verification_cases"
)

for table in "${SCOPED_TABLES[@]}"; do
    if grep -q "$table" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
        echo "✅ PASS: Scoped table $table included"
    else
        echo "❌ FAIL: Scoped table $table missing"
        exit 1
    fi
done

# Check for verifier validation
echo ""
echo "=== Verifier Validation Checks ==="

if grep -q "verifier_registry" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Verifier registry validation present"
else
    echo "❌ FAIL: Verifier registry validation missing"
    exit 1
fi

if grep -q "is_active" schema/migrations/0093_gf_fn_verifier_read_token.sql && grep -q "true" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Verifier active status validation present"
else
    echo "❌ FAIL: Verifier active status validation missing"
    exit 1
fi

if grep -q "methodology_scope" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Verifier methodology scope validation present"
else
    echo "❌ FAIL: Verifier methodology scope validation missing"
    exit 1
fi

# Check for project validation
if grep -q "project_id.*REFERENCES" schema/migrations/0093_gf_fn_verifier_read_token.sql && grep -q "projects" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: FK project_id present"
else
    echo "❌ FAIL: FK project_id missing"
    exit 1
fi

# Check for sector neutrality (no sector-specific terms)
echo ""
echo "=== Sector Neutrality Check ==="

if grep -q -i "solar\|plastic\|carbon\|forestry\|energy\|waste" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "❌ FAIL: Sector-specific terms found in migration"
    exit 1
else
    echo "✅ PASS: No sector-specific terms found"
fi

# Check for proper input validation
echo ""
echo "=== Input Validation Checks ==="

NULL_CHECKS=(
    "p_verifier_id IS NULL"
    "p_project_id IS NULL"
    "p_token_hash IS NULL"
)

for check in "${NULL_CHECKS[@]}"; do
    if grep -q "$check" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
        echo "✅ PASS: Input validation for $check present"
    else
        echo "❌ FAIL: Input validation for $check missing"
        exit 1
    fi
done

# Check for TTL validation
if grep -q "p_ttl_hours" schema/migrations/0093_gf_fn_verifier_read_token.sql && grep -q "8760" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: TTL validation present"
else
    echo "❌ FAIL: TTL validation missing"
    exit 1
fi

# Check for foreign key constraints
echo ""
echo "=== Foreign Key Checks ==="

# Check verifier_id FK
if grep -q "verifier_id.*REFERENCES" schema/migrations/0093_gf_fn_verifier_read_token.sql && grep -q "verifier_registry" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: FK verifier_id present"
else
    echo "❌ FAIL: FK verifier_id missing"
    exit 1
fi

# Check project_id FK
if grep -q "project_id.*REFERENCES" schema/migrations/0093_gf_fn_verifier_read_token.sql && grep -q "projects" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: FK project_id present"
else
    echo "❌ FAIL: FK project_id missing"
    exit 1
fi

# Check tenant_id FK
if grep -q "tenant_id.*REFERENCES" schema/migrations/0093_gf_fn_verifier_read_token.sql && grep -q "tenants" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: FK tenant_id present"
else
    echo "❌ FAIL: FK tenant_id missing"
    exit 1
fi

# Check for indexes
echo ""
echo "=== Index Checks ==="

INDEXES=(
    "idx_gf_verifier_read_tokens_verifier"
    "idx_gf_verifier_read_tokens_project"
    "idx_gf_verifier_read_tokens_tenant"
    "idx_gf_verifier_read_tokens_hash"
    "idx_gf_verifier_read_tokens_expires"
)

for index in "${INDEXES[@]}"; do
    if grep -q "$index" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
        echo "✅ PASS: Index $index exists"
    else
        echo "❌ FAIL: Index $index missing"
        exit 1
    fi
done

# Check for permissions granted
echo ""
echo "=== Permission Checks ==="

if grep -q "GRANT EXECUTE ON FUNCTION issue_verifier_read_token" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Permissions granted for issue_verifier_read_token"
else
    echo "❌ FAIL: Permissions missing for issue_verifier_read_token"
    exit 1
fi

if grep -q "GRANT EXECUTE ON FUNCTION revoke_verifier_read_token" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Permissions granted for revoke_verifier_read_token"
else
    echo "❌ FAIL: Permissions missing for revoke_verifier_read_token"
    exit 1
fi

# Check for revoke-first privileges
if grep -q "REVOKE ALL.*gf_verifier_read_tokens.*FROM PUBLIC" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Revoke-first privileges applied"
else
    echo "❌ FAIL: Revoke-first privileges missing"
    exit 1
fi

# Check that token secret is returned but not stored
if grep -q "RETURN v_token_secret" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Token secret returned (shown once)"
else
    echo "❌ FAIL: Token secret not returned"
    exit 1
fi

if grep -q "v_token_hash" schema/migrations/0093_gf_fn_verifier_read_token.sql && ! grep -q "RETURN.*v_token_hash" schema/migrations/0093_gf_fn_verifier_read_token.sql; then
    echo "✅ PASS: Token hash stored, secret not returned"
else
    echo "❌ FAIL: Token hash handling incorrect"
    exit 1
fi

echo ""
echo "✅ All checks passed for GF-W1-FNC-006"
echo "Migration: 0093_gf_fn_verifier_read_token.sql"
echo "Status: READY"

exit 0
