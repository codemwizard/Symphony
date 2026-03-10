using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Npgsql;

static class IngressHandler
{
    public static async Task<HandlerResult> HandleAsync(
        IngressRequest request,
        IIngressDurabilityStore store,
        ILogger logger,
        bool forceFailure,
        CancellationToken cancellationToken)
    {
        var validationErrors = IngressValidation.Validate(request);
        if (validationErrors.Count > 0)
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                ack = false,
                error_code = "INVALID_REQUEST",
                errors = validationErrors
            });
        }

        var schemaViolations = IngressValidation.ValidateCanonicalInstructionPayload(request.payload);
        if (schemaViolations.Count > 0)
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error = "SCHEMA_VALIDATION_FAILED",
                violations = schemaViolations
            });
        }

        if (forceFailure || IngressValidation.IsForcedFailureEnabled())
        {
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                ack = false,
                error_code = "ATTESTATION_DURABILITY_FAILED"
            });
        }

        var payloadJson = request.payload.GetRawText();
        var payloadHash = string.IsNullOrWhiteSpace(request.payload_hash)
            ? IngressValidation.Sha256Hex(payloadJson)
            : request.payload_hash.Trim();

        var persistInput = new PersistInput(
            instruction_id: request.instruction_id.Trim(),
            participant_id: request.participant_id.Trim(),
            idempotency_key: request.idempotency_key.Trim(),
            rail_type: request.rail_type.Trim(),
            payload_json: payloadJson,
            payload_hash: payloadHash,
            signature_hash: string.IsNullOrWhiteSpace(request.signature_hash) ? null : request.signature_hash.Trim(),
            tenant_id: string.IsNullOrWhiteSpace(request.tenant_id) ? null : request.tenant_id.Trim(),
            correlation_id: string.IsNullOrWhiteSpace(request.correlation_id) ? null : request.correlation_id.Trim(),
            upstream_ref: string.IsNullOrWhiteSpace(request.upstream_ref) ? null : request.upstream_ref.Trim(),
            downstream_ref: string.IsNullOrWhiteSpace(request.downstream_ref) ? null : request.downstream_ref.Trim(),
            nfs_sequence_ref: string.IsNullOrWhiteSpace(request.nfs_sequence_ref) ? null : request.nfs_sequence_ref.Trim()
        );

        var persistResult = await store.PersistAsync(persistInput, cancellationToken);
        if (!persistResult.Success)
        {
            logger.LogError("Ingress persistence failed: {Error}", persistResult.Error);
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                ack = false,
                error_code = "ATTESTATION_DURABILITY_FAILED"
            });
        }

        return new HandlerResult(StatusCodes.Status202Accepted, new
        {
            ack = true,
            instruction_id = persistInput.instruction_id,
            attestation_id = persistResult.AttestationId,
            outbox_id = persistResult.OutboxId,
            outbox_state = "PENDING",
            payload_hash = persistInput.payload_hash
        });
    }
}

static class IngressValidation
{
    private static readonly Regex CurrencyRegex = new("^[A-Z]{3}$", RegexOptions.Compiled);
    private const long MaxAmountMinor = 1_000_000_000_000;

    public static bool IsForcedFailureEnabled()
    {
        var value = Environment.GetEnvironmentVariable("INGRESS_FORCE_ATTESTATION_FAIL") ?? "0";
        return value == "1" || value.Equals("true", StringComparison.OrdinalIgnoreCase);
    }

