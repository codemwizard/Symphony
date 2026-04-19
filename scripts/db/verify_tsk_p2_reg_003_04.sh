#!/bin/bash
# Verification script for TSK-P2-REG-003-04: Add taxonomy_aligned column to projects

set -e

TASK_ID="TSK-P2-REG-003-04"
EVIDENCE_PATH="evidence/phase2/tsk_p2_reg_003_04.json"

# Create evidence directory if it doesn't exist
mkdir -p "$(dirname "$EVIDENCE_PATH")"

# Initialize evidence JSON
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$(git rev-parse HEAD)",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "in_progress",
  "checks": []
}
EOF

# Check 1: Migration file exists
if [ -f "schema/migrations/0128_taxonomy_aligned.sql" ]; then
  jq '.checks += [{"check_id": "migration_file_exists", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "migration_file_exists", "status": "fail", "message": "Migration file not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 2: MIGRATION_HEAD is 0128
if [ "$(cat schema/migrations/MIGRATION_HEAD)" = "0128" ]; then
  jq '.checks += [{"check_id": "migration_head_correct", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "migration_head_correct", "status": "fail", "message": "MIGRATION_HEAD is not 0128"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 3: ALTER TABLE ADD COLUMN present
if grep -q "ALTER TABLE.*projects.*ADD COLUMN.*taxonomy_aligned" schema/migrations/0128_taxonomy_aligned.sql; then
  jq '.checks += [{"check_id": "alter_table_present", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "alter_table_present", "status": "fail", "message": "ALTER TABLE ADD COLUMN not found"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# Check 4: Column is BOOLEAN NOT NULL DEFAULT false
if grep -q "taxonomy_aligned BOOLEAN NOT NULL DEFAULT false" schema/migrations/0128_taxonomy_aligned.sql; then
  jq '.checks += [{"check_id": "column_type_correct", "status": "pass"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
else
  jq '.checks += [{"check_id": "column_type_correct", "status": "fail", "message": "Column type is not BOOLEAN NOT NULL DEFAULT false"}]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  jq '.status = "failed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
  exit 1
fi

# All checks passed
jq '.status = "passed"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.column_exists = true' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.column_type_correct = true' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.migration_head = "0128"' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.observed_paths = ["schema/migrations/0128_taxonomy_aligned.sql", "schema/migrations/MIGRATION_HEAD"]' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.observed_hashes = {}' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.command_outputs = []' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"
jq '.execution_trace = []' "$EVIDENCE_PATH" > /tmp/evidence_tmp.json && mv /tmp/evidence_tmp.json "$EVIDENCE_PATH"

echo "Verification passed for $TASK_ID"
