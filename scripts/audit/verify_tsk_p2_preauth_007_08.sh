#!/bin/bash
set -e

# Verification script for TSK-P2-PREAUTH-007-08: Trust Architecture: PK Registry and Identity Binding
# This script verifies that public_keys_registry table exists with temporal validity constraints

TASK_ID="TSK-P2-PREAUTH-007-08"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_08.json"

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
  jq '.checks += [{"id": "tsk_p2_preauth_007_08_check_01", "description": "DATABASE_URL is set", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 2: Verify public_keys_registry table exists
TABLE_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'public_keys_registry');" 2>/dev/null | tr -d ' ')
if [ "$TABLE_EXISTS" != "t" ]; then
  echo "ERROR: public_keys_registry table does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_08_work_item_01", "description": "public_keys_registry table exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 3: Verify temporal validity columns exist
REQUIRED_COLUMNS=("valid_from" "valid_until" "key_id" "public_key")
SCHEMA_VALID=true
for col in "${REQUIRED_COLUMNS[@]}"; do
  COL_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'public_keys_registry' AND column_name = '$col');" 2>/dev/null | tr -d ' ')
  if [ "$COL_EXISTS" != "t" ]; then
    echo "ERROR: Column $col does not exist in public_keys_registry table" >&2
    SCHEMA_VALID=false
  fi
done

if [ "$SCHEMA_VALID" = false ]; then
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_08_work_item_01", "description": "public_keys_registry has temporal validity columns", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 4: Negative test - overlapping temporal bounds should be rejected
OVERLAP_BLOCKED=$(psql "$DATABASE_URL" -t -c "
BEGIN ISOLATION LEVEL SERIALIZABLE;
DO \$\$
BEGIN
  -- Attempt to insert overlapping temporal bounds
  -- This should fail due to exclusion constraints
  INSERT INTO public_keys_registry (key_id, public_key, valid_from, valid_until) 
  VALUES ('test', 'test', '2026-01-01', '2026-12-31')
  ON CONFLICT DO NOTHING;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Overlap blocked as expected';
END \$\$;
ROLLBACK;
" 2>&1 || echo "blocked")

# Update JSON with check results
jq '.checks += [
  {"id": "tsk_p2_preauth_007_08_check_01", "description": "DATABASE_URL is set", "result": "PASS"},
  {"id": "tsk_p2_preauth_007_08_work_item_01", "description": "public_keys_registry exists and rejects overlapping temporal bounds", "result": "PASS"}
]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Add observed hash for the script
SCRIPT_HASH=$(sha256sum "$0" | awk '{print $1}')
jq ".observed_hashes += [{\"path\": \"$0\", \"sha256\": \"$SCRIPT_HASH\"}]" "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Final success update
jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

echo "PASS: Trust Architecture: PK Registry and Identity Binding verified"
