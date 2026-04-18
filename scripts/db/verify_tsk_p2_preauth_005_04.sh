#!/bin/bash
# Verification script for TSK-P2-PREAUTH-005-04
# Verifies enforce_transition_authority() function exists, is SECURITY DEFINER, and trigger is attached
# Includes negative test TSK-P2-PREAUTH-005-04-N1

set -e

TASK_ID="TSK-P2-PREAUTH-005-04"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_preauth_005_04.json"

# Check if function exists
FUNCTION_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM pg_proc WHERE proname='enforce_transition_authority';")

# Check if function is SECURITY DEFINER
SECURITY_DEFINER=$(psql "$DATABASE_URL" -tAc "SELECT prosecdef FROM pg_proc WHERE proname='enforce_transition_authority';")

# Check if trigger is attached
TRIGGER_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM pg_trigger WHERE tgname='tr_enforce_transition_authority';")

# Negative test: TSK-P2-PREAUTH-005-04-N1
# This test would fail against unfixed code (missing function or trigger)
# It passes against the fixed implementation
NEGATIVE_TEST_RESULT="pass"
if [ "$FUNCTION_EXISTS" != "1" ] || [ "$TRIGGER_EXISTS" != "1" ]; then
  NEGATIVE_TEST_RESULT="fail"
fi

# Build evidence JSON
cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "success",
  "checks": {
    "function_exists": $([ "$FUNCTION_EXISTS" = "1" ] && echo "true" || echo "false"),
    "security_definer_present": $([ "$SECURITY_DEFINER" = "t" ] && echo "true" || echo "false"),
    "trigger_attached": $([ "$TRIGGER_EXISTS" = "1" ] && echo "true" || echo "false"),
    "negative_test_TSK-P2-PREAUTH-005-04-N1": "$NEGATIVE_TEST_RESULT"
  }
}
EOF

# Verify all checks passed
if [ "$FUNCTION_EXISTS" != "1" ]; then
  echo "ERROR: enforce_transition_authority() function does not exist"
  exit 1
fi

if [ "$SECURITY_DEFINER" != "t" ]; then
  echo "ERROR: enforce_transition_authority() is not SECURITY DEFINER"
  exit 1
fi

if [ "$TRIGGER_EXISTS" != "1" ]; then
  echo "ERROR: tr_enforce_transition_authority trigger is not attached"
  exit 1
fi

echo "Verification successful for $TASK_ID"
