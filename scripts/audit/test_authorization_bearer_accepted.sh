#!/usr/bin/env bash
set -euo pipefail
file="services/ledger-api/dotnet/src/LedgerApi/Program.cs"
rg -n 'ReadBearerToken\(' "$file" >/dev/null
rg -n 'Authorization"' "$file" >/dev/null
rg -n 'StartsWith\("Bearer "' "$file" >/dev/null
echo "✅ Authorization bearer scheme support present"
