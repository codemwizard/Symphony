#!/usr/bin/env bash
set -euo pipefail
# Ensure no logging statements include Authorization token/header values.
if rg -n "Log.*Authorization|Log.*x-api-key|Log.*x-admin-api-key|Log.*Bearer" services/ledger-api/dotnet/src/LedgerApi/Program.cs >/dev/null; then
  echo "❌ Authorization-bearing fields are referenced in logger statements"
  exit 1
fi
echo "✅ Authorization header/token redaction posture verified"
