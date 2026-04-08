# Pilot Demo Seeding Fix Design

## Overview

This design addresses a foreign key constraint violation that occurs during pilot demo seeding when `SeedChungaWorkers()` attempts to insert worker records into the `supplier_registry` table. The bug manifests because `SeedChungaWorkers()` independently recomputes the tenant ID from a seed string, which may not match the actual tenant ID created by `SeedDemoTenant()` and stored in the `public.tenants` table.

The fix ensures tenant ID consistency by passing the actual tenant ID from `SeedDemoTenant()` to `SeedChungaWorkers()` as a parameter, eliminating the recomputation logic and guaranteeing that worker records reference a tenant that exists in the database.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug - when `SeedChungaWorkers()` uses a tenant ID that doesn't exist in `public.tenants`
- **Property (P)**: The desired behavior - worker records should be inserted successfully using the actual tenant ID from the database
- **Preservation**: Existing seeding behavior, tenant creation logic, and worker registration that must remain unchanged by the fix
- **SeedDemoTenant()**: The function in `Program.cs` (line ~1506) that creates the demo tenant in both `tenant_registry` and `public.tenants` tables
- **SeedChungaWorkers()**: The function in `Program.cs` (line ~1641) that registers demo workers in the `supplier_registry` table
- **actualTenantId**: The tenant ID returned from the database after tenant creation, which may differ from the computed ID due to ON CONFLICT behavior
- **CreateStableGuid()**: A deterministic GUID generation function that produces the same GUID for the same seed string
- **supplier_registry**: The table that stores worker registrations with a foreign key constraint to `public.tenants(tenant_id)`

## Bug Details

### Bug Condition

The bug manifests when `SeedChungaWorkers()` attempts to insert worker records using a tenant ID that doesn't exist in the `public.tenants` table. The function independently recomputes the tenant ID from the seed string "ten-zambiagrn" or reads it from the `SYMPHONY_UI_TENANT_ID` environment variable, without receiving the actual tenant ID that was created and stored by `SeedDemoTenant()`.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type WorkerSeedingAttempt
  OUTPUT: boolean
  
  RETURN input.tenantId NOT IN (SELECT tenant_id FROM public.tenants)
         AND input.operation = "INSERT INTO supplier_registry"
         AND input.foreignKeyConstraint = "supplier_registry_tenant_id_fkey"
