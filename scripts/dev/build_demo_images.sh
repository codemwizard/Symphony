#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LEDGER_TAG="${LEDGER_TAG:-symphony/demo-ledger-api:pilot}"
WORKER_TAG="${WORKER_TAG:-symphony/demo-executor-worker:pilot}"

docker build -f "$ROOT_DIR/services/ledger-api/Dockerfile" -t "$LEDGER_TAG" "$ROOT_DIR"
docker build -f "$ROOT_DIR/services/executor-worker/Dockerfile" -t "$WORKER_TAG" "$ROOT_DIR"

echo "Built $LEDGER_TAG"
echo "Built $WORKER_TAG"
