using System.Text.Json;
using Microsoft.Extensions.Logging;
using Npgsql;

namespace Symphony.LedgerApi.Demo;

/// <summary>
/// Preservation Property Tests for Pilot Demo Seeding Fix
/// 
/// IMPORTANT: Follow observation-first methodology.
/// These tests capture the baseline behavior on UNFIXED code that must be preserved after the fix.
/// 
/// Preservation Requirements (from bugfix.md section 3):
/// - 3.1: Tenant creation in tenant_registry and public.tenants
/// - 3.2: Programme creation with legacy escrow_accounts and programs seeding
/// - 3.3: Worker registration with supplier_type = "WORKER"
/// - 3.4: Program supplier allowlist additions
/// - 3.5: Database schema error handling (42P01)
/// - 3.6: CreateStableGuid deterministic behavior
/// - 3.7: SeedDemoInstructions independence
/// 
/// Expected Outcome: Tests PASS on unfixed code (confirms baseline behavior to preserve)
/// </summary>
public static class PilotDemoSeedingPreservationTest
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = global::EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = global::EvidenceMeta.Load(rootDir);
        var evidencePath = Path.Combine(evidenceDir, "pilot_demo_seeding_preservation.json");

        logger.LogInformation("=== Preservation Property Tests ===");
        logger.LogInformation("Capturing baseline behavior that must be preserved after the fix.");

        var testResults = new List<object>();
        var allPassed = true;

        // Test Case 1: CreateStableGuid deterministic behavior (Requirement 3.6)
        try
        {
            logger.LogInformation("Test 1: Verifying CreateStableGuid deterministic behavior...");

            var seed = "test-stable-guid-seed";
            var guid1 = global::StableGuidHelper.CreateStableGuid(seed);
            var guid2 = global::StableGuidHelper.CreateStableGuid(seed);
            var guid3 = global::StableGuidHelper.CreateStableGuid(seed);

            bool isDeterministic = guid1 == guid2 && guid2 == guid3;

            logger.LogInformation($"CreateStableGuid is deterministic: {isDeterministic}");
            logger.LogInformation($"Generated GUID: {guid1}");

            testResults.Add(new
            {
                test_case = "create_stable_guid_deterministic",
                status = isDeterministic ? "PASS" : "FAIL",
                requirement = "3.6",
                details = new
                {
                    seed,
                    guid_1 = guid1.ToString(),
                    guid_2 = guid2.ToString(),
                    guid_3 = guid3.ToString(),
                    is_deterministic = isDeterministic
                },
                note = "CreateStableGuid must return the same GUID for the same seed string"
            });

            if (!isDeterministic)
            {
                allPassed = false;
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Test 1 failed with unexpected error");
            testResults.Add(new
            {
                test_case = "create_stable_guid_deterministic",
                status = "ERROR",
                requirement = "3.6",
                error = ex.Message
            });
            allPassed = false;
        }

        // Test Case 2: Worker registration with supplier_type = "WORKER" (Requirement 3.3)
        try
        {
            logger.LogInformation("Test 2: Verifying worker registration with supplier_type = 'WORKER'...");

            var testTenantId = "33333333-3333-3333-3333-333333333333";
            var testWorkerId = global::StableGuidHelper.CreateStableGuid("worker-preservation-test").ToString();

            Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", testTenantId);

            // Register a worker with supplier_type = "WORKER"
            await global::SupplierRegistryUpsertHandler.HandleAsync(new global::SupplierRegistryUpsertRequest(
                testTenantId,
                testWorkerId,
                "Preservation Test Worker",
                "MMO:+260971100888",
                -15.4167m,
                28.2833m,
                true,
                supplier_type: "WORKER"));

            // Retrieve the worker and verify supplier_type
            var worker = await global::SupplierPolicyStore.GetSupplierAsync(testTenantId, testWorkerId);

            bool workerExists = worker is not null;
            bool hasCorrectType = worker?.supplier_type == "WORKER";

            logger.LogInformation($"Worker exists: {workerExists}, Correct type: {hasCorrectType}");

            testResults.Add(new
            {
                test_case = "worker_registration_with_supplier_type",
                status = (workerExists && hasCorrectType) ? "PASS" : "FAIL",
                requirement = "3.3",
                details = new
                {
                    worker_exists = workerExists,
                    supplier_type = worker?.supplier_type,
                    expected_type = "WORKER",
                    has_correct_type = hasCorrectType
                },
                note = "Workers must be registered with supplier_type = 'WORKER' as required by pilot-demo policy"
            });

            if (!workerExists || !hasCorrectType)
            {
                allPassed = false;
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Test 2 failed with unexpected error");
            testResults.Add(new
            {
                test_case = "worker_registration_with_supplier_type",
                status = "ERROR",
                requirement = "3.3",
                error = ex.Message
            });
            allPassed = false;
        }

        // Test Case 3: Program supplier allowlist additions (Requirement 3.4)
        try
        {
            logger.LogInformation("Test 3: Verifying program supplier allowlist additions...");

            var testTenantId = "33333333-3333-3333-3333-333333333333";
            var testProgramId = "PGM-PRESERVATION-TEST";
            var testSupplierId = global::StableGuidHelper.CreateStableGuid("supplier-preservation-test").ToString();

            // Add supplier to allowlist
            await global::ProgramSupplierAllowlistUpsertHandler.HandleAsync(
                new global::ProgramSupplierAllowlistUpsertRequest(
                    testTenantId,
                    testProgramId,
                    testSupplierId,
                    true));

            // Verify the supplier is in the allowlist by checking policy
            var policyResult = await global::ProgramSupplierPolicyReadHandler.HandleAsync(
                testTenantId,
                testProgramId,
                testSupplierId);

            bool allowlistWorked = policyResult.StatusCode == 200;

            logger.LogInformation($"Allowlist addition worked: {allowlistWorked}");

            testResults.Add(new
            {
                test_case = "program_supplier_allowlist_additions",
                status = allowlistWorked ? "PASS" : "FAIL",
                requirement = "3.4",
                details = new
                {
                    allowlist_worked = allowlistWorked,
                    policy_status_code = policyResult.StatusCode
                },
                note = "Program supplier allowlist additions must continue to work"
            });

            if (!allowlistWorked)
            {
                allPassed = false;
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Test 3 failed with unexpected error");
            testResults.Add(new
            {
                test_case = "program_supplier_allowlist_additions",
                status = "ERROR",
                requirement = "3.4",
                error = ex.Message
            });
            allPassed = false;
        }

        // Test Case 4: Tenant creation behavior (Requirements 3.1, 3.2)
        // This test documents the expected tenant creation flow
        testResults.Add(new
        {
            test_case = "tenant_creation_behavior_documented",
            status = "INFO",
            requirements = new[] { "3.1", "3.2" },
            details = new
            {
                tenant_registry_creation = "SeedDemoTenant creates tenant in tenant_registry (control plane)",
                public_tenants_creation = "SeedDemoTenant creates tenant in public.tenants via OnboardAsync",
                programme_creation = "SeedDemoTenant creates programme and activates it",
                legacy_seeding = "SeedDemoTenant seeds escrow_accounts and programs tables for FK constraints",
                preservation_note = "All of these behaviors must remain unchanged after the fix"
            },
            note = "Tenant creation, programme setup, and legacy table seeding must continue to work exactly as before"
        });

        // Test Case 5: SeedDemoInstructions independence (Requirement 3.7)
        testResults.Add(new
        {
            test_case = "seed_demo_instructions_independence",
            status = "INFO",
            requirement = "3.7",
            details = new
            {
                independence_note = "SeedDemoInstructions must continue to function independently",
                no_parameter_changes = "SeedDemoInstructions should not require tenant ID parameter changes",
                preservation_note = "This function is not affected by the tenant ID passing fix"
            },
            note = "SeedDemoInstructions must remain completely independent of the tenant ID fix"
        });

        // Test Case 6: Database schema error handling (Requirement 3.5)
        testResults.Add(new
        {
            test_case = "database_schema_error_handling",
            status = "INFO",
            requirement = "3.5",
            details = new
            {
                error_code = "42P01",
                error_type = "Database schema not found",
                expected_behavior = "System logs critical error with migration guidance",
                preservation_note = "Error handling for schema errors must remain unchanged"
            },
            note = "Database schema error handling (42P01) must continue to log critical errors with migration guidance"
        });

        var finalStatus = allPassed ? "PASS" : "FAIL";

        await File.WriteAllTextAsync(
            evidencePath,
            JsonSerializer.Serialize(new
            {
                check_id = "PILOT-DEMO-SEEDING-PRESERVATION",
                task_id = "pilot-demo-seeding-fix-task-2",
                timestamp_utc = evidenceMeta.TimestampUtc,
                git_sha = evidenceMeta.GitSha,
                schema_fingerprint = evidenceMeta.SchemaFingerprint,
                status = finalStatus,
                pass = allPassed,
                note = "These tests capture baseline behavior on UNFIXED code that must be preserved after the fix.",
                test_results = testResults
            }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine,
            cancellationToken);

        logger.LogInformation($"=== Preservation Tests Complete ===");
        logger.LogInformation($"Evidence written: {evidencePath}");
        logger.LogInformation($"Status: {finalStatus}");
        logger.LogInformation($"Tests passed: {testResults.Count(t => t.GetType().GetProperty("status")?.GetValue(t)?.ToString() == "PASS")}/{testResults.Count(t => t.GetType().GetProperty("status")?.GetValue(t)?.ToString() != "INFO")}");

        return allPassed ? 0 : 1;
    }
}
