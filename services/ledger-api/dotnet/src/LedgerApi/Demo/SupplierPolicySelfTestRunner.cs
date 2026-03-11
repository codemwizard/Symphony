using System.Text.Json;
using Microsoft.Extensions.Logging;

namespace Symphony.LedgerApi.Demo;

public static class SupplierPolicySelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = global::EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = global::EvidenceMeta.Load(rootDir);
        var evidencePath = Path.Combine(evidenceDir, "tsk_p1_demo_006_supplier_policy.json");

        var tenantId = "11111111-1111-1111-1111-111111111111";
        var programA = "program-a";
        var programB = "program-b";
        var supplierId = "supplier-002";
        Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", tenantId);
        Environment.SetEnvironmentVariable("DEMO_INSTRUCTION_SIGNING_KEY", "demo-instruction-signing-key");

        await global::SupplierRegistryUpsertHandler.HandleAsync(new global::SupplierRegistryUpsertRequest(
            tenantId,
            supplierId,
            "Supplier Two",
            "MMO:+260970000002",
            -15.39m,
            28.32m,
            true));

        await global::ProgramSupplierAllowlistUpsertHandler.HandleAsync(new global::ProgramSupplierAllowlistUpsertRequest(
            tenantId,
            programA,
            supplierId,
            true));

        var allowed = await global::SignedInstructionFileHandler.GenerateAsync(
            new global::SignedInstructionGenerateRequest(
                tenantId,
                programA,
                "instr-006-allow",
                supplierId,
                "MMO:+260970000002",
                120000,
                "ZMW",
                "INV-006-A"),
            logger,
            cancellationToken);

        var deniedOtherProgram = await global::SignedInstructionFileHandler.GenerateAsync(
            new global::SignedInstructionGenerateRequest(
                tenantId,
                programB,
                "instr-006-deny-b",
                supplierId,
                "MMO:+260970000002",
                120000,
                "ZMW",
                "INV-006-B"),
            logger,
            cancellationToken);

        var deniedUnknownSupplier = await global::SignedInstructionFileHandler.GenerateAsync(
            new global::SignedInstructionGenerateRequest(
                tenantId,
                programA,
                "instr-006-deny-unknown",
                "supplier-unknown",
                "MMO:+260970000999",
                120000,
                "ZMW",
                "INV-006-U"),
            logger,
            cancellationToken);

        var policyProgramA = global::ProgramSupplierPolicyReadHandler.Handle(tenantId, programA, supplierId);
        var policyProgramB = global::ProgramSupplierPolicyReadHandler.Handle(tenantId, programB, supplierId);

        var tests = new[]
        {
            new { name = "program_a_supplier_allowed", status = allowed.StatusCode == 200 ? "PASS" : "FAIL" },
            new { name = "program_b_same_supplier_denied", status = deniedOtherProgram.StatusCode == 422 ? "PASS" : "FAIL" },
            new { name = "unknown_supplier_denied", status = deniedUnknownSupplier.StatusCode == 422 ? "PASS" : "FAIL" },
            new { name = "policy_surface_program_a_allow", status = PolicyDecision(policyProgramA) == "ALLOW" ? "PASS" : "FAIL" },
            new { name = "policy_surface_program_b_deny", status = PolicyDecision(policyProgramB) == "DENY" ? "PASS" : "FAIL" }
        };

        var status = tests.All(x => x.status == "PASS") ? "PASS" : "FAIL";

        await File.WriteAllTextAsync(
            evidencePath,
            JsonSerializer.Serialize(new
            {
                check_id = "TSK-P1-DEMO-006-SUPPLIER-POLICY",
                task_id = "TSK-P1-DEMO-006",
                timestamp_utc = evidenceMeta.TimestampUtc,
                git_sha = evidenceMeta.GitSha,
                schema_fingerprint = evidenceMeta.SchemaFingerprint,
                status,
                pass = status == "PASS",
                details = new
                {
                    enforced_error_code = "SUPPLIER_NOT_ALLOWLISTED",
                    tests
                }
            }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine,
            cancellationToken);

        Console.WriteLine($"Evidence written: {evidencePath}");
        return status == "PASS" ? 0 : 1;
    }

    private static string PolicyDecision(global::HandlerResult result)
    {
        using var parsed = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
        return parsed.RootElement.TryGetProperty("decision", out var decision)
            ? (decision.GetString() ?? "UNKNOWN")
            : "UNKNOWN";
    }
}
