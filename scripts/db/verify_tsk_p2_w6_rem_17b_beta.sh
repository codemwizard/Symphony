#!/bin/bash
# Verification script for TSK-P2-W6-REM-17b-beta
# Verifies backfill of policy_decisions.project_id

set -e

TASK_ID="TSK-P2-W6-REM-17b-beta"
GIT_SHA=$(git rev-parse HEAD || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_w6_rem_17b_beta.json"

mkdir -p $(dirname "$EVIDENCE_FILE")

echo "Running verification for $TASK_ID..."

# 1. Verify 0 nulls remain
NULL_COUNT=$(psql "$DATABASE_URL" -tAc "SELECT count(*) FROM policy_decisions WHERE project_id IS NULL;")
if [ "$NULL_COUNT" -ne 0 ]; then
  echo "FAIL: $NULL_COUNT rows in policy_decisions still have NULL project_id."
  exit 1
fi

echo "  No NULL project_id values remain."

# 2. Verify all non-null project_ids match their parent execution_records
MISMATCH_COUNT=$(psql "$DATABASE_URL" -tAc "
  SELECT count(*) 
  FROM policy_decisions pd 
  JOIN execution_records er ON pd.execution_id = er.execution_id 
  WHERE pd.project_id != er.project_id;
")

if [ "$MISMATCH_COUNT" -ne 0 ]; then
  echo "FAIL: $MISMATCH_COUNT rows in policy_decisions have project_id mismatched with execution_records."
  exit 1
fi

echo "  All project_id values match their parent execution_records lineage."

# 3. Verify append-only trigger is active
TRIGGER_ACTIVE=$(psql "$DATABASE_URL" -tAc "SELECT tgenabled FROM pg_trigger WHERE tgname = 'policy_decisions_append_only_trigger' AND tgrelid = 'policy_decisions'::regclass;")
if [ "$TRIGGER_ACTIVE" != "O" ]; then
  echo "FAIL: policy_decisions_append_only_trigger is not fully enabled (tgenabled = '$TRIGGER_ACTIVE')."
  exit 1
fi

echo "  policy_decisions_append_only_trigger is fully enabled."

cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": {
    "null_project_id_count": 0,
    "lineage_mismatch_count": 0,
    "append_only_trigger_active": true
  }
}
EOF

echo "Verification successful for $TASK_ID"
