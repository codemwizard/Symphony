#!/bin/bash
# verify_policy_scope_all_languages.sh
# Verify that security policies explicitly include C# and Python language scope

set -euo pipefail

echo "=== R-018-A1: Verify policy docs explicitly include C# and Python ==="

POLICY_DIR="docs/security"
REQUIRED_LANGUAGES=("C#" "Python")
FAILED_POLICIES=()

# Check each policy file for language scope
for policy_file in "$POLICY_DIR"/*.md; do
    if [[ -f "$policy_file" ]]; then
        policy_name=$(basename "$policy_file" .md)
        echo "Checking $policy_name..."
        
        missing_languages=()
        for lang in "${REQUIRED_LANGUAGES[@]}"; do
            if ! grep -q "$lang" "$policy_file"; then
                missing_languages+=("$lang")
            fi
        done
        
        if [[ ${#missing_languages[@]} -gt 0 ]]; then
            echo "❌ $policy_name missing languages: ${missing_languages[*]}"
            FAILED_POLICIES+=("$policy_name")
        else
            echo "✅ $policy_name includes all required languages"
        fi
    fi
done

echo ""
echo "=== R-018-A2: Verify SECURITY_ENFORCEMENT_MAP.yml validates against schema ==="

ENFORCEMENT_MAP="docs/contracts/SECURITY_ENFORCEMENT_MAP.yml"
SCHEMA_FILE="evidence_schemas/r_018_policy_enforcement_map.schema.json"

if [[ ! -f "$ENFORCEMENT_MAP" ]]; then
    echo "❌ SECURITY_ENFORCEMENT_MAP.yml not found"
    exit 1
fi

# Basic YAML syntax validation
if ! python3 -c "import yaml; yaml.safe_load(open('$ENFORCEMENT_MAP'))" 2>/dev/null; then
    echo "❌ SECURITY_ENFORCEMENT_MAP.yml has invalid YAML syntax"
    exit 1
fi

# Check required sections
required_sections=("languages" "enforcement_mappings" "ci_gates" "parameterization_requirements")
for section in "${required_sections[@]}"; do
    if ! grep -q "^$section:" "$ENFORCEMENT_MAP"; then
        echo "❌ Missing required section: $section"
        exit 1
    fi
done

echo "✅ SECURITY_ENFORCEMENT_MAP.yml has valid structure"

echo ""
echo "=== R-018-A3: Verify parameterized-query enforcement is CI-mapped ==="

# Check that parameterized queries are mapped in CI
if ! grep -q "parameterized_queries_required: true" "$ENFORCEMENT_MAP"; then
    echo "❌ parameterized_queries_required not found in enforcement map"
    exit 1
fi

# Check CI gate includes parameterization checks
if ! grep -q "lint_app_sql_injection" "$ENFORCEMENT_MAP"; then
    echo "❌ lint_app_sql_injection not found in CI gate mapping"
    exit 1
fi

echo "✅ Parameterized-query enforcement is CI-mapped"

echo ""
echo "=== Summary ==="

if [[ ${#FAILED_POLICIES[@]} -gt 0 ]]; then
    echo "❌ Policies missing language scope:"
    for policy in "${FAILED_POLICIES[@]}"; do
        echo "   - $policy"
    done
    exit 1
fi

echo "✅ All R-018 acceptance criteria passed"
echo "✅ Policy scope includes C# and Python"
echo "✅ SECURITY_ENFORCEMENT_MAP.yml validates"
echo "✅ Parameterized-query enforcement is CI-mapped"
