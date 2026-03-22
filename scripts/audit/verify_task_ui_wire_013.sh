#!/usr/bin/env bash
set -e

echo "Verifying TASK-UI-WIRE-013: Guided onboarding workflow UX..."

INDEX_FILE="src/supervisory-dashboard/index.html"

# 1. Verify UI forms exist with Tenant constraints
if ! grep -q 'id="btn-create-prog".*disabled' "$INDEX_FILE"; then
    echo "FAIL: Create Programme button is not constrained/disabled by default."
    exit 1
fi
if ! grep -q 'id="btn-register-sup".*disabled' "$INDEX_FILE"; then
    echo "FAIL: Register Supplier button is not constrained/disabled by default."
    exit 1
fi
if ! grep -q 'id="btn-activate-prog".*disabled' "$INDEX_FILE"; then
    echo "FAIL: Activate button is not constrained/disabled by default."
    exit 1
fi

# 2. Verify checkDisabled logic is present in loadOnboardingState
if ! grep -q "checkDisabled(" "$INDEX_FILE"; then
    echo "FAIL: Event listener constraints for forms were not implemented."
    exit 1
fi

echo "PASS: TASK-UI-WIRE-013 verified."
exit 0
