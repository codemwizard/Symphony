#!/bin/bash
# Verification script for TSK-P2-PREAUTH-001-01
# Verifies interpretation_packs table creation with temporal uniqueness constraint

set -e

EVIDENCE_FILE="evidence/phase2/tsk_p2_preauth_001_01.json"
TASK_ID="TSK-P2-PREAUTH-001-01"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize evidence
mkdir -p evidence/phase2
echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"IN_PROGRESS","checks":[]}' > "$EVIDENCE_FILE"

# Check 1: Table exists
echo "Checking if interpretation_packs table exists..."
TABLE_EXISTS=$(psql -tAc "SELECT 1 FROM information_schema.tables WHERE table_name = 'interpretation_packs' AND table_schema = 'public'")
if [ "$TABLE_EXISTS" = "1" ]; then
    echo "✓ interpretation_packs table exists"
else
    echo "✗ interpretation_packs table does not exist"
    echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"FAIL","checks":[{"name":"table_exists","status":"FAIL","message":"Table does not exist"}]}' > "$EVIDENCE_FILE"
    exit 1
fi

# Check 2: Temporal uniqueness constraint exists
echo "Checking temporal uniqueness constraint..."
CONSTRAINT_EXISTS=$(psql -tAc "SELECT 1 FROM pg_constraint WHERE conname = 'unique_interpretation_per_project_time'")
if [ "$CONSTRAINT_EXISTS" = "1" ]; then
    echo "✓ Temporal uniqueness constraint exists"
else
    echo "✗ Temporal uniqueness constraint does not exist"
    echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"FAIL","checks":[{"name":"temporal_uniqueness_present","status":"FAIL","message":"Temporal uniqueness constraint does not exist"}]}' > "$EVIDENCE_FILE"
    exit 1
fi

# Check 3: MIGRATION_HEAD updated to at least 0116
echo "Checking MIGRATION_HEAD..."
MIGRATION_HEAD=$(cat schema/migrations/MIGRATION_HEAD)
# Use numeric comparison for version check
if [ "$MIGRATION_HEAD" -ge "0116" ]; then
    echo "✓ MIGRATION_HEAD is at least 0116 (current: $MIGRATION_HEAD)"
else
    echo "✗ MIGRATION_HEAD is less than 0116 (current: $MIGRATION_HEAD)"
    echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"FAIL","checks":[{"name":"migration_head","status":"FAIL","message":"MIGRATION_HEAD is less than 0116"}]}' > "$EVIDENCE_FILE"
    exit 1
fi

# All checks passed
echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"PASS","checks":[{"name":"table_exists","status":"PASS"},{"name":"temporal_uniqueness_present","status":"PASS"},{"name":"migration_head","status":"PASS"}],"table_exists":true,"temporal_uniqueness_present":true,"migration_head":"'"$MIGRATION_HEAD"'"}' > "$EVIDENCE_FILE"

echo "All checks passed for TSK-P2-PREAUTH-001-01"
