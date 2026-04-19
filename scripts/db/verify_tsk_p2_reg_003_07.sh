#!/bin/bash
# Verification script for TSK-P2-REG-003-07: Register INV-178

set -e

TASK_ID="TSK-P2-REG-003-07"
EVIDENCE_PATH="evidence/phase2/tsk_p2_reg_003_07.json"

# Create evidence directory if it doesn't exist
mkdir -p "$(dirname "$EVIDENCE_PATH")"

# Initialize evidence JSON
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$(git rev-parse HEAD)",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "in_progress",
  "checks": []
}
EOF

# Check 1: INV-178 exists in INVARIANTS_MANIFEST.yml
if grep -q "id: INV-178" docs/invariants/INVARIANTS_MANIFEST.yml; then
  jq '.checks += [{"check_id": "inv_178_exists", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "inv_178_exists", "status": "fail", "message": "INV-178 not found in INVARIANTS_MANIFEST.yml"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 2: INV-178 status is implemented
if grep -A 5 "id: INV-178" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: implemented"; then
  jq '.checks += [{"check_id": "inv_178_implemented", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "inv_178_implemented", "status": "fail", "message": "INV-178 status is not implemented"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 3: INV-178 severity is P0
if grep -A 5 "id: INV-178" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "severity: P0"; then
  jq '.checks += [{"check_id": "inv_178_severity_p0", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "inv_178_severity_p0", "status": "fail", "message": "INV-178 severity is not P0"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 4: INV-178 title is correct
if grep -A 5 "id: INV-178" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "Project DNSH spatial check"; then
  jq '.checks += [{"check_id": "inv_178_title_correct", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "inv_178_title_correct", "status": "fail", "message": "INV-178 title is not correct"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# All checks passed
jq '.status = "passed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.inv_178_registered = true' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.inv_178_status = "implemented"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.observed_paths = ["docs/invariants/INVARIANTS_MANIFEST.yml"]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.observed_hashes = {}' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.command_outputs = []' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.execution_trace = []' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"

echo "Verification passed for $TASK_ID"
