#!/usr/bin/env bash
set -euo pipefail
# Pass if supervisor_api is absent; otherwise enforce no dynamic SQL sink patterns.
TARGET="services/supervisor_api/server.py"
if [[ ! -f "$TARGET" ]]; then
  echo "supervisor_api not present; no SQLi vectors to test in this repo surface"
  exit 0
fi
if rg -n "subprocess\\.(check_output|run|Popen).*psql|def psql_scalar|def psql_json_array" "$TARGET" >/dev/null; then
  echo "❌ supervisor_api still contains shell-to-DB sink patterns"
  exit 1
fi
if rg -n "f\".*SELECT|\\.format\\(.*SELECT|\\+.*SELECT" "$TARGET" >/dev/null; then
  echo "❌ supervisor_api contains potential SQLi string construction"
  exit 1
fi
echo "✅ supervisor_api SQLi vector checks passed"
