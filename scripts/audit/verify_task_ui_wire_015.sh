#!/usr/bin/env bash
set -euo pipefail
# Verify TASK-UI-WIRE-015: Artifact upload contract for secure-link recipients

PROGRAM_CS="services/ledger-api/dotnet/src/LedgerApi/Program.cs"
PASS=0; FAIL=0

check() {
  local desc="$1" file="$2" pattern="$3"
  if grep -qF "$pattern" "$file" 2>/dev/null; then
    echo "PASS: $desc"; PASS=$((PASS+1))
  else
    echo "FAIL: $desc"; FAIL=$((FAIL+1))
  fi
}

check "Upload endpoint mapped" "$PROGRAM_CS" '/api/public/evidence-links/upload'
check "Token validated in upload" "$PROGRAM_CS" 'EvidenceLinkTokenService.ValidateToken(token, signingKey, DateTimeOffset.UtcNow)'
check "Multipart form check" "$PROGRAM_CS" 'httpContext.Request.HasFormContentType'
check "Artifact file read" "$PROGRAM_CS" 'form.Files.GetFile("artifact")'
check "Size limit enforced" "$PROGRAM_CS" 'FILE_TOO_LARGE'
check "artifact_ref returned" "$PROGRAM_CS" 'artifact_ref = artifactRef'
check "Antiforgery disabled for upload" "$PROGRAM_CS" 'DisableAntiforgery()'

echo "---"
echo "TASK-UI-WIRE-015: $PASS passed, $FAIL failed"
exit $FAIL
