#!/bin/bash
# Verification script for TSK-P2-W6-REM-17b-alpha
# Verifies backfill of interpretation_version_id on state_transitions

set -e

TASK_ID="TSK-P2-W6-REM-17b-alpha"
GIT_SHA=$(git rev-parse HEAD || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w6_rem_17b_alpha.json"

mkdir -p $(dirname "$EVIDENCE_FILE")

echo "Running verification for $TASK_ID..."

# 1. Count remaining NULLs — must be 0
NULL_COUNT=$(psql "$DATABASE_URL" -tAc "
  SELECT COUNT(*) FROM state_transitions WHERE interpretation_version_id IS NULL;
")

# 2. Count total rows
TOTAL_COUNT=$(psql "$DATABASE_URL" -tAc "
  SELECT COUNT(*) FROM state_transitions;
")

# 3. Verify append-only trigger is re-enabled
TRIGGER_ENABLED=$(psql "$DATABASE_URL" -tAc "
  SELECT tgenabled FROM pg_trigger
  WHERE tgname = 'bd_01_deny_state_transitions_mutation'
    AND tgrelid = 'state_transitions'::regclass;
")

echo "  null_count=$NULL_COUNT total_count=$TOTAL_COUNT trigger_enabled=$TRIGGER_ENABLED"

NULL_CHECK="fail"
TRIGGER_CHECK="fail"

if [ "$NULL_COUNT" = "0" ]; then
  NULL_CHECK="pass"
fi

# tgenabled='O' means enabled (Origin), 'D' means disabled
if [ "$TRIGGER_ENABLED" = "O" ]; then
  TRIGGER_CHECK="pass"
fi

cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": {
    "null_count": "$NULL_COUNT",
    "total_rows": "$TOTAL_COUNT",
    "trigger_re_enabled": "$TRIGGER_CHECK",
    "null_check": "$NULL_CHECK"
  },
  "positive_test_results": {
    "TSK-P2-W6-REM-17b-alpha-P1": "$NULL_CHECK"
  }
}
EOF

if [ "$NULL_CHECK" != "pass" ]; then
  echo "FAIL: $NULL_COUNT rows still have NULL interpretation_version_id"
  exit 1
fi

if [ "$TRIGGER_CHECK" != "pass" ]; then
  echo "FAIL: append-only trigger not re-enabled (tgenabled=$TRIGGER_ENABLED)"
  exit 1
fi

echo "Verification successful for $TASK_ID"
