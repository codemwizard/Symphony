#!/usr/bin/env bash
# ============================================================
# down.sh — Stop local development environment
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🛑 Stopping Symphony development environment..."

cd "$ROOT_DIR/infra/docker"
docker compose down

echo "✅ Development environment stopped."
