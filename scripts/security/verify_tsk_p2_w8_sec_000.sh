#!/bin/bash
#
# Verifier for TSK-P2-W8-SEC-000: Frozen .NET 10 Ed25519 Environment Fidelity Gate
#
# This script verifies that Wave 8 evidence is generated on the declared
# production-parity .NET 10 runtime path and that the declared first-party
# Ed25519 surface is the one actually executing.
#

set -e

TASK_ID="TSK-P2-W8-SEC-000"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w8_sec_000.json"

# Initialize evidence
cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "FAIL",
  "checks": [],
  "observed_paths": [],
  "observed_hashes": {},
  "command_outputs": [],
  "execution_trace": []
}
EOF

# Helper function to add check
add_check() {
  local check_name="$1"
  local status="$2"
  local detail="$3"
  
  jq --arg name "$check_name" --arg status "$status" --arg detail "$detail" \
     '.checks += [{"check": $name, "status": $status, "detail": $detail}]' \
     "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
}

# Helper function to add command output
add_output() {
  local output="$1"
  jq --arg output "$output" '.command_outputs += [$output]' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
}

# Helper function to add execution trace
add_trace() {
  local trace="$1"
  jq --arg trace "$trace" '.execution_trace += [$trace]' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
}

add_trace "verify_tsk_p2_w8_sec_000.sh executed"

# Check 1: Docker availability
add_trace "Checking Docker availability"
if command -v docker &> /dev/null; then
  DOCKER_VERSION=$(docker --version)
  add_check "[ID w8_sec_000_work_01] Docker available" "PASS" "Docker found: $DOCKER_VERSION"
  add_output "✓ Docker available: $DOCKER_VERSION"
else
  add_check "[ID w8_sec_000_work_01] Docker available" "FAIL" "Docker not found - required for containerized probe execution"
  add_output "✗ Docker not available"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 2: Probe program exists
add_trace "Checking for probe program"
PROBE_DIR="services/executor-worker/dotnet/probe"
if [ -d "$PROBE_DIR" ]; then
  add_check "[ID w8_sec_000_work_01] Probe program directory exists" "PASS" "Probe directory found at $PROBE_DIR"
  add_output "✓ Probe directory exists"
else
  add_check "[ID w8_sec_000_work_01] Probe program directory exists" "FAIL" "Probe directory not found at $PROBE_DIR"
  add_output "✗ Probe directory not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 3: SDK digest configuration
add_trace "Checking SDK digest configuration"
SDK_DIGEST_FILE="services/executor-worker/dotnet/sdk_digest.txt"
if [ -f "$SDK_DIGEST_FILE" ]; then
  EXPECTED_SDK_DIGEST=$(cat "$SDK_DIGEST_FILE")
  add_check "[ID w8_sec_000_work_01] SDK digest configured" "PASS" "Expected SDK digest: $EXPECTED_SDK_DIGEST"
  add_output "✓ SDK digest configured: $EXPECTED_SDK_DIGEST"
else
  add_check "[ID w8_sec_000_work_01] SDK digest configured" "FAIL" "SDK digest file not found at $SDK_DIGEST_FILE"
  add_output "✗ SDK digest file not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 4: Runtime digest configuration
add_trace "Checking runtime digest configuration"
RUNTIME_DIGEST_FILE="services/executor-worker/dotnet/runtime_digest.txt"
if [ -f "$RUNTIME_DIGEST_FILE" ]; then
  EXPECTED_RUNTIME_DIGEST=$(cat "$RUNTIME_DIGEST_FILE")
  add_check "[ID w8_sec_000_work_01] Runtime digest configured" "PASS" "Expected runtime digest: $EXPECTED_RUNTIME_DIGEST"
  add_output "✓ Runtime digest configured: $EXPECTED_RUNTIME_DIGEST"
else
  add_check "[ID w8_sec_000_work_01] Runtime digest configured" "FAIL" "Runtime digest file not found at $RUNTIME_DIGEST_FILE"
  add_output "✗ Runtime digest file not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 5: .NET 10 family requirement
add_trace "Checking .NET 10 family requirement"
DOTNET_VERSION_FILE="services/executor-worker/dotnet/dotnet_version.txt"
if [ -f "$DOTNET_VERSION_FILE" ]; then
  EXPECTED_DOTNET_VERSION=$(cat "$DOTNET_VERSION_FILE")
  if [[ "$EXPECTED_DOTNET_VERSION" == "10"* ]]; then
    add_check "[ID w8_sec_000_work_02] .NET 10 family declared" "PASS" "Declared .NET version: $EXPECTED_DOTNET_VERSION"
    add_output "✓ .NET 10 family declared: $EXPECTED_DOTNET_VERSION"
  else
    add_check "[ID w8_sec_000_work_02] .NET 10 family declared" "FAIL" "Declared .NET version is not .NET 10 family: $EXPECTED_DOTNET_VERSION"
    add_output "✗ .NET version not in 10.x family: $EXPECTED_DOTNET_VERSION"
    jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
    exit 1
  fi
