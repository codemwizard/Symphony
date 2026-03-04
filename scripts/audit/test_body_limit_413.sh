#!/usr/bin/env bash
set -euo pipefail
file="services/ledger-api/dotnet/src/LedgerApi/Program.cs"
rg -n 'SYMPHONY_MAX_BODY_BYTES' "$file" >/dev/null
rg -n 'StatusCodes\.Status413PayloadTooLarge' "$file" >/dev/null
echo "✅ Request body size guard with deterministic 413 response is configured"
