#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj"

if ! command -v dotnet >/dev/null 2>&1; then
  echo "ERROR: dotnet is required for evidence pack API self-test"
  exit 1
fi

dotnet build "$PROJECT" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test-evidence-pack
