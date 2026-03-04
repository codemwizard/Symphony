#!/usr/bin/env bash
set -euo pipefail
file="services/ledger-api/dotnet/src/LedgerApi/appsettings.json"
if rg -n '"AllowedHosts"\s*:\s*"\*"' "$file" >/dev/null; then
  echo "❌ AllowedHosts wildcard is set in non-dev appsettings"
  exit 1
fi
rg -n '"AllowedHosts"\s*:\s*"[^"]+"' "$file" >/dev/null
echo "✅ AllowedHosts is explicitly scoped in non-dev settings"
