# Pilot Demo Seeding Error Analysis & Fix Plan

## Error Summary

**Error**: Foreign key constraint violation when seeding Chunga workers
```
23503: insert or update on table "supplier_registry" violates foreign key constraint "supplier_registry_tenant_id_fkey"
```

**Location**: `Program.cs:1668` in `SeedChungaWorkers()` function

**Root Cause**: The `supplier_registry` table has a foreign key constraint requiring that `tenant_id` exists in the `public.tenants` table, but the tenant may not be properly seeded in that table.

---

## Database Schema Analysis

### Foreign Key Constraint

From `schema/migrations/0075_supplier_registry_and_programme_allowlist.sql`:
```sql
CREATE TABLE IF NOT EXISTS public.supplier_registry (
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    supplier_id TEXT NOT NULL,
    ...
);
```

**Constraint**: `supplier_registry.tenant_id` MUST exist in `public.tenants.tenant_id`

---

## Current Seeding Flow

### Step 1: `SeedDemoTenant()` (Line ~1506)
```csharp
// 1. Creates tenant in tenant_registry (control plane)
var tenantResult = await trs.UpsertAsync(tenantId, demoTenantKey, "Zambia Green MFI", ...);

// 2. Creates tenant in public.tenants (legacy table) via OnboardAsync
await tos.OnboardAsync(new TenantOnboardingInput(
    actualTenantId, "Zambia Green MFI", "ZM", "enterprise", ...
), CancellationToken.None);

// 3. Creates programme
var progResult = await ps.CreateAsync(actualTenantId, "PGM-ZAMBIA-GRN-001", ...);
```

### Step 2: `SeedChungaWorkers()` (Line ~1641)
```csharp
// Attempts to insert workers into supplier_registry
await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    DemoTenantId, workerChunga001Id, "Chunga Worker 001", ...
));
```

---

## Root Cause Analysis

### Issue 1: Tenant ID Mismatch

**In `SeedDemoTenant()`**:
```csharp
var tenantId = CreateStableGuid(demoTenantKey);  // Computed GUID
var tenantResult = await trs.UpsertAsync(tenantId, ...);
var actualTenantId = Guid.Parse(tenantResult.Entry.TenantId);  // Actual GUID from DB
await tos.OnboardAsync(new TenantOnboardingInput(actualTenantId, ...));  // Uses actualTenantId
```

**In `SeedChungaWorkers()`**:
```csharp
var uiTidStr = Environment.GetEnvironmentVariable("SYMPHONY_UI_TENANT_ID");
string DemoTenantId;
if (!Guid.TryParse(uiTidStr, out var tenantGuid))
{
    DemoTenantId = CreateStableGuid("ten-zambiagrn").ToString();  // Recomputes GUID
}
else
{
    DemoTenantId = tenantGuid.ToString();
}

// Uses DemoTenantId which may NOT match actualTenantId from SeedDemoTenant
await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    DemoTenantId, ...  // ❌ May not exist in public.tenants
));
```

### Issue 2: No Verification of Tenant Existence

`SeedChungaWorkers()` does not verify that the tenant exists in `public.tenants` before attempting to insert workers.

### Issue 3: Error Handling Masks the Problem

```csharp
catch (Exception ex)
{
    l.LogWarning(ex, "Failed to auto-seed Chunga workers.");
}
```

The error is logged as a warning and execution continues, but the workers are not seeded.

---

## Why This Happens

### Scenario A: Fresh Database
1. `SeedDemoTenant()` runs successfully
2. Tenant is created in `public.tenants` with `actualTenantId`
3. `SeedChungaWorkers()` recomputes `DemoTenantId` from the same seed
4. **If `actualTenantId != DemoTenantId`** (due to ON CONFLICT or other logic), the FK constraint fails

### Scenario B: Existing Tenant
1. `SeedDemoTenant()` finds existing tenant in `tenant_registry`
2. `OnboardAsync()` may skip inserting into `public.tenants` (ON CONFLICT DO UPDATE)
3. `SeedChungaWorkers()` uses a different tenant ID
4. FK constraint fails

