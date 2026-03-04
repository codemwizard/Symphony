#!/bin/bash
# lint_app_sql_injection.sh
# Application-layer SQL injection detection for C# and Python

set -euo pipefail

echo "==> Application-Layer SQL Injection Lint (C# and Python)"

violations=0
cs_files=()
py_files=()
scan_root="${1:-.}"

# Find C# and Python files
while IFS= read -r -d '' file; do
    if [[ "$file" == *.cs ]]; then
        cs_files+=("$file")
    elif [[ "$file" == *.py ]]; then
        py_files+=("$file")
    fi
done < <(find "$scan_root" \
  \( -name "*.cs" -o -name "*.py" \) \
  -not -path "*/.git/*" \
  -not -path "*/node_modules/*" \
  -not -path "*/venv/*" \
  -not -path "*/.venv/*" \
  -not -path "*/env/*" \
  -not -path "*/__pycache__/*" \
  -not -path "*/site-packages/*" \
  -not -path "*/scripts/audit/tests/*" \
  -not -path "*/scripts/security/fixtures/*" \
  -print0)

echo "Found ${#cs_files[@]} C# files and ${#py_files[@]} Python files"

# Check C# files for SQL injection patterns
echo ""
echo "=== C# SQL Injection Patterns ==="

cs_patterns=(
    "string\.Format.*SELECT"
    "string\.Format.*INSERT"
    "string\.Format.*UPDATE"
    "string\.Format.*DELETE"
    "\$\".*SELECT"
    "\$\".*INSERT"
    "\$\".*UPDATE"
    "\$\".*DELETE"
    "string\.Concat.*SELECT"
    "string\.Concat.*INSERT"
    "string\.Concat.*UPDATE"
    "string\.Concat.*DELETE"
    "ExecuteNonQuery.*\+"
    "ExecuteReader.*\+"
    "ExecuteScalar.*\+"
    "FromSqlRaw.*\+"
    "FromSqlInterpolated.*\$"
)

for file in "${cs_files[@]}"; do
    for pattern in "${cs_patterns[@]}"; do
        if grep -E "$pattern" "$file" >/dev/null 2>&1; then
            echo "❌ C# SQLi pattern in $file: $pattern"
            grep -n -E "$pattern" "$file" | head -5
            violations=$((violations + 1))
        fi
    done
done

# Check Python files for SQL injection patterns
echo ""
echo "=== Python SQL Injection Patterns ==="

py_patterns=(
    "f\".*SELECT"
    "f\".*INSERT"
    "f\".*UPDATE"
    "f\".*DELETE"
    "\".*%.*SELECT"
    "\".*%.*INSERT"
    "\".*%.*UPDATE"
    "\".*%.*DELETE"
    "'.*%.*SELECT"
    "'.*%.*INSERT"
    "'.*%.*UPDATE"
    "'.*%.*DELETE"
    "\.format.*SELECT"
    "\.format.*INSERT"
    "\.format.*UPDATE"
    "\.format.*DELETE"
    "execute.*\+"
    "executemany.*\+"
    "cursor\.execute.*\+"
    "psycopg2\.extras\.execute_values.*\+"
)

for file in "${py_files[@]}"; do
    for pattern in "${py_patterns[@]}"; do
        if grep -E "$pattern" "$file" >/dev/null 2>&1; then
            echo "❌ Python SQLi pattern in $file: $pattern"
            grep -n -E "$pattern" "$file" | head -5
            violations=$((violations + 1))
        fi
    done
done

# Check for proper parameterized query usage
echo ""
echo "=== Parameterized Query Verification ==="

# C# parameterized patterns
cs_safe_patterns=(
    "Query<.*>.*new.*{.*}"
    "ExecuteSqlCommand.*new.*SqlParameter"
    "FromSqlRaw.*@.*"
    "ExecuteReader.*Parameters\.Add"
    "ExecuteNonQuery.*Parameters\.Add"
)

# Python parameterized patterns
py_safe_patterns=(
    "cursor\.execute.*%s"
    "cursor\.execute.*%.*s"
    "psycopg2\.extras\.execute_values.*%s"
    "asyncpg\.execute.*\$[0-9]"
    "text.*bindparams"
)

safe_usage_found=false

# Check for safe patterns in C#
for file in "${cs_files[@]}"; do
    for pattern in "${cs_safe_patterns[@]}"; do
        if grep -E "$pattern" "$file" >/dev/null 2>&1; then
            safe_usage_found=true
            break
        fi
    done
done

# Check for safe patterns in Python
for file in "${py_files[@]}"; do
    for pattern in "${py_safe_patterns[@]}"; do
        if grep -E "$pattern" "$file" >/dev/null 2>&1; then
            safe_usage_found=true
            break
        fi
    done
done

if [[ "$safe_usage_found" == false ]]; then
    echo "⚠️  No parameterized query patterns found"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "Files scanned: ${#cs_files[@]} C#, ${#py_files[@]} Python"
echo "Violations found: $violations"

if [[ "$violations" -gt 0 ]]; then
    echo "❌ SQL INJECTION BLOCK: Found $violations potential SQL injection vulnerabilities"
    exit 1
fi

echo "✅ Application-layer SQL injection check passed"
echo "✅ No dangerous string concatenation patterns found"

# Report statistics
echo ""
echo "=== Statistics ==="
echo "C# files scanned: ${#cs_files[@]}"
echo "Python files scanned: ${#py_files[@]}"
echo "Safe parameterized patterns found: $safe_usage_found"
