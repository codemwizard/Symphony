#!/bin/bash
# verify_semgrep_languages.sh
# Verify Semgrep rules cover Python and C# and tests pass
#
# Updated:
# - Removed jq dependency (uses python3 to parse JSON)
# - Keeps existing semantics and flags

set -euo pipefail

SEMGREP_RULES="security/semgrep/rules.yml"
REQUIRE_PY=false
REQUIRE_CS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --require)
            case "${2:-}" in
                py)
                    REQUIRE_PY=true
                    ;;
                cs)
                    REQUIRE_CS=true
                    ;;
                *)
                    echo "❌ Unknown --require target: ${2:-}"
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        *)
            echo "❌ Unknown argument: $1"
            exit 1
            ;;
    esac
done

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

echo ""
echo "=== C# Rules Coverage ==="
cs_rules=$(grep -c "languages: \[csharp\]" "$SEMGREP_RULES" || true)
echo "Found $cs_rules C# rules"

if [[ "$REQUIRE_CS" == "true" && "$cs_rules" -eq 0 ]]; then
    echo "❌ No C# rules found (required)"
    exit 1
fi

echo "C# rules:"
awk '
  /^ *- id:/ { id=$3 }
  /languages: \[csharp\]/ { if (id!="") print "  - " id; id="" }
' "$SEMGREP_RULES" || true

echo ""
echo "=== Python Rules Coverage ==="
py_rules=$(grep -c "languages: \[python\]" "$SEMGREP_RULES" || true)
echo "Found $py_rules Python rules"

if [[ "$REQUIRE_PY" == "true" && "$py_rules" -eq 0 ]]; then
    echo "❌ No Python rules found (required)"
    exit 1
fi

echo "Python rules:"
awk '
  /^ *- id:/ { id=$3 }
  /languages: \[python\]/ { if (id!="") print "  - " id; id="" }
' "$SEMGREP_RULES" || true

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

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

cat > "$TEMP_DIR/test_cs.cs" << 'EOF'
using System;
using System.Data.SqlClient;
public class TestSql {
    public void BadMethod(string input) {
        var cmd = new SqlCommand();
        cmd.CommandText = "SELECT * FROM users WHERE id = " + input;
    }
}
EOF

cat > "$TEMP_DIR/test_py.py" << 'EOF'
def test_function(user_input):
    sql = "SELECT * FROM users WHERE id = " + user_input
    api_key = "hardcoded_python_secret_12345"
    return sql
EOF

json_len_from_stdin() {
  python3 -c 'import json,sys
raw=sys.stdin.read().strip()
if not raw:
    print(0); raise SystemExit(0)
try:
    data=json.loads(raw)
except Exception:
    print(0); raise SystemExit(0)
print(len(data.get("results", [])))'
}

echo "Testing C# patterns..."
cs_raw="$(semgrep --config="$SEMGREP_RULES" --json --quiet --metrics off "$TEMP_DIR/test_cs.cs" 2>/dev/null || true)"
cs_findings="$(printf '%s' "$cs_raw" | json_len_from_stdin)"
echo "C# test findings: $cs_findings"

echo "Testing Python patterns..."
py_raw="$(semgrep --config="$SEMGREP_RULES" --json --quiet --metrics off "$TEMP_DIR/test_py.py" 2>/dev/null || true)"
py_findings="$(printf '%s' "$py_raw" | json_len_from_stdin)"
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
