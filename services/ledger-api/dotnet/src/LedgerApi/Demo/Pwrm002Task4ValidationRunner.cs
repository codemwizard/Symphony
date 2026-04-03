using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Symphony.LedgerApi.Demo;

public static class Pwrm002Task4ValidationRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var tenantId = "33333333-3333-3333-3333-333333333333";
        Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", tenantId);
        Environment.SetEnvironmentVariable("DEMO_EVIDENCE_LINK_SIGNING_KEY", "pwrm002-task4-key");
        Environment.SetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE", "/tmp/pwrm002_task4_submissions.ndjson");

        // Clean up any existing file
        var submissionsFile = Environment.GetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE")!;
        if (File.Exists(submissionsFile))
        {
            File.Delete(submissionsFile);
        }

        // Test 1: WEIGHBRIDGE_RECORD with null structured_payload should return 400 INVALID_REQUEST
        var issue1 = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId,
                "pwrm002-ins-001",
                "PGM-ZAMBIA-GRN-001",
                "WASTE_COLLECTOR",
                "+260971100001",
                -15.4167m,
                28.2833m,
                250m,
                300),
            logger,
            cancellationToken);

        string token1 = string.Empty;
        if (issue1.StatusCode == StatusCodes.Status200OK)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(issue1.Body));
            token1 = doc.RootElement.TryGetProperty("token", out var t) ? t.GetString() ?? string.Empty : string.Empty;
        }

        var ctx1 = new DefaultHttpContext();
        ctx1.Request.Headers["x-tenant-id"] = tenantId;
        ctx1.Request.Headers["x-evidence-link-token"] = token1;
        ctx1.Request.Headers["x-submitter-msisdn"] = "+260971100001";

        var result1 = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("WEIGHBRIDGE_RECORD", "s3://bucket/photo-001.jpg", -15.4167m, 28.2833m, null),
            ctx1,
            logger,
            cancellationToken);

        var test1Pass = result1.StatusCode == StatusCodes.Status400BadRequest;
        if (test1Pass)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(result1.Body));
            var errorCode = doc.RootElement.TryGetProperty("error_code", out var ec) ? ec.GetString() : null;
            test1Pass = errorCode == "INVALID_REQUEST";
        }

        // Test 2: WEIGHBRIDGE_RECORD with valid payload should return 202 and store backend net
        var issue2 = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId,
                "pwrm002-ins-002",
                "PGM-ZAMBIA-GRN-001",
                "WASTE_COLLECTOR",
                "+260971100001",
                -15.4167m,
                28.2833m,
                250m,
                300),
            logger,
            cancellationToken);

        string token2 = string.Empty;
        if (issue2.StatusCode == StatusCodes.Status200OK)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(issue2.Body));
            token2 = doc.RootElement.TryGetProperty("token", out var t) ? t.GetString() ?? string.Empty : string.Empty;
        }

        var ctx2 = new DefaultHttpContext();
        ctx2.Request.Headers["x-tenant-id"] = tenantId;
        ctx2.Request.Headers["x-evidence-link-token"] = token2;
        ctx2.Request.Headers["x-submitter-msisdn"] = "+260971100001";

        var payload = JsonDocument.Parse(@"{
            ""plastic_type"": ""PET"",
            ""gross_weight_kg"": 12.5,
            ""tare_weight_kg"": 0.1,
            ""net_weight_kg"": 12.4,
            ""collector_id"": ""worker-chunga-001""
        }").RootElement;

        var result2 = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("WEIGHBRIDGE_RECORD", "s3://bucket/photo-002.jpg", -15.4167m, 28.2833m, payload),
            ctx2,
            logger,
            cancellationToken);

        var test2Pass = result2.StatusCode == StatusCodes.Status202Accepted;

        // Verify backend net was stored
        if (test2Pass)
        {
            var submissions = global::EvidenceLinkSubmissionLog.ReadAll();
            var lastSubmission = submissions.LastOrDefault();
            if (lastSubmission.ValueKind != JsonValueKind.Undefined)
            {
                var hasNetWeight = lastSubmission.TryGetProperty("net_weight_kg", out var netWeight);
                test2Pass = hasNetWeight && netWeight.GetDecimal() == 12.4m;
            }
        }

        // Test 3: WEIGHBRIDGE_RECORD with invalid plastic_type should return 400 INVALID_WEIGHBRIDGE_PAYLOAD
        var issue3 = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId,
                "pwrm002-ins-003",
                "PGM-ZAMBIA-GRN-001",
                "WASTE_COLLECTOR",
                "+260971100001",
                -15.4167m,
                28.2833m,
                250m,
                300),
            logger,
            cancellationToken);

        string token3 = string.Empty;
        if (issue3.StatusCode == StatusCodes.Status200OK)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(issue3.Body));
            token3 = doc.RootElement.TryGetProperty("token", out var t) ? t.GetString() ?? string.Empty : string.Empty;
        }

        var ctx3 = new DefaultHttpContext();
        ctx3.Request.Headers["x-tenant-id"] = tenantId;
        ctx3.Request.Headers["x-evidence-link-token"] = token3;
        ctx3.Request.Headers["x-submitter-msisdn"] = "+260971100001";

        var invalidPayload = JsonDocument.Parse(@"{
            ""plastic_type"": ""GLASS"",
            ""gross_weight_kg"": 12.5,
            ""tare_weight_kg"": 0.1,
            ""net_weight_kg"": 12.4,
            ""collector_id"": ""worker-chunga-001""
        }").RootElement;

        var result3 = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("WEIGHBRIDGE_RECORD", "s3://bucket/photo-003.jpg", -15.4167m, 28.2833m, invalidPayload),
            ctx3,
            logger,
            cancellationToken);

        var test3Pass = result3.StatusCode == StatusCodes.Status400BadRequest;
        if (test3Pass)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(result3.Body));
            var errorCode = doc.RootElement.TryGetProperty("error_code", out var ec) ? ec.GetString() : null;
            test3Pass = errorCode == "INVALID_WEIGHBRIDGE_PAYLOAD";
        }

        var tests = new[]
        {
            new { name = "weighbridge_null_payload_rejected", status = test1Pass ? "PASS" : "FAIL" },
            new { name = "weighbridge_valid_payload_accepted_backend_net_stored", status = test2Pass ? "PASS" : "FAIL" },
            new { name = "weighbridge_invalid_plastic_type_rejected", status = test3Pass ? "PASS" : "FAIL" },
        };

        var allPass = tests.All(x => x.status == "PASS");

        logger.LogInformation("PWRM-002 Task 4 Validation: {Status}", allPass ? "PASS" : "FAIL");
        foreach (var test in tests)
        {
            logger.LogInformation("  {Name}: {Status}", test.name, test.status);
        }

        return allPass ? 0 : 1;
    }
}
