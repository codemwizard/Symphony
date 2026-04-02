#!/usr/bin/env bash
set -euo pipefail
# Verify TASK-UI-WIRE-014: Public landing route and browser-safe context contract

PROGRAM_CS="services/ledger-api/dotnet/src/LedgerApi/Program.cs"
HANDLERS_CS="services/ledger-api/dotnet/src/LedgerApi/Commands/EvidenceLinkHandlers.cs"
PASS=0; FAIL=0

check() {
  local desc="$1" file="$2" pattern="$3"
  if grep -qF "$pattern" "$file" 2>/dev/null; then
    echo "PASS: $desc"; PASS=$((PASS+1))
  else
    echo "FAIL: $desc"; FAIL=$((FAIL+1))
  fi
}

check "Landing route mapped" "$PROGRAM_CS" '/pilot-demo/evidence-link'
check "Context API mapped" "$PROGRAM_CS" '/api/public/evidence-links/context'
check "Token extracted from query" "$PROGRAM_CS" 'httpContext.Request.Query.TryGetValue("token"'
check "Token validated via EvidenceLinkTokenService" "$PROGRAM_CS" 'EvidenceLinkTokenService.ValidateToken(token, signingKey'
check "Duplicate check in context endpoint" "$PROGRAM_CS" 'ALREADY_SUBMITTED'
check "landing_url appended to issue response" "$HANDLERS_CS" 'landing_url = $"/pilot-demo/evidence-link#token={token}"'
check "Context returns require_gps flag" "$PROGRAM_CS" 'require_gps = validation.ExpectedLatitude'

echo "---"
echo "TASK-UI-WIRE-014: $PASS passed, $FAIL failed"
exit $FAIL
