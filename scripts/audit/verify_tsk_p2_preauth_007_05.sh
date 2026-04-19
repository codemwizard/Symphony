#!/bin/bash
set -e

# Verification script for TSK-P2-PREAUTH-007-05: Promote INV-165/167 and wire pre_ci.sh
# This script verifies that INV-165 and INV-167 are promoted to implemented status
# and that the three verifier scripts are wired into pre_ci.sh

TASK_ID="TSK-P2-PREAUTH-007-05"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_05.json"
MANIFEST_PATH="docs/invariants/INVARIANTS_MANIFEST.yml"
PRE_CI_PATH="scripts/dev/pre_ci.sh"

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

# Check 1: Verify INV-165 has status: implemented
if ! grep -A 5 "id: INV-165" "$MANIFEST_PATH" | grep -q "status: implemented"; then
  echo "ERROR: INV-165 does not have status: implemented" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_05_work_item_01", "description": "INV-165 has status: implemented", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_05_work_item_01", "description": "INV-165 has status: implemented", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 2: Verify INV-167 has status: implemented
if ! grep -A 5 "id: INV-167" "$MANIFEST_PATH" | grep -q "status: implemented"; then
  echo "ERROR: INV-167 does not have status: implemented" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_05_work_item_02", "description": "INV-167 has status: implemented", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_05_work_item_02", "description": "INV-167 has status: implemented", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 3: Verify pre_ci.sh includes verify_tsk_p2_preauth_006a_01.sh
if ! grep -q "verify_tsk_p2_preauth_006a_01.sh" "$PRE_CI_PATH"; then
  echo "ERROR: pre_ci.sh does not include verify_tsk_p2_preauth_006a_01.sh" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_05_work_item_03", "description": "pre_ci.sh includes verify_tsk_p2_preauth_006a_01.sh", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_05_work_item_03", "description": "pre_ci.sh includes verify_tsk_p2_preauth_006a_01.sh", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 4: Verify pre_ci.sh includes verify_tsk_p2_preauth_005_08.sh
if ! grep -q "verify_tsk_p2_preauth_005_08.sh" "$PRE_CI_PATH"; then
  echo "ERROR: pre_ci.sh does not include verify_tsk_p2_preauth_005_08.sh" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_05_work_item_04", "description": "pre_ci.sh includes verify_tsk_p2_preauth_005_08.sh", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_05_work_item_04", "description": "pre_ci.sh includes verify_tsk_p2_preauth_005_08.sh", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 5: Verify pre_ci.sh includes verify_tsk_p2_preauth_006c_03.sh
if ! grep -q "verify_tsk_p2_preauth_006c_03.sh" "$PRE_CI_PATH"; then
  echo "ERROR: pre_ci.sh does not include verify_tsk_p2_preauth_006c_03.sh" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_05_work_item_05", "description": "pre_ci.sh includes verify_tsk_p2_preauth_006c_03.sh", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_05_work_item_05", "description": "pre_ci.sh includes verify_tsk_p2_preauth_006c_03.sh", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Final success update
jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
jq '.inv_165_status_implemented = true' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
jq '.inv_167_status_implemented = true' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
jq '.pre_ci_wired = true' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

echo "PASS: INV-165/167 promoted to implemented and pre_ci.sh wired with verifiers"
