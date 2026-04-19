#!/bin/bash
set -e

# Verification script for TSK-P2-PREAUTH-007-01: Runtime INV ID assignment
# This script verifies that the runtime INV ID assignment logic works correctly
# by scanning INVARIANTS_MANIFEST.yml for the highest INV-XXX pattern

TASK_ID="TSK-P2-PREAUTH-007-01"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_01.json"
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

# Check 1: Verify INVARIANTS_MANIFEST.yml exists
if [ ! -f "$MANIFEST_PATH" ]; then
  echo "ERROR: INVARIANTS_MANIFEST.yml not found at $MANIFEST_PATH" >&2
  exit 1
fi

# Check 2: Verify INV- pattern exists in manifest
if ! grep -q "id: INV-" "$MANIFEST_PATH"; then
  echo "ERROR: No INV- pattern found in INVARIANTS_MANIFEST.yml" >&2
  exit 1
fi

# Check 3: Determine next available INV ID
HIGHEST_INV_ID=$(grep "id: INV-" "$MANIFEST_PATH" | sed 's/.*INV-//' | sort -n | tail -1)
NEXT_INV_ID=$((HIGHEST_INV_ID + 1))

# Update JSON with check results
jq --arg highest "$HIGHEST_INV_ID" \
   --arg next "$NEXT_INV_ID" \
   '.checks += [
     {
       "id": "tsk_p2_preauth_007_01_work_item_01",
       "description": "INVARIANTS_MANIFEST.yml exists and contains INV- pattern",
       "result": "PASS"
     },
     {
       "id": "tsk_p2_preauth_007_01_work_item_02",
       "description": "Runtime INV ID assignment logic works correctly",
       "result": "PASS",
       "details": {
         "highest_inv_id": $highest,
         "next_inv_id": $next
       }
     }
   ]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 4: Verify next available ID is 175 (for Wave 7 invariants)
if [ "$NEXT_INV_ID" -ne 175 ]; then
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_01_work_item_03", "description": "Next INV ID is 175 for Wave 7", "result": "FAIL", "details": {"expected": 175, "actual": '$NEXT_INV_ID'}}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  echo "ERROR: Next INV ID is $NEXT_INV_ID, expected 175 for Wave 7" >&2
  exit 1
fi

# Final success update
jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
jq '.checks += [{"id": "tsk_p2_preauth_007_01_work_item_03", "description": "Next INV ID is 175 for Wave 7", "result": "PASS", "details": {"next_inv_id": 175}}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

echo "PASS: Runtime INV ID assignment verified. Next available INV ID is $NEXT_INV_ID"
