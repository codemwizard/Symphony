#!/usr/bin/env bash
set -euo pipefail
file="services/ledger-api/dotnet/src/LedgerApi/Program.cs"
rg -n 'Request\.Query\.ContainsKey\("token"\)' "$file" >/dev/null
rg -n 'UNAUTHORIZED_TOKEN_TRANSPORT' "$file" >/dev/null
echo "✅ Querystring token transport is explicitly rejected"
