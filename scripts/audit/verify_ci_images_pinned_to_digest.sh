#!/usr/bin/env bash
set -euo pipefail
image=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) image="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done
[[ -n "$image" ]] || { echo "--image is required"; exit 1; }
pattern="${image}@sha256:[0-9a-f]{64}"
pattern="${image}(:[^[:space:]]+)?@sha256:[0-9a-f]{64}"
rg -n "$pattern" .github/workflows/invariants.yml >/dev/null || { echo "❌ ${image} is not pinned by digest in CI"; exit 1; }
echo "✅ ${image} is digest-pinned in CI workflow"
