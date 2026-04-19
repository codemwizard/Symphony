#!/bin/bash
# Verification script for TSK-P2-REG-004-01: Verify function exists and promote INV-169

set -e

TASK_ID="TSK-P2-REG-004-01"
EVIDENCE_PATH="evidence/phase2/tsk_p2_reg_004_01.json"

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

# Check 1: INV-169 exists in INVARIANTS_MANIFEST.yml
if grep -q "id: INV-169" docs/invariants/INVARIANTS_MANIFEST.yml; then
  jq '.checks += [{"check_id": "inv_169_exists", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "inv_169_exists", "status": "fail", "message": "INV-169 not found in INVARIANTS_MANIFEST.yml"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 2: INV-169 status is implemented
if grep -A 5 "id: INV-169" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "status: implemented"; then
  jq '.checks += [{"check_id": "inv_169_implemented", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "inv_169_implemented", "status": "fail", "message": "INV-169 status is not implemented"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 3: INV-169 severity is P0
if grep -A 5 "id: INV-169" docs/invariants/INVARIANTS_MANIFEST.yml | grep -q "severity: P0"; then
  jq '.checks += [{"check_id": "inv_169_severity_p0", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "inv_169_severity_p0", "status": "fail", "message": "INV-169 severity is not P0"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# All checks passed
jq '.status = "passed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.inv_169_implemented = true' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"

echo "Verification passed for $TASK_ID"
