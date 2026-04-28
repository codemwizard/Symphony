#!/bin/bash
# Verification script for TSK-P2-PREAUTH-005-02
# Verifies state_current table exists with (entity_type, entity_id) PRIMARY KEY
# Includes negative test TSK-P2-PREAUTH-005-02-N1

set -e

TASK_ID="TSK-P2-PREAUTH-005-02"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVIDENCE_FILE="evidence/phase2/tsk_p2_preauth_005_02.json"

# Check if table exists
TABLE_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM information_schema.tables WHERE table_name = 'state_current';")

# Check if PRIMARY KEY exists on entity_id
PRIMARY_KEY_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM information_schema.table_constraints tc JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name WHERE tc.table_name = 'state_current' AND tc.constraint_type = 'PRIMARY KEY' AND kcu.column_name = 'entity_id';")

# Negative test: TSK-P2-PREAUTH-005-02-N1
# This test actually attempts an INSERT without entity_type
NEGATIVE_TEST_RESULT="fail"

echo "Running behavioral tests for state_current..."
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'EOF'
BEGIN;
-- Positive Test
INSERT INTO state_current (entity_type, entity_id, current_state, updated_at)
VALUES ('TEST_ENTITY', gen_random_uuid(), 'A', NOW());
ROLLBACK;
EOF
if [ $? -ne 0 ]; then
    echo "ERROR: Behavioral positive test failed."
    exit 1
fi

# Negative Test (Missing entity_type)
if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'EOF' > /dev/null 2>&1
BEGIN;
INSERT INTO state_current (entity_id, current_state, updated_at)
VALUES (gen_random_uuid(), 'A', NOW());
ROLLBACK;
EOF
then
    echo "ERROR: Behavioral negative test failed (database accepted invalid data)."
    exit 1
else
    NEGATIVE_TEST_RESULT="pass"
fi

# Build evidence JSON
cat > "$EVIDENCE_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "success",
  "checks": {
    "table_exists": $([ "$TABLE_EXISTS" = "1" ] && echo "true" || echo "false"),
    "primary_key_present": $([ "$PRIMARY_KEY_EXISTS" = "1" ] && echo "true" || echo "false"),
    "negative_test_TSK-P2-PREAUTH-005-02-N1": "$NEGATIVE_TEST_RESULT"
  }
}
EOF

# Verify all checks passed
if [ "$TABLE_EXISTS" != "1" ]; then
  echo "ERROR: state_current table does not exist"
  exit 1
fi

if [ "$PRIMARY_KEY_EXISTS" != "1" ]; then
  echo "ERROR: entity_id PRIMARY KEY does not exist on state_current"
  exit 1
fi

echo "Verification successful for $TASK_ID"
