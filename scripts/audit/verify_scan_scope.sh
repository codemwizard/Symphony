#!/bin/bash
# verify_scan_scope.sh
# Verify that python-present => scanned and csharp-present => scanned

set -euo pipefail

echo "=== Verifying Scan Scope Coverage ==="

# Count language files in repository (git-tracked only for deterministic parity)
cs_files=$(git ls-files '*.cs' | wc -l)
py_files=$(git ls-files '*.py' | wc -l)

echo "Language files found:"
echo "  C# files: $cs_files"
echo "  Python files: $py_files"

# Check CI configuration for required scanners
CI_WORKFLOW=".github/workflows/invariants.yml"
if [[ ! -f "$CI_WORKFLOW" ]]; then
    echo "❌ CI workflow file not found: $CI_WORKFLOW"
    exit 1
fi

security_scan_run_text="$(
CI_WORKFLOW="$CI_WORKFLOW" python3 - <<'PY'
import os
from pathlib import Path
import yaml

wf = Path(os.environ["CI_WORKFLOW"])
doc = yaml.safe_load(wf.read_text(encoding="utf-8")) or {}
jobs = doc.get("jobs") or {}
sec = jobs.get("security_scan")
if not isinstance(sec, dict):
    print("")
    raise SystemExit(0)
steps = sec.get("steps") or []
print("\n".join((s.get("run") or "") for s in steps if isinstance(s, dict)))
PY
)"

echo ""
echo "=== Checking CI Scanner Coverage ==="

if [[ "$cs_files" -gt 0 ]]; then
    echo "C# files present, checking for C# scanners..."
    
    if echo "$security_scan_run_text" | grep -q "semgrep"; then
        echo "✅ Semgrep found (covers C#)"
    else
        echo "❌ Semgrep not found in security_scan (required for C#)"
        exit 1
    fi
    
    if echo "$security_scan_run_text" | grep -q "lint_app_sql_injection"; then
        echo "✅ Application SQL injection lint found (covers C#)"
    else
        echo "❌ Application SQL injection lint not found (required for C#)"
        exit 1
    fi
else
    echo "✅ No C# files found, C# scanning not required"
fi

if [[ "$py_files" -gt 0 ]]; then
    echo "Python files present, checking for Python scanners..."
    
    if echo "$security_scan_run_text" | grep -q "semgrep"; then
        echo "✅ Semgrep found (covers Python)"
    else
        echo "❌ Semgrep not found in security_scan (required for Python)"
        exit 1
    fi
    
    if echo "$security_scan_run_text" | grep -q "lint_app_sql_injection"; then
        echo "✅ Application SQL injection lint found (covers Python)"
    else
        echo "❌ Application SQL injection lint not found (required for Python)"
        exit 1
    fi
else
    echo "✅ No Python files found, Python scanning not required"
fi

# Check for scanner script availability
echo ""
echo "=== Checking Scanner Script Availability ==="

required_scripts=(
    "scripts/security/lint_app_sql_injection.sh"
    "scripts/security/scan_secrets.sh"
    "scripts/security/lint_security_definer_search_path.sh"
)

for script in "${required_scripts[@]}"; do
    if [[ -f "$script" ]]; then
        if [[ -x "$script" ]]; then
            echo "✅ $script exists and executable"
        else
            echo "❌ $script exists but not executable"
            exit 1
        fi
    else
        echo "❌ $script not found"
        exit 1
    fi
done

# Check Semgrep rules availability
echo ""
echo "=== Checking Semgrep Rules ==="

if [[ -f "security/semgrep/rules.yml" ]]; then
    echo "✅ Semgrep rules file exists"
    
    # Count rules for each language
    cs_rules=$(grep -c "languages: \[csharp\]" security/semgrep/rules.yml || true)
    py_rules=$(grep -c "languages: \[python\]" security/semgrep/rules.yml || true)
    
    echo "Semgrep rules count:"
    echo "  C# rules: $cs_rules"
    echo "  Python rules: $py_rules"
    
    if [[ "$cs_files" -gt 0 && "$cs_rules" -eq 0 ]]; then
        echo "❌ C# files present but no C# Semgrep rules"
        exit 1
    fi
    
    if [[ "$py_files" -gt 0 && "$py_rules" -eq 0 ]]; then
        echo "❌ Python files present but no Python Semgrep rules"
        exit 1
    fi
    
    echo "✅ Semgrep rule coverage adequate"
else
    echo "❌ Semgrep rules file not found"
    exit 1
fi

echo ""
echo "=== Summary ==="
echo "✅ Language presence verified"
echo "✅ Scanner coverage verified"
echo "✅ Script availability verified"
echo "✅ Semgrep rules verified"
echo "✅ Scan scope contract enforced"
