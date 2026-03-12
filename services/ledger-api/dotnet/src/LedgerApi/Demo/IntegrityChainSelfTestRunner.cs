using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Symphony.LedgerApi.Demo;

public static class IntegrityChainSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = global::EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = global::EvidenceMeta.Load(rootDir);
        var evidencePath = Path.Combine(evidenceDir, "tsk_p1_int_002_integrity_verifier_stack.json");

        var tempDir = Path.Combine(Path.GetTempPath(), "symphony_int_002");
        Directory.CreateDirectory(tempDir);
        var signedPath = Path.Combine(tempDir, "signed_instruction_file_sample.json");
        var dispatchPath = Path.Combine(tempDir, "evidence_link_sms_dispatch.ndjson");
        var submissionsPath = Path.Combine(tempDir, "evidence_link_submissions.ndjson");
        var exceptionsPath = Path.Combine(tempDir, "demo_exception_log.ndjson");

        Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", "11111111-1111-1111-1111-111111111111");
        Environment.SetEnvironmentVariable("DEMO_INSTRUCTION_SIGNING_KEY", "demo-instruction-self-test-key");
        Environment.SetEnvironmentVariable("DEMO_EVIDENCE_LINK_SIGNING_KEY", "demo-link-self-test-key");
        Environment.SetEnvironmentVariable("DEMO_SIGNED_INSTRUCTION_FILE", signedPath);
        Environment.SetEnvironmentVariable("EVIDENCE_LINK_SMS_DISPATCH_FILE", dispatchPath);
        Environment.SetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE", submissionsPath);
        Environment.SetEnvironmentVariable("DEMO_EXCEPTION_LOG_FILE", exceptionsPath);

        ResetFiles(signedPath, dispatchPath, submissionsPath, exceptionsPath);
        Environment.SetEnvironmentVariable("SYMPHONY_CHAIN_POPULATION", "1");

        var signedResult = await RunSignedInstructionFlow(signedPath, logger, cancellationToken);
        var evidenceResult = await RunEvidenceFlow(logger, cancellationToken);

        var signedChain = global::TamperEvidentChain.VerifyJsonFile(signedPath, "governed_instruction");
        var dispatchChain = global::TamperEvidentChain.VerifyNdjsonFile(dispatchPath, "evidence_event_sms_dispatch");
        var submissionChain = global::TamperEvidentChain.VerifyNdjsonFile(submissionsPath, "evidence_event_submission");

        var tamperedSignedPath = Path.Combine(tempDir, "signed_instruction_file_sample.tampered_chain.json");
        TamperSignedInstructionFile(signedPath, tamperedSignedPath);
        var tamperedEvidencePath = Path.Combine(tempDir, "evidence_link_submissions.tampered.ndjson");
        TamperFirstEvidenceEntry(submissionsPath, tamperedEvidencePath);

        var tamperedSignedCheck = global::TamperEvidentChain.VerifyJsonFile(tamperedSignedPath, "governed_instruction");
        var tamperedEvidenceCheck = global::TamperEvidentChain.VerifyNdjsonFile(tamperedEvidencePath, "evidence_event_submission");

        var withoutChain = await MeasureP95Async(enabled: false, signedPath, dispatchPath, submissionsPath, exceptionsPath, logger, cancellationToken);
        var withChain = await MeasureP95Async(enabled: true, signedPath, dispatchPath, submissionsPath, exceptionsPath, logger, cancellationToken);
        var deltaMs = Math.Round(withChain - withoutChain, 3);

        var pass =
            signedResult &&
            evidenceResult &&
            signedChain.Pass &&
            dispatchChain.Pass &&
            submissionChain.Pass &&
            !tamperedSignedCheck.Pass &&
            !tamperedEvidenceCheck.Pass &&
            deltaMs <= 100m;

        var payload = new
        {
            check_id = "TSK-P1-INT-002-INTEGRITY-VERIFIER-STACK",
            task_id = "TSK-P1-INT-002",
            timestamp_utc = evidenceMeta.TimestampUtc,
            git_sha = evidenceMeta.GitSha,
            schema_fingerprint = evidenceMeta.SchemaFingerprint,
            status = pass ? "PASS" : "FAIL",
            pass,
            declared_reference_hardware = DescribeHardware(),
            measurement_method = "p95 wall-clock transaction delta over 100 runs, comparing equivalent signed-instruction and evidence-link flows with and without chain population",
            runs = 100,
            latency_ms = new
            {
                without_chain_p95 = withoutChain,
                with_chain_p95 = withChain,
                chain_population_delta = deltaMs,
                threshold = 100m
            },
            domains = new
            {
                governed_instruction = new
                {
                    chain_record_present = signedChain.Pass,
                    tamper_fixture_rejected = !tamperedSignedCheck.Pass,
                    verification_error = tamperedSignedCheck.ErrorCode
                },
                evidence_events = new
                {
                    dispatch_chain_present = dispatchChain.Pass,
                    submission_chain_present = submissionChain.Pass,
                    tamper_fixture_rejected = !tamperedEvidenceCheck.Pass,
                    verification_error = tamperedEvidenceCheck.ErrorCode
                }
            },
            commit_boundary = "same persisted envelope write for attested event and chain record",
            tests = new[]
            {
                new { name = "signed_instruction_flow", status = signedResult ? "PASS" : "FAIL" },
                new { name = "evidence_event_flow", status = evidenceResult ? "PASS" : "FAIL" },
                new { name = "signed_instruction_chain_verification", status = signedChain.Pass ? "PASS" : "FAIL" },
                new { name = "evidence_event_chain_verification", status = (dispatchChain.Pass && submissionChain.Pass) ? "PASS" : "FAIL" },
                new { name = "signed_instruction_broken_chain_rejected", status = !tamperedSignedCheck.Pass ? "PASS" : "FAIL" },
                new { name = "evidence_event_broken_chain_rejected", status = !tamperedEvidenceCheck.Pass ? "PASS" : "FAIL" },
                new { name = "latency_delta_within_threshold", status = deltaMs <= 100m ? "PASS" : "FAIL" }
            }
        };

        await File.WriteAllTextAsync(
            evidencePath,
            JsonSerializer.Serialize(payload, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine,
            cancellationToken);

        Console.WriteLine($"Evidence written: {evidencePath}");
        return pass ? 0 : 1;
    }

    private static async Task<bool> RunSignedInstructionFlow(string signedPath, ILogger logger, CancellationToken cancellationToken)
    {
        await global::SupplierRegistryUpsertHandler.HandleAsync(new global::SupplierRegistryUpsertRequest(
            "11111111-1111-1111-1111-111111111111", "supplier-001", "Demo Supplier", "acct-001", -15.39m, 28.32m, true));
        await global::ProgramSupplierAllowlistUpsertHandler.HandleAsync(new global::ProgramSupplierAllowlistUpsertRequest(
            "11111111-1111-1111-1111-111111111111", "program-a", "supplier-001", true));

        var result = await global::SignedInstructionFileHandler.GenerateAsync(
            new global::SignedInstructionGenerateRequest(
                "11111111-1111-1111-1111-111111111111",
                "program-a",
                "instruction-001",
                "supplier-001",
                "acct-001",
                1000,
                "ZMW",
                "INT-002-REF"),
            logger,
            cancellationToken);

        return result.StatusCode == StatusCodes.Status200OK && File.Exists(signedPath);
    }

    private static async Task<bool> RunEvidenceFlow(ILogger logger, CancellationToken cancellationToken)
    {
        var issue = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                "11111111-1111-1111-1111-111111111111",
                "instruction-001",
                "program-a",
                "VENDOR",
                "+260971000111",
                -15.39m,
                28.32m,
                250m,
                120),
            logger,
            cancellationToken);

        if (issue.StatusCode != StatusCodes.Status200OK)
        {
            return false;
        }

        using var doc = JsonDocument.Parse(JsonSerializer.Serialize(issue.Body));
        var token = doc.RootElement.GetProperty("token").GetString() ?? string.Empty;

        var context = new DefaultHttpContext();
        context.Request.Headers["x-tenant-id"] = "11111111-1111-1111-1111-111111111111";
        context.Request.Headers["x-evidence-link-token"] = token;
        context.Request.Headers["x-submitter-msisdn"] = "+260971000111";
        var submit = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("INVOICE", "s3://bucket/invoice-001.pdf", -15.39m, 28.32m),
            context,
            logger,
            cancellationToken);

        return submit.StatusCode == StatusCodes.Status202Accepted;
    }

    private static async Task<decimal> MeasureP95Async(
        bool enabled,
        string signedPath,
        string dispatchPath,
        string submissionsPath,
        string exceptionsPath,
        ILogger logger,
        CancellationToken cancellationToken)
    {
        ResetFiles(signedPath, dispatchPath, submissionsPath, exceptionsPath);
        Environment.SetEnvironmentVariable("SYMPHONY_CHAIN_POPULATION", enabled ? "1" : "0");

        var measurements = new List<decimal>(capacity: 100);
        for (var i = 0; i < 100; i++)
        {
            var sw = Stopwatch.StartNew();
            var signedOk = await RunSignedInstructionFlow(signedPath, logger, cancellationToken);
            var evidenceOk = await RunEvidenceFlow(logger, cancellationToken);
            sw.Stop();
            if (!signedOk || !evidenceOk)
            {
                return 9999m;
            }

            measurements.Add((decimal)sw.Elapsed.TotalMilliseconds);
        }

        measurements.Sort();
        var index = (int)Math.Ceiling(measurements.Count * 0.95m) - 1;
        if (index < 0)
        {
            index = 0;
        }

        return Math.Round(measurements[index], 3);
    }

    private static void ResetFiles(params string[] paths)
    {
        foreach (var path in paths)
        {
            var dir = Path.GetDirectoryName(path);
            if (!string.IsNullOrWhiteSpace(dir))
            {
                Directory.CreateDirectory(dir);
            }

            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }
    }

    private static void TamperSignedInstructionFile(string sourcePath, string targetPath)
    {
        var node = JsonNode.Parse(File.ReadAllText(sourcePath))?.AsObject()
            ?? throw new InvalidOperationException("signed instruction payload missing");
        node["payload"]!["reference"] = "INT-002-TAMPER";
        File.WriteAllText(targetPath, JsonSerializer.Serialize(node, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine);
    }

    private static void TamperFirstEvidenceEntry(string sourcePath, string targetPath)
    {
        var lines = File.ReadAllLines(sourcePath);
        if (lines.Length == 0)
        {
            throw new InvalidOperationException("evidence submission log missing");
        }

        var node = JsonNode.Parse(lines[0])?.AsObject()
            ?? throw new InvalidOperationException("evidence submission payload missing");
        node["artifact_ref"] = "s3://bucket/invoice-001-tampered.pdf";
        lines[0] = JsonSerializer.Serialize(node);
        File.WriteAllLines(targetPath, lines);
    }

    private static string DescribeHardware()
        => $"local workspace host {Environment.MachineName}; dotnet demo host self-test; {RuntimeInformation.FrameworkDescription}";
}
