#!/usr/bin/env bash
set -e

# Verifier for TSK-P2-PREAUTH-004-02: state_rules table schema
# This script verifies that the state_rules table has been created correctly
# with all required columns, constraints, and indexes as per the Wave 4 contract

TASK_ID="TSK-P2-PREAUTH-004-02"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_004_02.json"

# Get git SHA
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize evidence JSON
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "IN_PROGRESS",
  "checks": []
}
EOF

# Function to add check to evidence
add_check() {
  local name="$1"
  local result="$2"
  local details="$3"
  
  local temp_file=$(mktemp)
  jq --arg name "$name" --arg result "$result" --arg details "$details" \
    '.checks += [{"name": $name, "result": $result, "details": $details}]' \
    "$EVIDENCE_PATH" > "$temp_file"
  mv "$temp_file" "$EVIDENCE_PATH"
}

# Check 1: Verify table exists
echo "Checking state_rules table exists..."
TABLE_EXISTS=$(psql -v ON_ERROR_STOP=1 -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'state_rules');" 2>&1)
if [ "$TABLE_EXISTS" = "t" ]; then
  add_check "table_exists" "PASS" "state_rules table exists in public schema"
else
  add_check "table_exists" "FAIL" "state_rules table does not exist"
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "${EVIDENCE_PATH}.tmp" && mv "${EVIDENCE_PATH}.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 2: Verify all 7 columns exist
echo "Checking columns..."
COLUMNS=$(psql -v ON_ERROR_STOP=1 -t -c "
  SELECT column_name, data_type, is_nullable, column_default
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'state_rules'
  ORDER BY ordinal_position;" 2>&1)

EXPECTED_COLUMNS=("state_rule_id" "from_state" "to_state" "required_decision_type" "allowed" "rule_priority" "created_at")
for col in "${EXPECTED_COLUMNS[@]}"; do
  if echo "$COLUMNS" | grep -q "^$col"; then
    add_check "column_$col" "PASS" "Column $col exists"
  else
    add_check "column_$col" "FAIL" "Column $col missing"
    jq '.status = "FAIL"' "$EVIDENCE_PATH" > "${EVIDENCE_PATH}.tmp" && mv "${EVIDENCE_PATH}.tmp" "$EVIDENCE_PATH"
    exit 1
  fi
done

# Check 3: Verify rule_priority has correct type and default
echo "Checking rule_priority column details..."
RULE_PRIORITY_DETAILS=$(psql -v ON_ERROR_STOP=1 -t -c "
  SELECT data_type, is_nullable, column_default
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'state_rules' AND column_name = 'rule_priority';" 2>&1)

if echo "$RULE_PRIORITY_DETAILS" | grep -q "integer" && \
   echo "$RULE_PRIORITY_DETAILS" | grep -q "NO" && \
   echo "$RULE_PRIORITY_DETAILS" | grep -q "0"; then
  add_check "rule_priority_details" "PASS" "rule_priority is INT NOT NULL DEFAULT 0"
else
  add_check "rule_priority_details" "FAIL" "rule_priority does not match expected type/nullability/default"
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "${EVIDENCE_PATH}.tmp" && mv "${EVIDENCE_PATH}.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 4: Verify PRIMARY KEY constraint
echo "Checking PRIMARY KEY constraint..."
PK_EXISTS=$(psql -v ON_ERROR_STOP=1 -t -c "
  SELECT EXISTS (
    SELECT FROM information_schema.table_constraints
    WHERE table_schema = 'public' 
    AND table_name = 'state_rules' 
    AND constraint_type = 'PRIMARY KEY');" 2>&1)
if [ "$PK_EXISTS" = "t" ]; then
  add_check "primary_key" "PASS" "PRIMARY KEY constraint exists on state_rule_id"
else
  add_check "primary_key" "FAIL" "PRIMARY KEY constraint missing"
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "${EVIDENCE_PATH}.tmp" && mv "${EVIDENCE_PATH}.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 5: Verify UNIQUE constraint
echo "Checking UNIQUE constraint..."
UNIQUE_EXISTS=$(psql -v ON_ERROR_STOP=1 -t -c "
  SELECT EXISTS (
    SELECT FROM information_schema.table_constraints
    WHERE table_schema = 'public' 
    AND table_name = 'state_rules' 
    AND constraint_type = 'UNIQUE');" 2>&1)
if [ "$UNIQUE_EXISTS" = "t" ]; then
  add_check "unique_constraint" "PASS" "UNIQUE constraint exists"
else
  add_check "unique_constraint" "FAIL" "UNIQUE constraint missing"
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "${EVIDENCE_PATH}.tmp" && mv "${EVIDENCE_PATH}.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 6: Verify index exists
echo "Checking index..."
INDEX_EXISTS=$(psql -v ON_ERROR_STOP=1 -t -c "
  SELECT EXISTS (
    SELECT FROM pg_indexes
    WHERE tablename = 'state_rules' 
    AND indexname = 'idx_state_rules_from_priority');" 2>&1)
if [ "$INDEX_EXISTS" = "t" ]; then
  add_check "index_exists" "PASS" "idx_state_rules_from_priority index exists"
else
  add_check "index_exists" "FAIL" "idx_state_rules_from_priority index missing"
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "${EVIDENCE_PATH}.tmp" && mv "${EVIDENCE_PATH}.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 7: Verify MIGRATION_HEAD
echo "Checking MIGRATION_HEAD..."
MIGRATION_HEAD=$(cat schema/migrations/MIGRATION_HEAD 2>/dev/null || echo "")
if [ "$MIGRATION_HEAD" = "0135" ]; then
  add_check "migration_head" "PASS" "MIGRATION_HEAD is 0135"
else
  add_check "migration_head" "FAIL" "MIGRATION_HEAD is $MIGRATION_HEAD, expected 0135"
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "${EVIDENCE_PATH}.tmp" && mv "${EVIDENCE_PATH}.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Update evidence with final status
jq --arg columns "$COLUMNS" \
   --arg migration_head_value "$MIGRATION_HEAD" \
   '.status = "PASS" | .columns_present = $columns | .migration_head_value = $migration_head_value' \
   "$EVIDENCE_PATH" > "${EVIDENCE_PATH}.tmp" && mv "${EVIDENCE_PATH}.tmp" "$EVIDENCE_PATH"

echo "All checks passed. Evidence written to $EVIDENCE_PATH"
