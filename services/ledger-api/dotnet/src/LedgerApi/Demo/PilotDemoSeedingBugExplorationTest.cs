using System.Text.Json;
using Microsoft.Extensions.Logging;
using Npgsql;

namespace Symphony.LedgerApi.Demo;

/// <summary>
/// Bug Condition Exploration Test for Pilot Demo Seeding FK Constraint Violation
/// 
/// CRITICAL: This test MUST FAIL on unfixed code - failure confirms the bug exists.
/// DO NOT attempt to fix the test or the code when it fails.
/// 
/// Bug Condition: SeedChungaWorkers() uses a tenant ID that doesn't exist in public.tenants,
/// causing FK constraint violation (23503) when inserting into supplier_registry.
/// 
/// Expected Behavior (after fix): Workers should insert successfully using the actual tenant ID
/// from SeedDemoTenant() that exists in the database.
/// 
/// Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3
/// 
/// NOTE: This test demonstrates the bug by checking if workers were successfully seeded.
/// On UNFIXED code: Workers will NOT be in supplier_registry (FK violation prevents insert)
/// On FIXED code: Workers WILL be in supplier_registry (using correct tenant ID)
/// </summary>
public static class PilotDemoSeedingBugExplorationTest
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = global::EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = global::EvidenceMeta.Load(rootDir);
        var evidencePath = Path.Combine(evidenceDir, "pilot_demo_seeding_bug_exploration.json");

        logger.LogInformation("=== Bug Condition Exploration Test ===");
        logger.LogInformation("This test checks if the pilot demo seeding bug exists.");
        logger.LogInformation("On UNFIXED code: Workers will NOT be seeded (FK violation)");
        logger.LogInformation("On FIXED code: Workers WILL be seeded successfully");

        var testResults = new List<object>();
        var bugExists = false;

        // Test Case 1: Check if Chunga workers exist in supplier_registry
        // On unfixed code, they should NOT exist due to FK constraint violation
        // On fixed code, they SHOULD exist
        try
        {
            logger.LogInformation("Test 1: Checking if Chunga workers were seeded...");

            var worker001Id = global::StableGuidHelper.CreateStableGuid("worker-chunga-001").ToString();
            var worker002Id = global::StableGuidHelper.CreateStableGuid("worker-chunga-002").ToString();

            // Attempt to retrieve workers from supplier registry
            // Note: We need to know the tenant ID to query, so we'll use the computed one
            var demoTenantId = global::StableGuidHelper.CreateStableGuid("ten-zambiagrn").ToString();

            var worker001 = await global::SupplierPolicyStore.GetSupplierAsync(demoTenantId, worker001Id);
            var worker002 = await global::SupplierPolicyStore.GetSupplierAsync(demoTenantId, worker002Id);

            bool worker001Exists = worker001 is not null;
            bool worker002Exists = worker002 is not null;

            logger.LogInformation($"Worker 001 exists: {worker001Exists}");
            logger.LogInformation($"Worker 002 exists: {worker002Exists}");

            // On UNFIXED code: Workers should NOT exist (FK violation prevented insert)
            // On FIXED code: Workers SHOULD exist
            if (!worker001Exists || !worker002Exists)
            {
                bugExists = true;
                logger.LogWarning("BUG CONFIRMED: Workers were not seeded (FK constraint violation likely occurred)");
            }
            else
            {
                logger.LogInformation("Workers exist - bug may be fixed OR test is running after successful manual seeding");
            }

            testResults.Add(new
            {
                test_case = "chunga_workers_seeded",
                status = (worker001Exists && worker002Exists) ? "PASS" : "FAIL",
                details = new
                {
                    worker_001_exists = worker001Exists,
                    worker_002_exists = worker002Exists,
                    tenant_id_used = demoTenantId,
                    worker_001_id = worker001Id,
                    worker_002_id = worker002Id
                },
                note = "On unfixed code, workers should NOT exist. On fixed code, workers SHOULD exist."
            });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Test 1 failed with unexpected error");
            testResults.Add(new
            {
                test_case = "chunga_workers_seeded",
                status = "ERROR",
                error = ex.Message
            });
            bugExists = true;
        }

        // Test Case 2: Verify tenant exists in public.tenants
        // This confirms the tenant was created successfully
        try
        {
            logger.LogInformation("Test 2: Checking if demo tenant exists in public.tenants...");

            var demoTenantId = global::StableGuidHelper.CreateStableGuid("ten-zambiagrn");

            // Query public.tenants directly to check if tenant exists
            var dataSourceStr = Environment.GetEnvironmentVariable("DATABASE_URL");
            if (string.IsNullOrEmpty(dataSourceStr))
            {
                throw new InvalidOperationException("DATABASE_URL environment variable not set");
            }

            await using var dataSource = NpgsqlDataSource.Create(dataSourceStr);
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = "SELECT COUNT(*) FROM public.tenants WHERE tenant_id = @tid";
            cmd.Parameters.AddWithValue("tid", demoTenantId);

            var count = (long)(await cmd.ExecuteScalarAsync(cancellationToken) ?? 0L);
            bool tenantExists = count > 0;

            logger.LogInformation($"Demo tenant exists in public.tenants: {tenantExists}");

            testResults.Add(new
            {
                test_case = "demo_tenant_exists",
                status = tenantExists ? "PASS" : "FAIL",
                details = new
                {
                    tenant_exists = tenantExists,
                    tenant_id = demoTenantId.ToString()
                },
                note = "Tenant should exist if SeedDemoTenant ran successfully"
            });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Test 2 failed with unexpected error");
            testResults.Add(new
            {
                test_case = "demo_tenant_exists",
                status = "ERROR",
                error = ex.Message
            });
        }

        // Test Case 3: Check for FK constraint violation in logs
        // This is indirect evidence - we document that the error should appear in logs
        testResults.Add(new
        {
            test_case = "fk_constraint_violation_documented",
            status = "INFO",
            details = new
            {
                expected_error = "23503: insert or update on table \"supplier_registry\" violates foreign key constraint \"supplier_registry_tenant_id_fkey\"",
                check_logs = "Review application logs for this error message"
            },
            note = "On unfixed code, this error should appear in logs when SeedChungaWorkers runs"
        });

        var finalStatus = bugExists ? "BUG_CONFIRMED" : "BUG_NOT_DETECTED";

        await File.WriteAllTextAsync(
            evidencePath,
            JsonSerializer.Serialize(new
            {
                check_id = "PILOT-DEMO-SEEDING-BUG-EXPLORATION",
                task_id = "pilot-demo-seeding-fix-task-1",
                timestamp_utc = evidenceMeta.TimestampUtc,
                git_sha = evidenceMeta.GitSha,
                schema_fingerprint = evidenceMeta.SchemaFingerprint,
                status = finalStatus,
                bug_exists = bugExists,
                note = "On UNFIXED code, bug should be confirmed (workers not seeded). On FIXED code, bug should not be detected (workers seeded successfully).",
                test_results = testResults
            }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine,
            cancellationToken);

        logger.LogInformation($"=== Bug Exploration Test Complete ===");
        logger.LogInformation($"Evidence written: {evidencePath}");
        logger.LogInformation($"Status: {finalStatus}");
        logger.LogInformation($"Bug exists: {bugExists}");

        // Return 0 if bug is confirmed (expected on unfixed code)
        // Return 1 if bug is not detected (unexpected on unfixed code, expected on fixed code)
        return bugExists ? 0 : 1;
    }
}
