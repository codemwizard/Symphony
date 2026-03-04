#!/usr/bin/env bash
set -euo pipefail
file="services/ledger-api/dotnet/src/LedgerApi/Program.cs"
rg -n 'AddRateLimiter' "$file" >/dev/null
rg -n 'StatusCodes\.Status429TooManyRequests' "$file" >/dev/null
rg -n 'UseRateLimiter\(' "$file" >/dev/null
echo "✅ Rate limiter middleware and 429 rejection configured"
