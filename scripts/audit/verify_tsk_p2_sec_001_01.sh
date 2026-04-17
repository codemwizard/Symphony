#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

TASK_ID="TSK-P2-SEC-001-01"
GIT_SHA="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EVIDENCE_FILE="evidence/phase2/tsk_p2_sec_001_01.json"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

# Run verification checks
status="PASS"
verifier_exists="false"
grep_pattern_correct="false"
verifier_passes="false"
inv_130_status=""
command_outputs=()
observed_paths=()
observed_hashes=()

# Check 1: Verifier script exists and is executable
if test -x scripts/security/verify_supervisor_bind_localhost.sh; then
    verifier_exists="true"
    observed_paths+=("scripts/security/verify_supervisor_bind_localhost.sh")
    observed_hashes+=("$(sha256sum scripts/security/verify_supervisor_bind_localhost.sh | awk '{print $1}')")
else
    status="FAIL"
    command_outputs+=("verifier_exists: FAIL - script not found or not executable")
fi

# Check 2: Verifier contains exact grep pattern
if grep -q "grep -E 'HTTPServer" scripts/security/verify_supervisor_bind_localhost.sh; then
    grep_pattern_correct="true"
    command_outputs+=("grep_pattern_correct: PASS")
else
    grep_pattern_correct="false"
    status="FAIL"
    command_outputs+=("grep_pattern_correct: FAIL - pattern not found")
fi

# Check 3: Verifier passes on current code
if bash scripts/security/verify_supervisor_bind_localhost.sh > /tmp/tsk_p2_sec_001_01_output.txt 2>&1; then
    verifier_passes="true"
    command_outputs+=("verifier_passes: PASS")
    observed_paths+=("supervisor_api/server.py")
    if [[ -f "supervisor_api/server.py" ]]; then
        observed_hashes+=("$(sha256sum supervisor_api/server.py | awk '{print $1}')")
    fi
else
    verifier_passes="false"
    status="FAIL"
    command_outputs+=("verifier_passes: FAIL - $(cat /tmp/tsk_p2_sec_001_01_output.txt)")
fi

# Check 4: INV-130 status
inv_130_status=$(grep -A 5 "id: INV-130" docs/invariants/INVARIANTS_MANIFEST.yml | grep "status:" | awk '{print $2}' || echo "not_found")
if [[ "$inv_130_status" == "implemented" ]]; then
    inv_130_implemented="true"
    command_outputs+=("inv_130_status: implemented")
    observed_paths+=("docs/invariants/INVARIANTS_MANIFEST.yml")
    observed_hashes+=("$(sha256sum docs/invariants/INVARIANTS_MANIFEST.yml | awk '{print $1}')")
else
    inv_130_implemented="false"
    status="FAIL"
    command_outputs+=("inv_130_status: $inv_130_status (expected: implemented)")
fi

# Build execution trace
execution_trace="[
  {\"step\": \"check_verifier_exists\", \"status\": \"$verifier_exists\"},
  {\"step\": \"check_grep_pattern\", \"status\": \"$grep_pattern_correct\"},
  {\"step\": \"run_verifier\", \"status\": \"$verifier_passes\"},
  {\"step\": \"check_inv_130_status\", \"status\": \"$inv_130_implemented\"}
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
    {"name": "grep_pattern_correct", "status": "$grep_pattern_correct"},
    {"name": "verifier_passes", "status": "$verifier_passes"},
    {"name": "inv_130_implemented", "status": "$inv_130_implemented"}
  ],
  "verifier_path": "scripts/security/verify_supervisor_bind_localhost.sh",
  "inv_130_status": "$inv_130_status",
  "observed_paths": $(printf '%s\n' "${observed_paths[@]}" | jq -R . | jq -s .),
  "observed_hashes": $(printf '%s\n' "${observed_hashes[@]}" | jq -R . | jq -s .),
  "command_outputs": $(printf '%s\n' "${command_outputs[@]}" | jq -R . | jq -s .),
  "execution_trace": $execution_trace
}
EOL

rm -f /tmp/tsk_p2_sec_001_01_output.txt

if [[ "$status" == "FAIL" ]]; then
    echo "Verification failed for $TASK_ID" >&2
    exit 1
fi

echo "Verification passed for $TASK_ID"
