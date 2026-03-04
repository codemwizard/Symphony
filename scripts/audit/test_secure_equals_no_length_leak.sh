#!/usr/bin/env bash
set -euo pipefail
file="services/ledger-api/dotnet/src/LedgerApi/Program.cs"
rg -n 'SHA256\.HashData' "$file" >/dev/null
if rg -n 'expectedBytes\.Length != actualBytes\.Length' "$file" >/dev/null; then
  echo "❌ length-based early return still present in SecureEquals"
  exit 1
fi
rg -n 'FixedTimeEquals' "$file" >/dev/null
echo "✅ SecureEquals uses hash-then-compare with fixed-time compare"
