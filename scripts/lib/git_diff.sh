#!/usr/bin/env bash
set -euo pipefail

# Backward-compatible aggregate import:
# - parity-critical scripts must source scripts/lib/git_diff_range_only.sh directly
# - development/staged helpers live in scripts/lib/git_diff_dev.sh
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/git_diff_range_only.sh"
source "$ROOT_DIR/lib/git_diff_dev.sh"
