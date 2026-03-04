#!/usr/bin/env bash
set -euo pipefail

# R-000 Negative Test: Prove admin endpoints reject requests without ADMIN_API_KEY.
# This is a static code analysis test (does not require a running server).
# It verifies that AuthorizeAdminTenantOnboarding enforces the key structurally.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROGRAM_CS="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs"

status="PASS"
errors=()

echo "=== R-000: Admin Endpoint Auth Requirement Test ==="

# --- Negative Test 1: x-admin-claim bypass must NOT exist ---
echo -n "  [N1] x-admin-claim bypass absent... "
if grep -qE 'x-admin-claim' "$PROGRAM_CS" 2>/dev/null; then
  echo "FAIL"
  status="FAIL"
  errors+=("x-admin-claim bypass still present — any caller can skip auth")
else
  echo "PASS"
fi

# --- Negative Test 2: Missing ADMIN_API_KEY must return 503 ---
echo -n "  [N2] Missing ADMIN_API_KEY returns 503... "
if grep -qE 'AUTHZ_CONFIG_MISSING' "$PROGRAM_CS" 2>/dev/null \
  && grep -qE 'ADMIN_API_KEY must be configured' "$PROGRAM_CS" 2>/dev/null; then
  echo "PASS"
else
  echo "FAIL"
  status="FAIL"
  errors+=("No fail-closed 503 for missing ADMIN_API_KEY found")
fi

# --- Positive Test 1: SecureEquals is used for key comparison ---
echo -n "  [P1] SecureEquals used for admin key comparison... "
# The AuthorizeAdminTenantOnboarding method must call SecureEquals
if grep -A 30 'AuthorizeAdminTenantOnboarding' "$PROGRAM_CS" | grep -q 'SecureEquals'; then
  echo "PASS"
else
  echo "FAIL"
  status="FAIL"
  errors+=("SecureEquals not used in AuthorizeAdminTenantOnboarding — timing attack possible")
fi

# --- Positive Test 2: All admin endpoints route through AuthorizeAdminTenantOnboarding ---
echo -n "  [P2] All /v1/admin/ endpoints use AuthorizeAdminTenantOnboarding... "
admin_endpoints=$(grep -cE 'MapPost\s*\(\s*"/v1/admin/' "$PROGRAM_CS" || true)
admin_authz=$(grep -cE 'AuthorizeAdminTenantOnboarding' "$PROGRAM_CS" || true)
# There should be at least as many authz calls as admin endpoint registrations
if [[ "$admin_endpoints" -gt 0 && "$admin_authz" -ge "$admin_endpoints" ]]; then
  echo "PASS (${admin_endpoints} endpoints, ${admin_authz} authz calls)"
else
  echo "FAIL (${admin_endpoints} endpoints, ${admin_authz} authz calls)"
  status="FAIL"
  errors+=("Not all admin endpoints are guarded by AuthorizeAdminTenantOnboarding")
fi

echo ""
if [[ "$status" != "PASS" ]]; then
  echo "❌ R-000 admin endpoint auth test FAILED:" >&2
  for e in "${errors[@]}"; do echo "  - $e" >&2; done
  exit 1
fi

echo "✅ R-000 admin endpoint auth test PASSED."
