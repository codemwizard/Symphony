#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PROJECT="services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj"

# Self-test mode validates ingress contract + fail-closed semantics without binding a network socket.
dotnet build "$PROJECT" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test