    public static List<string> Validate(IngressRequest request)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(request.instruction_id))
        {
            errors.Add("instruction_id is required");
        }

        if (string.IsNullOrWhiteSpace(request.participant_id))
        {
            errors.Add("participant_id is required");
        }

        if (string.IsNullOrWhiteSpace(request.idempotency_key))
        {
            errors.Add("idempotency_key is required");
        }

        if (string.IsNullOrWhiteSpace(request.rail_type))
        {
            errors.Add("rail_type is required");
        }

        if (request.payload.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null)
        {
            errors.Add("payload is required");
        }

        if (string.IsNullOrWhiteSpace(request.tenant_id))
        {
            errors.Add("tenant_id is required");
        }
        else if (!Guid.TryParse(request.tenant_id, out _))
        {
            errors.Add("tenant_id must be a valid UUID");
        }

        if (!string.IsNullOrWhiteSpace(request.correlation_id) && !Guid.TryParse(request.correlation_id, out _))
        {
            errors.Add("correlation_id must be a valid UUID when provided");
        }

        return errors;
    }

    public static string Sha256Hex(string input)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }

    public static List<object> ValidateCanonicalInstructionPayload(JsonElement payload)
    {
        var violations = new List<object>();

        if (payload.ValueKind != JsonValueKind.Object)
        {
            violations.Add(new { field = "payload", message = "payload must be a JSON object" });
            return violations;
        }

        void RequireString(string field, Func<string, bool>? extraPredicate = null, string? extraMessage = null)
        {
            if (!payload.TryGetProperty(field, out var value))
            {
                violations.Add(new { field, message = $"{field} is required" });
                return;
            }
            if (value.ValueKind != JsonValueKind.String)
            {
                violations.Add(new { field, message = $"{field} must be a string" });
                return;
            }

            var text = value.GetString() ?? string.Empty;
            if (string.IsNullOrWhiteSpace(text))
            {
                violations.Add(new { field, message = $"{field} must not be empty" });
                return;
            }

            if (extraPredicate is not null && !extraPredicate(text))
            {
                violations.Add(new { field, message = extraMessage ?? $"{field} is invalid" });
            }
        }

        RequireString("instruction_id", s => Guid.TryParse(s, out _), "instruction_id must be a valid UUID");
        RequireString("tenant_id", s => Guid.TryParse(s, out _), "tenant_id must be a valid UUID");
        RequireString("rail_type");

        if (!payload.TryGetProperty("amount_minor", out var amount))
        {
            violations.Add(new { field = "amount_minor", message = "amount_minor is required" });
        }
        else if (amount.ValueKind != JsonValueKind.Number || !amount.TryGetInt64(out var amountMinor))
        {
            violations.Add(new { field = "amount_minor", message = "amount_minor must be an integer" });
        }
        else if (amountMinor <= 0)
        {
            violations.Add(new { field = "amount_minor", message = "amount_minor must be greater than 0" });
        }
        else if (amountMinor > MaxAmountMinor)
        {
            violations.Add(new { field = "amount_minor", message = $"amount_minor must not exceed {MaxAmountMinor}" });
        }

        RequireString("currency_code", s => CurrencyRegex.IsMatch(s), "currency_code must be ISO 4217 uppercase alpha-3");
        RequireString("beneficiary_ref_hash");
        RequireString("idempotency_key");
        RequireString(
            "submitted_at_utc",
            s => DateTimeOffset.TryParse(s, out _),
            "submitted_at_utc must be an ISO 8601 timestamp"
        );

        return violations;
    }
}

static class TenantOnboardingValidation
{
    public static List<string> Validate(TenantOnboardingRequest request)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(request.tenant_id))
        {
            errors.Add("tenant_id is required");
        }
        else if (!Guid.TryParse(request.tenant_id, out _))
        {
            errors.Add("tenant_id must be a valid UUID");
        }

        if (string.IsNullOrWhiteSpace(request.display_name))
        {
            errors.Add("display_name is required");
        }

        if (string.IsNullOrWhiteSpace(request.jurisdiction_code))
        {
            errors.Add("jurisdiction_code is required");
        }
        else if (request.jurisdiction_code.Trim().Length != 2)
        {
            errors.Add("jurisdiction_code must be an ISO-3166 alpha-2 code");
        }

        if (string.IsNullOrWhiteSpace(request.plan))
        {
            errors.Add("plan is required");
        }

        return errors;
    }
}

record KycHashPersistResult(bool Success, bool ProviderFound, string? KycRecordId, string? AnchoredAtUtc, string? Outcome, string RetentionClass, string? Error)
{
    public static KycHashPersistResult Ok(string kycRecordId, string anchoredAtUtc, string outcome, string retentionClass)
        => new(true, true, kycRecordId, anchoredAtUtc, outcome, retentionClass, null);

    public static KycHashPersistResult ProviderNotFound()
        => new(false, false, null, null, null, "FIC_AML_CUSTOMER_ID", "provider_not_found");

