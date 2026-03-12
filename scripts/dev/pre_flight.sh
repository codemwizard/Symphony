#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "==> Pre-flight local checks"
echo "==> Light commit-path gate: staged structural preflight only"
bash scripts/audit/preflight_structural_staged.sh
echo "==> Heavy push-time parity remains in scripts/dev/pre_ci.sh"
