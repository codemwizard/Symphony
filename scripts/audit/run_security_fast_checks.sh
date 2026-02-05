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
if [[ -x scripts/security/lint_ddl_lock_risk.sh || -f scripts/security/lint_ddl_lock_risk.sh ]]; then
  run scripts/security/lint_ddl_lock_risk.sh
fi
if [[ -x scripts/security/lint_security_definer_dynamic_sql.sh || -f scripts/security/lint_security_definer_dynamic_sql.sh ]]; then
  run scripts/security/lint_security_definer_dynamic_sql.sh
fi
if [[ -x scripts/security/verify_ddl_allowlist_governance.sh || -f scripts/security/verify_ddl_allowlist_governance.sh ]]; then
  run scripts/security/verify_ddl_allowlist_governance.sh
fi

echo ""
echo "✅ Fast security checks passed"
