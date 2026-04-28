#!/bin/bash
# Verification script for TSK-P2-W6-REM-16c
# Mathematically verifies absence of P7601 and presence of P7504 in pg_proc

set -e

TASK_ID="TSK-P2-W6-REM-16c"
GIT_SHA=$(git rev-parse HEAD || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w6_rem_16c.json"

mkdir -p $(dirname "$EVIDENCE_FILE")

echo "Running verification for $TASK_ID..."

# 1. Verify P7601 is entirely absent from the function definition
HAS_P7601=$(psql "$DATABASE_URL" -tAc "SELECT count(*) FROM pg_proc WHERE proname = 'issue_adjustment_with_recipient' AND prosrc LIKE '%P7601%';")

if [ "$HAS_P7601" != "0" ]; then
  echo "FAIL: The string 'P7601' is still present in issue_adjustment_with_recipient."
  exit 1
fi

echo "  Proof 1: 'P7601' successfully evicted from function definition."

# 2. Verify P7504 is present in the function definition
HAS_P7504=$(psql "$DATABASE_URL" -tAc "SELECT count(*) FROM pg_proc WHERE proname = 'issue_adjustment_with_recipient' AND prosrc LIKE '%P7504%';")

if [ "$HAS_P7504" != "1" ]; then
  echo "FAIL: The string 'P7504' was not found exactly once in issue_adjustment_with_recipient."
  exit 1
fi

echo "  Proof 2: 'P7504' successfully verified in function definition."

cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": {
    "P7601_absent": true,
    "P7504_present": true
  }
}
EOF

echo "Verification successful for $TASK_ID"
