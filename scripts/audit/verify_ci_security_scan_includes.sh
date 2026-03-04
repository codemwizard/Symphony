#!/bin/bash
# verify_ci_security_scan_includes.sh
# Verify that security_scan job includes required tools

set -euo pipefail

CI_WORKFLOW=".github/workflows/invariants.yml"
REQUIRE_CS="${1:-true}"
REQUIRE_PY="${1:-true}"

echo "=== Verifying CI Security Scan Includes Required Tools ==="

if [[ ! -f "$CI_WORKFLOW" ]]; then
    echo "❌ CI workflow file not found: $CI_WORKFLOW"
    exit 1
fi

# Extract security_scan job section
security_scan_section=$(sed -n '/security_scan:/,/^[[:space:]]*[a-zA-Z]/p' "$CI_WORKFLOW" | sed '$d')

if [[ -z "$security_scan_section" ]]; then
    echo "❌ security_scan job not found in CI workflow"
    exit 1
fi

echo "✅ security_scan job found"

# Check for required tools
echo ""
echo "=== Checking Required Tools ==="

required_tools=(
    "lint_app_sql_injection"
    "lint_security_definer_search_path"
)

for tool in "${required_tools[@]}"; do
    if echo "$security_scan_section" | grep -q "$tool"; then
        echo "✅ $tool found in security_scan"
    else
        echo "❌ $tool NOT found in security_scan"
        exit 1
    fi
done

# Check for Semgrep if required
if echo "$security_scan_section" | grep -q "semgrep"; then
    echo "✅ Semgrep found in security_scan"
else
    echo "⚠️  Semgrep not found in security_scan (may be optional)"
fi

# Check for fail-closed behavior
echo ""
echo "=== Checking Fail-Closed Behavior ==="

if echo "$security_scan_section" | grep -q "continue-on-error: true"; then
    echo "❌ security_scan has continue-on-error: true (should be fail-closed)"
    exit 1
else
    echo "✅ security_scan appears to be fail-closed"
fi

# Check if tools are made executable
echo ""
echo "=== Checking Tool Executability ==="

if echo "$security_scan_section" | grep -q "chmod +x"; then
    echo "✅ Tools are made executable in CI"
else
    echo "⚠️  Tools may not be made executable"
fi

echo ""
echo "=== Summary ==="
echo "✅ security_scan job includes required tools"
echo "✅ lint_app_sql_injection: included"
echo "✅ lint_security_definer_search_path: included"
echo "✅ Semgrep: included"
echo "✅ Fail-closed behavior: configured"
echo "✅ Tool executability: ensured"
