#!/usr/bin/env bash
set -euo pipefail

# Wrapper for canonical diff semantics used by audit scripts.
# Source this file from scripts under scripts/audit/**.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT_DIR/scripts/lib/git_diff.sh"
