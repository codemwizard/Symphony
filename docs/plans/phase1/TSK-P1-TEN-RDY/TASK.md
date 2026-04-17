# TSK-P1-TEN-RDY: Tenant Readiness Middleware

## Phase: Tenant Readiness Middleware
## Phase Key: TSK-P1-TEN-RDY

### Tasks

- [x] **Component 1**: Create `ITenantReadinessProbe` interface + `EnvVarTenantReadinessProbe` + `DatabaseTenantReadinessProbe`
- [x] **Component 2**: Create `TenantReadinessMiddleware`
- [x] **Component 3**: Wire middleware into `Program.cs`, update `/health` endpoints, update `SeedDemoTenant`
- [x] **Component 4**: Clean up `ApiAuthorization.cs` (add ReadinessProbe fallback for pilot-demo)
- [x] **Component 5**: Fix `test_tenant_allowlist_deny_all.sh` (force production profile, remove unnecessary auth headers)
- [x] **Component 6**: Create unit tests + register in self-test entry point
- [x] **Build verification**: `dotnet build` — 0 errors, 2 pre-existing warnings

### Unit Tests Created/Run
| Test | Component | Status |
|------|-----------|--------|
| Test_EnvVar_EmptyEnv_NotReady | EnvVarTenantReadinessProbe | BUILD OK |
| Test_EnvVar_PopulatedEnv_Ready | EnvVarTenantReadinessProbe | BUILD OK |
| Test_EnvVar_MarkReady_NoOp | EnvVarTenantReadinessProbe | BUILD OK |
| Test_Middleware_NotReady_V1Path_Returns503 | TenantReadinessMiddleware | BUILD OK |
| Test_Middleware_NotReady_HealthPath_Passthrough | TenantReadinessMiddleware | BUILD OK |
| Test_Middleware_NotReady_HealthzPath_Passthrough | TenantReadinessMiddleware | BUILD OK |
| Test_Middleware_NotReady_ReadyzPath_Passthrough | TenantReadinessMiddleware | BUILD OK |
| Test_Middleware_NotReady_BootstrapEndpoint_Passthrough | TenantReadinessMiddleware | BUILD OK |
| Test_Middleware_NotReady_PilotUiPath_Passthrough | TenantReadinessMiddleware | BUILD OK |
| Test_Middleware_NotReady_SessionPath_Passthrough | TenantReadinessMiddleware | BUILD OK |
| Test_Middleware_Ready_V1Path_Passthrough | TenantReadinessMiddleware | BUILD OK |
| Test_Middleware_503Body_HasCorrectErrorCode | TenantReadinessMiddleware | BUILD OK |
| test_tenant_allowlist_deny_all.sh | Integration (R-002) | PENDING RUNTIME |