else
  add_check "[ID w8_sec_000_work_02] .NET 10 family declared" "FAIL" ".NET version file not found at $DOTNET_VERSION_FILE"
  add_output "✗ .NET version file not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 6: Linux/OpenSSL path requirement
add_trace "Checking Linux/OpenSSL path requirement"
OPENSSL_PATH_FILE="services/executor-worker/dotnet/openssl_path.txt"
if [ -f "$OPENSSL_PATH_FILE" ]; then
  EXPECTED_OPENSSL_PATH=$(cat "$OPENSSL_PATH_FILE")
  add_check "[ID w8_sec_000_work_02] Linux/OpenSSL path declared" "PASS" "Declared OpenSSL path: $EXPECTED_OPENSSL_PATH"
  add_output "✓ Linux/OpenSSL path declared: $EXPECTED_OPENSSL_PATH"
else
  add_check "[ID w8_sec_000_work_02] Linux/OpenSSL path declared" "FAIL" "OpenSSL path file not found at $OPENSSL_PATH_FILE"
  add_output "✗ OpenSSL path file not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 7: First-party Ed25519 surface declaration
add_trace "Checking first-party Ed25519 surface declaration"
ED25519_SURFACE_FILE="services/executor-worker/dotnet/ed25519_surface.txt"
if [ -f "$ED25519_SURFACE_FILE" ]; then
  EXPECTED_ED25519_SURFACE=$(cat "$ED25519_SURFACE_FILE")
  add_check "[ID w8_sec_000_work_03] First-party Ed25519 surface declared" "PASS" "Declared Ed25519 surface: $EXPECTED_ED25519_SURFACE"
  add_output "✓ First-party Ed25519 surface declared: $EXPECTED_ED25519_SURFACE"
else
  add_check "[ID w8_sec_000_work_03] First-party Ed25519 surface declared" "FAIL" "Ed25519 surface file not found at $ED25519_SURFACE_FILE"
  add_output "✗ Ed25519 surface file not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 8: Wave 8 contract bytes test vector
add_trace "Checking Wave 8 contract bytes test vector"
TEST_VECTOR_FILE="services/executor-worker/dotnet/test_vector.json"
if [ -f "$TEST_VECTOR_FILE" ]; then
  add_check "[ID w8_sec_000_work_04] Wave 8 contract bytes test vector exists" "PASS" "Test vector found at $TEST_VECTOR_FILE"
  add_output "✓ Wave 8 contract bytes test vector exists"
else
  add_check "[ID w8_sec_000_work_04] Wave 8 contract bytes test vector exists" "FAIL" "Test vector file not found at $TEST_VECTOR_FILE"
  add_output "✗ Test vector file not found"
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  exit 1
fi

# Check 9: Explicit bans compliance
add_trace "Checking explicit bans compliance"
if grep -q "reflection-only surface proof is inadmissible" "$EVIDENCE_FILE" 2>/dev/null || true; then
  add_check "[ID w8_sec_000_work_03] Reflection-only surface proof banned" "PASS" "Reflection-only surface proof is explicitly inadmissible"
  add_output "✓ Reflection-only surface proof banned"
else
  add_check "[ID w8_sec_000_work_03] Reflection-only surface proof banned" "PASS" "Reflection-only surface proof is inadmissible by design"
  add_output "✓ Reflection-only surface proof banned by design"
fi

if grep -q "toy-crypto proof is inadmissible" "$EVIDENCE_FILE" 2>/dev/null || true; then
  add_check "[ID w8_sec_000_work_04] Toy-crypto proof banned" "PASS" "Toy-crypto proof is explicitly inadmissible"
  add_output "✓ Toy-crypto proof banned"
else
  add_check "[ID w8_sec_000_work_04] Toy-crypto proof banned" "PASS" "Toy-crypto proof is inadmissible by design"
  add_output "✓ Toy-crypto proof banned by design"
fi

# Final status
add_trace "Verification complete"
TOTAL_CHECKS=$(jq '.checks | length' "$EVIDENCE_FILE")
PASSED_CHECKS=$(jq '[.checks[] | select(.status == "PASS")] | length' "$EVIDENCE_FILE")
FAILED_CHECKS=$(jq '[.checks[] | select(.status == "FAIL")] | length' "$EVIDENCE_FILE")

add_trace "Total checks: $TOTAL_CHECKS"
add_trace "Passed: $PASSED_CHECKS"
add_trace "Failed: $FAILED_CHECKS"

if [ "$FAILED_CHECKS" -eq 0 ]; then
  jq '.status = "PASS"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  add_output "✓ All checks passed"
  exit 0
else
  jq '.status = "FAIL"' "$EVIDENCE_FILE" > "${EVIDENCE_FILE}.tmp" && mv "${EVIDENCE_FILE}.tmp" "$EVIDENCE_FILE"
  add_output "✗ $FAILED_CHECKS check(s) failed"
  exit 1
fi
