using System.Text.Json;
using Microsoft.Extensions.Logging;

namespace Symphony.LedgerApi.Demo;

public static class SignedInstructionEgressSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = global::EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = global::EvidenceMeta.Load(rootDir);
        var evidencePath = Path.Combine(evidenceDir, "tsk_p1_demo_005_signed_instruction_file_egress.json");
        var samplePath = Path.Combine(evidenceDir, "signed_instruction_file_sample.json");

        var tenantId = "11111111-1111-1111-1111-111111111111";
        var programId = "program-a";
        var supplierId = "supplier-001";
        Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", tenantId);
        Environment.SetEnvironmentVariable("DEMO_INSTRUCTION_SIGNING_KEY", "demo-instruction-signing-key");

        await global::SupplierRegistryUpsertHandler.HandleAsync(new global::SupplierRegistryUpsertRequest(
            tenantId,
            supplierId,
            "Supplier One",
            "MMO:+260970000001",
            -15.39m,
            28.32m,
            true));
        await global::ProgramSupplierAllowlistUpsertHandler.HandleAsync(new global::ProgramSupplierAllowlistUpsertRequest(
            tenantId,
            programId,
            supplierId,
            true));

        var generated = await global::SignedInstructionFileHandler.GenerateAsync(
            new global::SignedInstructionGenerateRequest(
                tenantId,
                programId,
                "instr-005-001",
                supplierId,
                "MMO:+260970000001",
                250000,
                "ZMW",
                "INV-005-001"),
            logger,
            cancellationToken);

        string generatedPath = samplePath;
        if (generated.StatusCode == 200)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(generated.Body));
            if (doc.RootElement.TryGetProperty("instruction_file_path", out var p) && !string.IsNullOrWhiteSpace(p.GetString()))
            {
                generatedPath = p.GetString()!;
            }
        }

        var verifyUntouched = await global::SignedInstructionFileHandler.VerifyAsync(
            new global::SignedInstructionVerifyRequest(generatedPath),
            cancellationToken);

        // Tamper critical fields and verify checksum-break path.
        var tamperedJson = await File.ReadAllTextAsync(generatedPath, cancellationToken);
        using var parsed = JsonDocument.Parse(tamperedJson);
        var payload = parsed.RootElement.GetProperty("payload");
        var tamperedPayload = new
        {
            tenant_id = payload.GetProperty("tenant_id").GetString(),
            program_id = payload.GetProperty("program_id").GetString(),
            instruction_id = payload.GetProperty("instruction_id").GetString(),
            supplier_id = payload.GetProperty("supplier_id").GetString(),
            supplier_account = "MMO:+260970999999",
            amount_minor = payload.GetProperty("amount_minor").GetInt64() + 1,
            currency_code = payload.GetProperty("currency_code").GetString(),
            reference = "INV-005-TAMPER",
            generated_at_utc = payload.GetProperty("generated_at_utc").GetString()
        };

        var tamperedEnvelope = new
        {
            schema = parsed.RootElement.GetProperty("schema").GetString(),
            payload = tamperedPayload,
            payload_hash = parsed.RootElement.GetProperty("payload_hash").GetString(),
            signature_alg = parsed.RootElement.GetProperty("signature_alg").GetString(),
            signature = parsed.RootElement.GetProperty("signature").GetString()
        };
        await File.WriteAllTextAsync(generatedPath, JsonSerializer.Serialize(tamperedEnvelope, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        var verifyTampered = await global::SignedInstructionFileHandler.VerifyAsync(
            new global::SignedInstructionVerifyRequest(generatedPath),
            cancellationToken);

        var tests = new[]
        {
            new { name = "generate_signed_instruction_file", status = generated.StatusCode == 200 ? "PASS" : "FAIL" },
            new { name = "verify_untouched_file", status = verifyUntouched.StatusCode == 200 ? "PASS" : "FAIL" },
            new { name = "verify_tampered_file_fails", status = verifyTampered.StatusCode == 422 ? "PASS" : "FAIL" }
        };
        var status = tests.All(x => x.status == "PASS") ? "PASS" : "FAIL";

        await File.WriteAllTextAsync(
            evidencePath,
            JsonSerializer.Serialize(new
            {
                check_id = "TSK-P1-DEMO-005-SIGNED-EGRESS",
                task_id = "TSK-P1-DEMO-005",
                timestamp_utc = evidenceMeta.TimestampUtc,
                git_sha = evidenceMeta.GitSha,
                schema_fingerprint = evidenceMeta.SchemaFingerprint,
                status,
                pass = status == "PASS",
                details = new
                {
                    instruction_file_path = generatedPath,
                    tamper_error_code = "CHECKSUM_BREAK",
                    critical_fields_covered = new[] { "amount_minor", "supplier_account", "reference" },
                    tests
                }
            }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine,
            cancellationToken);

        Console.WriteLine($"Evidence written: {evidencePath}");
        return status == "PASS" ? 0 : 1;
    }
}
