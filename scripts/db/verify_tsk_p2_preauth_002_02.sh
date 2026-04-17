#!/bin/bash
# Verification script for TSK-P2-PREAUTH-002-02
# Verifies unit_conversions table creation with UNIQUE constraint on (from_unit, to_unit)

set -e

EVIDENCE_FILE="evidence/phase2/tsk_p2_preauth_002_02.json"
TASK_ID="TSK-P2-PREAUTH-002-02"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize evidence
mkdir -p evidence/phase2
echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"IN_PROGRESS","checks":[]}' > "$EVIDENCE_FILE"

# Check 1: Table exists
echo "Checking if unit_conversions table exists..."
TABLE_EXISTS=$(psql -tAc "SELECT 1 FROM information_schema.tables WHERE table_name = 'unit_conversions' AND table_schema = 'public'")
if [ "$TABLE_EXISTS" = "1" ]; then
    echo "✓ unit_conversions table exists"
else
    echo "✗ unit_conversions table does not exist"
    echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"FAIL","checks":[{"name":"table_exists","status":"FAIL","message":"Table does not exist"}]}' > "$EVIDENCE_FILE"
    exit 1
fi

# Check 2: UNIQUE constraint on (from_unit, to_unit) exists
echo "Checking UNIQUE constraint on (from_unit, to_unit)..."
CONSTRAINT_EXISTS=$(psql -tAc "SELECT 1 FROM pg_constraint WHERE conname = 'unique_unit_pair'")
if [ "$CONSTRAINT_EXISTS" = "1" ]; then
    echo "✓ UNIQUE constraint on (from_unit, to_unit) exists"
else
    echo "✗ UNIQUE constraint on (from_unit, to_unit) does not exist"
    echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"FAIL","checks":[{"name":"unique_constraint_present","status":"FAIL","message":"UNIQUE constraint does not exist"}]}' > "$EVIDENCE_FILE"
    exit 1
fi

# All checks passed
echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"PASS","checks":[{"name":"table_exists","status":"PASS"},{"name":"unique_constraint_present","status":"PASS"}],"table_exists":true,"unique_constraint_present":true}' > "$EVIDENCE_FILE"

echo "All checks passed for TSK-P2-PREAUTH-002-02"
