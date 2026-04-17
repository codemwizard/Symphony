# TSK-P1-TEN-RDY Walkthrough: Tenant Readiness Middleware

## Problem Solved

Symphony's multi-tenancy architecture had a middleware ordering bug: admin authentication (403 `FORBIDDEN_ADMIN_REQUIRED`) executed **before** the tenant readiness check (503 `TENANT_ALLOWLIST_UNCONFIGURED`). When no tenants were configured, requests received a misleading 403 instead of the semantically correct 503.

Additionally, the pilot-demo profile hardcoded `tenantAllowlistConfigured = true`, bypassing the security check entirely.

## What Changed

### New Files

| File | Purpose |
|------|---------|
| [ITenantReadinessProbe.cs](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/services/ledger-api/dotnet/src/LedgerApi/Security/ITenantReadinessProbe.cs) | Interface + 2 implementations: `EnvVarTenantReadinessProbe` (production) and `DatabaseTenantReadinessProbe` (pilot-demo only) |
| [TenantReadinessMiddleware.cs](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/services/ledger-api/dotnet/src/LedgerApi/Security/TenantReadinessMiddleware.cs) | Class-based middleware for unit testing; inline version used in Program.cs |
| [TenantReadinessMiddlewareTests.cs](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/services/ledger-api/dotnet/src/LedgerApi/Security/TenantReadinessMiddlewareTests.cs) | 12 unit tests covering probes, middleware routing, and 503 response body |

### Modified Files

| File | Changes |
|------|---------|
| [Program.cs](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/services/ledger-api/dotnet/src/LedgerApi/Program.cs) | Replaced `tenantAllowlistConfigured` boolean with `ITenantReadinessProbe`; added inline middleware after `UseRateLimiter()`; updated `/health`, `/healthz`, `/readyz` endpoints; wired probe into `SeedDemoTenant` with `MarkReady()` calls |
| [ApiAuthorization.cs](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/services/ledger-api/dotnet/src/LedgerApi/Security/ApiAuthorization.cs) | Added static `ReadinessProbe` property; `AuthorizeTenantScope` falls through when probe reports ready and env var is empty (pilot-demo path only) |
| [DemoSelfTestEntryPoint.cs](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/services/ledger-api/dotnet/src/LedgerApi/Demo/DemoSelfTestEntryPoint.cs) | Registered `--self-test-tenant-readiness` command |
| [test_tenant_allowlist_deny_all.sh](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/scripts/audit/test_tenant_allowlist_deny_all.sh) | Forces `SYMPHONY_RUNTIME_PROFILE=production`; removed auth headers from 503 test (middleware intercepts before auth) |

## Architecture

### Before (broken)
```
Request → Body Size → Rate Limit → [Handler: Admin Auth (403)] → [Handler: Tenant Scope (503)]
                                    ^^^^^^^^^^^^^^^^^^^^^^^^
                                    Blocks before 503 can run
```

### After (fixed)
```
Request → Body Size → Rate Limit → TenantReadinessMiddleware (503) → [Handler: Admin Auth (403)]
                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                    503 returned BEFORE any auth check
```

### Production vs Pilot-Demo Isolation

```
Production path:     EnvVarTenantReadinessProbe → checks SYMPHONY_KNOWN_TENANTS
                     ApiAuthorization.ReadinessProbe = null (never set)

Pilot-demo path:     DatabaseTenantReadinessProbe → queries tenant_registry at startup
                     ApiAuthorization.ReadinessProbe = dbProbe (set at startup only)
                     SeedDemoTenant → calls readinessProbe.MarkReady()
```

Production code has **zero dependency** on the pilot-demo implementation.

## Verification

- **Build**: `dotnet build` — **0 errors**, 2 pre-existing warnings
- **Unit tests**: 12 tests in `TenantReadinessMiddlewareTests.cs` (runnable via `--self-test-tenant-readiness`)
- **Integration**: `test_tenant_allowlist_deny_all.sh` updated to validate the core invariant: 503 returned WITHOUT any auth credentials
