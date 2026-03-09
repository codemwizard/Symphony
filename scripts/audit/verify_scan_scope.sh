#!/bin/bash
# verify_scan_scope.sh
# Verify that python-present => scanned and csharp-present => scanned

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$ROOT_DIR/evidence/security/sec_002_scan_scope_truth.json"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

echo "=== Verifying Scan Scope Coverage ==="

required_roots=("services" "scripts")
cs_files=$(git ls-files '*.cs' | wc -l)
py_files=$(git ls-files '*.py' | wc -l)

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
echo "=== Checking Required Scan Roots ==="
semgrep_roots=$(python3 - <<'PY' "$ROOT_DIR/evidence/phase0/semgrep_sast.json"
import json,sys
from pathlib import Path
p=Path(sys.argv[1])
if not p.exists():
    print("")
    raise SystemExit(0)
data=json.loads(p.read_text(encoding="utf-8"))
print("\n".join(data.get("scanned_roots", [])))
PY
)
missing_roots=()
for root in "${required_roots[@]}"; do
    if git ls-files "$root/**" | grep -q .; then
        if ! printf '%s\n' "$semgrep_roots" | grep -qx "$root"; then
            echo "❌ Required root missing from semgrep evidence: $root"
            missing_roots+=("$root")
        else
            echo "✅ Required root scanned: $root"
        fi
    fi
done

if [[ "${#missing_roots[@]}" -gt 0 ]]; then
    exit 1
fi

python3 - <<'PY' "$EVIDENCE_FILE" "$cs_files" "$py_files" "${required_roots[@]}"
import json,sys
path=sys.argv[1]
cs=int(sys.argv[2]); py=int(sys.argv[3]); roots=sys.argv[4:]
payload={
  "task_id":"SEC-002",
  "status":"PASS",
  "pass": True,
  "languages":{"cs_files":cs,"py_files":py},
  "required_roots": roots,
}
with open(path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, indent=2)
    fh.write("\n")
PY

echo ""
echo "=== Summary ==="
echo "✅ Language presence verified"
echo "✅ Scanner coverage verified"
echo "✅ Script availability verified"
echo "✅ Semgrep rules verified"
echo "✅ Scan scope contract enforced"
