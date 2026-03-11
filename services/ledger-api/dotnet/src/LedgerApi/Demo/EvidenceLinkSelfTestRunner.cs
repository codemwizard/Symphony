using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Symphony.LedgerApi.Demo;

public static class EvidenceLinkSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = global::EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = global::EvidenceMeta.Load(rootDir);
        var evidencePath = Path.Combine(evidenceDir, "tsk_p1_demo_002_sms_secure_link.json");

        var tenantId = "11111111-1111-1111-1111-111111111111";
        Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", tenantId);
        Environment.SetEnvironmentVariable("DEMO_EVIDENCE_LINK_SIGNING_KEY", "demo-link-self-test-key");
        Environment.SetEnvironmentVariable("ADMIN_API_KEY", "demo-admin-key");
        Environment.SetEnvironmentVariable("SYMPHONY_ENV", "development");

        var issue = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId,
                "demo-ins-001",
                "VENDOR",
                "+260971000111",
                -15.39m,
                28.32m,
                250m,
                120),
            logger,
            cancellationToken);

        string token = string.Empty;
        if (issue.StatusCode == StatusCodes.Status200OK)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(issue.Body));
            token = doc.RootElement.TryGetProperty("token", out var t) ? t.GetString() ?? string.Empty : string.Empty;
        }

        var validContext = new DefaultHttpContext();
        validContext.Request.Headers["x-tenant-id"] = tenantId;
        validContext.Request.Headers["x-evidence-link-token"] = token;
        validContext.Request.Headers["x-submitter-msisdn"] = "+260971000111";
        var validSubmit = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("INVOICE", "s3://bucket/invoice-001.pdf", -15.39m, 28.32m),
            validContext,
            logger,
            cancellationToken);

        var tamperedContext = new DefaultHttpContext();
        tamperedContext.Request.Headers["x-tenant-id"] = tenantId;
        tamperedContext.Request.Headers["x-evidence-link-token"] = token + "x";
        tamperedContext.Request.Headers["x-submitter-msisdn"] = "+260971000111";
        var tamperedSubmit = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("INVOICE", "s3://bucket/invoice-001.pdf", -15.39m, 28.32m),
            tamperedContext,
            logger,
            cancellationToken);

        var expiredValidation = global::EvidenceLinkTokenService.ValidateToken(
            token,
            global::EvidenceLinkIssueHandler.ResolveSigningKey(),
            DateTimeOffset.UtcNow.AddHours(1));

        var tests = new[]
        {
            new { name = "issue_secure_link", status = issue.StatusCode == StatusCodes.Status200OK ? "PASS" : "FAIL" },
            new { name = "submit_with_valid_token", status = validSubmit.StatusCode == StatusCodes.Status202Accepted ? "PASS" : "FAIL" },
            new { name = "submit_with_tampered_token_rejected", status = tamperedSubmit.StatusCode == StatusCodes.Status401Unauthorized ? "PASS" : "FAIL" },
            new { name = "submit_with_expired_token_rejected", status = (!expiredValidation.Success && expiredValidation.ErrorCode == "LINK_TOKEN_EXPIRED") ? "PASS" : "FAIL" },
        };

        var status = tests.All(x => x.status == "PASS") ? "PASS" : "FAIL";
        await File.WriteAllTextAsync(
            evidencePath,
            JsonSerializer.Serialize(new
            {
                check_id = "TSK-P1-DEMO-002-SMS-SECURE-LINK",
                task_id = "TSK-P1-DEMO-002",
                timestamp_utc = evidenceMeta.TimestampUtc,
                git_sha = evidenceMeta.GitSha,
                schema_fingerprint = evidenceMeta.SchemaFingerprint,
                status,
                pass = status == "PASS",
                details = new
                {
                    token_transport = "bearer-or-x-evidence-link-token",
                    sms_dispatch_seam = "SIMULATED_DISPATCHED",
                    tests
                }
            }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine,
            cancellationToken);

        Console.WriteLine($"Evidence written: {evidencePath}");
        return status == "PASS" ? 0 : 1;
    }
}
