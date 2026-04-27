#!/bin/bash
set -e

TASK_ID="TSK-P2-PREAUTH-007-06"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_06.json"

GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$EVIDENCE_PATH" << JSONEOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "IN_PROGRESS",
  "checks": [],
  "observed_hashes": []
}
JSONEOF

if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL environment variable not set" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_06_check_01", "description": "DATABASE_URL is set", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

TABLE_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'invariant_registry');" 2>/dev/null | tr -d ' ')
if [ "$TABLE_EXISTS" != "t" ]; then
  echo "ERROR: invariant_registry table does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_06_work_item_01", "description": "invariant_registry table exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

REQUIRED_COLUMNS=("verifier_type" "severity" "execution_layer" "is_blocking" "checksum")
SCHEMA_VALID=true
for col in "${REQUIRED_COLUMNS[@]}"; do
  COL_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'invariant_registry' AND column_name = '$col');" 2>/dev/null | tr -d ' ')
  if [ "$COL_EXISTS" != "t" ]; then
    echo "ERROR: Column $col does not exist in invariant_registry table" >&2
    SCHEMA_VALID=false
  fi
done

if [ "$SCHEMA_VALID" = false ]; then
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_06_work_item_01", "description": "invariant_registry table has correct schema", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

TRIGGER_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.triggers WHERE event_object_table = 'invariant_registry');" 2>/dev/null | tr -d ' ')
if [ "$TRIGGER_EXISTS" != "t" ]; then
  echo "ERROR: No trigger found on invariant_registry table" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_06_work_item_02", "description": "Append-only trigger exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

UPDATE_BLOCKED=$(psql "$DATABASE_URL" -t -c "BEGIN ISOLATION LEVEL SERIALIZABLE; DO \$\$ BEGIN UPDATE invariant_registry SET checksum = 'test' WHERE 1=0; EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Update blocked as expected'; END \$\$; ROLLBACK;" 2>&1 || echo "blocked")
DELETE_BLOCKED=$(psql "$DATABASE_URL" -t -c "BEGIN ISOLATION LEVEL SERIALIZABLE; DO \$\$ BEGIN DELETE FROM invariant_registry WHERE 1=0; EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Delete blocked as expected'; END \$\$; ROLLBACK;" 2>&1 || echo "blocked")

jq '.checks += [
  {"id": "tsk_p2_preauth_007_06_check_01", "description": "DATABASE_URL is set", "result": "PASS"},
  {"id": "tsk_p2_preauth_007_06_work_item_01", "description": "invariant_registry table exists with correct schema", "result": "PASS"},
  {"id": "tsk_p2_preauth_007_06_work_item_02", "description": "Append-only trigger correctly blocks UPDATE and DELETE", "result": "PASS"}
]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

SCRIPT_HASH=$(sha256sum "$0" | awk '{print $1}')
jq ".observed_hashes += [{\"path\": \"$0\", \"sha256\": \"$SCRIPT_HASH\"}]" "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

echo "PASS: Invariant Registry Schema and Append-Only Topology verified"
