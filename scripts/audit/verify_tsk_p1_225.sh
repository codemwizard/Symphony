#!/usr/bin/env bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

echo "=== TSK-P1-225 Verification ==="

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/tasks/TEST-001"
cat << 'EOF' > "$TMP_DIR/tasks/TEST-001/meta.yml"
schema_version: 1
phase: '1'
task_id: TEST-001
title: "Valid task pack"
owner_role: SECURITY_GUARDIAN
status: planned
touches:
  - dummy_file.txt
EOF

# [ID tsk_p1_225_work_item_03] 
cat << 'EOF' > "$TMP_DIR/tasks/TEST-001/meta_invalid.yml"
schema_version: 1
phase: '1'
task_id: TEST-001
owner_role: SECURITY_GUARDIAN
status: planned
touches:
  - dummy_file.txt
EOF

echo "[Test N1] Running against invalid pack (missing title)"
INVALID_OUT=$(python3 scripts/audit/task_contract_gate.py --meta "$TMP_DIR/tasks/TEST-001/meta_invalid.yml")

if echo "$INVALID_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$INVALID_OUT" | grep '"failure_class"' >/dev/null; then
    echo "Negative test passed."
else
    echo "ERROR: Gate did not emit valid structured failure for missing field."
    echo "Gate output was: $INVALID_OUT"
    exit 1
fi

# [ID tsk_p1_225_work_item_02] 
echo "[Test P1] Running against valid pack"
VALID_OUT=$(python3 scripts/audit/task_contract_gate.py --meta "$TMP_DIR/tasks/TEST-001/meta.yml")

if echo "$VALID_OUT" | grep '"status": "PASS"' >/dev/null; then
    echo "Positive test passed."
else
    echo "ERROR: Gate incorrectly failed valid metadata."
    echo "Gate output was: $VALID_OUT"
    exit 1
fi

git_sha=$(git rev-parse HEAD || echo "UNKNOWN")
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat << EOF > evidence/phase1/tsk_p1_225_contract_gate.json
{
  "task_id": "TSK-P1-225",
  "git_sha": "$git_sha",
  "timestamp_utc": "$timestamp",
  "status": "PASS",
  "checks": {
    "N1_missing_field_rejected": "PASS",
    "P1_valid_metadata_accepted": "PASS"
  },
  "invalid_case_result": $INVALID_OUT,
  "valid_case_result": $VALID_OUT,
  "fail_class_fields": ["MISSING_FIELDS", "UNPARSEABLE_YAML", "INVALID_TOUCH_PATHS", "MISSING_META", "ROOT_NOT_DICT"]
}
EOF

echo "TSK-P1-225 Verification Complete. Evidence written to evidence/phase1/tsk_p1_225_contract_gate.json"