### Scenario C: Environment Variable Set
1. `SYMPHONY_UI_TENANT_ID` is set to a different GUID
2. `SeedChungaWorkers()` uses that GUID
3. That GUID doesn't exist in `public.tenants`
4. FK constraint fails

---

## Fix Plan

### Option 1: Pass Tenant ID from SeedDemoTenant to SeedChungaWorkers ✅ RECOMMENDED

**Changes Required**:

1. **Modify function signature**:
```csharp
// Before
async Task SeedChungaWorkers(IProgrammeStore ps, ILogger l)

// After
async Task SeedChungaWorkers(IProgrammeStore ps, ILogger l, Guid actualTenantId)
```

2. **Update SeedDemoTenant to return tenant ID**:
```csharp
async Task<Guid?> SeedDemoTenant(...)
{
    // ... existing logic ...
    var actualTenantId = Guid.Parse(tenantResult.Entry.TenantId);
    await tos.OnboardAsync(new TenantOnboardingInput(actualTenantId, ...));
    // ... rest of logic ...
    return actualTenantId;  // Return the actual tenant ID
}
```

3. **Update caller**:
```csharp
// Before
await SeedDemoTenant(runtimeProfile, tenantRegistryStore, programmeStore, tenantOnboardingStore, dataSource, logger);
await SeedChungaWorkers(programmeStore, logger);

// After
var actualTenantId = await SeedDemoTenant(runtimeProfile, tenantRegistryStore, programmeStore, tenantOnboardingStore, dataSource, logger);
if (actualTenantId.HasValue)
{
    await SeedChungaWorkers(programmeStore, logger, actualTenantId.Value);
}
```

4. **Update SeedChungaWorkers to use passed tenant ID**:
```csharp
async Task SeedChungaWorkers(IProgrammeStore ps, ILogger l, Guid actualTenantId)
{
    try
    {
        var DemoTenantId = actualTenantId.ToString();  // Use passed ID, not recomputed
        
        // ... rest of logic unchanged ...
    }
    catch (Exception ex)
    {
        l.LogWarning(ex, "Failed to auto-seed Chunga workers.");
    }
}
```

**Pros**:
- ✅ Guarantees tenant ID consistency
- ✅ Minimal code changes
- ✅ Clear data flow
- ✅ No environment variable dependency

**Cons**:
- Requires function signature changes

---

### Option 2: Query Tenant ID from Database

**Changes Required**:

1. **Add tenant lookup in SeedChungaWorkers**:
```csharp
async Task SeedChungaWorkers(IProgrammeStore ps, ILogger l)
{
    try
    {
        // Query the actual tenant ID from tenant_registry
        var tenantKey = "ten-zambiagrn";
        var tenant = await tenantRegistryStore.GetByKeyAsync(tenantKey, default);
        
        if (tenant == null)
        {
            l.LogWarning("Demo tenant not found. Skipping worker seeding.");
            return;
        }
        
        var DemoTenantId = tenant.TenantId;  // Use actual ID from DB
        
        // ... rest of logic ...
    }
    catch (Exception ex)
    {
        l.LogWarning(ex, "Failed to auto-seed Chunga workers.");
    }
}
```

**Pros**:
- ✅ No function signature changes
- ✅ Always uses correct tenant ID from DB
- ✅ Self-healing if tenant exists

**Cons**:
- ❌ Requires additional database query
- ❌ Needs access to `tenantRegistryStore` (not currently passed)
- ❌ More complex

---

### Option 3: Use Shared Constant for Tenant ID

**Changes Required**:

1. **Define constant at top of Program.cs**:
```csharp
// At class level
private static readonly Guid DEMO_TENANT_ID = CreateStableGuid("ten-zambiagrn");
```

2. **Use constant in both functions**:
```csharp
async Task SeedDemoTenant(...)
{
    var tenantId = DEMO_TENANT_ID;  // Use constant
    // ... rest of logic ...
}

async Task SeedChungaWorkers(...)
{
    var DemoTenantId = DEMO_TENANT_ID.ToString();  // Use same constant
    // ... rest of logic ...
}
```

