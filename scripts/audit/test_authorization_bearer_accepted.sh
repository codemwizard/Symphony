#!/usr/bin/env bash
set -euo pipefail
file="services/ledger-api/dotnet/src/LedgerApi/Program.cs"
rg -n 'ReadAuthorizationToken\(' "$file" >/dev/null
rg -n 'Authorization"' "$file" >/dev/null
rg -n 'string\\.Equals\\(parts\\[0\\], \"bearer\"' "$file" >/dev/null
echo "✅ Authorization header token scheme support present"
