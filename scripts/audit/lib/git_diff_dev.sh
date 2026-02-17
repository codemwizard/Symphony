#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT_DIR/scripts/lib/git_diff_range_only.sh"
source "$ROOT_DIR/scripts/lib/git_diff_dev.sh"
