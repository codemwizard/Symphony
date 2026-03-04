#!/bin/bash
# verify_enforcement_map_parameterization_ci.sh
# Verify that parameterized-query enforcement is CI-mapped and fail-closed

set -euo pipefail

ENFORCEMENT_MAP="docs/contracts/SECURITY_ENFORCEMENT_MAP.yml"
CI_WORKFLOW=".github/workflows/invariants.yml"

echo "=== Verifying Parameterized-Query CI Enforcement ==="

# Check 1: Parameterized queries required in enforcement map
echo "Checking parameterized_queries_required in enforcement map..."
if ! grep -q "parameterized_queries_required: true" "$ENFORCEMENT_MAP"; then
    echo "❌ parameterized_queries_required not set to true"
    exit 1
fi
echo "✅ parameterized_queries_required: true found"

# Check 2: Application SQL injection lint is mapped
echo "Checking application SQL injection lint mapping..."
if ! grep -q "lint_app_sql_injection" "$ENFORCEMENT_MAP"; then
    echo "❌ lint_app_sql_injection not found in enforcement map"
    exit 1
fi
echo "✅ lint_app_sql_injection mapped"

# Check 3: CI workflow includes security_scan
echo "Checking CI workflow includes security_scan..."
if [[ ! -f "$CI_WORKFLOW" ]]; then
    echo "❌ CI workflow file not found: $CI_WORKFLOW"
    exit 1
fi

if ! grep -q "security_scan:" "$CI_WORKFLOW"; then
    echo "❌ security_scan job not found in CI workflow"
    exit 1
fi
echo "✅ security_scan job found in CI workflow"

# Check 4: security_scan runs required tools
echo "Checking security_scan runs required tools..."
security_scan_section=$(sed -n '/security_scan:/,/^[[:space:]]*[a-zA-Z]/p' "$CI_WORKFLOW")

required_tools=("lint_app_sql_injection" "lint_security_definer_search_path" "scan_secrets")
for tool in "${required_tools[@]}"; do
    if ! echo "$security_scan_section" | grep -q "$tool"; then
        echo "❌ Required tool not in security_scan: $tool"
        exit 1
    fi
    echo "✅ $tool found in security_scan"
done

# Check 5: security_scan is fail-closed
echo "Checking security_scan fail-closed behavior..."
if echo "$security_scan_section" | grep -q "continue-on-error: true"; then
    echo "❌ security_scan has continue-on-error: true (should be fail-closed)"
    exit 1
fi

# Check if security_scan has proper failure handling
if ! echo "$security_scan_section" | grep -q "if.*failure"; then
    echo "⚠️  security_scan may not have explicit failure handling"
else
    echo "✅ security_scan has failure handling"
fi

# Check 6: Parameterization requirements include both languages
echo "Checking parameterization requirements cover both languages..."
if ! grep -q "cs:" "$ENFORCEMENT_MAP"; then
    echo "❌ C# parameterization requirements missing"
    exit 1
fi

if ! grep -q "py:" "$ENFORCEMENT_MAP"; then
    echo "❌ Python parameterization requirements missing"
    exit 1
fi

echo "✅ C# and Python parameterization requirements found"

echo ""
echo "=== Summary ==="
echo "✅ Parameterized-query enforcement is CI-mapped"
echo "✅ Application SQL injection lint is included"
echo "✅ Security scan job includes required tools"
echo "✅ Both C# and Python parameterization covered"
echo "✅ CI enforcement configuration verified"
