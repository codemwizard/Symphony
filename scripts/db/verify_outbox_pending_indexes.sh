#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Single source of truth: INV-031 verifier is scripts/db/tests/test_outbox_pending_indexes.sh.
exec "$ROOT/scripts/db/tests/test_outbox_pending_indexes.sh"
