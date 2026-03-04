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

echo "Validating enforcement mappings..."
if ! python3 - <<'PY'
import sys
import yaml
from pathlib import Path

path = Path("docs/contracts/SECURITY_ENFORCEMENT_MAP.yml")
data = yaml.safe_load(path.read_text())

mappings = data.get("enforcement_mappings", [])
if not mappings:
    print("❌ No enforcement mappings found")
    sys.exit(1)
print(f"✅ Found {len(mappings)} enforcement mappings")

required_fields = ["policy_id", "title", "enforcement_type", "languages", "tools", "ci_gate"]
for idx, mapping in enumerate(mappings, start=1):
    missing = [f for f in required_fields if f not in mapping]
    if missing:
        print(f"❌ enforcement_mappings[{idx}] missing field(s): {', '.join(missing)}")
        sys.exit(1)
    if not mapping.get("tools"):
        print(f"❌ enforcement_mappings[{idx}] has empty tools list")
        sys.exit(1)

ci_gates = data.get("ci_gates", [])
security_scan = next((g for g in ci_gates if g.get("name") == "security_scan"), None)
if not security_scan:
    print("❌ security_scan CI gate not found")
    sys.exit(1)
if security_scan.get("fail_closed") is not True:
    print("❌ security_scan fail_closed is not true")
    sys.exit(1)
print("✅ CI gate configuration valid")

param_req = data.get("parameterization_requirements", {})
if "database_access" not in param_req:
    print("❌ database_access parameterization requirements missing")
    sys.exit(1)
frameworks = param_req.get("frameworks", {})
if "cs" not in frameworks or "py" not in frameworks:
    print("❌ parameterization frameworks must include cs and py")
    sys.exit(1)
print("✅ Parameterization requirements valid")
print("✅ Enforcement mappings have required fields")
PY
then
    exit 1
fi

echo ""
echo "✅ SECURITY_ENFORCEMENT_MAP.yml validation passed"
echo "✅ All required sections and fields present"
echo "✅ C# and Python language coverage confirmed"
echo "✅ CI gate fail-closed configuration verified"
