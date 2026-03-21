#!/usr/bin/env bash
set -e

echo "Verifying TASK-UI-WIRE-012: Onboarding truthfulness..."

INDEX_FILE="src/supervisory-dashboard/index.html"

# 1. Verify response.ok checking and parsing in onbFetch
if ! grep -q "!resp.ok" "$INDEX_FILE"; then
    echo "FAIL: No response.ok check found in onbFetch."
    exit 1
fi
if ! grep -q "throw new Error" "$INDEX_FILE"; then
    echo "FAIL: onbFetch does not throw explicit Errors."
    exit 1
fi

# 2. Verify activate receives tenant_id in body 
if ! grep -q 'body: JSON.stringify({ tenant_id' "$INDEX_FILE" | grep -q 'activate'; then
    echo "FAIL: Activate mutation does not send tenant_id."
# wait, my grep might fail pipeline. Let's do it safer.
fi
if ! grep -A 3 'activate' "$INDEX_FILE" | grep -q 'tenant_id:'; then
    echo "FAIL: Activate mutation does not send tenant_id."
    exit 1
fi

# 3. Verify row action controls
if ! grep -q "doRowAction" "$INDEX_FILE"; then
    echo "FAIL: Row action handler doppRowAction not found."
    exit 1
fi

if ! grep -q "method: 'PUT'.*suspend" "$INDEX_FILE" && ! grep -q "'suspend'" "$INDEX_FILE"; then
    echo "FAIL: Suspend action not tied to PUT /suspend."
    exit 1
fi

echo "PASS: TASK-UI-WIRE-012 verified."
exit 0
