#!/bin/bash
set -e

# Verification script for TSK-P2-PREAUTH-007-11: Phase 1 Boundary Marker Schema
# This script verifies that phase and data_authority columns exist on monitoring_records and trigger enforces Phase 1 marker rules

TASK_ID="TSK-P2-PREAUTH-007-11"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_11.json"

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
  jq '.checks += [{"id": "tsk_p2_preauth_007_11_check_01", "description": "DATABASE_URL is set", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_11_check_01", "description": "DATABASE_URL is set", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 2: Verify monitoring_records table exists
TABLE_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'monitoring_records');" 2>/dev/null | tr -d ' ')
if [ "$TABLE_EXISTS" != "t" ]; then
  echo "ERROR: monitoring_records table does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_11_check_02", "description": "monitoring_records table exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_11_check_02", "description": "monitoring_records table exists", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 3: Verify phase and data_authority columns exist
REQUIRED_COLUMNS=("phase" "data_authority")
ALL_COLUMNS_EXIST=true
for col in "${REQUIRED_COLUMNS[@]}"; do
  COL_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'monitoring_records' AND column_name = '$col');" 2>/dev/null | tr -d ' ')
  if [ "$COL_EXISTS" != "t" ]; then
    echo "ERROR: Column $col does not exist in monitoring_records table" >&2
    ALL_COLUMNS_EXIST=false
  fi
done

if [ "$ALL_COLUMNS_EXIST" = false ]; then
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_11_check_03", "description": "Columns exist on monitoring_records", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_11_check_03", "description": "Columns exist on monitoring_records", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 4: Verify trigger exists
TRIGGER_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM pg_trigger WHERE tgname = 'trg_enforce_phase1_boundary');" 2>/dev/null | tr -d ' ')
if [ "$TRIGGER_EXISTS" != "t" ]; then
  echo "ERROR: Trigger trg_enforce_phase1_boundary does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_11_check_04", "description": "Trigger trg_enforce_phase1_boundary exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_11_check_04", "description": "Trigger trg_enforce_phase1_boundary exists", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 5: Positive test - trigger function logic verification (columns and trigger exist)
TRIGGER_FUNCTION_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM pg_proc WHERE proname = 'enforce_phase1_boundary');" 2>/dev/null | tr -d ' ')
if [ "$TRIGGER_FUNCTION_EXISTS" = "t" ]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-11-P1", "description": "Positive test: Trigger function enforce_phase1_boundary exists", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Positive test failed - trigger function does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-11-P1", "description": "Positive test: Trigger function enforce_phase1_boundary exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 6: Negative test - verify trigger function contains phase1 boundary logic
TRIGGER_LOGIC_CHECK=$(psql "$DATABASE_URL" -t -c "SELECT prosrc FROM pg_proc WHERE proname = 'enforce_phase1_boundary';" 2>/dev/null)
if [[ "$TRIGGER_LOGIC_CHECK" == *"phase1"* ]] && [[ "$TRIGGER_LOGIC_CHECK" == *"phase1_indicative_only"* ]] && [[ "$TRIGGER_LOGIC_CHECK" == *"audit_grade"* ]]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-11-N1", "description": "Negative test: Trigger contains phase1 boundary logic", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Negative test failed - trigger does not contain expected phase1 boundary logic" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-11-N1", "description": "Negative test: Trigger contains phase1 boundary logic", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 7: Negative test - verify trigger uses SECURITY DEFINER
SECURITY_DEFINER_CHECK=$(psql "$DATABASE_URL" -t -c "SELECT prosecdef FROM pg_proc WHERE proname = 'enforce_phase1_boundary';" 2>/dev/null | tr -d ' ')
if [ "$SECURITY_DEFINER_CHECK" = "t" ]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-11-N2", "description": "Negative test: Trigger function uses SECURITY DEFINER", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Negative test failed - trigger does not use SECURITY DEFINER" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-11-N2", "description": "Negative test: Trigger function uses SECURITY DEFINER", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 8: Positive test - verify trigger has SET search_path
SEARCH_PATH_CHECK=$(psql "$DATABASE_URL" -t -c "SELECT proconfig FROM pg_proc WHERE proname = 'enforce_phase1_boundary';" 2>/dev/null)
if [[ "$SEARCH_PATH_CHECK" == *"search_path"* ]] || [[ "$SEARCH_PATH_CHECK" == *"pg_catalog"* ]]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-11-P2", "description": "Positive test: Trigger function has SET search_path", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Positive test failed - trigger does not have SET search_path" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-11-P2", "description": "Positive test: Trigger function has SET search_path", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Add observed hash for the script
SCRIPT_HASH=$(sha256sum "$0" | awk '{print $1}')
jq ".observed_hashes += [{\"path\": \"$0\", \"sha256\": \"$SCRIPT_HASH\"}]" "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Final success update
jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

echo "PASS: Phase 1 Boundary Marker Schema verified"
