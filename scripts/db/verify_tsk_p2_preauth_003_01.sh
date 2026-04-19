#!/bin/bash
# Verification script for TSK-P2-PREAUTH-003-01
# Verifies that execution_records table exists with correct columns and indexes

set -e

echo "Verifying TSK-P2-PREAUTH-003-01: execution_records table creation"

DB_CMD="docker exec symphony-postgres psql -U symphony -d symphony -t -c"

# Check if table exists
TABLE_EXISTS=$($DB_CMD "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'execution_records');" | tr -d ' ')

if [ "$TABLE_EXISTS" != "t" ]; then
    echo "FAIL: execution_records table does not exist"
    exit 1
fi

echo "PASS: execution_records table exists"

# Check for required columns
COLUMNS=(
    "execution_id"
    "project_id"
    "execution_timestamp"
    "status"
    "interpretation_version_id"
    "created_at"
)

for col in "${COLUMNS[@]}"; do
    COL_EXISTS=$($DB_CMD "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'execution_records' AND column_name = '$col');" | tr -d ' ')
    if [ "$COL_EXISTS" != "t" ]; then
        echo "FAIL: Column $col does not exist in execution_records"
        exit 1
    fi
    echo "PASS: Column $col exists"
done

# Check for index on project_id
INDEX_EXISTS=$($DB_CMD "SELECT EXISTS (SELECT FROM pg_indexes WHERE tablename = 'execution_records' AND indexname = 'idx_execution_records_project_id');" | tr -d ' ')

if [ "$INDEX_EXISTS" != "t" ]; then
    echo "FAIL: Index idx_execution_records_project_id does not exist"
    exit 1
fi

echo "PASS: Index idx_execution_records_project_id exists"

# Check MIGRATION_HEAD
MIGRATION_HEAD=$(cat schema/migrations/MIGRATION_HEAD | tr -d '\n')
# Use numeric comparison for version check
if [ "$MIGRATION_HEAD" -lt "0118" ]; then
    echo "FAIL: MIGRATION_HEAD is $MIGRATION_HEAD, expected at least 0118"
    exit 1
fi

echo "PASS: MIGRATION_HEAD is at least 0118 (current: $MIGRATION_HEAD)"

# Emit evidence
mkdir -p evidence/phase2
cat > evidence/phase2/tsk_p2_preauth_003_01.json << EOF
{
  "task_id": "TSK-P2-PREAUTH-003-01",
  "status": "PASS",
  "git_sha": "$(git rev-parse HEAD)",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "checks": {
    "table_exists": true,
    "all_columns_present": true,
    "index_present": true,
    "migration_head": "$MIGRATION_HEAD"
  }
}
EOF

echo "Verification complete: TSK-P2-PREAUTH-003-01 PASSED"
