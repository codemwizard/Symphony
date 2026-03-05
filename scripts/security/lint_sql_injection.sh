#!/usr/bin/env bash
set -euo pipefail

# Compatibility wrapper: keep legacy entrypoint name wired to current lint.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/lint_app_sql_injection.sh" "$@"
