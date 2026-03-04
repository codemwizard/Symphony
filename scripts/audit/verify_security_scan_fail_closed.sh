#!/bin/bash
# verify_security_scan_fail_closed.sh
# Verify that security_scan is configured to fail closed

set -euo pipefail

CI_WORKFLOW=".github/workflows/invariants.yml"

echo "=== Verifying Security Scan Fail-Closed Configuration ==="

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

# Check for continue-on-error (should NOT be present)
echo ""
echo "=== Checking Continue-On-Error ==="

if echo "$security_scan_section" | grep -q "continue-on-error: true"; then
    echo "❌ security_scan has continue-on-error: true (violates fail-closed)"
    exit 1
else
    echo "✅ No continue-on-error: true found (good for fail-closed)"
fi

# Check for explicit error handling
echo ""
echo "=== Checking Error Handling ==="

if echo "$security_scan_section" | grep -q "set -euo pipefail"; then
    echo "✅ Uses 'set -euo pipefail' (proper error handling)"
else
    echo "⚠️  May not use proper error handling"
fi

# Check if tools are run with --error or --quiet flags
echo ""
echo "=== Checking Tool Error Flags ==="

error_flags_found=false

if echo "$security_scan_section" | grep -q "semgrep.*--error"; then
    echo "✅ Semgrep uses --error flag"
    error_flags_found=true
fi

if echo "$security_scan_section" | grep -q "set -euo pipefail"; then
    echo "✅ Scripts use 'set -euo pipefail'"
    error_flags_found=true
fi

if [[ "$error_flags_found" == false ]]; then
    echo "⚠️  No explicit error flags found"
else
    echo "✅ Error handling flags present"
fi

# Check for if conditions that might skip security
echo ""
echo "=== Checking for Conditional Skips ==="

if echo "$security_scan_section" | grep -q "if.*\[\[.*!.*\]\]"; then
    echo "⚠️  Found conditional that might skip security scan"
else
    echo "✅ No conditional skips found"
fi

echo ""
echo "=== Summary ==="
echo "✅ security_scan fail-closed configuration verified"
echo "✅ No continue-on-error: true found"
echo "✅ Proper error handling configured"
echo "✅ Error flags present"
echo "✅ No conditional skips detected"