    public static KycHashPersistResult Fail(string error)
        => new(false, true, null, null, null, "FIC_AML_CUSTOMER_ID", error);
}

interface IKycHashBridgeStore
{
    Task<KycHashPersistResult> PersistAsync(KycHashBridgeRequest request, CancellationToken cancellationToken);
}

static class KycHashBridgeValidation
{
    private static readonly HashSet<string> PiiFields = new(StringComparer.OrdinalIgnoreCase)
    {
        "nrc_number",
        "full_name",
        "date_of_birth",
        "photo_url"
    };

    public static bool TryRejectPiiFields(JsonElement payload, out string field)
    {
        field = string.Empty;
        if (payload.ValueKind != JsonValueKind.Object)
        {
            return false;
        }

        foreach (var property in payload.EnumerateObject())
        {
            if (PiiFields.Contains(property.Name))
            {
                field = property.Name;
                return true;
            }
        }

        return false;
    }

    public static (KycHashBridgeRequest? Request, List<string> Errors) Parse(JsonElement payload)
    {
        var errors = new List<string>();
        if (payload.ValueKind != JsonValueKind.Object)
        {
            errors.Add("request body must be an object");
            return (null, errors);
        }

        string ReadRequired(string field)
        {
            if (!payload.TryGetProperty(field, out var prop) || prop.ValueKind != JsonValueKind.String)
            {
                errors.Add($"{field} is required");
                return string.Empty;
            }

            var value = prop.GetString() ?? string.Empty;
            if (string.IsNullOrWhiteSpace(value))
            {
                errors.Add($"{field} is required");
                return string.Empty;
            }

            return value.Trim();
        }

        var memberId = ReadRequired("member_id");
        var providerCode = ReadRequired("provider_code");
        var outcome = ReadRequired("outcome");
        var verificationMethod = ReadRequired("verification_method");
        var verificationHash = ReadRequired("verification_hash");
        var hashAlgorithm = ReadRequired("hash_algorithm");
        var providerSignature = ReadRequired("provider_signature");
        var providerReference = ReadRequired("provider_reference");
        var verifiedAtProvider = ReadRequired("verified_at_provider");

        if (!string.IsNullOrWhiteSpace(memberId) && !Guid.TryParse(memberId, out _))
        {
            errors.Add("member_id must be a valid UUID");
        }
        if (!string.IsNullOrWhiteSpace(verifiedAtProvider) && !DateTimeOffset.TryParse(verifiedAtProvider, out _))
        {
            errors.Add("verified_at_provider must be an ISO 8601 timestamp");
        }

        if (errors.Count > 0)
        {
            return (null, errors);
        }

        return (new KycHashBridgeRequest(
            member_id: memberId,
            provider_code: providerCode,
            outcome: outcome,
            verification_method: verificationMethod,
            verification_hash: verificationHash,
            hash_algorithm: hashAlgorithm,
            provider_signature: providerSignature,
            provider_reference: providerReference,
            verified_at_provider: verifiedAtProvider
        ), errors);
    }
}

static class KycHashBridgeHandler
{
    public static async Task<HandlerResult> HandleAsync(
        KycHashBridgeRequest request,
        IKycHashBridgeStore store,
        ILogger logger,
        CancellationToken cancellationToken)
    {
        var persist = await store.PersistAsync(request, cancellationToken);
        if (!persist.ProviderFound)
        {
            return new HandlerResult(StatusCodes.Status404NotFound, new
            {
                error_code = "PROVIDER_NOT_FOUND"
            });
        }

        if (!persist.Success || string.IsNullOrWhiteSpace(persist.KycRecordId) || string.IsNullOrWhiteSpace(persist.AnchoredAtUtc))
        {
            logger.LogError("KYC hash bridge persistence failed: {Error}", persist.Error);
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                error_code = "KYC_HASH_BRIDGE_FAILED"
            });
        }

        return new HandlerResult(StatusCodes.Status200OK, new
        {
            kyc_record_id = persist.KycRecordId,
            anchored_at = persist.AnchoredAtUtc,
            outcome = persist.Outcome,
            retention_class = persist.RetentionClass
        });
    }
}
