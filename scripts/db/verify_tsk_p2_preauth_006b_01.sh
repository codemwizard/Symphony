#!/bin/bash
# Verification script for TSK-P2-PREAUTH-006B-01
# Verifies enforce_monitoring_authority() function exists, is SECURITY DEFINER, and trigger is attached

set -e

TASK_ID="TSK-P2-PREAUTH-006B-01"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_006b_01.json"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Check if function exists
FUNCTION_EXISTS=$(psql -tAc "SELECT 1 FROM pg_proc WHERE proname='enforce_monitoring_authority'" 2>/dev/null || echo "0")

# Check if function is SECURITY DEFINER
SECURITY_DEFINER=$(psql -tAc "SELECT prosecdef FROM pg_proc WHERE proname='enforce_monitoring_authority'" 2>/dev/null || echo "")

# Check if trigger is attached
TRIGGER_EXISTS=$(psql -tAc "SELECT 1 FROM pg_trigger WHERE tgname='trg_enforce_monitoring_authority'" 2>/dev/null || echo "0")

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
    "function_exists": $([ "$FUNCTION_EXISTS" = "1" ] && echo "true" || echo "false"),
    "security_definer_present": $([ "$SECURITY_DEFINER" = "t" ] && echo "true" || echo "false"),
    "trigger_attached": $([ "$TRIGGER_EXISTS" = "1" ] && echo "true" || echo "false"),
    "migration_head": "$MIGRATION_HEAD"
  },
  "function_exists": $([ "$FUNCTION_EXISTS" = "1" ] && echo "true" || echo "false"),
  "security_definer_present": $([ "$SECURITY_DEFINER" = "t" ] && echo "true" || echo "false"),
  "trigger_attached": $([ "$TRIGGER_EXISTS" = "1" ] && echo "true" || echo "false"),
  "migration_head": "$MIGRATION_HEAD"
}
EOF

# Verify checks passed
if [ "$FUNCTION_EXISTS" != "1" ]; then
  echo "FAIL: enforce_monitoring_authority function does not exist"
  exit 1
fi

if [ "$SECURITY_DEFINER" != "t" ]; then
  echo "FAIL: enforce_monitoring_authority function is not SECURITY DEFINER"
  exit 1
fi

if [ "$TRIGGER_EXISTS" != "1" ]; then
  echo "FAIL: trg_enforce_monitoring_authority trigger is not attached"
  exit 1
fi

# Use numeric comparison for version check
if [ "$MIGRATION_HEAD" -lt "0122" ]; then
  echo "FAIL: MIGRATION_HEAD is $MIGRATION_HEAD, expected at least 0122"
  exit 1
fi

echo "PASS: TSK-P2-PREAUTH-006B-01 verification complete"
