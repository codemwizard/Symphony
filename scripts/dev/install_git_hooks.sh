#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

HOOKS_DIR="$(git rev-parse --git-path hooks)"
mkdir -p "$HOOKS_DIR"

HOOK_SOURCE_DIR=".githooks"

install_hook() {
  local hook_name="$1"
  local src="$HOOK_SOURCE_DIR/$hook_name"
  local dst="$HOOKS_DIR/$hook_name"
  local src_abs dst_abs

  if [[ ! -f "$src" ]]; then
    echo "ERROR: tracked hook source missing: $src"
    exit 1
  fi

  src_abs="$(realpath "$src")"
  dst_abs="$(realpath -m "$dst")"
  if [[ "$src_abs" == "$dst_abs" ]]; then
    chmod 0755 "$dst"
    echo "✅ Hook $hook_name already active at resolved hooks path: $dst"
    return 0
  fi

  install -m 0755 "$src" "$dst"
  echo "✅ Installed $hook_name hook from tracked source: $src -> $dst"
}

install_hook pre-commit
install_hook pre-push
