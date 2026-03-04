#!/bin/bash
# verify_semgrep_languages.sh
# Verify Semgrep rules cover Python and C# and tests pass

set -euo pipefail

SEMGREP_RULES="security/semgrep/rules.yml"
REQUIRE_PY="${1:-true}"
REQUIRE_CS="${1:-true}"

echo "=== Verifying Semgrep Language Coverage ==="

if [[ ! -f "$SEMGREP_RULES" ]]; then
    echo "❌ Semgrep rules file not found: $SEMGREP_RULES"
    exit 1
fi

echo "Checking Semgrep rules syntax..."
if ! semgrep --config="$SEMGREP_RULES" --validate 2>/dev/null; then
    echo "❌ Semgrep rules syntax validation failed"
    exit 1
fi
echo "✅ Semgrep rules syntax valid"

# Check for C# rules
echo ""
echo "=== C# Rules Coverage ==="
cs_rules=$(grep -c "languages: \[csharp\]" "$SEMGREP_RULES" || true)
echo "Found $cs_rules C# rules"

if [[ "$REQUIRE_CS" == "true" && "$cs_rules" -eq 0 ]]; then
    echo "❌ No C# rules found (required)"
    exit 1
fi

# List C# rules
echo "C# rules:"
grep -A 1 "languages: \[csharp\]" "$SEMGREP_RULES" | grep "id:" | sed 's/.*id: /  - /'

# Check for Python rules
echo ""
echo "=== Python Rules Coverage ==="
py_rules=$(grep -c "languages: \[python\]" "$SEMGREP_RULES" || true)
echo "Found $py_rules Python rules"

if [[ "$REQUIRE_PY" == "true" && "$py_rules" -eq 0 ]]; then
    echo "❌ No Python rules found (required)"
    exit 1
fi

# List Python rules
echo "Python rules:"
grep -A 1 "languages: \[python\]" "$SEMGREP_RULES" | grep "id:" | sed 's/.*id: /  - /'

# Check for specific rule categories
echo ""
echo "=== Rule Categories ==="

sql_injection_rules=$(grep -c "sql.*injection\|SQL.*injection" "$SEMGREP_RULES" || true)
echo "SQL injection rules: $sql_injection_rules"

hardcoded_secret_rules=$(grep -c "hardcoded.*secret\|secret.*hardcoded" "$SEMGREP_RULES" || true)
echo "Hardcoded secret rules: $hardcoded_secret_rules"

insecure_rng_rules=$(grep -c "insecure.*rng\|rng.*insecure" "$SEMGREP_RULES" || true)
echo "Insecure RNG rules: $insecure_rng_rules"

admin_bypass_rules=$(grep -c "admin.*bypass\|bypass.*admin" "$SEMGREP_RULES" || true)
echo "Admin bypass rules: $admin_bypass_rules"

# Verify minimum rule counts
min_cs_rules=3
min_py_rules=3

if [[ "$cs_rules" -lt "$min_cs_rules" ]]; then
    echo "❌ Insufficient C# rules: $cs_rules (minimum $min_cs_rules)"
    exit 1
fi

if [[ "$py_rules" -lt "$min_py_rules" ]]; then
    echo "❌ Insufficient Python rules: $py_rules (minimum $min_py_rules)"
    exit 1
fi

echo ""
echo "=== Semgrep Test Results ==="

# Create temporary test files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Create test files with known patterns
cat > "$TEMP_DIR/test_cs.cs" << 'EOF'
using System;
public class TestSql {
    public void BadMethod(string input) {
        string sql = "SELECT * FROM users WHERE id = " + input;
    }
}
EOF

cat > "$TEMP_DIR/test_py.py" << 'EOF'
def test_function(user_input):
    sql = "SELECT * FROM users WHERE id = " + user_input
    return sql
EOF

# Test Semgrep against test files
echo "Testing C# patterns..."
cs_findings=$(semgrep --config="$SEMGREP_RULES" --quiet --json "$TEMP_DIR/test_cs.cs" | jq '.results | length' 2>/dev/null || echo "0")
echo "C# test findings: $cs_findings"

echo "Testing Python patterns..."
py_findings=$(semgrep --config="$SEMGREP_RULES" --quiet --json "$TEMP_DIR/test_py.py" | jq '.results | length' 2>/dev/null || echo "0")
echo "Python test findings: $py_findings"

if [[ "$cs_findings" -eq 0 ]]; then
    echo "❌ C# test patterns not detected (rules may not be working)"
    exit 1
fi

if [[ "$py_findings" -eq 0 ]]; then
    echo "❌ Python test patterns not detected (rules may not be working)"
    exit 1
fi

echo ""
echo "=== Summary ==="
echo "✅ Semgrep rules syntax valid"
echo "✅ C# rules: $cs_rules (minimum $min_cs_rules)"
echo "✅ Python rules: $py_rules (minimum $min_py_rules)"
echo "✅ SQL injection rules: $sql_injection_rules"
echo "✅ Hardcoded secret rules: $hardcoded_secret_rules"
echo "✅ Insecure RNG rules: $insecure_rng_rules"
echo "✅ Admin bypass rules: $admin_bypass_rules"
echo "✅ C# test patterns detected: $cs_findings"
echo "✅ Python test patterns detected: $py_findings"
echo "✅ Semgrep expansion completed successfully"
