#!/bin/bash
# validate_security_enforcement_map.sh - Simple version
set -euo pipefail

ENFORCEMENT_MAP="docs/contracts/SECURITY_ENFORCEMENT_MAP.yml"

echo "=== Validating SECURITY_ENFORCEMENT_MAP.yml ==="

if [[ ! -f "$ENFORCEMENT_MAP" ]]; then
    echo "❌ SECURITY_ENFORCEMENT_MAP.yml not found"
    exit 1
fi

# YAML syntax validation
echo "Checking YAML syntax..."
if ! python3 -c "import yaml; yaml.safe_load(open('$ENFORCEMENT_MAP'))" 2>/dev/null; then
    echo "❌ SECURITY_ENFORCEMENT_MAP.yml has invalid YAML syntax"
    exit 1
fi
echo "✅ YAML syntax valid"

# Check required top-level keys
echo "Checking required sections..."
required_keys=("languages" "enforcement_mappings" "ci_gates" "parameterization_requirements")
for key in "${required_keys[@]}"; do
    if grep -q "^$key:" "$ENFORCEMENT_MAP"; then
        echo "✅ $key section found"
    else
        echo "❌ Missing section: $key"
        exit 1
    fi
done

# Check language coverage
echo "Checking language coverage..."
if grep -q "id: \"cs\"" "$ENFORCEMENT_MAP" && grep -q "id: \"py\"" "$ENFORCEMENT_MAP"; then
    echo "✅ C# and Python languages covered"
else
    echo "❌ Missing C# or Python language definitions"
    exit 1
fi

# Check CI gate configuration
echo "Checking CI gate..."
if grep -q "ci_gates:" "$ENFORCEMENT_MAP" && grep -q "fail_closed: true" "$ENFORCEMENT_MAP"; then
    echo "✅ CI gate configured with fail_closed"
else
    echo "❌ CI gate not properly configured"
    exit 1
fi

echo "✅ SECURITY_ENFORCEMENT_MAP.yml validation passed"
