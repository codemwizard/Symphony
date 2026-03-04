#!/usr/bin/env bash
set -euo pipefail
# Pass if supervisor_api is absent; otherwise enforce no string-concat SQL patterns.
if [[ ! -f scripts/supervisor_api.py ]]; then
  echo "supervisor_api not present; no SQLi vectors to test in this repo surface"
  exit 0
fi
if rg -n "f\".*SELECT|\.format\(.*SELECT|\+.*SELECT" scripts/supervisor_api.py >/dev/null; then
  echo "❌ supervisor_api contains potential SQLi string construction"
  exit 1
fi
echo "✅ supervisor_api SQLi vector checks passed"