END FUNCTION
```

### Examples

- **Fresh Database**: `SeedDemoTenant()` creates tenant with `actualTenantId = "a1b2c3d4-..."`, but `SeedChungaWorkers()` recomputes `DemoTenantId = "e5f6g7h8-..."` → FK constraint violation
- **ON CONFLICT Scenario**: `SeedDemoTenant()` finds existing tenant and returns `actualTenantId = "x9y8z7w6-..."`, but `SeedChungaWorkers()` computes `DemoTenantId = "a1b2c3d4-..."` → FK constraint violation
- **Environment Variable Set**: `SYMPHONY_UI_TENANT_ID = "12345678-..."` is used by `SeedDemoTenant()`, but `SeedChungaWorkers()` reads a different value or recomputes → FK constraint violation
- **Edge Case - Missing Environment Variable**: `SYMPHONY_UI_TENANT_ID` is not set, both functions compute from seed, but database ON CONFLICT logic returns different ID → FK constraint violation

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Tenant creation in `tenant_registry` (control plane) must continue to work exactly as before
- Tenant onboarding in `public.tenants` (legacy table) via `OnboardAsync` must remain unchanged
- Programme creation and activation must continue to work as before
- Legacy `escrow_accounts` and `programs` table seeding must remain unchanged
- Worker registration with `supplier_type = "WORKER"` must continue as required by pilot-demo policy
- Program supplier allowlist additions must continue to work
- `CreateStableGuid()` deterministic behavior must remain unchanged
- `SeedDemoInstructions()` must continue to function independently
- Error logging for database schema errors (42P01) must remain unchanged
- Warning-level logging for seeding failures must remain unchanged

**Scope:**
All inputs that do NOT involve the tenant ID parameter passing between `SeedDemoTenant()` and `SeedChungaWorkers()` should be completely unaffected by this fix. This includes:
- All other seeding functions (`SeedDemoInstructions()`)
- Tenant creation logic and database interactions
- Worker registration logic (except tenant ID source)
- Programme creation and policy binding
- Legacy table seeding for escrow accounts and programs

## Hypothesized Root Cause

Based on the bug description and code analysis, the most likely issues are:

1. **Tenant ID Recomputation**: `SeedChungaWorkers()` independently recomputes the tenant ID using `CreateStableGuid("ten-zambiagrn")`, which may not match the actual tenant ID stored in the database by `SeedDemoTenant()` due to ON CONFLICT behavior or database-side ID generation

2. **Environment Variable Inconsistency**: The `SYMPHONY_UI_TENANT_ID` environment variable may be read at different times or with different values by the two functions, causing ID mismatch

3. **No Data Flow Between Functions**: The actual tenant ID from `SeedDemoTenant()` is not passed to `SeedChungaWorkers()`, forcing the latter to guess or recompute the ID

4. **ON CONFLICT Behavior**: When `UpsertAsync` encounters an existing tenant, it may return a different tenant ID than the one computed by `CreateStableGuid()`, but this actual ID is not propagated to `SeedChungaWorkers()`

## Correctness Properties

Property 1: Bug Condition - Worker Seeding with Valid Tenant ID

_For any_ worker seeding attempt where the tenant ID passed to `SeedChungaWorkers()` is the actual tenant ID returned from `SeedDemoTenant()` and exists in `public.tenants`, the fixed function SHALL successfully insert worker records into `supplier_registry` without foreign key constraint violations.

**Validates: Requirements 2.1, 2.2, 2.3**

Property 2: Preservation - Existing Seeding Behavior

_For any_ seeding operation that does NOT involve the tenant ID parameter passing between `SeedDemoTenant()` and `SeedChungaWorkers()`, the fixed code SHALL produce exactly the same behavior as the original code, preserving all tenant creation, programme setup, legacy table seeding, and worker registration logic.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `services/ledger-api/dotnet/src/LedgerApi/Program.cs`

**Function 1**: `SeedDemoTenant` (line ~1506)

**Specific Changes**:
1. **Change Return Type**: Modify function signature from `async Task SeedDemoTenant(...)` to `async Task<Guid?> SeedDemoTenant(...)`
   - Return `actualTenantId` on successful tenant creation
   - Return `null` on failure or when tenant already exists without successful retrieval

2. **Add Return Statement**: After successful tenant onboarding and programme creation, return the `actualTenantId` that was used for `OnboardAsync`
   - Location: After the legacy escrow/programs seeding block (line ~1600)
   - Return value: `actualTenantId` (the Guid parsed from `tenantResult.Entry.TenantId`)

3. **Return Null on Failure**: In the catch block, return `null` to indicate seeding failure
   - Location: In the catch block at the end of the function (line ~1630)

**Function 2**: `SeedChungaWorkers` (line ~1641)

**Specific Changes**:
1. **Add Parameter**: Modify function signature from `async Task SeedChungaWorkers(IProgrammeStore ps, ILogger l)` to `async Task SeedChungaWorkers(IProgrammeStore ps, ILogger l, Guid actualTenantId)`
   - Add `Guid actualTenantId` as the third parameter

2. **Remove Tenant ID Computation Logic**: Delete the entire block that computes `DemoTenantId` from environment variable or seed string
   - Remove lines that read `SYMPHONY_UI_TENANT_ID`
   - Remove lines that call `CreateStableGuid("ten-zambiagrn")`
   - Remove the conditional logic that chooses between environment variable and computed GUID

3. **Use Passed Tenant ID**: Replace the computed `DemoTenantId` with the passed parameter
   - Change: `string DemoTenantId;` → `var DemoTenantId = actualTenantId.ToString();`
   - This ensures the function uses the actual tenant ID from the database

**Caller Site**: Main seeding orchestration (line ~1495)

**Specific Changes**:
1. **Capture Return Value**: Change the call to `SeedDemoTenant` to capture the returned tenant ID
   - Before: `await SeedDemoTenant(runtimeProfile, tenantRegistryStore, programmeStore, tenantOnboardingStore, dataSource, logger);`
   - After: `var actualTenantId = await SeedDemoTenant(runtimeProfile, tenantRegistryStore, programmeStore, tenantOnboardingStore, dataSource, logger);`

2. **Conditional Worker Seeding**: Only call `SeedChungaWorkers` if tenant seeding succeeded
   - Before: `await SeedChungaWorkers(programmeStore, logger);`
   - After: 
     ```csharp
     if (actualTenantId.HasValue)
     {
         await SeedChungaWorkers(programmeStore, logger, actualTenantId.Value);
     }
     else
     {
         logger.LogWarning("Skipping worker seeding because tenant seeding did not complete successfully.");
     }
     ```

3. **Add Logging**: Log when worker seeding is skipped due to tenant seeding failure

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Manually test the unfixed code by deleting the database, running migrations, and starting the LedgerApi with `SYMPHONY_RUNTIME_PROFILE=pilot-demo`. Observe the logs for FK constraint violations. Run these tests on the UNFIXED code to observe failures and understand the root cause.

**Test Cases**:
1. **Fresh Database Test**: Delete database, run migrations, start LedgerApi → expect FK constraint violation in logs (will fail on unfixed code)
2. **Environment Variable Test**: Set `SYMPHONY_UI_TENANT_ID` to a random GUID, start LedgerApi → expect FK constraint violation (will fail on unfixed code)
3. **Existing Tenant Test**: Seed tenant manually, restart LedgerApi → expect FK constraint violation if IDs don't match (may fail on unfixed code)
4. **Log Inspection Test**: Check `supplier_registry` table for worker records → expect zero workers inserted (will fail on unfixed code)

**Expected Counterexamples**:
- Npgsql.PostgresException with SqlState "23503" (foreign key constraint violation)
- Log message: "Failed to auto-seed Chunga workers."
- Possible causes: tenant ID mismatch, environment variable inconsistency, ON CONFLICT behavior returning different ID

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  actualTenantId := SeedDemoTenant_fixed(...)
  result := SeedChungaWorkers_fixed(programmeStore, logger, actualTenantId)
  ASSERT result.success = true
  ASSERT result.workersInserted = 2
  ASSERT NO foreignKeyConstraintViolation
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT SeedDemoTenant_original(input) = SeedDemoTenant_fixed(input)
  ASSERT tenantCreationBehavior_original = tenantCreationBehavior_fixed
  ASSERT programmeCreationBehavior_original = programmeCreationBehavior_fixed
  ASSERT legacyTableSeedingBehavior_original = legacyTableSeedingBehavior_fixed
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for tenant creation, programme setup, and legacy table seeding, then write property-based tests capturing that behavior.

**Test Cases**:
1. **Tenant Creation Preservation**: Observe that tenant creation in `tenant_registry` and `public.tenants` works correctly on unfixed code, then verify this continues after fix
2. **Programme Creation Preservation**: Observe that programme creation, activation, and policy binding work correctly on unfixed code, then verify this continues after fix
3. **Legacy Table Seeding Preservation**: Observe that `escrow_accounts` and `programs` table seeding works correctly on unfixed code, then verify this continues after fix
4. **SeedDemoInstructions Independence**: Verify that `SeedDemoInstructions()` continues to work independently without requiring tenant ID parameter

### Unit Tests

- Test `SeedDemoTenant` returns non-null Guid on successful tenant creation
- Test `SeedDemoTenant` returns null on failure (database error, schema missing)
- Test `SeedChungaWorkers` successfully inserts workers when given valid tenant ID
- Test `SeedChungaWorkers` with tenant ID that exists in `public.tenants` → success
- Test caller skips `SeedChungaWorkers` when `SeedDemoTenant` returns null
- Test that worker records in `supplier_registry` have correct `tenant_id` matching `public.tenants`

### Property-Based Tests

- Generate random tenant keys and verify `SeedDemoTenant` always returns a valid Guid that exists in `public.tenants`
- Generate random worker configurations and verify `SeedChungaWorkers` succeeds when given the actual tenant ID from the database
- Test that across many seeding attempts, the tenant ID passed to `SeedChungaWorkers` always matches the tenant ID in `public.tenants`

### Integration Tests

- Full seeding flow: Delete database, run migrations, start LedgerApi, verify tenant and workers are seeded successfully
- Restart test: Seed once, restart LedgerApi, verify idempotent behavior (no duplicate errors)
- Environment variable test: Set `SYMPHONY_UI_TENANT_ID`, verify both functions use the same tenant ID
- Check database state: Verify `public.tenants` contains tenant, `supplier_registry` contains workers with matching `tenant_id`
- Check logs: Verify no FK constraint errors, verify success messages for both tenant and worker seeding
