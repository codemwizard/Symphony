#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

before_head="$(git rev-parse HEAD)"
before_branch="$(git rev-parse --abbrev-ref HEAD)"

export GIT_DIR="$ROOT_DIR/.git"
export GIT_WORK_TREE="$ROOT_DIR"
export GIT_INDEX_FILE="$ROOT_DIR/.git/index"

bash "$ROOT_DIR/scripts/audit/test_diff_semantics_parity.sh" >/tmp/symphony_parity_hostile_stdout.txt

after_head="$(git rev-parse HEAD)"
after_branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$before_head" != "$after_head" ]]; then
  echo "❌ parity hostile-env test mutated HEAD" >&2
  exit 1
fi
if [[ "$before_branch" != "$after_branch" ]]; then
  echo "❌ parity hostile-env test mutated branch" >&2
  exit 1
fi

if ! grep -q '^Diff semantics parity fixtures passed\.$' /tmp/symphony_parity_hostile_stdout.txt; then
  echo "❌ parity hostile-env test did not report fixture success" >&2
  exit 1
fi

echo "Diff semantics parity hostile-env regression passed."
