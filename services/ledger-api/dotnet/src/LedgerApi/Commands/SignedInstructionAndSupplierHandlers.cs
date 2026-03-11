using System.Collections.Concurrent;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Http;

sealed record SupplierRegistryEntry(
    string tenant_id,
    string supplier_id,
    string supplier_name,
    string payout_target,
    decimal? registered_latitude,
    decimal? registered_longitude,
    bool active,
    string updated_at_utc
);

static class SupplierPolicyStore
{
    private static readonly ConcurrentDictionary<string, SupplierRegistryEntry> SupplierRegistry = new(StringComparer.Ordinal);
    private static readonly ConcurrentDictionary<string, bool> ProgramSupplierAllowlist = new(StringComparer.Ordinal);

    public static void UpsertSupplier(SupplierRegistryEntry entry)
        => SupplierRegistry[$"{entry.tenant_id}:{entry.supplier_id}"] = entry;

    public static void UpsertAllowlist(string tenantId, string programId, string supplierId, bool allowed)
        => ProgramSupplierAllowlist[$"{tenantId}:{programId}:{supplierId}"] = allowed;

    public static SupplierRegistryEntry? GetSupplier(string tenantId, string supplierId)
        => SupplierRegistry.TryGetValue($"{tenantId}:{supplierId}", out var entry) ? entry : null;

    public static bool IsAllowlisted(string tenantId, string programId, string supplierId)
        => ProgramSupplierAllowlist.TryGetValue($"{tenantId}:{programId}:{supplierId}", out var allowed) && allowed;
}

static class SupplierRegistryUpsertHandler
{
    public static Task<HandlerResult> HandleAsync(SupplierRegistryUpsertRequest request)
    {
        var errors = new List<string>();
        if (string.IsNullOrWhiteSpace(request.tenant_id) || !Guid.TryParse(request.tenant_id, out _))
        {
            errors.Add("tenant_id must be a valid UUID");
        }
        if (string.IsNullOrWhiteSpace(request.supplier_id))
        {
            errors.Add("supplier_id is required");
        }
        if (string.IsNullOrWhiteSpace(request.supplier_name))
        {
            errors.Add("supplier_name is required");
        }
        if (string.IsNullOrWhiteSpace(request.payout_target))
        {
            errors.Add("payout_target is required");
        }

        if (errors.Count > 0)
        {
            return Task.FromResult(new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors
            }));
        }

        var normalized = new SupplierRegistryEntry(
            tenant_id: request.tenant_id.Trim(),
            supplier_id: request.supplier_id.Trim(),
            supplier_name: request.supplier_name.Trim(),
            payout_target: request.payout_target.Trim(),
            registered_latitude: request.registered_latitude,
            registered_longitude: request.registered_longitude,
            active: request.active,
            updated_at_utc: DateTimeOffset.UtcNow.ToString("O"));

        SupplierPolicyStore.UpsertSupplier(normalized);

        return Task.FromResult(new HandlerResult(StatusCodes.Status200OK, new
        {
            upserted = true,
            supplier = normalized
        }));
    }
}

static class ProgramSupplierAllowlistUpsertHandler
{
    public static Task<HandlerResult> HandleAsync(ProgramSupplierAllowlistUpsertRequest request)
    {
        var errors = new List<string>();
        if (string.IsNullOrWhiteSpace(request.tenant_id) || !Guid.TryParse(request.tenant_id, out _))
        {
            errors.Add("tenant_id must be a valid UUID");
        }
        if (string.IsNullOrWhiteSpace(request.program_id))
        {
            errors.Add("program_id is required");
        }
        if (string.IsNullOrWhiteSpace(request.supplier_id))
        {
            errors.Add("supplier_id is required");
        }

        if (errors.Count > 0)
        {
            return Task.FromResult(new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors
            }));
        }

        SupplierPolicyStore.UpsertAllowlist(request.tenant_id.Trim(), request.program_id.Trim(), request.supplier_id.Trim(), request.allowed);

        return Task.FromResult(new HandlerResult(StatusCodes.Status200OK, new
        {
            updated = true,
            tenant_id = request.tenant_id.Trim(),
            program_id = request.program_id.Trim(),
            supplier_id = request.supplier_id.Trim(),
            allowed = request.allowed
        }));
    }
}

