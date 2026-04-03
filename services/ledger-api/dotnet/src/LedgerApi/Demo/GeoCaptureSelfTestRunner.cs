using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Symphony.LedgerApi.Demo;

public static class GeoCaptureSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = global::EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = global::EvidenceMeta.Load(rootDir);
        var evidencePath = Path.Combine(evidenceDir, "tsk_p1_demo_003_browser_geo_capture.json");

        var tenantId = "11111111-1111-1111-1111-111111111111";
        Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", tenantId);
        Environment.SetEnvironmentVariable("DEMO_EVIDENCE_LINK_SIGNING_KEY", "demo-link-geo-key");

        var submissionsPath = "/tmp/symphony_geo_capture_test_submissions.ndjson";
        if (File.Exists(submissionsPath)) File.Delete(submissionsPath);
        Environment.SetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE", submissionsPath);

        var issue = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId,
                "geo-ins-001",
                "program-a",
                "FIELD_OFFICER",
                "+260971000222",
                -15.3900m,
                28.3200m,
                150m,
                300),
            logger,
            cancellationToken);

        string token = string.Empty;
        if (issue.StatusCode == StatusCodes.Status200OK)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(issue.Body));
            token = doc.RootElement.TryGetProperty("token", out var t) ? t.GetString() ?? string.Empty : string.Empty;
        }

        var validCtx = new DefaultHttpContext();
        validCtx.Request.Headers["x-tenant-id"] = tenantId;
        validCtx.Request.Headers["x-evidence-link-token"] = token;
        validCtx.Request.Headers["x-submitter-msisdn"] = "+260971000222";
        var valid = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("DELIVERY_PHOTO", "s3://bucket/photo-001.jpg", -15.3902m, 28.3201m),
            validCtx,
            logger,
            cancellationToken);

        var farCtx = new DefaultHttpContext();
        farCtx.Request.Headers["x-tenant-id"] = tenantId;
        farCtx.Request.Headers["x-evidence-link-token"] = token;
        farCtx.Request.Headers["x-submitter-msisdn"] = "+260971000222";
        var far = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("DELIVERY_PHOTO", "s3://bucket/photo-001.jpg", -14.0000m, 27.0000m),
            farCtx,
            logger,
            cancellationToken);

        var missingCtx = new DefaultHttpContext();
        missingCtx.Request.Headers["x-tenant-id"] = tenantId;
        missingCtx.Request.Headers["x-evidence-link-token"] = token;
        missingCtx.Request.Headers["x-submitter-msisdn"] = "+260971000222";
        var missing = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("DELIVERY_PHOTO", "s3://bucket/photo-001.jpg", null, null),
            missingCtx,
            logger,
            cancellationToken);

        var tests = new[]
        {
            new { name = "geo_match_within_range", status = valid.StatusCode == StatusCodes.Status202Accepted ? "PASS" : "FAIL" },
            new { name = "geo_match_failed_out_of_range", status = far.StatusCode == StatusCodes.Status422UnprocessableEntity ? "PASS" : "FAIL" },
            new { name = "geo_required_missing_rejected", status = missing.StatusCode == StatusCodes.Status422UnprocessableEntity ? "PASS" : "FAIL" },
        };
        var status = tests.All(x => x.status == "PASS") ? "PASS" : "FAIL";

        await File.WriteAllTextAsync(
            evidencePath,
            JsonSerializer.Serialize(new
            {
                check_id = "TSK-P1-DEMO-003-GEO-CAPTURE",
                task_id = "TSK-P1-DEMO-003",
                timestamp_utc = evidenceMeta.TimestampUtc,
                git_sha = evidenceMeta.GitSha,
                schema_fingerprint = evidenceMeta.SchemaFingerprint,
                status,
                pass = status == "PASS",
                details = new
                {
                    capture_mode = "submission_time_geolocation",
                    exif_dependency = false,
                    tests
                }
            }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine,
            cancellationToken);

        Console.WriteLine($"Evidence written: {evidencePath}");
        return status == "PASS" ? 0 : 1;
    }
}
