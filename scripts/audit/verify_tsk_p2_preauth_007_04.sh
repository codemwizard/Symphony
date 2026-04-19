#!/bin/bash
set -e

# Verification script for TSK-P2-PREAUTH-007-04: Register INV-177 (phase1_boundary_marked)
# This script verifies that INV-177 is registered correctly in INVARIANTS_MANIFEST.yml

TASK_ID="TSK-P2-PREAUTH-007-04"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_04.json"
MANIFEST_PATH="docs/invariants/INVARIANTS_MANIFEST.yml"

# Get git SHA
GIT_SHA=$(git rev-parse HEAD)

# Get timestamp
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize JSON output
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "IN_PROGRESS",
  "checks": []
}
EOF

# Check 1: Verify INV-177 exists in INVARIANTS_MANIFEST.yml
if ! grep -q "id: INV-177" "$MANIFEST_PATH"; then
  echo "ERROR: INV-177 not found in INVARIANTS_MANIFEST.yml" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_04_work_item_01", "description": "INV-177 exists in INVARIANTS_MANIFEST.yml", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_04_work_item_01", "description": "INV-177 exists in INVARIANTS_MANIFEST.yml", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 2: Verify INV-177 has status: implemented
if ! grep -A 20 "id: INV-177" "$MANIFEST_PATH" | grep -q "status: implemented"; then
  echo "ERROR: INV-177 does not have status: implemented" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_04_work_item_01", "description": "INV-177 has status: implemented", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_04_work_item_01", "description": "INV-177 has status: implemented", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 3: Verify INV-177 has enforcement field
if ! grep -A 20 "id: INV-177" "$MANIFEST_PATH" | grep -q "enforcement"; then
  echo "ERROR: INV-177 does not have enforcement field" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_04_work_item_01", "description": "INV-177 has enforcement field", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_04_work_item_01", "description": "INV-177 has enforcement field", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 4: Verify INV-177 enforcement points to correct script
ENFORCEMENT_SCRIPT=$(grep -A 20 "id: INV-177" "$MANIFEST_PATH" | grep "^  enforcement:" | sed 's/.*enforcement: //' | tr -d '"')
if [ "$ENFORCEMENT_SCRIPT" != "scripts/audit/verify_tsk_p2_preauth_006c_03.sh" ]; then
  echo "ERROR: INV-177 enforcement does not point to scripts/audit/verify_tsk_p2_preauth_006c_03.sh" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq --arg expected "scripts/audit/verify_tsk_p2_preauth_006c_03.sh" --arg actual "$ENFORCEMENT_SCRIPT" '.checks += [{"id": "tsk_p2_preauth_007_04_work_item_02", "description": "INV-177 enforcement points to correct script", "result": "FAIL", "details": {"expected": $expected, "actual": $actual}}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_04_work_item_02", "description": "INV-177 enforcement points to correct script", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Final success update
jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
jq '.inv_177_registered = true' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
jq '.inv_177_status_implemented = true' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

echo "PASS: INV-177 registered correctly with status: implemented"
