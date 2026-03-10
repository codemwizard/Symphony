using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Npgsql;

record IngressRequest(
    string instruction_id,
    string participant_id,
    string idempotency_key,
    string rail_type,
    JsonElement payload,
    string? payload_hash,
    string? signature_hash,
    string? tenant_id,
    string? correlation_id,
    string? upstream_ref,
    string? downstream_ref,
    string? nfs_sequence_ref
);

record TenantOnboardingRequest(
    string tenant_id,
    string display_name,
    string jurisdiction_code,
    string plan
);

record KycHashBridgeRequest(
    string member_id,
    string provider_code,
    string outcome,
    string verification_method,
    string verification_hash,
    string hash_algorithm,
    string provider_signature,
    string provider_reference,
    string verified_at_provider
);

record RegulatoryIncidentCreateRequest(
    string tenant_id,
    string incident_type,
    string detected_at,
    string description,
    string severity
);

record PersistInput(
    string instruction_id,
    string participant_id,
    string idempotency_key,
    string rail_type,
    string payload_json,
    string payload_hash,
    string? signature_hash,
    string? tenant_id,
    string? correlation_id,
    string? upstream_ref,
    string? downstream_ref,
    string? nfs_sequence_ref
);

record PersistResult(bool Success, string? AttestationId, string? OutboxId, string? Error)
{
    public static PersistResult Ok(string attestationId, string outboxId) => new(true, attestationId, outboxId, null);
    public static PersistResult Fail(string error) => new(false, null, null, error);
}

interface IIngressDurabilityStore
{
    Task<PersistResult> PersistAsync(PersistInput input, CancellationToken cancellationToken);
}

record TenantOnboardingInput(
    Guid TenantId,
    string DisplayName,
    string JurisdictionCode,
    string Plan,
    string IdempotencyKey
);

record TenantOnboardingResult(
    bool Success,
    string? TenantId,
    DateTimeOffset? CreatedAt,
    string? OutboxId,
    bool CreatedNew,
    string? Error)
{
    public static TenantOnboardingResult Ok(string tenantId, DateTimeOffset createdAt, string? outboxId, bool createdNew)
        => new(true, tenantId, createdAt, outboxId, createdNew, null);

    public static TenantOnboardingResult Fail(string error)
        => new(false, null, null, null, false, error);
}

interface ITenantOnboardingStore
{
    Task<TenantOnboardingResult> OnboardAsync(TenantOnboardingInput input, CancellationToken cancellationToken);
}

record HandlerResult(int StatusCode, object Body);

static class StoreErrorMessages
{
    public const string PersistenceUnavailable = "persistence unavailable";
    public const string ReportLookupUnavailable = "report lookup unavailable";
}
