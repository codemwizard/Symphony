using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Symphony.LedgerApi.Demo;

public static class MsisdnSubmitterMatchSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = global::EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = global::EvidenceMeta.Load(rootDir);
        var evidencePath = Path.Combine(evidenceDir, "tsk_p1_demo_004_msisdn_submitter_match.json");

        var tenantId = "11111111-1111-1111-1111-111111111111";
        Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", tenantId);
        Environment.SetEnvironmentVariable("DEMO_EVIDENCE_LINK_SIGNING_KEY", "demo-link-msisdn-key");

        var issue = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId,
                "msisdn-ins-001",
                "VENDOR",
                "+260971000333",
                null,
                null,
                null,
                300),
            logger,
            cancellationToken);

        string token = string.Empty;
        if (issue.StatusCode == StatusCodes.Status200OK)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(issue.Body));
            token = doc.RootElement.TryGetProperty("token", out var t) ? t.GetString() ?? string.Empty : string.Empty;
        }

        var okCtx = new DefaultHttpContext();
        okCtx.Request.Headers["x-tenant-id"] = tenantId;
        okCtx.Request.Headers["x-evidence-link-token"] = token;
        okCtx.Request.Headers["x-submitter-msisdn"] = "+260971000333";
        var ok = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("INVOICE", "s3://bucket/invoice-002.pdf", null, null),
            okCtx,
            logger,
            cancellationToken);

        var mismatchCtx = new DefaultHttpContext();
        mismatchCtx.Request.Headers["x-tenant-id"] = tenantId;
        mismatchCtx.Request.Headers["x-evidence-link-token"] = token;
        mismatchCtx.Request.Headers["x-submitter-msisdn"] = "+260971999999";
        var mismatch = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("INVOICE", "s3://bucket/invoice-002.pdf", null, null),
            mismatchCtx,
            logger,
            cancellationToken);

        var missingCtx = new DefaultHttpContext();
        missingCtx.Request.Headers["x-tenant-id"] = tenantId;
        missingCtx.Request.Headers["x-evidence-link-token"] = token;
        var missing = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("INVOICE", "s3://bucket/invoice-002.pdf", null, null),
            missingCtx,
            logger,
            cancellationToken);

        var tests = new[]
        {
            new { name = "matching_msisdn_accepted", status = ok.StatusCode == StatusCodes.Status202Accepted ? "PASS" : "FAIL" },
            new { name = "mismatched_msisdn_rejected", status = mismatch.StatusCode == StatusCodes.Status403Forbidden ? "PASS" : "FAIL" },
            new { name = "missing_msisdn_rejected", status = missing.StatusCode == StatusCodes.Status403Forbidden ? "PASS" : "FAIL" },
        };
        var status = tests.All(x => x.status == "PASS") ? "PASS" : "FAIL";

        await File.WriteAllTextAsync(
            evidencePath,
            JsonSerializer.Serialize(new
            {
                check_id = "TSK-P1-DEMO-004-MSISDN-MATCH",
                task_id = "TSK-P1-DEMO-004",
                timestamp_utc = evidenceMeta.TimestampUtc,
                git_sha = evidenceMeta.GitSha,
                schema_fingerprint = evidenceMeta.SchemaFingerprint,
                status,
                pass = status == "PASS",
                details = new
                {
                    identity_claim_boundary = "network_layer_submitter_match_only",
                    tests
                }
            }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine,
            cancellationToken);

        Console.WriteLine($"Evidence written: {evidencePath}");
        return status == "PASS" ? 0 : 1;
    }
}

