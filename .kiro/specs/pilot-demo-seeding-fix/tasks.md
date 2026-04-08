# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Worker Seeding FK Constraint Violation
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For deterministic bugs, scope the property to the concrete failing case(s) to ensure reproducibility
  - Test that `SeedChungaWorkers()` fails with FK constraint violation when tenant ID doesn't exist in `public.tenants`
  - The test assertions should match the Expected Behavior Properties from design
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found to understand root cause
  - Mark task complete when test is written, run, and failure is documented
  - _Bug_Condition: isBugCondition(input) where input.tenantId NOT IN (SELECT tenant_id FROM public.tenants) AND input.operation = "INSERT INTO supplier_registry"_
  - _Expected_Behavior: Worker records SHALL successfully insert into supplier_registry without foreign key constraint violations_
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Existing Seeding Behavior
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-buggy inputs
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - Test cases to observe and capture:
    - Tenant creation in `tenant_registry` (control plane) works correctly
    - Tenant onboarding in `public.tenants` via `OnboardAsync` works correctly
    - Programme creation and activation works correctly
    - Legacy `escrow_accounts` and `programs` table seeding works correctly
    - `CreateStableGuid()` deterministic behavior remains unchanged
    - `SeedDemoInstructions()` functions independently
  - _Preservation: All seeding operations NOT involving tenant ID parameter passing between SeedDemoTenant() and SeedChungaWorkers() SHALL produce exactly the same behavior_
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [x] 3. Fix for pilot demo seeding FK constraint violation

  - [x] 3.1 Modify `SeedDemoTenant` to return actual tenant ID
    - Change function signature from `async Task SeedDemoTenant(...)` to `async Task<Guid?> SeedDemoTenant(...)`
    - Location: `services/ledger-api/dotnet/src/LedgerApi/Program.cs` line ~1506
    - After successful tenant onboarding and programme creation, return `actualTenantId` (line ~1600)
    - In the catch block, return `null` to indicate seeding failure (line ~1630)
    - _Bug_Condition: isBugCondition(input) where input.tenantId NOT IN (SELECT tenant_id FROM public.tenants)_
    - _Expected_Behavior: SeedDemoTenant SHALL return the actual tenant ID from the database that exists in public.tenants_
    - _Preservation: Tenant creation, programme setup, and legacy table seeding SHALL remain unchanged_
    - _Requirements: 2.1, 3.1, 3.2_

  - [x] 3.2 Modify `SeedChungaWorkers` to accept tenant ID parameter
    - Change function signature from `async Task SeedChungaWorkers(IProgrammeStore ps, ILogger l)` to `async Task SeedChungaWorkers(IProgrammeStore ps, ILogger l, Guid actualTenantId)`
    - Location: `services/ledger-api/dotnet/src/LedgerApi/Program.cs` line ~1641
    - Remove tenant ID computation logic (environment variable read and `CreateStableGuid` call)
    - Replace computed `DemoTenantId` with passed parameter: `var DemoTenantId = actualTenantId.ToString();`
    - _Bug_Condition: isBugCondition(input) where SeedChungaWorkers recomputes tenant ID independently_
    - _Expected_Behavior: SeedChungaWorkers SHALL use the actual tenant ID passed as parameter_
    - _Preservation: Worker registration logic, supplier_type setting, and allowlist additions SHALL remain unchanged_
    - _Requirements: 2.2, 3.3, 3.4_

  - [x] 3.3 Update caller to pass tenant ID and handle null case
    - Location: `services/ledger-api/dotnet/src/LedgerApi/Program.cs` line ~1495
    - Capture return value: `var actualTenantId = await SeedDemoTenant(...);`
    - Add conditional worker seeding:
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
    - _Bug_Condition: isBugCondition(input) where tenant ID is not passed between functions_
    - _Expected_Behavior: Caller SHALL pass actual tenant ID to SeedChungaWorkers and skip worker seeding if tenant seeding fails_
    - _Preservation: SeedDemoInstructions SHALL continue to function independently_
    - _Requirements: 2.1, 2.2, 2.3, 3.7_

  - [x] 3.4 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Worker Seeding with Valid Tenant ID
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - Verify that `SeedChungaWorkers` successfully inserts worker records without FK constraint violations
    - Verify that worker records in `supplier_registry` have correct `tenant_id` matching `public.tenants`
    - _Expected_Behavior: For any worker seeding attempt where tenant ID is actual ID from SeedDemoTenant, workers SHALL insert successfully_
    - _Requirements: 2.1, 2.2, 2.3_

  - [x] 3.5 Verify preservation tests still pass
    - **Property 2: Preservation** - Existing Seeding Behavior
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions)
    - Verify tenant creation, programme setup, and legacy table seeding continue to work correctly
    - Verify `SeedDemoInstructions()` continues to function independently
    - _Preservation: All seeding operations NOT involving tenant ID parameter passing SHALL produce exactly the same behavior as before_
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [x] 4. Checkpoint - Ensure all tests pass
  - Run full seeding flow: Delete database, run migrations, start LedgerApi with `SYMPHONY_RUNTIME_PROFILE=pilot-demo`
  - Verify tenant and workers are seeded successfully
  - Check database state: Verify `public.tenants` contains tenant, `supplier_registry` contains workers with matching `tenant_id`
  - Check logs: Verify no FK constraint errors (23503), verify success messages for both tenant and worker seeding
  - Test restart scenario: Restart LedgerApi, verify idempotent behavior (no duplicate errors)
  - Test environment variable: Set `SYMPHONY_UI_TENANT_ID`, verify both functions use the same tenant ID
  - Ensure all tests pass, ask the user if questions arise
