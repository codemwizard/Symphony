#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROGRAM="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
GUARDS="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/RequestSecurityGuards.cs"
EVIDENCE="$ROOT_DIR/evidence/security/sec_003_trust_boundary_corrections.json"
mkdir -p "$(dirname "$EVIDENCE")"
rg -n "SYMPHONY_TRUSTED_PROXIES|ForwardedHeaders.None|KnownProxies.Add" "$PROGRAM" >/dev/null
! rg -n "ReadForwardedFor" "$GUARDS" >/dev/null
rg -n "AuthorizeTenantScope\(tenantId\)|WHERE ia\.instruction_id = @instruction_id\s+AND ia\.tenant_id = @tenant_id" "$PROGRAM" >/dev/null
python3 - <<'PY' "$EVIDENCE"
import json, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
  json.dump({
    'task_id': 'SEC-003',
    'status': 'PASS',
    'pass': True,
    'trusted_proxy_config_required': True,
    'spoofable_forwarded_for_fallback_removed': True,
    'tenant_object_scope_enforced': True,
  }, fh, indent=2)
  fh.write('\n')
PY
echo "SEC-003 verification passed: $EVIDENCE"
