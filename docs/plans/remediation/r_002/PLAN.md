# Remediation Plan: R-002 Tenant allowlist deny-all default

## Goal
Ensure that if `SYMPHONY_KNOWN_TENANTS` is unconfigured, all tenant-scoped requests are rejected (503) instead of accepted. Adds safe dev bootstrapping.

## Steps
1. Centralize the missing allowlist logic into `ApiAuthorization.AuthorizeTenantScope`.
2. Reject with explicit `StatusCodes.Status503ServiceUnavailable` instead of generic 403.
3. Keep 403 exclusively for configured allowlists with unknown tenants.
4. Update unified `/health` block.
5. Provide local DX via `scripts/dev/export_known_tenants.sh`.
6. Verify via `scripts/audit/test_tenant_allowlist_deny_all.sh` and `scripts/audit/test_tenant_allowlist_unknown_reject.sh`.
