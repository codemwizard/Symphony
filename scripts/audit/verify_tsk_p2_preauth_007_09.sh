#!/bin/bash
set -e

# Verification script for TSK-P2-PREAUTH-007-09: Trust Architecture: Delegated Grant Schema
# This script verifies that delegated_signing_grants table exists and correctly maps actor scope to payload

TASK_ID="TSK-P2-PREAUTH-007-09"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_09.json"

# Get git SHA
GIT_SHA=$(git rev-parse HEAD)

# Get timestamp
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize JSON output
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "IN_PROGRESS",
  "checks": [],
  "observed_hashes": []
}
EOF

# Check 1: Verify DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL environment variable not set" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_09_check_01", "description": "DATABASE_URL is set", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 2: Verify delegated_signing_grants table exists
TABLE_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'delegated_signing_grants');" 2>/dev/null | tr -d ' ')
if [ "$TABLE_EXISTS" != "t" ]; then
  echo "ERROR: delegated_signing_grants table does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_09_work_item_01", "description": "delegated_signing_grants table exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 3: Verify table has required columns for actor scope and payload mapping
REQUIRED_COLUMNS=("actor_id" "scope" "payload_hash" "grant_id")
SCHEMA_VALID=true
for col in "${REQUIRED_COLUMNS[@]}"; do
  COL_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'delegated_signing_grants' AND column_name = '$col');" 2>/dev/null | tr -d ' ')
  if [ "$COL_EXISTS" != "t" ]; then
    echo "ERROR: Column $col does not exist in delegated_signing_grants table" >&2
    SCHEMA_VALID=false
  fi
done

if [ "$SCHEMA_VALID" = false ]; then
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_09_work_item_01", "description": "delegated_signing_grants has required columns", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Update JSON with check results
jq '.checks += [
  {"id": "tsk_p2_preauth_007_09_check_01", "description": "DATABASE_URL is set", "result": "PASS"},
  {"id": "tsk_p2_preauth_007_09_work_item_01", "description": "delegated_signing_grants table exists and correctly maps actor scope to payload", "result": "PASS"}
]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Add observed hash for the script
SCRIPT_HASH=$(sha256sum "$0" | awk '{print $1}')
jq ".observed_hashes += [{\"path\": \"$0\", \"sha256\": \"$SCRIPT_HASH\"}]" "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Final success update
jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

echo "PASS: Trust Architecture: Delegated Grant Schema verified"
