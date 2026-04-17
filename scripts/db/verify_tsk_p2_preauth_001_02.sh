#!/bin/bash
# Verification script for TSK-P2-PREAUTH-001-02
# Verifies resolve_interpretation_pack() function with exact signature and SECURITY DEFINER

set -e

EVIDENCE_FILE="evidence/phase2/tsk_p2_preauth_001_02.json"
TASK_ID="TSK-P2-PREAUTH-001-02"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize evidence
mkdir -p evidence/phase2
echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"IN_PROGRESS","checks":[]}' > "$EVIDENCE_FILE"

# Check 1: Function exists with exact signature
echo "Checking if resolve_interpretation_pack function exists with exact signature..."
FUNCTION_EXISTS=$(psql -tAc "SELECT 1 FROM pg_proc WHERE proname='resolve_interpretation_pack' AND prorettype='uuid'::regtype AND pronargs=2 AND proargtypes[0]='uuid'::regtype AND proargtypes[1]='timestamptz'::regtype")
if [ "$FUNCTION_EXISTS" = "1" ]; then
    echo "✓ Function exists with exact signature"
else
    echo "✗ Function does not exist or has incorrect signature"
    echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"FAIL","checks":[{"name":"function_exists","status":"FAIL","message":"Function does not exist or has incorrect signature"}]}' > "$EVIDENCE_FILE"
    exit 1
fi

# Check 2: Function is SECURITY DEFINER
echo "Checking if function is SECURITY DEFINER..."
SECURITY_DEFINER=$(psql -tAc "SELECT prosecdef FROM pg_proc WHERE proname='resolve_interpretation_pack'")
if [ "$SECURITY_DEFINER" = "t" ]; then
    echo "✓ Function is SECURITY DEFINER"
else
    echo "✗ Function is not SECURITY DEFINER"
    echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"FAIL","checks":[{"name":"security_definer_present","status":"FAIL","message":"Function is not SECURITY DEFINER"}]}' > "$EVIDENCE_FILE"
    exit 1
fi

# Check 3: Function has hardened search_path
echo "Checking if function has hardened search_path..."
SEARCH_PATH=$(psql -tAc "SELECT proconfig FROM pg_proc WHERE proname='resolve_interpretation_pack'")
if echo "$SEARCH_PATH" | grep -q "search_path"; then
    echo "✓ Function has hardened search_path"
else
    echo "✗ Function does not have hardened search_path"
    echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"FAIL","checks":[{"name":"search_path_hardened","status":"FAIL","message":"Function does not have hardened search_path"}]}' > "$EVIDENCE_FILE"
    exit 1
fi

# All checks passed
echo '{"task_id":"'"$TASK_ID"'","git_sha":"'"$GIT_SHA"'","timestamp_utc":"'"$TIMESTAMP_UTC"'","status":"PASS","checks":[{"name":"function_exists","status":"PASS"},{"name":"security_definer_present","status":"PASS"},{"name":"search_path_hardened","status":"PASS"}],"function_exists":true,"function_signature_correct":true,"security_definer_present":true}' > "$EVIDENCE_FILE"

echo "All checks passed for TSK-P2-PREAUTH-001-02"
