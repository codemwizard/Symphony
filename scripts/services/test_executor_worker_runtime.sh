#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="$ROOT_DIR/services/executor-worker/dotnet/src/ExecutorWorker/ExecutorWorker.csproj"

if ! command -v dotnet >/dev/null 2>&1; then
  echo "ERROR: dotnet is required for executor worker self-test"
  exit 1
fi

dotnet build "$PROJECT" -nologo -v minimal >/dev/null
dotnet run --no-launch-profile --project "$PROJECT" -- --self-test
