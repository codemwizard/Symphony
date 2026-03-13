#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LEDGER_STAGE="$ROOT_DIR/services/ledger-api/.publish"
WORKER_STAGE="$ROOT_DIR/services/executor-worker/.publish"
LEDGER_TAG="${LEDGER_TAG:-symphony/demo-ledger-api:pilot}"
WORKER_TAG="${WORKER_TAG:-symphony/demo-executor-worker:pilot}"

cleanup() {
  rm -rf "$LEDGER_STAGE" "$WORKER_STAGE"
}
trap cleanup EXIT

mkdir -p "$LEDGER_STAGE/app" "$LEDGER_STAGE/src" "$WORKER_STAGE/app"

dotnet publish "$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj" -c Release -o "$LEDGER_STAGE/app"
cp -R "$ROOT_DIR/src/supervisory-dashboard" "$LEDGER_STAGE/src/"
cp -R "$ROOT_DIR/scripts" "$LEDGER_STAGE/"
cp -R "$ROOT_DIR/evidence" "$LEDGER_STAGE/"

dotnet publish "$ROOT_DIR/services/executor-worker/dotnet/src/ExecutorWorker/ExecutorWorker.csproj" -c Release -o "$WORKER_STAGE/app"

docker build -f "$ROOT_DIR/services/ledger-api/Dockerfile" -t "$LEDGER_TAG" "$ROOT_DIR/services/ledger-api"
docker build -f "$ROOT_DIR/services/executor-worker/Dockerfile" -t "$WORKER_TAG" "$ROOT_DIR/services/executor-worker"

echo "Built $LEDGER_TAG"
echo "Built $WORKER_TAG"
