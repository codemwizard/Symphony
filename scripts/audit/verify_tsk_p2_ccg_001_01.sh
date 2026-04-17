#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

TASK_ID="TSK-P2-CCG-001-01"
GIT_SHA="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EVIDENCE_FILE="evidence/phase2/tsk_p2_ccg_001_01.json"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

# Run verification checks
status="PASS"
verifier_exists="false"
verifier_passes="false"
inv_159_status=""
inv_160_status=""
inv_161_status=""
inv_166_status=""
command_outputs=()
observed_paths=()
observed_hashes=()

# Check 1: Verifier script exists and is executable
if test -x scripts/audit/verify_core_contract_gate.sh; then
    verifier_exists="true"
    observed_paths+=("scripts/audit/verify_core_contract_gate.sh")
    observed_hashes+=("$(sha256sum scripts/audit/verify_core_contract_gate.sh | awk '{print $1}')")
else
    status="FAIL"
    command_outputs+=("verifier_exists: FAIL - script not found or not executable")
fi

# Check 2: Verifier passes on current code
if bash scripts/audit/verify_core_contract_gate.sh > /tmp/tsk_p2_ccg_001_01_output.txt 2>&1; then
    verifier_passes="true"
    command_outputs+=("verifier_passes: PASS")
else
    verifier_passes="false"
    status="FAIL"
    command_outputs+=("verifier_passes: FAIL - $(cat /tmp/tsk_p2_ccg_001_01_output.txt)")
fi

# Check 3: INV-159 status
inv_159_status=$(grep -A 5 "id: INV-159" docs/invariants/INVARIANTS_MANIFEST.yml | grep "status:" | awk '{print $2}' || echo "not_found")
if [[ "$inv_159_status" == "implemented" ]]; then
    inv_159_implemented="true"
    command_outputs+=("inv_159_status: implemented")
    observed_paths+=("docs/invariants/INVARIANTS_MANIFEST.yml")
    observed_hashes+=("$(sha256sum docs/invariants/INVARIANTS_MANIFEST.yml | awk '{print $1}')")
else
    inv_159_implemented="false"
    status="FAIL"
    command_outputs+=("inv_159_status: $inv_159_status (expected: implemented)")
fi

# Check 4: INV-160 status
inv_160_status=$(grep -A 5 "id: INV-160" docs/invariants/INVARIANTS_MANIFEST.yml | grep "status:" | awk '{print $2}' || echo "not_found")
if [[ "$inv_160_status" == "implemented" ]]; then
    inv_160_implemented="true"
    command_outputs+=("inv_160_status: implemented")
else
    inv_160_implemented="false"
    status="FAIL"
    command_outputs+=("inv_160_status: $inv_160_status (expected: implemented)")
fi

# Check 5: INV-161 status
inv_161_status=$(grep -A 5 "id: INV-161" docs/invariants/INVARIANTS_MANIFEST.yml | grep "status:" | awk '{print $2}' || echo "not_found")
if [[ "$inv_161_status" == "implemented" ]]; then
    inv_161_implemented="true"
    command_outputs+=("inv_161_status: implemented")
else
    inv_161_implemented="false"
    status="FAIL"
    command_outputs+=("inv_161_status: $inv_161_status (expected: implemented)")
fi

# Check 6: INV-166 status
inv_166_status=$(grep -A 5 "id: INV-166" docs/invariants/INVARIANTS_MANIFEST.yml | grep "status:" | awk '{print $2}' || echo "not_found")
if [[ "$inv_166_status" == "implemented" ]]; then
    inv_166_implemented="true"
    command_outputs+=("inv_166_status: implemented")
else
    inv_166_implemented="false"
    status="FAIL"
    command_outputs+=("inv_166_status: $inv_166_status (expected: implemented)")
fi

# Build execution trace
execution_trace="[
  {\"step\": \"check_verifier_exists\", \"status\": \"$verifier_exists\"},
  {\"step\": \"run_verifier\", \"status\": \"$verifier_passes\"},
  {\"step\": \"check_inv_159_status\", \"status\": \"$inv_159_implemented\"},
  {\"step\": \"check_inv_160_status\", \"status\": \"$inv_160_implemented\"},
  {\"step\": \"check_inv_161_status\", \"status\": \"$inv_161_implemented\"},
  {\"step\": \"check_inv_166_status\", \"status\": \"$inv_166_implemented\"}
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
    {"name": "inv_159_implemented", "status": "$inv_159_implemented"},
    {"name": "inv_160_implemented", "status": "$inv_160_implemented"},
    {"name": "inv_161_implemented", "status": "$inv_161_implemented"},
    {"name": "inv_166_implemented", "status": "$inv_166_implemented"}
  ],
  "verifier_path": "scripts/audit/verify_core_contract_gate.sh",
  "inv_159_status": "$inv_159_status",
  "inv_160_status": "$inv_160_status",
  "inv_161_status": "$inv_161_status",
  "inv_166_status": "$inv_166_status",
  "observed_paths": $(printf '%s\n' "${observed_paths[@]}" | jq -R . | jq -s .),
  "observed_hashes": $(printf '%s\n' "${observed_hashes[@]}" | jq -R . | jq -s .),
  "command_outputs": $(printf '%s\n' "${command_outputs[@]}" | jq -R . | jq -s .),
  "execution_trace": $execution_trace
}
EOL

rm -f /tmp/tsk_p2_ccg_001_01_output.txt

if [[ "$status" == "FAIL" ]]; then
    echo "Verification failed for $TASK_ID" >&2
    exit 1
fi

echo "Verification passed for $TASK_ID"
