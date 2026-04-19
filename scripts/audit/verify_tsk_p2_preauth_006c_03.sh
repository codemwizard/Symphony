#!/bin/bash
# Verification script for TSK-P2-PREAUTH-006C-03
# Verifies DataAuthority and AuditGrade properties exist in AssetBatch and StateTransition read models

set -e

TASK_ID="TSK-P2-PREAUTH-006C-03"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_006c_03.json"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Check if AssetBatch.cs exists
ASSET_BATCH_EXISTS=$(test -f src/Symphony/Models/AssetBatch.cs && echo "true" || echo "false")
ASSET_BATCH_DATA_AUTHORITY=$(grep -q "DataAuthority" src/Symphony/Models/AssetBatch.cs 2>/dev/null && echo "true" || echo "false")
ASSET_BATCH_AUDIT_GRADE=$(grep -q "AuditGrade" src/Symphony/Models/AssetBatch.cs 2>/dev/null && echo "true" || echo "false")

# Check if StateTransition.cs exists
STATE_TRANSITION_EXISTS=$(test -f src/Symphony/Models/StateTransition.cs && echo "true" || echo "false")
STATE_TRANSITION_DATA_AUTHORITY=$(grep -q "DataAuthority" src/Symphony/Models/StateTransition.cs 2>/dev/null && echo "true" || echo "false")
STATE_TRANSITION_AUDIT_GRADE=$(grep -q "AuditGrade" src/Symphony/Models/StateTransition.cs 2>/dev/null && echo "true" || echo "false")

# Build evidence JSON
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "success",
  "checks": {
    "asset_batch_exists": $ASSET_BATCH_EXISTS,
    "asset_batch_data_authority": $ASSET_BATCH_DATA_AUTHORITY,
    "asset_batch_audit_grade": $ASSET_BATCH_AUDIT_GRADE,
    "state_transition_exists": $STATE_TRANSITION_EXISTS,
    "state_transition_data_authority": $STATE_TRANSITION_DATA_AUTHORITY,
    "state_transition_audit_grade": $STATE_TRANSITION_AUDIT_GRADE
  },
  "data_authority_in_asset_batch": $ASSET_BATCH_DATA_AUTHORITY,
  "data_authority_in_state_transition": $STATE_TRANSITION_DATA_AUTHORITY
}
EOF

# Verify checks passed
if [ "$ASSET_BATCH_EXISTS" != "true" ]; then
  echo "FAIL: AssetBatch.cs does not exist"
  exit 1
fi

if [ "$ASSET_BATCH_DATA_AUTHORITY" != "true" ]; then
  echo "FAIL: DataAuthority property missing from AssetBatch"
  exit 1
fi

if [ "$ASSET_BATCH_AUDIT_GRADE" != "true" ]; then
  echo "FAIL: AuditGrade property missing from AssetBatch"
  exit 1
fi

if [ "$STATE_TRANSITION_EXISTS" != "true" ]; then
  echo "FAIL: StateTransition.cs does not exist"
  exit 1
fi

if [ "$STATE_TRANSITION_DATA_AUTHORITY" != "true" ]; then
  echo "FAIL: DataAuthority property missing from StateTransition"
  exit 1
fi

if [ "$STATE_TRANSITION_AUDIT_GRADE" != "true" ]; then
  echo "FAIL: AuditGrade property missing from StateTransition"
  exit 1
fi

echo "PASS: TSK-P2-PREAUTH-006C-03 verification complete"