static class ProgramSupplierPolicyReadHandler
{
    public static HandlerResult Handle(string tenantId, string programId, string supplierId)
    {
        var supplier = SupplierPolicyStore.GetSupplier(tenantId, supplierId);
        var allowlisted = SupplierPolicyStore.IsAllowlisted(tenantId, programId, supplierId);

        return new HandlerResult(StatusCodes.Status200OK, new
        {
            tenant_id = tenantId,
            program_id = programId,
            supplier_id = supplierId,
            supplier_exists = supplier is not null,
            supplier_active = supplier?.active ?? false,
            allowlisted,
            decision = (supplier is not null && supplier.active && allowlisted) ? "ALLOW" : "DENY"
        });
    }
}

static class SignedInstructionFileHandler
{
    public static async Task<HandlerResult> GenerateAsync(SignedInstructionGenerateRequest request, ILogger logger, CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        if (string.IsNullOrWhiteSpace(request.tenant_id) || !Guid.TryParse(request.tenant_id, out _))
        {
            errors.Add("tenant_id must be a valid UUID");
        }
        if (string.IsNullOrWhiteSpace(request.program_id))
        {
            errors.Add("program_id is required");
        }
        if (string.IsNullOrWhiteSpace(request.instruction_id))
        {
            errors.Add("instruction_id is required");
        }
        if (string.IsNullOrWhiteSpace(request.supplier_id))
        {
            errors.Add("supplier_id is required");
        }
        if (string.IsNullOrWhiteSpace(request.supplier_account))
        {
            errors.Add("supplier_account is required");
        }
        if (request.amount_minor <= 0)
        {
            errors.Add("amount_minor must be > 0");
        }
        if (string.IsNullOrWhiteSpace(request.currency_code) || request.currency_code.Trim().Length != 3)
        {
            errors.Add("currency_code must be a 3-letter ISO code");
        }
        if (string.IsNullOrWhiteSpace(request.reference))
        {
            errors.Add("reference is required");
        }

        if (errors.Count > 0)
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors
            });
        }

        var tenantId = request.tenant_id.Trim();
        var programId = request.program_id.Trim();
        var supplierId = request.supplier_id.Trim();
        var supplier = SupplierPolicyStore.GetSupplier(tenantId, supplierId);
        var allowlisted = SupplierPolicyStore.IsAllowlisted(tenantId, programId, supplierId);
        if (supplier is null || !supplier.active || !allowlisted)
        {
            await DemoExceptionLog.AppendAsync(new
            {
                tenant_id = tenantId,
                program_id = programId,
                instruction_id = request.instruction_id.Trim(),
                supplier_id = supplierId,
                error_code = "SUPPLIER_NOT_ALLOWLISTED",
                recorded_at_utc = DateTimeOffset.UtcNow.ToString("O")
            }, cancellationToken);
            return new HandlerResult(StatusCodes.Status422UnprocessableEntity, new
            {
                error_code = "SUPPLIER_NOT_ALLOWLISTED",
                tenant_id = tenantId,
                program_id = programId,
                supplier_id = supplierId,
                supplier_exists = supplier is not null,
                supplier_active = supplier?.active ?? false,
                allowlisted
            });
        }

        var signingKey = ResolveSigningKey();
        if (string.IsNullOrWhiteSpace(signingKey))
        {
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                error_code = "SIGNING_KEY_MISSING",
                errors = new[] { "DEMO_INSTRUCTION_SIGNING_KEY or EVIDENCE_SIGNING_KEY must be configured" }
            });
        }

        var payload = new
        {
            tenant_id = tenantId,
            program_id = programId,
            instruction_id = request.instruction_id.Trim(),
            supplier_id = supplierId,
            supplier_account = request.supplier_account.Trim(),
            amount_minor = request.amount_minor,
            currency_code = request.currency_code.Trim().ToUpperInvariant(),
            reference = request.reference.Trim(),
            generated_at_utc = DateTimeOffset.UtcNow.ToString("O")
        };

        var canonicalPayload = JsonSerializer.Serialize(payload);
        var payloadHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(canonicalPayload))).ToLowerInvariant();
        var signature = ComputeHmac(canonicalPayload, signingKey);

        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = EvidenceMeta.Load(rootDir);
        var filePath = Path.Combine(evidenceDir, "signed_instruction_file_sample.json");
        await File.WriteAllTextAsync(filePath, JsonSerializer.Serialize(new
        {
            check_id = "TSK-P1-DEMO-005-SIGNED-INSTRUCTION-SAMPLE",
            task_id = "TSK-P1-DEMO-005",
            timestamp_utc = evidenceMeta.TimestampUtc,
            git_sha = evidenceMeta.GitSha,
            schema_fingerprint = evidenceMeta.SchemaFingerprint,
            status = "PASS",
            pass = true,
            schema = "symphony.signed_instruction_file.v1",
            payload,
            payload_hash = payloadHash,
            signature_alg = "HMAC-SHA256",
            signature
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        logger.LogInformation("Generated signed instruction file for instruction {InstructionId}", request.instruction_id);

        return new HandlerResult(StatusCodes.Status200OK, new
        {
            generated = true,
            instruction_file_path = filePath,
            payload_hash = payloadHash,
            signature_alg = "HMAC-SHA256",
            signature,
            critical_fields_signed = new[] { "amount_minor", "supplier_account", "reference" }
        });
    }

    public static async Task<HandlerResult> VerifyAsync(SignedInstructionVerifyRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.instruction_file_path))
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors = new[] { "instruction_file_path is required" }
            });
        }

        if (!File.Exists(request.instruction_file_path))
        {
            return new HandlerResult(StatusCodes.Status404NotFound, new
            {
                error_code = "INSTRUCTION_FILE_NOT_FOUND"
            });
        }

        var signingKey = ResolveSigningKey();
        if (string.IsNullOrWhiteSpace(signingKey))
        {
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                error_code = "SIGNING_KEY_MISSING",
                errors = new[] { "DEMO_INSTRUCTION_SIGNING_KEY or EVIDENCE_SIGNING_KEY must be configured" }
            });
        }

        var raw = await File.ReadAllTextAsync(request.instruction_file_path, cancellationToken);
        using var parsed = JsonDocument.Parse(raw);
        var root = parsed.RootElement;

        if (!root.TryGetProperty("payload", out var payloadNode)
            || !root.TryGetProperty("payload_hash", out var payloadHashNode)
            || !root.TryGetProperty("signature", out var signatureNode))
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INSTRUCTION_FILE_INVALID",
                errors = new[] { "payload, payload_hash, and signature are required" }
            });
        }

        var canonicalPayload = JsonSerializer.Serialize(payloadNode);
        var actualHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(canonicalPayload))).ToLowerInvariant();
        var expectedHash = payloadHashNode.GetString() ?? string.Empty;
        var actualSignature = ComputeHmac(canonicalPayload, signingKey);
        var expectedSignature = signatureNode.GetString() ?? string.Empty;

        var hashOk = SecureEquals(actualHash, expectedHash);
        var signatureOk = SecureEquals(actualSignature, expectedSignature);
        if (!hashOk || !signatureOk)
        {
            await DemoExceptionLog.AppendAsync(new
            {
                tenant_id = payloadNode.TryGetProperty("tenant_id", out var tenantNode) ? tenantNode.GetString() : null,
                program_id = payloadNode.TryGetProperty("program_id", out var programNode) ? programNode.GetString() : null,
                instruction_id = payloadNode.TryGetProperty("instruction_id", out var instructionNode) ? instructionNode.GetString() : null,
                supplier_id = payloadNode.TryGetProperty("supplier_id", out var supplierNode) ? supplierNode.GetString() : null,
                error_code = "CHECKSUM_BREAK",
                recorded_at_utc = DateTimeOffset.UtcNow.ToString("O")
            }, cancellationToken);
            return new HandlerResult(StatusCodes.Status422UnprocessableEntity, new
            {
                error_code = "CHECKSUM_BREAK",
                verified = false,
                hash_ok = hashOk,
                signature_ok = signatureOk,
                critical_fields_covered = new[] { "amount_minor", "supplier_account", "reference" }
            });
        }

        return new HandlerResult(StatusCodes.Status200OK, new
        {
            verified = true,
            hash_ok = true,
            signature_ok = true,
            critical_fields_covered = new[] { "amount_minor", "supplier_account", "reference" }
        });
    }

    public static string ResolveSigningKey()
        => (Environment.GetEnvironmentVariable("DEMO_INSTRUCTION_SIGNING_KEY")
            ?? Environment.GetEnvironmentVariable("EVIDENCE_SIGNING_KEY")
            ?? string.Empty).Trim();

    private static string ComputeHmac(string canonicalPayload, string signingKey)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(signingKey));
        return Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes(canonicalPayload))).ToLowerInvariant();
    }

    private static bool SecureEquals(string left, string right)
    {
        var leftBytes = SHA256.HashData(Encoding.UTF8.GetBytes(left ?? string.Empty));
        var rightBytes = SHA256.HashData(Encoding.UTF8.GetBytes(right ?? string.Empty));
        return CryptographicOperations.FixedTimeEquals(leftBytes, rightBytes);
    }
}
