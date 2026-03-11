using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Symphony.LedgerApi.Demo;

public static class SupervisoryReadModelsSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = global::EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = global::EvidenceMeta.Load(rootDir);
        var evidencePath = Path.Combine(evidenceDir, "tsk_p1_demo_007_supervisory_read_models.json");

        var tenantId = "11111111-1111-1111-1111-111111111111";
        var programId = "program-a";
        var supplierId = "supplier-007";
        Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", tenantId);
        Environment.SetEnvironmentVariable("DEMO_EVIDENCE_LINK_SIGNING_KEY", "demo-link-self-test-key");
        Environment.SetEnvironmentVariable("DEMO_INSTRUCTION_SIGNING_KEY", "demo-instruction-signing-key");

        await global::SupplierRegistryUpsertHandler.HandleAsync(new global::SupplierRegistryUpsertRequest(
            tenantId,
            supplierId,
            "Supplier Seven",
            "MMO:+260970000007",
            -15.39m,
            28.32m,
            true));
        await global::ProgramSupplierAllowlistUpsertHandler.HandleAsync(new global::ProgramSupplierAllowlistUpsertRequest(
            tenantId,
            programId,
            supplierId,
            true));

        // Generate one allowed instruction and one denied instruction to populate exception log.
        _ = await global::SignedInstructionFileHandler.GenerateAsync(new global::SignedInstructionGenerateRequest(
                tenantId,
                programId,
                "instr-007-allow",
                supplierId,
                "MMO:+260970000007",
                9900,
                "ZMW",
                "INV-007-A"),
            logger,
            cancellationToken);

        _ = await global::SignedInstructionFileHandler.GenerateAsync(new global::SignedInstructionGenerateRequest(
                tenantId,
                "program-b",
                "instr-007-denied",
                supplierId,
                "MMO:+260970000007",
                9900,
                "ZMW",
                "INV-007-B"),
            logger,
            cancellationToken);

        // Populate evidence submissions.
        var issue = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId,
                "instr-007-allow",
                "FIELD_OFFICER",
                "+260971700700",
                null,
                null,
                null,
                300),
            logger,
            cancellationToken);

        var token = string.Empty;
        if (issue.StatusCode == StatusCodes.Status200OK)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(issue.Body));
            token = doc.RootElement.TryGetProperty("token", out var t) ? t.GetString() ?? string.Empty : string.Empty;
        }

        var ctx = new DefaultHttpContext();
        ctx.Request.Headers["x-tenant-id"] = tenantId;
        ctx.Request.Headers["x-evidence-link-token"] = token;
        ctx.Request.Headers["x-submitter-msisdn"] = "+260971700700";
        _ = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("INVOICE", "s3://bucket/inv-007.pdf", null, null),
            ctx,
            logger,
            cancellationToken);

        _ = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest("DELIVERY_PHOTO", "s3://bucket/photo-007.jpg", null, null),
            ctx,
            logger,
            cancellationToken);

        var reveal = global::SupervisoryRevealReadModelHandler.Handle(tenantId, programId);
        var crossTenantDenied = global::ApiAuthorization.AuthorizeTenantScope("22222222-2222-2222-2222-222222222222");

        bool HasTopLevel(JsonElement root, params string[] fields)
            => fields.All(field => root.TryGetProperty(field, out _));

        bool hasRequired = false;
        if (reveal.StatusCode == StatusCodes.Status200OK)
        {
            using var revealDoc = JsonDocument.Parse(JsonSerializer.Serialize(reveal.Body));
            hasRequired = HasTopLevel(revealDoc.RootElement, "programme_summary", "timeline", "evidence_completeness", "exception_log");
        }

        var tests = new[]
        {
            new { name = "reveal_read_model_components_present", status = (reveal.StatusCode == StatusCodes.Status200OK && hasRequired) ? "PASS" : "FAIL" },
            new { name = "cross_tenant_denied_fail_closed", status = (crossTenantDenied is not null && crossTenantDenied.StatusCode == StatusCodes.Status403Forbidden) ? "PASS" : "FAIL" }
        };

        var status = tests.All(x => x.status == "PASS") ? "PASS" : "FAIL";

        await File.WriteAllTextAsync(
            evidencePath,
            JsonSerializer.Serialize(new
            {
                check_id = "TSK-P1-DEMO-007-SUPERVISORY-READ-MODELS",
                task_id = "TSK-P1-DEMO-007",
                timestamp_utc = evidenceMeta.TimestampUtc,
                git_sha = evidenceMeta.GitSha,
                schema_fingerprint = evidenceMeta.SchemaFingerprint,
                status,
                pass = status == "PASS",
                details = new
                {
                    reveal_api = "/v1/supervisory/programmes/{program_id}/reveal",
                    read_only = true,
                    tests
                }
            }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine,
            cancellationToken);

        Console.WriteLine($"Evidence written: {evidencePath}");
        return status == "PASS" ? 0 : 1;
    }
}
