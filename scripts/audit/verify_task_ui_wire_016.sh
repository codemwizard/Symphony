#!/usr/bin/env bash
set -euo pipefail
# Verify TASK-UI-WIRE-016: End-to-end landing submission UX

HANDLERS_CS="services/ledger-api/dotnet/src/LedgerApi/Commands/EvidenceLinkHandlers.cs"
LANDING="src/recipient-landing/index.html"
PASS=0; FAIL=0

check() {
  local desc="$1" file="$2" pattern="$3"
  if grep -qF "$pattern" "$file" 2>/dev/null; then
    echo "PASS: $desc"; PASS=$((PASS+1))
  else
    echo "FAIL: $desc"; FAIL=$((FAIL+1))
  fi
}

# Backend duplicate protection
check "409 duplicate protection" "$HANDLERS_CS" 'DUPLICATE_SUBMISSION'
check "Duplicate check reads log" "$HANDLERS_CS" 'EvidenceLinkSubmissionLog.ReadAll()'
check "409 status code" "$HANDLERS_CS" 'Status409Conflict'

# Landing page UX
check "Landing page exists" "$LANDING" '<!DOCTYPE html>'
check "Token extraction from hash" "$LANDING" 'hash.match(/token=([^&]+)/)'
check "Context API called" "$LANDING" '/api/public/evidence-links/context'
check "Upload API called" "$LANDING" '/api/public/evidence-links/upload'
check "Submit API called" "$LANDING" '/v1/evidence-links/submit'
check "GPS acquisition" "$LANDING" 'navigator.geolocation.getCurrentPosition'
check "Duplicate screen" "$LANDING" 'screen-duplicate'
check "Success screen" "$LANDING" 'screen-success'
check "Error screen" "$LANDING" 'screen-error'
check "File size validation" "$LANDING" '10 * 1024 * 1024'

echo "---"
echo "TASK-UI-WIRE-016: $PASS passed, $FAIL failed"
exit $FAIL
