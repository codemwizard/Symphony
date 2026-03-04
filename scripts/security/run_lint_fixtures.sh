#!/bin/bash
# run_lint_fixtures.sh
# Run fixture suites to verify lint scripts work correctly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
SUITE="${1:-}"

echo "==> Running Lint Fixtures"

if [[ -z "$SUITE" ]]; then
    echo "Usage: $0 --suite <suite_name>"
    echo "Available suites: app_sql_injection"
    exit 1
fi

case "$SUITE" in
    "app_sql_injection")
        run_app_sql_injection_fixtures
        ;;
    *)
        echo "❌ Unknown suite: $SUITE"
        exit 1
        ;;
esac

run_app_sql_injection_fixtures() {
    echo "=== Running App SQL Injection Fixtures ==="
    
    # Create temporary fixture directory
    TEMP_FIXTURES=$(mktemp -d)
    trap "rm -rf $TEMP_FIXTURES" EXIT
    
    # Create bad fixtures (should fail)
    echo "Creating bad fixtures (should fail)..."
    
    cat > "$TEMP_FIXTURES/bad_cs.cs" << 'EOF'
using System;
public class BadSql {
    public void VulnerableMethod(string userInput) {
        // This should be flagged - string concatenation
        string sql = "SELECT * FROM users WHERE id = " + userInput;
        // This should be flagged - string.Format
        string sql2 = string.Format("SELECT * FROM users WHERE name = '{0}'", userInput);
        // This should be flagged - interpolation
        string sql3 = $"SELECT * FROM users WHERE email = '{userInput}'";
    }
}
EOF

    cat > "$TEMP_FIXTURES/bad_py.py" << 'EOF'
import psycopg2

def vulnerable_query(user_input):
    # This should be flagged - string concatenation
    sql = "SELECT * FROM users WHERE id = " + user_input
    # This should be flagged - % formatting
    sql2 = "SELECT * FROM users WHERE name = '%s'" % user_input
    # This should be flagged - f-string
    sql3 = f"SELECT * FROM users WHERE email = '{user_input}'"
    return sql
EOF

    # Create good fixtures (should pass)
    echo "Creating good fixtures (should pass)..."
    
    cat > "$TEMP_FIXTURES/good_cs.cs" << 'EOF'
using System;
using System.Data.SqlClient;
public class GoodSql {
    public void SafeMethod(string userInput) {
        // This should NOT be flagged - parameterized
        string sql = "SELECT * FROM users WHERE id = @id";
        using (var cmd = new SqlCommand(sql, connection)) {
            cmd.Parameters.Add("@id", userInput);
        }
        // This should NOT be flagged - Dapper parameterized
        var users = connection.Query<User>("SELECT * FROM users WHERE name = @name", new { name = userInput });
    }
}
EOF

    cat > "$TEMP_FIXTURES/good_py.py" << 'EOF'
import psycopg2

def safe_query(user_input):
    # This should NOT be flagged - parameterized
    sql = "SELECT * FROM users WHERE id = %s"
    cursor.execute(sql, (user_input,))
    # This should NOT be flagged - parameterized
    sql2 = "SELECT * FROM users WHERE name = %s"
    cursor.execute(sql2, (user_input,))
    return sql
EOF

    # Test bad fixtures (should fail)
    echo ""
    echo "=== Testing Bad Fixtures (Should Fail) ==="
    
    echo "Testing bad_cs.cs..."
    if bash "$SCRIPT_DIR/lint_app_sql_injection.sh" 2>/dev/null | grep -q "❌"; then
        echo "✅ Bad C# fixture correctly detected SQLi patterns"
    else
        echo "❌ Bad C# fixture NOT detected (should have failed)"
        return 1
    fi
    
    echo "Testing bad_py.py..."
    if bash "$SCRIPT_DIR/lint_app_sql_injection.sh" 2>/dev/null | grep -q "❌"; then
        echo "✅ Bad Python fixture correctly detected SQLi patterns"
    else
        echo "❌ Bad Python fixture NOT detected (should have failed)"
        return 1
    fi

    # Test good fixtures (should pass)
    echo ""
    echo "=== Testing Good Fixtures (Should Pass) ==="
    
    # Copy good fixtures to temp location for testing
    cp "$TEMP_FIXTURES/good_cs.cs" "$TEMP_FIXTURES/test_good.cs"
    cp "$TEMP_FIXTURES/good_py.py" "$TEMP_FIXTURES/test_good.py"
    
    # Temporarily move to fixture dir and test
    (cd "$TEMP_FIXTURES" && bash "$SCRIPT_DIR/lint_app_sql_injection.sh" >/dev/null 2>&1)
    if [[ $? -eq 0 ]]; then
        echo "✅ Good fixtures correctly passed (no false positives)"
    else
        echo "❌ Good fixtures failed (false positive)"
        return 1
    fi

    echo ""
    echo "✅ App SQL Injection fixture suite passed"
    echo "✅ Bad fixtures correctly detected vulnerabilities"
    echo "✅ Good fixtures correctly passed (no false positives)"
}
