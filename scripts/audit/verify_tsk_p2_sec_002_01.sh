#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

TASK_ID="TSK-P2-SEC-002-01"
GIT_SHA="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EVIDENCE_FILE="evidence/phase2/tsk_p2_sec_002_01.json"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

# Run verification checks
status="PASS"
verifier_exists="false"
verifier_passes="false"
inv_131_status=""
command_outputs=()
observed_paths=()
observed_hashes=()

# Check 1: Verifier script exists and is executable
if test -x scripts/audit/test_admin_endpoints_require_key.sh; then
    verifier_exists="true"
    observed_paths+=("scripts/audit/test_admin_endpoints_require_key.sh")
    observed_hashes+=("$(sha256sum scripts/audit/test_admin_endpoints_require_key.sh | awk '{print $1}')")
else
    status="FAIL"
    command_outputs+=("verifier_exists: FAIL - script not found or not executable")
fi

# Check 2: Run the actual verifier
if bash scripts/audit/test_admin_endpoints_require_key.sh > /tmp/tsk_p2_sec_002_01_output.txt 2>&1; then
    verifier_passes="true"
    command_outputs+=("verifier_passes: PASS")
    observed_paths+=("services/ledger-api/dotnet/src/LedgerApi/Program.cs")
    if [[ -f "services/ledger-api/dotnet/src/LedgerApi/Program.cs" ]]; then
        observed_hashes+=("$(sha256sum services/ledger-api/dotnet/src/LedgerApi/Program.cs | awk '{print $1}')")
    fi
else
    verifier_passes="false"
    status="FAIL"
    command_outputs+=("verifier_passes: FAIL - $(cat /tmp/tsk_p2_sec_002_01_output.txt)")
fi

# Check 3: INV-131 status
inv_131_status=$(grep -A 5 "id: INV-131" docs/invariants/INVARIANTS_MANIFEST.yml | grep "status:" | awk '{print $2}' || echo "not_found")
if [[ "$inv_131_status" == "implemented" ]]; then
    inv_131_implemented="true"
    command_outputs+=("inv_131_status: implemented")
    observed_paths+=("docs/invariants/INVARIANTS_MANIFEST.yml")
    observed_hashes+=("$(sha256sum docs/invariants/INVARIANTS_MANIFEST.yml | awk '{print $1}')")
else
    inv_131_implemented="false"
    status="FAIL"
    command_outputs+=("inv_131_status: $inv_131_status (expected: implemented)")
fi

# Build execution trace
execution_trace="[
  {\"step\": \"check_verifier_exists\", \"status\": \"$verifier_exists\"},
  {\"step\": \"run_verifier\", \"status\": \"$verifier_passes\"},
  {\"step\": \"check_inv_131_status\", \"status\": \"$inv_131_implemented\"}
]"

# Write evidence
cat > "$EVIDENCE_FILE" << EOL
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "$status",
  "checks": [
    {"name": "verifier_exists", "status": "$verifier_exists"},
    {"name": "verifier_passes", "status": "$verifier_passes"},
    {"name": "inv_131_implemented", "status": "$inv_131_implemented"}
  ],
  "verifier_path": "scripts/audit/test_admin_endpoints_require_key.sh",
  "inv_131_status": "$inv_131_status",
  "observed_paths": $(printf '%s\n' "${observed_paths[@]}" | jq -R . | jq -s .),
  "observed_hashes": $(printf '%s\n' "${observed_hashes[@]}" | jq -R . | jq -s .),
  "command_outputs": $(printf '%s\n' "${command_outputs[@]}" | jq -R . | jq -s .),
  "execution_trace": $execution_trace
}
EOL

rm -f /tmp/tsk_p2_sec_002_01_output.txt

if [[ "$status" == "FAIL" ]]; then
    echo "Verification failed for $TASK_ID" >&2
    exit 1
fi

echo "Verification passed for $TASK_ID"
