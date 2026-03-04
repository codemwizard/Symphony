#!/bin/bash
# validate_security_enforcement_map.sh
# Validate SECURITY_ENFORCEMENT_MAP.yml against schema and requirements

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
echo "Checking required top-level keys..."
required_keys=("manifest_version" "languages" "enforcement_mappings" "ci_gates" "parameterization_requirements" "validation")

for key in "${required_keys[@]}"; do
    if ! grep -q "^$key:" "$ENFORCEMENT_MAP"; then
        echo "❌ Missing required top-level key: $key"
        exit 1
    fi
done
echo "✅ All required top-level keys present"

# Validate language entries
echo "Validating language entries..."
cs_found=false
py_found=false

# Use grep to find language definitions
if grep -q "id: \"cs\"" "$ENFORCEMENT_MAP"; then
    cs_found=true
fi

if grep -q "id: \"py\"" "$ENFORCEMENT_MAP"; then
    py_found=true
fi

if [[ "$cs_found" != true ]]; then
    echo "❌ C# language definition missing"
    exit 1
fi

if [[ "$py_found" != true ]]; then
    echo "❌ Python language definition missing"
    exit 1
fi

echo "✅ C# and Python language definitions found"

# Validate enforcement mappings have required fields
echo "Validating enforcement mappings..."
policy_ids=$(grep "^  - policy_id:" "$ENFORCEMENT_MAP" | wc -l)

if [[ "$policy_ids" -gt 0 ]]; then
    echo "✅ Found $policy_ids enforcement mappings"
    
    # Check that each mapping has required fields
    required_fields=("title" "enforcement_type" "languages" "tools" "ci_gate")
    for field in "${required_fields[@]}"; do
        field_count=$(grep -A 5 "^  - policy_id:" "$ENFORCEMENT_MAP" | grep -c "^    $field:" || true)
        if [[ "$field_count" -lt "$policy_ids" ]]; then
            echo "❌ Some enforcement mappings missing field: $field"
            exit 1
        fi
    done
    echo "✅ All enforcement mappings have required fields"
else
    echo "❌ No enforcement mappings found"
    exit 1
fi

echo "✅ Enforcement mappings have required fields"

# Validate CI gate configuration
echo "Validating CI gate configuration..."
if ! grep -q "security_scan:" "$ENFORCEMENT_MAP"; then
    echo "❌ security_scan CI gate not found"
    exit 1
fi

if ! grep -q "fail_closed: true" "$ENFORCEMENT_MAP"; then
    echo "❌ CI gate fail_closed not set to true"
    exit 1
fi

echo "✅ CI gate configuration valid"

# Validate parameterization requirements
echo "Validating parameterization requirements..."
if ! grep -q "database_access:" "$ENFORCEMENT_MAP"; then
    echo "❌ database_access parameterization requirements missing"
    exit 1
fi

if ! grep -q "frameworks:" "$ENFORCEMENT_MAP"; then
    echo "❌ frameworks parameterization requirements missing"
    exit 1
fi

echo "✅ Parameterization requirements valid"

echo ""
echo "✅ SECURITY_ENFORCEMENT_MAP.yml validation passed"
echo "✅ All required sections and fields present"
echo "✅ C# and Python language coverage confirmed"
echo "✅ CI gate fail-closed configuration verified"
