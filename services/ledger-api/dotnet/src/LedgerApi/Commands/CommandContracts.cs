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

record EvidenceLinkIssueRequest(
    string tenant_id,
    string instruction_id,
    string program_id,
    string submitter_class,
    string submitter_msisdn,
    decimal? expected_latitude,
    decimal? expected_longitude,
    decimal? max_distance_meters,
    int? expires_in_seconds
);

record EvidenceLinkSubmitRequest(
    string artifact_type,
    string artifact_ref,
    decimal? latitude,
    decimal? longitude
);

record SignedInstructionGenerateRequest(
    string tenant_id,
    string program_id,
    string instruction_id,
    string supplier_id,
    string supplier_account,
    long amount_minor,
    string currency_code,
    string reference
);

record SignedInstructionVerifyRequest(
    string instruction_file_path
);

record SignedInstructionVerifyRefRequest(
    string instruction_file_ref
);

record SupplierRegistryUpsertRequest(
    string tenant_id,
    string supplier_id,
    string supplier_name,
    string payout_target,
    decimal? registered_latitude,
    decimal? registered_longitude,
    bool active
);

record ProgramSupplierAllowlistUpsertRequest(
    string tenant_id,
    string program_id,
    string supplier_id,
    bool allowed
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

// ─── Onboarding Control-Plane Contracts (TSK-P1-217) ───────────────

record TenantRegistryEntry(
    string TenantId,
    string TenantKey,
    string DisplayName,
    string Status,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

record TenantRegistryResult(bool Success, TenantRegistryEntry? Entry, bool CreatedNew, string? Error)
{
    public static TenantRegistryResult Ok(TenantRegistryEntry entry, bool createdNew)
        => new(true, entry, createdNew, null);
    public static TenantRegistryResult Fail(string error)
        => new(false, null, false, error);
}

interface ITenantRegistryStore
{
    Task<bool> ExistsAsync(Guid tenantId, CancellationToken cancellationToken, bool bypassRls = false);
    Task<TenantRegistryEntry?> GetAsync(Guid tenantId, CancellationToken cancellationToken, bool bypassRls = false);
    Task<IReadOnlyList<TenantRegistryEntry>> ListAsync(CancellationToken cancellationToken, bool bypassRls = false);
    Task<TenantRegistryResult> UpsertAsync(Guid tenantId, string tenantKey, string displayName, CancellationToken cancellationToken, bool bypassRls = false);
    Task<bool> RegisterSupplierAsync(Guid tenantId, string supplierId, string supplierName, string payoutTarget, CancellationToken cancellationToken, bool bypassRls = false);
}

record ProgrammeEntry(
    string ProgrammeId,
    string TenantId,
    string ProgrammeKey,
    string DisplayName,
    string Status,
    string? PolicyCode,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

record ProgrammeResult(bool Success, ProgrammeEntry? Entry, bool CreatedNew, string? Error)
{
    public static ProgrammeResult Ok(ProgrammeEntry entry, bool createdNew)
        => new(true, entry, createdNew, null);
    public static ProgrammeResult Fail(string error)
        => new(false, null, false, error);
}

interface IProgrammeStore
{
    Task<IReadOnlyList<ProgrammeEntry>> ListAsync(Guid? tenantId, CancellationToken cancellationToken, bool bypassRls = false);
    Task<ProgrammeResult> CreateAsync(Guid tenantId, string programmeKey, string displayName, CancellationToken cancellationToken, bool bypassRls = false);
    Task<ProgrammeResult> ActivateAsync(Guid programmeId, Guid tenantId, CancellationToken cancellationToken, bool bypassRls = false);
    Task<ProgrammeResult> SuspendAsync(Guid programmeId, Guid tenantId, CancellationToken cancellationToken, bool bypassRls = false);
    Task<ProgrammeResult> BindPolicyAsync(Guid programmeId, Guid tenantId, string policyCode, CancellationToken cancellationToken, bool bypassRls = false);
}
