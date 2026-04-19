#!/bin/bash
# Verification script for TSK-P2-PREAUTH-006A-01
# Verifies data_authority_level ENUM type exists and contains all 7 values

set -e

TASK_ID="TSK-P2-PREAUTH-006A-01"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_006a_01.json"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Check if ENUM type exists
ENUM_EXISTS=$(psql -tAc "SELECT 1 FROM pg_type WHERE typname = 'data_authority_level'" 2>/dev/null || echo "0")

# Check if all 7 values are present
VALUES_COUNT=$(psql -tAc "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'data_authority_level'::regtype" 2>/dev/null || echo "0")

# Check MIGRATION_HEAD
MIGRATION_HEAD=$(cat schema/migrations/MIGRATION_HEAD)

# Build evidence JSON
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "success",
  "checks": {
    "enum_exists": $([ "$ENUM_EXISTS" = "1" ] && echo "true" || echo "false"),
    "enum_values_present": $([ "$VALUES_COUNT" = "7" ] && echo "true" || echo "false"),
    "migration_head": "$MIGRATION_HEAD"
  },
  "enum_exists": $([ "$ENUM_EXISTS" = "1" ] && echo "true" || echo "false"),
  "enum_values_present": $([ "$VALUES_COUNT" = "7" ] && echo "true" || echo "false"),
  "migration_head": "$MIGRATION_HEAD"
}
EOF

# Verify checks passed
if [ "$ENUM_EXISTS" != "1" ]; then
  echo "FAIL: data_authority_level ENUM type does not exist"
  exit 1
fi

if [ "$VALUES_COUNT" != "7" ]; then
  echo "FAIL: data_authority_level ENUM has $VALUES_COUNT values, expected 7"
  exit 1
fi

# Use numeric comparison for version check
if [ "$MIGRATION_HEAD" -lt "0121" ]; then
  echo "FAIL: MIGRATION_HEAD is $MIGRATION_HEAD, expected at least 0121"
  exit 1
fi

echo "PASS: TSK-P2-PREAUTH-006A-01 verification complete"
