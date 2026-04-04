using System.Text.Json;
using Microsoft.Extensions.Logging;

namespace Symphony.LedgerApi.Demo;

public static class Pwrm0001MonitoringReportSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = global::EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = global::EvidenceMeta.Load(rootDir);
        var evidencePath = Path.Combine(evidenceDir, "pwrm_monitoring_report.json");

        // FIX F16: Full isolation — namespaced IDs
        var tenantId = "44444444-4444-4444-4444-444444444444";
        var programId = "PGM-SELFTEST-PWRM004";
        var worker001 = global::StableGuidHelper.CreateStableGuid("worker-chunga-001-selftest-004").ToString();
        var worker002 = global::StableGuidHelper.CreateStableGuid("worker-chunga-002-selftest-004").ToString();

        // Isolated NDJSON paths
        var submissionsPath = "/tmp/pwrm004_selftest_submissions.ndjson";
        var exceptionLogPath = "/tmp/pwrm004_selftest_exceptions.ndjson";

        // Delete at start
        if (File.Exists(submissionsPath)) File.Delete(submissionsPath);
        if (File.Exists(exceptionLogPath)) File.Delete(exceptionLogPath);

        Environment.SetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE", submissionsPath);
        Environment.SetEnvironmentVariable("DEMO_EXCEPTION_LOG_FILE", exceptionLogPath);
        Environment.SetEnvironmentVariable("DEMO_EVIDENCE_LINK_SIGNING_KEY", "pwrm004-selftest-key");

        // Seed workers with supplier_type = "WORKER"
        await global::SupplierRegistryUpsertHandler.HandleAsync(new global::SupplierRegistryUpsertRequest(
            tenantId, worker001, "Test Worker 004-001", "MMO:+260971100001",
            -15.4167m, 28.2833m, true, supplier_type: "WORKER"));
        await global::SupplierRegistryUpsertHandler.HandleAsync(new global::SupplierRegistryUpsertRequest(
            tenantId, worker002, "Test Worker 004-002", "MMO:+260971100002",
            -15.4167m, 28.2833m, true, supplier_type: "WORKER"));
        await global::ProgramSupplierAllowlistUpsertHandler.HandleAsync(
            new global::ProgramSupplierAllowlistUpsertRequest(tenantId, programId, worker001, true));
        await global::ProgramSupplierAllowlistUpsertHandler.HandleAsync(
            new global::ProgramSupplierAllowlistUpsertRequest(tenantId, programId, worker002, true));

        // Test Case 1: No submissions → total_collections=0, proof_completeness_rate=1.0
        var test1Pass = await TestCase1_EmptyReport(tenantId, programId, rootDir, logger, cancellationToken);

        // Test Case 2: Two WEIGHBRIDGE_RECORDs (PET 12.4kg + PET 8.1kg, different instruction_ids) → TOTAL=20.5
        var test2Pass = await TestCase2_TotalAccumulation(tenantId, programId, worker001, rootDir, logger, cancellationToken);

        // Test Case 3: Two WEIGHBRIDGE_RECORDs SAME instruction_id (seq 0: PET 12.4kg, seq 1: HDPE 8.1kg) → winner=seq 1
        var test3Pass = await TestCase3_LatestWinsBySequence(tenantId, programId, worker001, rootDir, logger, cancellationToken);

        // Test Case 4: One instruction: all four PWRM0001 proof types submitted → complete_collections=1
        var test4Pass = await TestCase4_CompleteCollection(tenantId, programId, worker001, rootDir, logger, cancellationToken);

        // Test Case 5: One instruction: missing TRANSFER_MANIFEST → incomplete_collections=1
        var test5Pass = await TestCase5_IncompleteCollection(tenantId, programId, worker001, rootDir, logger, cancellationToken);

        // Test Case 6: One complete + one incomplete → proof_completeness_rate=0.5
        var test6Pass = await TestCase6_CompletenessRate(tenantId, programId, worker001, rootDir, logger, cancellationToken);

        // Test Case 7: One exception log entry seeded for programId → exception_count=1
        var test7Pass = await TestCase7_ExceptionCount(tenantId, programId, rootDir, logger, cancellationToken);

        // Test Case 8: zgft_waste_sector_alignment fields → all three booleans = true
        var test8Pass = await TestCase8_ZgftAlignment(tenantId, programId, rootDir, logger, cancellationToken);

        var tests = new[]
        {
            new { name = "empty_report_defaults", status = test1Pass ? "PASS" : "FAIL" },
            new { name = "total_accumulation_decimal_exact", status = test2Pass ? "PASS" : "FAIL" },
            new { name = "latest_wins_by_sequence", status = test3Pass ? "PASS" : "FAIL" },
            new { name = "complete_collection", status = test4Pass ? "PASS" : "FAIL" },
            new { name = "incomplete_collection", status = test5Pass ? "PASS" : "FAIL" },
            new { name = "completeness_rate", status = test6Pass ? "PASS" : "FAIL" },
            new { name = "exception_count", status = test7Pass ? "PASS" : "FAIL" },
            new { name = "zgft_alignment", status = test8Pass ? "PASS" : "FAIL" }
        };

        var status = tests.All(x => x.status == "PASS") ? "PASS" : "FAIL";

        await File.WriteAllTextAsync(
            evidencePath,
            JsonSerializer.Serialize(new
            {
                check_id = "PWRM-004-MONITORING-REPORT",
                task_id = "PWRM-004",
                timestamp_utc = evidenceMeta.TimestampUtc,
                git_sha = evidenceMeta.GitSha,
                schema_fingerprint = evidenceMeta.SchemaFingerprint,
                status,
                pass = status == "PASS",
                details = new
                {
                    tests
                }
            }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine,
            cancellationToken);

        Console.WriteLine($"Evidence written: {evidencePath}");
        Console.WriteLine($"Test results: {tests.Count(x => x.status == "PASS")}/{tests.Length} passed");

        return status == "PASS" ? 0 : 1;
    }

    private static async Task<bool> TestCase1_EmptyReport(
        string tenantId, string programId, string rootDir, ILogger logger, CancellationToken cancellationToken)
    {
        // No submissions seeded — call handler directly
        var result = await global::Pwrm0001MonitoringReportHandler.HandleAsync(programId, rootDir, cancellationToken);
        if (result.StatusCode != 200) return false;

        using var doc = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
        var root = doc.RootElement;

        var totalCollections = root.TryGetProperty("total_collections", out var tc) ? tc.GetInt32() : -1;
        var rate = root.TryGetProperty("proof_completeness_rate", out var r) ? r.GetDecimal() : -1m;

        return totalCollections == 0 && rate == 1.0m;
    }

    private static async Task<bool> TestCase2_TotalAccumulation(
        string tenantId, string programId, string workerId, string rootDir, ILogger logger, CancellationToken cancellationToken)
    {
        // Clear submissions
        var submissionsPath = Environment.GetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE")!;
        if (File.Exists(submissionsPath)) File.Delete(submissionsPath);

        // Seed two WEIGHBRIDGE_RECORDs with different instruction_ids
        await SeedWeighbridgeRecord(tenantId, programId, "CHG-SELFTEST-004-T2-001", workerId, "PET", 12.5m, 0.1m, 12.4m, logger, cancellationToken);
        await SeedWeighbridgeRecord(tenantId, programId, "CHG-SELFTEST-004-T2-002", workerId, "PET", 8.2m, 0.1m, 8.1m, logger, cancellationToken);

        var result = await global::Pwrm0001MonitoringReportHandler.HandleAsync(programId, rootDir, cancellationToken);
        if (result.StatusCode != 200) return false;

        using var doc = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
        var root = doc.RootElement;

        if (!root.TryGetProperty("plastic_totals_kg", out var totals)) return false;
        var petTotal = totals.TryGetProperty("PET", out var pet) ? pet.GetDecimal() : -1m;
        var total = totals.TryGetProperty("TOTAL", out var t) ? t.GetDecimal() : -1m;

        // Exact decimal check: 12.4 + 8.1 = 20.5
        return petTotal == 20.5m && total == 20.5m;
    }

    private static async Task<bool> TestCase3_LatestWinsBySequence(
        string tenantId, string programId, string workerId, string rootDir, ILogger logger, CancellationToken cancellationToken)
    {
        // Clear submissions
        var submissionsPath = Environment.GetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE")!;
        if (File.Exists(submissionsPath)) File.Delete(submissionsPath);

        // Seed two WEIGHBRIDGE_RECORDs with SAME instruction_id directly to log
        // This bypasses the duplicate check to test the aggregation logic
        // seq 0: PET 12.4kg, seq 1: HDPE 8.1kg
        var instructionId = "CHG-SELFTEST-004-T3-001";
        
        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "WEIGHBRIDGE_RECORD",
            artifact_ref = $"s3://bucket/{instructionId}-seq0.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O"),
            structured_payload = JsonDocument.Parse($@"{{
                ""plastic_type"": ""PET"",
                ""gross_weight_kg"": 12.5,
                ""tare_weight_kg"": 0.1,
                ""net_weight_kg"": 12.4,
                ""collector_id"": ""{workerId}""
            }}").RootElement,
            net_weight_kg = 12.4m
        }, cancellationToken);

        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "WEIGHBRIDGE_RECORD",
            artifact_ref = $"s3://bucket/{instructionId}-seq1.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O"),
            structured_payload = JsonDocument.Parse($@"{{
                ""plastic_type"": ""HDPE"",
                ""gross_weight_kg"": 8.2,
                ""tare_weight_kg"": 0.1,
                ""net_weight_kg"": 8.1,
                ""collector_id"": ""{workerId}""
            }}").RootElement,
            net_weight_kg = 8.1m
        }, cancellationToken);

        var result = await global::Pwrm0001MonitoringReportHandler.HandleAsync(programId, rootDir, cancellationToken);
        if (result.StatusCode != 200) return false;

        using var doc = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
        var root = doc.RootElement;

        var totalCollections = root.TryGetProperty("total_collections", out var tc) ? tc.GetInt32() : -1;
        if (totalCollections != 1) return false;

        if (!root.TryGetProperty("plastic_totals_kg", out var totals)) return false;
        var hdpeTotal = totals.TryGetProperty("HDPE", out var hdpe) ? hdpe.GetDecimal() : -1m;
        var petTotal = totals.TryGetProperty("PET", out var pet) ? pet.GetDecimal() : -1m;
        var total = totals.TryGetProperty("TOTAL", out var t) ? t.GetDecimal() : -1m;

        // Winner is seq 1 (HDPE 8.1), not seq 0 (PET 12.4)
        return hdpeTotal == 8.1m && petTotal == 0m && total == 8.1m;
    }

    private static async Task<bool> TestCase4_CompleteCollection(
        string tenantId, string programId, string workerId, string rootDir, ILogger logger, CancellationToken cancellationToken)
    {
        // Clear submissions
        var submissionsPath = Environment.GetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE")!;
        if (File.Exists(submissionsPath)) File.Delete(submissionsPath);

        var instructionId = "CHG-SELFTEST-004-T4-001";

        // Seed all four proof types directly to log (bypassing duplicate check)
        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "WEIGHBRIDGE_RECORD",
            artifact_ref = $"s3://bucket/{instructionId}-wb.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O"),
            structured_payload = JsonDocument.Parse($@"{{
                ""plastic_type"": ""PET"",
                ""gross_weight_kg"": 12.5,
                ""tare_weight_kg"": 0.1,
                ""net_weight_kg"": 12.4,
                ""collector_id"": ""{workerId}""
            }}").RootElement,
            net_weight_kg = 12.4m
        }, cancellationToken);

        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "COLLECTION_PHOTO",
            artifact_ref = $"s3://bucket/{instructionId}-photo.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O")
        }, cancellationToken);

        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "QUALITY_AUDIT_RECORD",
            artifact_ref = $"s3://bucket/{instructionId}-audit.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O")
        }, cancellationToken);

        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "TRANSFER_MANIFEST",
            artifact_ref = $"s3://bucket/{instructionId}-manifest.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O")
        }, cancellationToken);

        var result = await global::Pwrm0001MonitoringReportHandler.HandleAsync(programId, rootDir, cancellationToken);
        if (result.StatusCode != 200) return false;

        using var doc = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
        var root = doc.RootElement;

        var completeCollections = root.TryGetProperty("complete_collections", out var cc) ? cc.GetInt32() : -1;
        return completeCollections == 1;
    }

    private static async Task<bool> TestCase5_IncompleteCollection(
        string tenantId, string programId, string workerId, string rootDir, ILogger logger, CancellationToken cancellationToken)
    {
        // Clear submissions
        var submissionsPath = Environment.GetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE")!;
        if (File.Exists(submissionsPath)) File.Delete(submissionsPath);

        var instructionId = "CHG-SELFTEST-004-T5-001";

        // Seed only three proof types (missing TRANSFER_MANIFEST) directly to log
        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "WEIGHBRIDGE_RECORD",
            artifact_ref = $"s3://bucket/{instructionId}-wb.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O"),
            structured_payload = JsonDocument.Parse($@"{{
                ""plastic_type"": ""PET"",
                ""gross_weight_kg"": 12.5,
                ""tare_weight_kg"": 0.1,
                ""net_weight_kg"": 12.4,
                ""collector_id"": ""{workerId}""
            }}").RootElement,
            net_weight_kg = 12.4m
        }, cancellationToken);

        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "COLLECTION_PHOTO",
            artifact_ref = $"s3://bucket/{instructionId}-photo.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O")
        }, cancellationToken);

        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "QUALITY_AUDIT_RECORD",
            artifact_ref = $"s3://bucket/{instructionId}-audit.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O")
        }, cancellationToken);

        var result = await global::Pwrm0001MonitoringReportHandler.HandleAsync(programId, rootDir, cancellationToken);
        if (result.StatusCode != 200) return false;

        using var doc = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
        var root = doc.RootElement;

        var incompleteCollections = root.TryGetProperty("incomplete_collections", out var ic) ? ic.GetInt32() : -1;
        return incompleteCollections == 1;
    }

    private static async Task<bool> TestCase6_CompletenessRate(
        string tenantId, string programId, string workerId, string rootDir, ILogger logger, CancellationToken cancellationToken)
    {
        // Clear submissions
        var submissionsPath = Environment.GetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE")!;
        if (File.Exists(submissionsPath)) File.Delete(submissionsPath);

        // One complete collection
        var instructionId1 = "CHG-SELFTEST-004-T6-001";
        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId1,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "WEIGHBRIDGE_RECORD",
            artifact_ref = $"s3://bucket/{instructionId1}-wb.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O"),
            structured_payload = JsonDocument.Parse($@"{{
                ""plastic_type"": ""PET"",
                ""gross_weight_kg"": 12.5,
                ""tare_weight_kg"": 0.1,
                ""net_weight_kg"": 12.4,
                ""collector_id"": ""{workerId}""
            }}").RootElement,
            net_weight_kg = 12.4m
        }, cancellationToken);

        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId1,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "COLLECTION_PHOTO",
            artifact_ref = $"s3://bucket/{instructionId1}-photo.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O")
        }, cancellationToken);

        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId1,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "QUALITY_AUDIT_RECORD",
            artifact_ref = $"s3://bucket/{instructionId1}-audit.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O")
        }, cancellationToken);

        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId1,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "TRANSFER_MANIFEST",
            artifact_ref = $"s3://bucket/{instructionId1}-manifest.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O")
        }, cancellationToken);

        // One incomplete collection
        var instructionId2 = "CHG-SELFTEST-004-T6-002";
        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId2,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "WEIGHBRIDGE_RECORD",
            artifact_ref = $"s3://bucket/{instructionId2}-wb.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O"),
            structured_payload = JsonDocument.Parse($@"{{
                ""plastic_type"": ""HDPE"",
                ""gross_weight_kg"": 8.2,
                ""tare_weight_kg"": 0.1,
                ""net_weight_kg"": 8.1,
                ""collector_id"": ""{workerId}""
            }}").RootElement,
            net_weight_kg = 8.1m
        }, cancellationToken);

        await global::EvidenceLinkSubmissionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId2,
            program_id = programId,
            submitter_class = "WASTE_COLLECTOR",
            submitter_msisdn = "+260971100001",
            artifact_type = "COLLECTION_PHOTO",
            artifact_ref = $"s3://bucket/{instructionId2}-photo.jpg",
            latitude = -15.4167m,
            longitude = 28.2833m,
            submitted_at_utc = DateTimeOffset.UtcNow.ToString("O")
        }, cancellationToken);

        var result = await global::Pwrm0001MonitoringReportHandler.HandleAsync(programId, rootDir, cancellationToken);
        if (result.StatusCode != 200) return false;

        using var doc = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
        var root = doc.RootElement;

        var rate = root.TryGetProperty("proof_completeness_rate", out var r) ? r.GetDecimal() : -1m;
        return rate == 0.5m;
    }

    private static async Task<bool> TestCase7_ExceptionCount(
        string tenantId, string programId, string rootDir, ILogger logger, CancellationToken cancellationToken)
    {
        // Clear exception log
        var exceptionLogPath = Environment.GetEnvironmentVariable("DEMO_EXCEPTION_LOG_FILE")!;
        if (File.Exists(exceptionLogPath)) File.Delete(exceptionLogPath);

        // FIX F10: Explicitly seed exception log entry
        await global::DemoExceptionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            program_id = programId,
            instruction_id = "CHG-SELFTEST-004-EXC-001",
            error_code = "SIM_SWAP_FLAG",
            recorded_at_utc = DateTimeOffset.UtcNow.ToString("O")
        }, cancellationToken);

        var result = await global::Pwrm0001MonitoringReportHandler.HandleAsync(programId, rootDir, cancellationToken);
        if (result.StatusCode != 200) return false;

        using var doc = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
        var root = doc.RootElement;

        var exceptionCount = root.TryGetProperty("exception_count", out var ec) ? ec.GetInt32() : -1;
        return exceptionCount == 1;
    }

    private static async Task<bool> TestCase8_ZgftAlignment(
        string tenantId, string programId, string rootDir, ILogger logger, CancellationToken cancellationToken)
    {
        var result = await global::Pwrm0001MonitoringReportHandler.HandleAsync(programId, rootDir, cancellationToken);
        if (result.StatusCode != 200) return false;

        using var doc = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
        var root = doc.RootElement;

        if (!root.TryGetProperty("zgft_waste_sector_alignment", out var zgft)) return false;

        var pollutionPrevention = zgft.TryGetProperty("pollution_prevention", out var pp) && pp.GetBoolean();
        var circularEconomy = zgft.TryGetProperty("circular_economy", out var ce) && ce.GetBoolean();
        var doNoHarm = zgft.TryGetProperty("do_no_significant_harm_declared", out var dnh) && dnh.GetBoolean();

        return pollutionPrevention && circularEconomy && doNoHarm;
    }

    // Helper: Seed a WEIGHBRIDGE_RECORD submission (sequential await)
    private static async Task SeedWeighbridgeRecord(
        string tenantId, string programId, string instructionId, string workerId,
        string plasticType, decimal gross, decimal tare, decimal net,
        ILogger logger, CancellationToken cancellationToken)
    {
        var issue = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId, instructionId, programId,
                "WASTE_COLLECTOR", "+260971100001",
                -15.4167m, 28.2833m, 250m, 300),
            logger, cancellationToken);

        if (issue.StatusCode != 200) throw new InvalidOperationException("Issue failed");

        var token = ExtractToken(issue);
        var ctx = CreateHttpContext(tenantId, token, "+260971100001");

        var payload = JsonDocument.Parse($@"{{
            ""plastic_type"": ""{plasticType}"",
            ""gross_weight_kg"": {gross},
            ""tare_weight_kg"": {tare},
            ""net_weight_kg"": {net},
            ""collector_id"": ""{workerId}""
        }}").RootElement;

        var result = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("WEIGHBRIDGE_RECORD", $"s3://bucket/{instructionId}.jpg", -15.4167m, 28.2833m, payload),
            ctx, logger, cancellationToken);

        if (result.StatusCode != 202) throw new InvalidOperationException("Submit failed");
    }

    // Helper: Seed a non-WEIGHBRIDGE proof type submission (sequential await)
    private static async Task SeedProofType(
        string tenantId, string programId, string instructionId, string workerId,
        string artifactType, ILogger logger, CancellationToken cancellationToken)
    {
        var issue = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId, instructionId, programId,
                "WASTE_COLLECTOR", "+260971100001",
                -15.4167m, 28.2833m, 250m, 300),
            logger, cancellationToken);

        if (issue.StatusCode != 200) throw new InvalidOperationException("Issue failed");

        var token = ExtractToken(issue);
        var ctx = CreateHttpContext(tenantId, token, "+260971100001");

        var result = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest(artifactType, $"s3://bucket/{instructionId}-{artifactType}.jpg", -15.4167m, 28.2833m, null),
            ctx, logger, cancellationToken);

        if (result.StatusCode != 202) throw new InvalidOperationException("Submit failed");
    }

    private static string ExtractToken(global::HandlerResult result)
    {
        using var doc = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
        return doc.RootElement.TryGetProperty("token", out var t) ? t.GetString() ?? string.Empty : string.Empty;
    }

    private static DefaultHttpContext CreateHttpContext(string tenantId, string token, string msisdn)
    {
        var ctx = new DefaultHttpContext();
        ctx.Request.Headers["x-tenant-id"] = tenantId;
        ctx.Request.Headers["x-evidence-link-token"] = token;
        ctx.Request.Headers["x-submitter-msisdn"] = msisdn;
        return ctx;
    }
}
