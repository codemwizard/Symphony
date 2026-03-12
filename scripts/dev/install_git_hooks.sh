#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

mkdir -p .git/hooks

HOOK_SOURCE_DIR=".githooks"

install_hook() {
  local hook_name="$1"
  local src="$HOOK_SOURCE_DIR/$hook_name"
  local dst=".git/hooks/$hook_name"

  if [[ ! -f "$src" ]]; then
    echo "ERROR: tracked hook source missing: $src"
    exit 1
  fi

  install -m 0755 "$src" "$dst"
  echo "✅ Installed $hook_name hook from tracked source: $src -> $dst"
}

install_hook pre-commit
install_hook pre-push
