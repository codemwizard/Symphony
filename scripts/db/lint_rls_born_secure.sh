#!/usr/bin/env bash
# Born-Secure RLS Lint — bash wrapper for lint_rls_born_secure.py
#
# Enforces exact canonical RLS templates on GF migration files.
# See lint_rls_born_secure.py for enforcement rules.
#
# Usage:
#   lint_rls_born_secure.sh <sql_file> [sql_file ...]
#   lint_rls_born_secure.sh schema/migrations/008[0-9]_gf_*.sql
#
# Exit 0 = PASS, Exit 1 = FAIL, Exit 2 = setup error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LINT_PY="$SCRIPT_DIR/lint_rls_born_secure.py"

# Use venv python if available
if [[ -x "$REPO_ROOT/.venv/bin/python3" ]]; then
    PYTHON="$REPO_ROOT/.venv/bin/python3"
else
    PYTHON="python3"
fi

if [[ ! -f "$LINT_PY" ]]; then
    echo "ERROR: lint_rls_born_secure.py not found at $LINT_PY" >&2
    exit 2
fi

if [[ $# -lt 1 ]]; then
    # Auto-discover GF migration files when called without args (pre_ci integration)
    shopt -s nullglob
    GF_FILES=("$REPO_ROOT"/schema/migrations/008[0-9]_gf_*.sql)
    shopt -u nullglob
    if [[ ${#GF_FILES[@]} -eq 0 ]]; then
        echo "INFO: No GF migration files found to lint; skipping." >&2
        exit 0
    fi
    set -- "${GF_FILES[@]}"
fi

exec "$PYTHON" "$LINT_PY" "$@"
