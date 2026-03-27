#!/usr/bin/env bash
set -euo pipefail

echo "==> GF-W1-FNC-001 Project Registration Functions Verification"

# Check if migration exists
if [[ ! -f "schema/migrations/0088_gf_fn_project_registration.sql" ]]; then
    echo "❌ FAIL: Migration file 0088_gf_fn_project_registration.sql not found"
    exit 1
fi

echo "✅ PASS: Migration file exists"

# Check functions exist
echo ""
echo "=== Function Checks ==="

FUNCTIONS=(
    "register_project"
    "activate_project"
    "query_project_details"
    "list_tenant_projects"
)

for func in "${FUNCTIONS[@]}"; do
    if grep -q "CREATE OR REPLACE FUNCTION.*$func" schema/migrations/0088_gf_fn_project_registration.sql; then
        echo "✅ PASS: Function $func exists"
    else
        echo "❌ FAIL: Function $func missing"
        exit 1
    fi
done

# Check SECURITY DEFINER posture
echo ""
echo "=== Security Checks ==="

if grep -q "SECURITY DEFINER" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "✅ PASS: Functions are SECURITY DEFINER"
else
    echo "❌ FAIL: Functions not SECURITY DEFINER"
    exit 1
fi

if grep -q "SET search_path = pg_catalog, public" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "✅ PASS: Hardened search_path present"
else
    echo "❌ FAIL: Hardened search_path missing"
    exit 1
fi

# Check for error handling with SQLSTATE codes
echo ""
echo "=== Error Handling Checks ==="

SQLSTATES=(
    "GF001"
    "GF002"
    "GF003"
    "GF004"
    "GF005"
    "GF006"
    "GF007"
    "GF008"
    "GF009"
)

for code in "${SQLSTATES[@]}"; do
    if grep -q "$code" schema/migrations/0088_gf_fn_project_registration.sql; then
        echo "✅ PASS: SQLSTATE $code defined"
    else
        echo "❌ FAIL: SQLSTATE $code missing"
        exit 1
    fi
done

# Check for methodology validation
echo ""
echo "=== Methodology Validation Checks ==="

if grep -q "methodology_versions" schema/migrations/0088_gf_fn_project_registration.sql && grep -q "methodology_version_id" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "✅ PASS: Methodology version validation present"
else
    echo "❌ FAIL: Methodology version validation missing"
    exit 1
fi

if grep -q "adapter_registrations" schema/migrations/0088_gf_fn_project_registration.sql && grep -q "is_active.*true" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "✅ PASS: Adapter activity validation present"
else
    echo "❌ FAIL: Adapter activity validation missing"
    exit 1
fi

# Check for monitoring record integration
echo ""
echo "=== Monitoring Integration Checks ==="

if grep -q "record_monitoring_record" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "✅ PASS: Monitoring record integration present"
else
    echo "❌ FAIL: Monitoring record integration missing"
    exit 1
fi

if grep -q "PROJECT_REGISTRATION" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "✅ PASS: Project registration event type present"
else
    echo "❌ FAIL: Project registration event type missing"
    exit 1
fi

if grep -q "PROJECT_ACTIVATION" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "✅ PASS: Project activation event type present"
else
    echo "❌ FAIL: Project activation event type missing"
    exit 1
fi

# Check for lifecycle transition integration
echo ""
echo "=== Lifecycle Integration Checks ==="

if grep -q "transition_asset_status" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "✅ PASS: Asset lifecycle transition integration present"
else
    echo "❌ FAIL: Asset lifecycle transition integration missing"
    exit 1
fi

# Check for sector neutrality (no sector-specific terms)
echo ""
echo "=== Sector Neutrality Check ==="

if grep -q -i "solar\|plastic\|carbon\|forestry\|energy\|waste" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "❌ FAIL: Sector-specific terms found in migration"
    exit 1
else
    echo "✅ PASS: No sector-specific terms found"
fi

# Check for proper input validation
echo ""
echo "=== Input Validation Checks ==="

VALIDATIONS=(
    "p_tenant_id IS NULL"
    "p_project_name IS NULL"
    "p_jurisdiction_code IS NULL"
    "p_methodology_version_id IS NULL"
)

for validation in "${VALIDATIONS[@]}"; do
    if grep -q "$validation" schema/migrations/0088_gf_fn_project_registration.sql; then
        echo "✅ PASS: Input validation for $validation present"
    else
        echo "❌ FAIL: Input validation for $validation missing"
        exit 1
    fi
done

# Check for status validation
if grep -q "v_current_status" schema/migrations/0088_gf_fn_project_registration.sql && grep -q "DRAFT" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "✅ PASS: Project status validation present"
else
    echo "❌ FAIL: Project status validation missing"
    exit 1
fi

# Check for permissions granted
echo ""
echo "=== Permission Checks ==="

if grep -q "GRANT EXECUTE ON FUNCTION register_project" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "✅ PASS: Permissions granted for register_project"
else
    echo "❌ FAIL: Permissions missing for register_project"
    exit 1
fi

if grep -q "GRANT EXECUTE ON FUNCTION activate_project" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "✅ PASS: Permissions granted for activate_project"
else
    echo "❌ FAIL: Permissions missing for activate_project"
    exit 1
fi

# Check for adapter boundary compliance (no methodology-specific logic)
echo ""
echo "=== Adapter Boundary Check ==="

if grep -q "methodology_version_id" schema/migrations/0088_gf_fn_project_registration.sql && \
   grep -q "adapter_registration_id" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "✅ PASS: Uses methodology_version_id and adapter_registration references"
else
    echo "❌ FAIL: Missing adapter boundary references"
    exit 1
fi

# Ensure no direct interpretation of payload fields
if grep -q "payload_schema_reference_id\|record_payload_json" schema/migrations/0088_gf_fn_project_registration.sql; then
    echo "❌ FAIL: Direct payload field interpretation detected"
    exit 1
else
    echo "✅ PASS: No direct payload field interpretation"
fi

echo ""
echo "✅ All checks passed for GF-W1-FNC-001"
echo "Migration: 0088_gf_fn_project_registration.sql"
echo "Status: READY"

exit 0
