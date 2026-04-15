#!/usr/bin/env bash
set -euo pipefail

# Verify TSK-P1-PLT-008: Pilot Onboarding UI Remediation
# This script enforces that the semantic drift between the UI variables and the
# .NET backend API payloads is closed via explicit parameter mappings.

TARGET_FILE="src/symphony-pilot/onboarding.html"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [[ ! -f "$TARGET_FILE" ]]; then
    echo "CRITICAL_FAIL: $TARGET_FILE not found" >&2
    exit 1
fi

missing=0
declare -a fails

# 1. Check for `t.tenant_id` and `p.programme_id` in dropdowns
if ! grep -q "\${t.tenant_id}" "$TARGET_FILE"; then
    missing=1
    fails+=("Missing \${t.tenant_id} population in dropdown")
fi

if ! grep -q "\${p.programme_id}" "$TARGET_FILE"; then
    missing=1
    fails+=("Missing \${p.programme_id} mapping in dropdown or table")
fi

# 2. Check for `dataset.tenant` extraction
if ! grep -q "dataset.tenant" "$TARGET_FILE"; then
    missing=1
    fails+=("Missing dataset.tenant extraction for bind/activate API parameters")
fi

# 3. Check for specific `{ tenant_id: tenantId` payload injections
if ! grep -q "tenant_id: tenantId" "$TARGET_FILE"; then
    missing=1
    fails+=("Missing tenant_id JSON body mapping for PUT/POST fetches")
fi

# 4. Check for `t.tenant_key` and `p.policy_code` mapping
if ! grep -q "t.tenant_key" "$TARGET_FILE" || ! grep -q "p.policy_code" "$TARGET_FILE"; then
    missing=1
    fails+=("Missing snake_case property mapping for table stats")
fi

if [[ $missing -ne 0 ]]; then
    echo "FAIL: Semantic properties not aligned in $TARGET_FILE" >&2
    for f in "${fails[@]}"; do
        echo " - $f" >&2
    done
    exit 1
fi

HASH=$(sha256sum "$TARGET_FILE" | awk '{print $1}')

cat <<EOF
{
  "task_id": "TSK-P1-PLT-008",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TS",
  "status": "PASS",
  "checks": [
    {"name": "t.tenant_id mapping", "status": "PASS"},
    {"name": "p.programme_id mapping", "status": "PASS"},
    {"name": "dataset.tenant context extraction", "status": "PASS"},
    {"name": "snake_case stat mapping", "status": "PASS"},
    {"name": "tenant_id JSON body injection", "status": "PASS"}
  ],
  "observed_paths": ["$TARGET_FILE"],
  "observed_hashes": {
    "src/symphony-pilot/onboarding.html": "$HASH"
  },
  "command_outputs": {},
  "execution_trace": [
    "audit_target_exists",
    "regex_verify_dropdowns",
    "regex_verify_dataset",
    "regex_verify_json_injections",
    "regex_verify_snake_case",
    "SUCCESS"
  ]
}
EOF
exit 0
