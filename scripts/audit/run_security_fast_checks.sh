#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "==> Fast security checks (cheap, deterministic)"

run() { echo ""; echo "-> $*"; "$@"; }

echo ""
echo "==> Shell syntax checks (scripts/security/*.sh)"
for f in scripts/security/*.sh; do
  [[ -f "$f" ]] || continue
  run bash -n "$f"
done

echo ""
echo "==> Required security scripts present"
REQ=(
  "scripts/security/lint_sql_injection.sh"
  "scripts/security/lint_privilege_grants.sh"
  "scripts/security/lint_core_boundary.sh"
)
for f in "${REQ[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: missing required file: $f"
    exit 1
  fi
done

echo ""
echo "==> Run security lints"
run scripts/security/lint_sql_injection.sh
run scripts/security/lint_privilege_grants.sh
run scripts/security/lint_core_boundary.sh

echo ""
echo "✅ Fast security checks passed"
