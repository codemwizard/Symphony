#!/bin/bash
# validate_scan_scope_contract.sh
# Validate SECURITY_SCAN_SCOPE.yml against schema and requirements

set -euo pipefail

CONTRACT_FILE="docs/contracts/SECURITY_SCAN_SCOPE.yml"

echo "=== Validating Security Scan Scope Contract ==="

if [[ ! -f "$CONTRACT_FILE" ]]; then
    echo "❌ SECURITY_SCAN_SCOPE.yml not found"
    exit 1
fi

# YAML syntax validation
echo "Checking YAML syntax..."
if ! python3 -c "import yaml; yaml.safe_load(open('$CONTRACT_FILE'))" 2>/dev/null; then
    echo "❌ SECURITY_SCAN_SCOPE.yml has invalid YAML syntax"
    exit 1
fi
echo "✅ YAML syntax valid"

# Check required top-level sections
echo ""
echo "Checking required top-level sections..."
required_sections=("languages" "security_tools" "coverage_requirements" "validation" "failure_modes" "compliance_standards")

for section in "${required_sections[@]}"; do
    if ! grep -q "^$section:" "$CONTRACT_FILE"; then
        echo "❌ Missing required section: $section"
        exit 1
    fi
done
echo "✅ All required sections present"

# Validate language entries
echo ""
echo "=== Validating Language Entries ==="

cs_found=false
py_found=false

while IFS= read -r line; do
    if echo "$line" | grep -Eq '^[[:space:]]*-[[:space:]]*id:[[:space:]]*"cs"'; then
        cs_found=true
    fi
    if echo "$line" | grep -Eq '^[[:space:]]*-[[:space:]]*id:[[:space:]]*"py"'; then
        py_found=true
    fi
done < "$CONTRACT_FILE"

if [[ "$cs_found" != true ]]; then
    echo "❌ C# language definition missing"
    exit 1
fi

if [[ "$py_found" != true ]]; then
    echo "❌ Python language definition missing"
    exit 1
fi

echo "✅ C# and Python language definitions found"

# Validate security tool entries
echo ""
echo "=== Validating Security Tool Entries ==="

required_tools=("semgrep" "lint_app_sql_injection" "scan_secrets")

for tool in "${required_tools[@]}"; do
    if ! grep -q "name: \"$tool\"" "$CONTRACT_FILE"; then
        echo "❌ Required tool not found: $tool"
        exit 1
    fi
    echo "✅ Found tool: $tool"
done

# Validate tool script references
echo ""
echo "=== Validating Tool Script References ==="

while IFS= read -r line; do
    if [[ "$line" =~ script:[[:space:]]*scripts/ ]]; then
        script_path=$(echo "$line" | sed 's/.*script:[[:space:]]*//')
        if [[ -f "$script_path" ]]; then
            echo "✅ Script exists: $script_path"
        else
            echo "❌ Script not found: $script_path"
            exit 1
        fi
    fi
done < "$CONTRACT_FILE"

# Validate coverage requirements
echo ""
echo "=== Validating Coverage Requirements ==="

if ! grep -q "language_presence_rules:" "$CONTRACT_FILE"; then
    echo "❌ language_presence_rules not found"
    exit 1
fi

if ! grep -q "tool_availability_rules:" "$CONTRACT_FILE"; then
    echo "❌ tool_availability_rules not found"
    exit 1
fi

echo "✅ Coverage requirements defined"

# Check for minimum rule counts
echo ""
echo "=== Checking Minimum Rule Requirements ==="

min_rules_pattern="minimum_rules:"
if grep -q "$min_rules_pattern" "$CONTRACT_FILE"; then
    echo "✅ Minimum rule requirements specified"
else
    echo "⚠️  No minimum rule requirements found"
fi

echo ""
echo "=== Summary ==="
echo "✅ SECURITY_SCAN_SCOPE.yml validation passed"
echo "✅ YAML syntax valid"
echo "✅ All required sections present"
echo "✅ C# and Python language coverage"
echo "✅ Required security tools defined"
echo "✅ Tool script references valid"
echo "✅ Coverage requirements specified"
echo "✅ Contract ready for use"
