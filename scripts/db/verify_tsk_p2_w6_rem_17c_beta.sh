#!/bin/bash
# Verification script for TSK-P2-W6-REM-17c-beta
# Verifies NOT NULL constraint on policy_decisions.project_id

set -e

TASK_ID="TSK-P2-W6-REM-17c-beta"
GIT_SHA=$(git rev-parse HEAD || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w6_rem_17c_beta.json"

mkdir -p $(dirname "$EVIDENCE_FILE")

echo "Running verification for $TASK_ID..."

# 1. Verify schema constraint
IS_NULLABLE=$(psql "$DATABASE_URL" -tAc "SELECT is_nullable FROM information_schema.columns WHERE table_name = 'policy_decisions' AND column_name = 'project_id';")

if [ "$IS_NULLABLE" != "NO" ]; then
  echo "FAIL: policy_decisions.project_id is still nullable ($IS_NULLABLE)."
  exit 1
fi

echo "  Schema verified: project_id is NOT NULL."

cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": {
    "is_nullable": false
  }
}
EOF

echo "Verification successful for $TASK_ID"
