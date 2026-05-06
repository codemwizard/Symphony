#!/bin/bash

# TSK-P2-W8-SEC-000 Verification Script
# Verifies .NET 10 Ed25519 environment fidelity gate

set -euo pipefail

TASK_ID="TSK-P2-W8-SEC-000"
EVIDENCE_PATH="evidence/phase2/tsk_p2_w8_sec_000.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

echo "=== TSK-P2-W8-SEC-000 Verification ==="
echo "Task ID: $TASK_ID"
echo "Git SHA: $GIT_SHA"
echo "Timestamp: $TIMESTAMP"

CHECK_RESULTS_FILE=$(mktemp)
trap 'rm -f "$CHECK_RESULTS_FILE"' EXIT

# Check 1: Probe project exists
echo "Check 1: Probe project exists"
if [ -f "scripts/security/probes/w8_ed25519_environment_fidelity/Wave8Ed25519Probe.csproj" ]; then
    echo "probe_project_exists:PASS" >> "$CHECK_RESULTS_FILE"
    echo "✓ Probe project file exists"
else
    echo "probe_project_exists:FAIL" >> "$CHECK_RESULTS_FILE"
    echo "✗ Probe project file missing"
fi

# Check 2: Probe program exists
echo "Check 2: Probe program exists"
if [ -f "scripts/security/probes/w8_ed25519_environment_fidelity/Program.cs" ]; then
    echo "probe_program_exists:PASS" >> "$CHECK_RESULTS_FILE"
    echo "✓ Probe program file exists"
else
    echo "probe_program_exists:FAIL" >> "$CHECK_RESULTS_FILE"
    echo "✗ Probe program file missing"
fi

# Check 3: Probe builds successfully
echo "Check 3: Probe builds successfully"
PROBE_DIR="scripts/security/probes/w8_ed25519_environment_fidelity"
if dotnet build "$PROBE_DIR" --configuration Release --verbosity quiet > /dev/null 2>&1; then
    echo "probe_builds:PASS" >> "$CHECK_RESULTS_FILE"
    echo "✓ Probe builds successfully"
else
    echo "probe_builds:FAIL" >> "$CHECK_RESULTS_FILE"
    echo "✗ Probe build failed"
fi

# Check 4: Probe executes and generates valid evidence
echo "Check 4: Probe executes and generates valid evidence"
PROBE_OUTPUT=$(dotnet run --project "$PROBE_DIR" --configuration Release --no-build 2>/dev/null || echo '{"status":"EXEC_FAIL"}')

if echo "$PROBE_OUTPUT" | python3 -c "
import sys
import json
try:
    data = json.load(sys.stdin)
    required_fields = ['task_id', 'git_sha', 'timestamp_utc', 'status', 'environment_tuple', 'sdk_fingerprint', 'runtime_fingerprint', 'runtime_family', 'ed25519_surface_invoked', 'ed25519_signature_verification', 'semantic_fidelity']
    missing_fields = [field for field in required_fields if field not in data]
    
    if missing_fields:
        sys.exit(1)
    
    if data.get('status') != 'PASS':
        sys.exit(1)
    
    if not data.get('ed25519_surface_invoked', False):
        sys.exit(1)
    
    if not data.get('ed25519_signature_verification', False):
        sys.exit(1)
    
    # Validate semantic fidelity
    semantic = data.get('semantic_fidelity', {})
    if not semantic.get('passes', False):
        sys.exit(1)
    
    sys.exit(0)
except Exception:
    sys.exit(1)
"; then
    echo "probe_execution:PASS" >> "$CHECK_RESULTS_FILE"
    echo "✓ Probe executes and generates valid evidence"
else
    echo "probe_execution:FAIL" >> "$CHECK_RESULTS_FILE"
    echo "✗ Probe execution failed"
fi

# Generate evidence JSON
echo "Generating evidence JSON..."
mkdir -p "$(dirname "$EVIDENCE_PATH")"

python3 - "$TASK_ID" "$GIT_SHA" "$TIMESTAMP" "$CHECK_RESULTS_FILE" "$EVIDENCE_PATH" "$PROBE_DIR" << 'PYTHON_EOF'
import json
import os
import subprocess
import sys
import hashlib

task_id = sys.argv[1]
git_sha = sys.argv[2]
timestamp = sys.argv[3]
check_results_file = sys.argv[4]
evidence_path = sys.argv[5]
probe_dir = sys.argv[6]

# Read check results from temp file
check_results = []
try:
    with open(check_results_file, 'r') as f:
        check_results = [line.strip() for line in f if line.strip()]
except Exception:
    pass

def check_status(check_name):
    for result in check_results:
        if result.startswith(f"{check_name}:"):
            return result.split(":", 1)[1]
    return "FAIL"

# Run probe to capture its JSON output
try:
    probe_result = subprocess.run(
        ['dotnet', 'run', '--project', probe_dir, '--configuration', 'Release', '--no-build'],
        capture_output=True,
        text=True,
        timeout=60
    )
    probe_data = json.loads(probe_result.stdout)
except Exception as e:
    probe_data = {"status": "FAIL", "error": str(e)}

# Determine overall status
all_pass = all("PASS" in r for r in check_results) and probe_data.get("status") == "PASS"

# Compute file hashes
def file_sha256(path):
    try:
        h = hashlib.sha256()
        with open(path, 'rb') as f:
            for chunk in iter(lambda: f.read(8192), b''):
                h.update(chunk)
        return h.hexdigest()
    except Exception:
        return "hash_error"

csproj_path = os.path.join(probe_dir, "Wave8Ed25519Probe.csproj")
program_path = os.path.join(probe_dir, "Program.cs")

evidence = {
    "task_id": task_id,
    "git_sha": git_sha,
    "timestamp_utc": timestamp,
    "status": "PASS" if all_pass else "FAIL",
    "checks": [
        {"check": "probe_project_exists", "status": check_status("probe_project_exists")},
        {"check": "probe_program_exists", "status": check_status("probe_program_exists")},
        {"check": "probe_builds", "status": check_status("probe_builds")},
        {"check": "probe_execution", "status": check_status("probe_execution")}
    ],
    "observed_paths": [csproj_path, program_path],
    "observed_hashes": {
        "Wave8Ed25519Probe.csproj": file_sha256(csproj_path),
        "Program.cs": file_sha256(program_path)
    },
    "execution_trace": [
        "verify_tsk_p2_w8_sec_000.sh executed",
        f"Passed: {sum(1 for r in check_results if 'PASS' in r)}",
        f"Failed: {sum(1 for r in check_results if 'FAIL' in r)}"
    ],
    "probe_data": probe_data
}

with open(evidence_path, 'w') as f:
    json.dump(evidence, f, indent=2)

print(f"Status: {evidence['status']}")
PYTHON_EOF

echo "=== Verification Complete ==="
echo "Evidence written to: $EVIDENCE_PATH"
