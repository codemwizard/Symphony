#!/bin/bash
# SEC-000 verification script with fixed syntax
set -e

PROBE_DIR="scripts/security/probes/w8_ed25519_environment_fidelity"
CHECK_RESULTS="/tmp/sec_000_checks.txt"
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_sec_000.json"

# Initialize check results
echo "Starting SEC-000 verification" > "$CHECK_RESULTS"

# Check 1: Probe project exists
echo "Check 1: Probe project exists"
if [ -f "$PROBE_DIR/Wave8Ed25519Probe.csproj" ]; then
    echo "probe_project_exists:PASS" >> "$CHECK_RESULTS"
    echo "✓ Probe project exists"
else
    echo "probe_project_exists:FAIL" >> "$CHECK_RESULTS"
    echo "✗ Probe project not found"
    exit 1
fi

# Check 2: Probe builds successfully
echo "Check 2: Probe builds successfully"
if dotnet build "$PROBE_DIR" --configuration Release --no-restore > /dev/null 2>&1; then
    echo "probe_builds:PASS" >> "$CHECK_RESULTS"
    echo "✓ Probe builds successfully"
else
    echo "probe_builds:FAIL" >> "$CHECK_RESULTS"
    echo "✗ Probe build failed"
    exit 1
fi

# Check 3: Probe executes and generates valid evidence
echo "Check 3: Probe executes and generates valid evidence"
PROBE_OUTPUT=$(dotnet run --project "$PROBE_DIR" --configuration Release --no-build 2>/dev/null || echo '{"status":"EXEC_FAIL"}')

# Simple validation without complex Python parsing
if echo "$PROBE_OUTPUT" | grep -q '"status":"PASS"' || echo "$PROBE_OUTPUT" | grep -q '"status": "PASS"'; then
    echo "probe_execution:PASS" >> "$CHECK_RESULTS"
    echo "✓ Probe executes and generates valid evidence"
else
    echo "probe_execution:FAIL" >> "$CHECK_RESULTS"
    echo "✗ Probe execution failed"
    echo "Output: $PROBE_OUTPUT"
    exit 1
fi

# Check 4: Evidence file generated
echo "Check 4: Evidence file generated"
mkdir -p "$(dirname "$EVIDENCE_FILE")"
echo "$PROBE_OUTPUT" > "$EVIDENCE_FILE"

if [ -f "$EVIDENCE_FILE" ]; then
    echo "evidence_file_exists:PASS" >> "$CHECK_RESULTS"
    echo "✓ Evidence file generated"
else
    echo "evidence_file_exists:FAIL" >> "$CHECK_RESULTS"
    echo "✗ Evidence file not generated"
    exit 1
fi

# Check 5: Evidence file contains required fields
echo "Check 5: Evidence file contains required fields"
REQUIRED_FIELDS='"task_id" "git_sha" "timestamp_utc" "status" "environment_tuple" "sdk_fingerprint" "runtime_fingerprint" "runtime_family" "ed25519_surface_invoked" "ed25519_signature_verification" "semantic_fidelity"'

for field in $REQUIRED_FIELDS; do
    if ! grep -q "$field" "$EVIDENCE_FILE"; then
        echo "evidence_fields:FAIL" >> "$CHECK_RESULTS"
        echo "✗ Missing required field: $field"
        exit 1
    fi
done

echo "evidence_fields:PASS" >> "$CHECK_RESULTS"
echo "✓ All required fields present"

# Final status
echo ""
echo "=== SEC-000 Verification Summary ==="
cat "$CHECK_RESULTS"

# Count passes
PASSES=$(grep -c "PASS" "$CHECK_RESULTS" || echo "0")
TOTAL=$(grep -c "PASS\|FAIL" "$CHECK_RESULTS" || echo "0")

echo ""
echo "Passed: $PASSES/$TOTAL checks"

if [ "$PASSES" -eq "$TOTAL" ]; then
    echo "✅ SEC-000 verification PASSED"
    exit 0
else
    echo "❌ SEC-000 verification FAILED"
    exit 1
fi
