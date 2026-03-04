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
if ! python3 - <<'PY'
import re
from pathlib import Path
import sys

workflow = Path(".github/workflows/invariants.yml").read_text()
match = re.search(r"(?ms)^  security_scan:\n(.*?)(?=^  [a-zA-Z0-9_]+:\n|\Z)", workflow)
if not match:
    print("❌ Unable to extract security_scan section")
    sys.exit(1)
section = match.group(0)

required_tools = [
    "lint_app_sql_injection.sh",
    "lint_security_definer_search_path.sh",
]
for tool in required_tools:
    if tool not in section:
        print(f"❌ Required tool not in security_scan: {tool}")
        sys.exit(1)
    print(f"✅ {tool} found in security_scan")

# secrets scanning can be directly invoked or included via fast checks
if "scan_secrets.sh" in section or "run_security_fast_checks.sh" in section:
    print("✅ secrets scanning found in security_scan")
else:
    print("❌ Required secrets scanning not in security_scan")
    sys.exit(1)
PY
then
    exit 1
fi

# Check 5: security_scan is fail-closed
echo "Checking security_scan fail-closed behavior..."
security_scan_section="$(python3 - <<'PY'
import re
from pathlib import Path
workflow = Path('.github/workflows/invariants.yml').read_text()
m = re.search(r'(?ms)^  security_scan:\n(.*?)(?=^  [a-zA-Z0-9_]+:\n|\Z)', workflow)
print(m.group(0) if m else '')
PY
)"
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