**Pros**:
- ✅ Simple
- ✅ No function signature changes
- ✅ Guaranteed consistency

**Cons**:
- ❌ Doesn't handle `SYMPHONY_UI_TENANT_ID` environment variable
- ❌ Assumes stable GUID generation is deterministic
- ❌ Doesn't account for ON CONFLICT scenarios

---

## Recommended Solution: Option 1

**Why**: Option 1 is the most robust because it:
1. Uses the **actual tenant ID returned from the database**
2. Handles ON CONFLICT scenarios correctly
3. Respects `SYMPHONY_UI_TENANT_ID` if set in `SeedDemoTenant`
4. Makes data flow explicit and traceable
5. Prevents ID mismatches at the source

---

## Implementation Steps

### Step 1: Modify SeedDemoTenant Return Type
- Change return type from `Task` to `Task<Guid?>`
- Return `actualTenantId` on success
- Return `null` on failure

### Step 2: Modify SeedChungaWorkers Signature
- Add `Guid actualTenantId` parameter
- Remove tenant ID computation logic
- Use passed `actualTenantId` directly

### Step 3: Update Caller
- Capture return value from `SeedDemoTenant`
- Pass tenant ID to `SeedChungaWorkers`
- Add null check before calling `SeedChungaWorkers`

### Step 4: Update SeedDemoInstructions (if needed)
- Check if `SeedDemoInstructions` also needs the tenant ID
- Apply same pattern if necessary

### Step 5: Test
- Delete database
- Run migrations
- Start LedgerApi
- Verify tenant and workers are seeded successfully
- Check logs for no FK constraint errors

---

## Additional Improvements

### 1. Better Error Logging
```csharp
catch (Exception ex)
{
    if (ex is Npgsql.PostgresException pex && pex.SqlState == "23503")
    {
        l.LogError(ex, "Foreign key constraint violation: tenant_id {TenantId} does not exist in public.tenants", DemoTenantId);
    }
    else
    {
        l.LogWarning(ex, "Failed to auto-seed Chunga workers.");
    }
}
```

### 2. Verify Tenant Exists Before Seeding Workers
```csharp
// Add verification query
await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
await using var cmd = conn.CreateCommand();
cmd.CommandText = "SELECT EXISTS(SELECT 1 FROM public.tenants WHERE tenant_id = @tid)";
cmd.Parameters.AddWithValue("tid", actualTenantId);
var exists = (bool)(await cmd.ExecuteScalarAsync() ?? false);

if (!exists)
{
    l.LogError("Tenant {TenantId} does not exist in public.tenants. Cannot seed workers.", actualTenantId);
    return;
}
```

### 3. Make Seeding Idempotent
```csharp
// Check if workers already exist before inserting
var existingWorker = await SupplierPolicyStore.GetSupplierAsync(DemoTenantId, workerChunga001Id);
if (existingWorker != null)
{
    l.LogInformation("Worker {WorkerId} already exists. Skipping.", workerChunga001Id);
    return;
}
```

---

## Testing Checklist

- [ ] Fresh database: Tenant and workers seed successfully
- [ ] Existing tenant: Workers seed successfully
- [ ] `SYMPHONY_UI_TENANT_ID` set: Uses correct tenant ID
- [ ] Database without tenant: Logs error, doesn't crash
- [ ] Multiple restarts: Idempotent (no duplicate errors)
- [ ] Check `public.tenants` table: Tenant exists
- [ ] Check `supplier_registry` table: Workers exist with correct `tenant_id`
- [ ] Check logs: No FK constraint errors

---

## Files to Modify

1. **services/ledger-api/dotnet/src/LedgerApi/Program.cs**
   - Line ~1495: Update caller
   - Line ~1506: Modify `SeedDemoTenant` return type
   - Line ~1641: Modify `SeedChungaWorkers` signature

---

## Estimated Effort

- **Code changes**: 15-20 lines
- **Testing**: 30 minutes
- **Total**: 1 hour

---

**Status**: Analysis Complete - Ready for Implementation
**Priority**: HIGH (Blocks pilot demo functionality)
**Risk**: LOW (Isolated change, well-understood problem)
