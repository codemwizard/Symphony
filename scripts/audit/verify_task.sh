#!/usr/bin/env bash
set -e

# Canonical Task Verification Entrypoint
# This script is the single sanctioned execution shell for all Symphony task verification.

if [ -z "$1" ]; then
    echo "Usage: $0 <TASK-ID | path/to/meta.yml> [additional_args...]"
    exit 1
fi

export SYMPHONY_CANONICAL_ENTRYPOINT=1
export SYMPHONY_CANONICAL_INVOCATION="verify_task.sh"

TASK_ARG="$1"
shift

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ "$TASK_ARG" == *.yml ]]; then
    META_PATH="$TASK_ARG"
else
    META_PATH="$ROOT_DIR/tasks/$TASK_ARG/meta.yml"
fi

if [ ! -f "$META_PATH" ]; then
    echo "Error: Cannot find $META_PATH"
    exit 1
fi

export PYTHONPATH="$ROOT_DIR/scripts/audit:$PYTHONPATH"
python3 "$ROOT_DIR/scripts/audit/task_verification_runner.py" --meta "$META_PATH" "$@"
