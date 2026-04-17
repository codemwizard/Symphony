#!/bin/bash
# Verification script for TSK-P2-PREAUTH-003-02
# Verifies that interpretation_version_id column and FK constraint exist in execution_records

set -e

echo "Verifying TSK-P2-PREAUTH-003-02: interpretation_version_id FK addition"

DB_CMD="docker exec symphony-postgres psql -U symphony -d symphony -t -c"

# Check if interpretation_version_id column exists
COL_EXISTS=$($DB_CMD "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'execution_records' AND column_name = 'interpretation_version_id');" | tr -d ' ')

if [ "$COL_EXISTS" != "t" ]; then
    echo "FAIL: interpretation_version_id column does not exist in execution_records"
    exit 1
fi

echo "PASS: interpretation_version_id column exists"

# Check for FK constraint to interpretation_packs
FK_EXISTS=$($DB_CMD "
SELECT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_name = 'execution_records'
      AND kcu.column_name = 'interpretation_version_id'
      AND ccu.table_name = 'interpretation_packs'
);" | tr -d ' ')

if [ "$FK_EXISTS" != "t" ]; then
    echo "FAIL: FK constraint from execution_records.interpretation_version_id to interpretation_packs does not exist"
    exit 1
fi

echo "PASS: FK constraint to interpretation_packs exists"

# Emit evidence
mkdir -p evidence/phase2
cat > evidence/phase2/tsk_p2_preauth_003_02.json << EOF
{
  "task_id": "TSK-P2-PREAUTH-003-02",
  "status": "PASS",
  "git_sha": "$(git rev-parse HEAD)",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "checks": {
    "column_exists": true,
    "fk_constraint_present": true
  }
}
EOF

echo "Verification complete: TSK-P2-PREAUTH-003-02 PASSED"
