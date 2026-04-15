using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Npgsql;

sealed class FileIngressDurabilityStore(ILogger logger, string? path = null) : IIngressDurabilityStore
{
    private readonly string _path = path
        ?? Environment.GetEnvironmentVariable("INGRESS_STORAGE_FILE")
        ?? "/tmp/symphony_ingress_attestations.ndjson";

    public async Task<PersistResult> PersistAsync(PersistInput input, CancellationToken cancellationToken)
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(_path) ?? "/tmp");

            var attestationId = Guid.NewGuid().ToString();
            var outboxId = Guid.NewGuid().ToString();
            var asOfUtc = ProjectionMeta.AsOfUtc();
            var line = JsonSerializer.Serialize(new
            {
                attestation_id = attestationId,
                outbox_id = outboxId,
                instruction_id = input.instruction_id,
                participant_id = input.participant_id,
                idempotency_key = input.idempotency_key,
                rail_type = input.rail_type,
                payload_hash = input.payload_hash,
                signature_hash = input.signature_hash,
                tenant_id = input.tenant_id,
                correlation_id = input.correlation_id,
                upstream_ref = input.upstream_ref,
                downstream_ref = input.downstream_ref,
                nfs_sequence_ref = input.nfs_sequence_ref,
                written_at_utc = asOfUtc
            });

            await File.AppendAllTextAsync(_path, line + Environment.NewLine, cancellationToken);
            var (amountMinor, currencyCode) = ProjectionPayload.ParseAmountAndCurrency(input.payload_json);
            await ProjectionFiles.UpsertByKeyAsync(
                ProjectionFiles.InstructionStatusPath(),
                "instruction_id",
                input.instruction_id,
                new InstructionStatusProjection(
                    instruction_id: input.instruction_id,
                    tenant_id: input.tenant_id ?? string.Empty,
                    participant_id: input.participant_id,
                    rail_type: input.rail_type,
                    status: "PENDING",
                    attestation_id: attestationId,
                    outbox_id: outboxId,
                    payload_hash: input.payload_hash,
                    amount_minor: amountMinor,
                    currency_code: currencyCode,
                    correlation_id: input.correlation_id,
                    as_of_utc: asOfUtc,
                    projection_version: ProjectionMeta.Version),
                cancellationToken);
            await ProjectionFiles.UpsertByKeyAsync(
                ProjectionFiles.EvidenceBundlePath(),
                "instruction_id",
                input.instruction_id,
                new EvidencePack(
                    api_version: "v1",
                    schema_version: "phase1-evidence-pack-v1",
                    instruction_id: input.instruction_id,
                    tenant_id: input.tenant_id ?? string.Empty,
                    attestation_id: attestationId,
                    outbox_id: outboxId,
                    payload_hash: input.payload_hash,
                    signature_hash: input.signature_hash,
                    correlation_id: input.correlation_id,
                    upstream_ref: input.upstream_ref,
                    downstream_ref: input.downstream_ref,
                    nfs_sequence_ref: input.nfs_sequence_ref,
                    written_at_utc: asOfUtc,
                    timeline: new object[]
                    {
                        new { event_name = "ATTESTED", at_utc = asOfUtc, actor = "ingress_api" },
                        new { event_name = "OUTBOX_ENQUEUED", at_utc = asOfUtc, actor = "ingress_api" }
                    },
                    as_of_utc: asOfUtc,
                    projection_version: ProjectionMeta.Version),
                cancellationToken);
            return PersistResult.Ok(attestationId, outboxId);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to persist ingress attestation to file store.");
            return PersistResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }
}

sealed class NpgsqlIngressDurabilityStore(ILogger logger, NpgsqlDataSource dataSource) : IIngressDurabilityStore
{
    public async Task<PersistResult> PersistAsync(PersistInput input, CancellationToken cancellationToken)
    {
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.Transaction = tx;
            cmd.CommandText = @"
WITH inserted AS (
  INSERT INTO public.ingress_attestations (
    instruction_id,
    tenant_id,
    payload_hash,
    signature_hash,
    correlation_id,
    upstream_ref,
    downstream_ref,
    nfs_sequence_ref
  ) VALUES (
    @instruction_id,
    @tenant_id,
    @payload_hash,
    @signature_hash,
    @correlation_id,
    @upstream_ref,
    @downstream_ref,
    @nfs_sequence_ref
  )
  RETURNING attestation_id::text
), enqueued AS (
  SELECT outbox_id::text
  FROM public.enqueue_payment_outbox(
    @instruction_id,
    @participant_id,
    @idempotency_key,
    @rail_type,
    @payload_json::jsonb
  )
)
SELECT (SELECT attestation_id FROM inserted), (SELECT outbox_id FROM enqueued LIMIT 1);
";
            cmd.Parameters.AddWithValue("instruction_id", input.instruction_id);
            cmd.Parameters.AddWithValue("tenant_id", DbValueParsers.ParseRequiredUuid(input.tenant_id, "tenant_id"));
            cmd.Parameters.AddWithValue("payload_hash", input.payload_hash);
            cmd.Parameters.AddWithValue("signature_hash", (object?)input.signature_hash ?? DBNull.Value);
            cmd.Parameters.AddWithValue("correlation_id", DbValueParsers.ParseOptionalUuid(input.correlation_id));
            cmd.Parameters.AddWithValue("upstream_ref", (object?)input.upstream_ref ?? DBNull.Value);
            cmd.Parameters.AddWithValue("downstream_ref", (object?)input.downstream_ref ?? DBNull.Value);
            cmd.Parameters.AddWithValue("nfs_sequence_ref", (object?)input.nfs_sequence_ref ?? DBNull.Value);
            cmd.Parameters.AddWithValue("participant_id", input.participant_id);
            cmd.Parameters.AddWithValue("idempotency_key", input.idempotency_key);
            cmd.Parameters.AddWithValue("rail_type", input.rail_type);
            cmd.Parameters.AddWithValue("payload_json", input.payload_json);

            string attestationId;
            string outboxId;
            await using (var reader = await cmd.ExecuteReaderAsync(cancellationToken))
            {
                if (!await reader.ReadAsync(cancellationToken))
                {
                    return PersistResult.Fail("db returned no attestation/outbox output");
                }

                attestationId = reader.IsDBNull(0) ? string.Empty : reader.GetString(0);
                outboxId = reader.IsDBNull(1) ? string.Empty : reader.GetString(1);
            }

            if (string.IsNullOrWhiteSpace(attestationId) || string.IsNullOrWhiteSpace(outboxId))
            {
                await tx.RollbackAsync(cancellationToken);
                return PersistResult.Fail("db returned malformed attestation/outbox output");
            }

            var (amountMinor, currencyCode) = ProjectionPayload.ParseAmountAndCurrency(input.payload_json);
            var asOfUtc = DateTimeOffset.UtcNow;
            await using var projection = conn.CreateCommand();
            projection.Transaction = tx;
            projection.CommandText = @"
INSERT INTO public.instruction_status_projection (
  instruction_id, tenant_id, participant_id, rail_type, status, attestation_id, outbox_id,
  payload_hash, amount_minor, currency_code, correlation_id, as_of_utc, projection_version
) VALUES (
  @instruction_id, @tenant_id, @participant_id, @rail_type, 'PENDING', @attestation_id, @outbox_id,
  @payload_hash, @amount_minor, @currency_code, @correlation_id, @as_of_utc, @projection_version
)
ON CONFLICT (instruction_id)
DO UPDATE SET
  tenant_id = EXCLUDED.tenant_id,
  participant_id = EXCLUDED.participant_id,
  rail_type = EXCLUDED.rail_type,
  status = EXCLUDED.status,
  attestation_id = EXCLUDED.attestation_id,
  outbox_id = EXCLUDED.outbox_id,
  payload_hash = EXCLUDED.payload_hash,
  amount_minor = EXCLUDED.amount_minor,
  currency_code = EXCLUDED.currency_code,
  correlation_id = EXCLUDED.correlation_id,
  as_of_utc = EXCLUDED.as_of_utc,
  projection_version = EXCLUDED.projection_version;

INSERT INTO public.evidence_bundle_projection (
  instruction_id, tenant_id, projection_payload, as_of_utc, projection_version
) VALUES (
  @instruction_id, @tenant_id, @evidence_payload::jsonb, @as_of_utc, @projection_version
)
ON CONFLICT (instruction_id)
DO UPDATE SET
  tenant_id = EXCLUDED.tenant_id,
  projection_payload = EXCLUDED.projection_payload,
  as_of_utc = EXCLUDED.as_of_utc,
  projection_version = EXCLUDED.projection_version;";
            projection.Parameters.AddWithValue("instruction_id", input.instruction_id);
            projection.Parameters.AddWithValue("tenant_id", DbValueParsers.ParseRequiredUuid(input.tenant_id, "tenant_id"));
            projection.Parameters.AddWithValue("participant_id", input.participant_id);
            projection.Parameters.AddWithValue("rail_type", input.rail_type);
            projection.Parameters.AddWithValue("attestation_id", Guid.Parse(attestationId));
            projection.Parameters.AddWithValue("outbox_id", Guid.Parse(outboxId));
            projection.Parameters.AddWithValue("payload_hash", input.payload_hash);
            projection.Parameters.AddWithValue("amount_minor", amountMinor);
            projection.Parameters.AddWithValue("currency_code", currencyCode);
            projection.Parameters.AddWithValue("correlation_id", DbValueParsers.ParseOptionalUuid(input.correlation_id));
            projection.Parameters.AddWithValue("as_of_utc", asOfUtc);
            projection.Parameters.AddWithValue("projection_version", ProjectionMeta.Version);
            projection.Parameters.AddWithValue("evidence_payload", JsonSerializer.Serialize(new EvidencePack(
                api_version: "v1",
                schema_version: "phase1-evidence-pack-v1",
                instruction_id: input.instruction_id,
                tenant_id: input.tenant_id ?? string.Empty,
                attestation_id: attestationId,
                outbox_id: outboxId,
                payload_hash: input.payload_hash,
                signature_hash: input.signature_hash,
                correlation_id: input.correlation_id,
                upstream_ref: input.upstream_ref,
                downstream_ref: input.downstream_ref,
                nfs_sequence_ref: input.nfs_sequence_ref,
                written_at_utc: asOfUtc.ToString("O"),
                timeline: new object[]
                {
                    new { event_name = "ATTESTED", at_utc = asOfUtc.ToString("O"), actor = "ingress_api" },
                    new { event_name = "OUTBOX_ENQUEUED", at_utc = asOfUtc.ToString("O"), actor = "ingress_api" }
                },
                as_of_utc: asOfUtc.ToString("O"),
                projection_version: ProjectionMeta.Version)));
            await projection.ExecuteNonQueryAsync(cancellationToken);
            await tx.CommitAsync(cancellationToken);
            return PersistResult.Ok(attestationId, outboxId);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Npgsql ingress persistence failed.");
            return PersistResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }
}

sealed class FileTenantOnboardingStore(ILogger logger, string? path = null) : ITenantOnboardingStore
{
    private readonly string _path = path
        ?? Environment.GetEnvironmentVariable("TENANT_ONBOARDING_FILE")
        ?? "/tmp/symphony_tenant_onboarding.ndjson";

    public async Task<TenantOnboardingResult> OnboardAsync(TenantOnboardingInput input, CancellationToken cancellationToken)
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(_path) ?? "/tmp");
            if (!File.Exists(_path))
            {
                await File.WriteAllTextAsync(_path, string.Empty, cancellationToken);
            }

            var lines = await File.ReadAllLinesAsync(_path, cancellationToken);
            foreach (var line in lines.Where(l => !string.IsNullOrWhiteSpace(l)))
            {
                using var existing = JsonDocument.Parse(line);
                var root = existing.RootElement;
                var existingTenantId = root.TryGetProperty("tenant_id", out var tenantIdProp) ? tenantIdProp.GetString() : null;
                if (!string.Equals(existingTenantId, input.TenantId.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                var createdAtRaw = root.TryGetProperty("created_at", out var createdAtProp)
                    ? createdAtProp.GetString()
                    : null;
                if (!DateTimeOffset.TryParse(createdAtRaw, out var createdAt))
                {
                    createdAt = DateTimeOffset.UtcNow;
                }

                var outboxId = root.TryGetProperty("outbox_id", out var outboxProp)
                    ? outboxProp.GetString()
                    : null;
                return TenantOnboardingResult.Ok(input.TenantId.ToString(), createdAt, outboxId, createdNew: false);
            }

            var now = DateTimeOffset.UtcNow;
            var outboxIdCreated = Guid.NewGuid().ToString();
            var linePayload = JsonSerializer.Serialize(new
            {
                tenant_id = input.TenantId.ToString(),
                display_name = input.DisplayName,
                jurisdiction_code = input.JurisdictionCode,
                plan = input.Plan,
                idempotency_key = input.IdempotencyKey,
                rls_session_seed = $"app.current_tenant_id={input.TenantId}",
                outbox_id = outboxIdCreated,
                outbox_event = "TENANT_CREATED",
                created_at = now.ToString("O"),
                written_at_utc = now.ToString("O")
            });
            await File.AppendAllTextAsync(_path, linePayload + Environment.NewLine, cancellationToken);

            return TenantOnboardingResult.Ok(input.TenantId.ToString(), now, outboxIdCreated, createdNew: true);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed tenant onboarding file persistence.");
            return TenantOnboardingResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }
}

sealed class NpgsqlTenantOnboardingStore(ILogger logger, NpgsqlDataSource dataSource) : ITenantOnboardingStore
{
    public async Task<TenantOnboardingResult> OnboardAsync(TenantOnboardingInput input, CancellationToken cancellationToken)
    {
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);

            var tenantKey = $"ten-{input.TenantId.ToString("N")[..12]}";
            var billableClientKey = $"tenant-{input.TenantId.ToString("N").ToLowerInvariant()}";

            await using var onboard = conn.CreateCommand();
            onboard.Transaction = tx;
            onboard.CommandText = @"
WITH tenant_scope AS (
  SELECT set_config('app.current_tenant_id', @tenant_id::text, true)
),
billable_upsert AS (
  INSERT INTO public.billable_clients (
    billable_client_id,
    legal_name,
    client_type,
    status,
    client_key
  )
  VALUES (
    public.uuid_v7_or_random(),
    @display_name,
    'ENTERPRISE',
    'ACTIVE',
    @billable_client_key
  )
  ON CONFLICT (client_key)
  DO UPDATE SET legal_name = EXCLUDED.legal_name
  RETURNING billable_client_id
),
existing AS (
  SELECT t.tenant_id, t.created_at
  FROM public.tenants t
  WHERE t.tenant_id = @tenant_id
),
inserted AS (
  INSERT INTO public.tenants(
    tenant_id,
    tenant_key,
    tenant_name,
    tenant_type,
    status,
    billable_client_id
  )
  SELECT
    @tenant_id,
    @tenant_key,
    @display_name,
    'COMMERCIAL',
    'ACTIVE',
    (SELECT billable_client_id FROM billable_upsert LIMIT 1)
  WHERE NOT EXISTS (SELECT 1 FROM existing)
  ON CONFLICT (tenant_id) DO NOTHING
  RETURNING tenant_id, created_at
)
SELECT
  COALESCE((SELECT tenant_id::text FROM inserted LIMIT 1), (SELECT tenant_id::text FROM existing LIMIT 1)),
  COALESCE((SELECT created_at FROM inserted LIMIT 1), (SELECT created_at FROM existing LIMIT 1)),
  EXISTS(SELECT 1 FROM inserted) AS created_new;
";
            onboard.Parameters.AddWithValue("tenant_id", input.TenantId);
            onboard.Parameters.AddWithValue("display_name", input.DisplayName);
            onboard.Parameters.AddWithValue("tenant_key", tenantKey);
            onboard.Parameters.AddWithValue("billable_client_key", billableClientKey);

            string tenantId;
            DateTimeOffset createdAt;
            bool createdNew;
            await using (var reader = await onboard.ExecuteReaderAsync(cancellationToken))
            {
                if (!await reader.ReadAsync(cancellationToken))
                {
                    return TenantOnboardingResult.Fail("db returned no tenant onboarding result");
                }

                tenantId = reader.IsDBNull(0) ? string.Empty : reader.GetString(0);
                if (reader.IsDBNull(1))
                {
                    return TenantOnboardingResult.Fail("db returned missing created_at");
                }

                createdAt = reader.GetFieldValue<DateTimeOffset>(1);
                createdNew = !reader.IsDBNull(2) && reader.GetBoolean(2);
            }

            if (string.IsNullOrWhiteSpace(tenantId))
            {
                return TenantOnboardingResult.Fail("db returned missing tenant_id");
            }

            string? outboxId = null;
            var participantId = "tenant_admin";
            if (createdNew)
            {
                var eventInstructionId = $"tenant-onboarding:{input.TenantId:N}";
                var payloadJson = JsonSerializer.Serialize(new
                {
                    event_type = "TENANT_CREATED",
                    tenant_id = tenantId,
                    display_name = input.DisplayName,
                    jurisdiction_code = input.JurisdictionCode,
                    plan = input.Plan,
                    rls_session_seed = $"app.current_tenant_id={tenantId}"
                });

                await using var enqueue = conn.CreateCommand();
                enqueue.Transaction = tx;
                enqueue.CommandText = @"
SELECT outbox_id::text
FROM public.enqueue_payment_outbox(
  @instruction_id,
  @participant_id,
  @idempotency_key,
  'TENANT_CREATED',
  @payload_json::jsonb
)
LIMIT 1;";
                enqueue.Parameters.AddWithValue("instruction_id", eventInstructionId);
                enqueue.Parameters.AddWithValue("participant_id", participantId);
                enqueue.Parameters.AddWithValue("idempotency_key", input.IdempotencyKey);
                enqueue.Parameters.AddWithValue("payload_json", payloadJson);
                var outboxIdObj = await enqueue.ExecuteScalarAsync(cancellationToken);
                outboxId = outboxIdObj?.ToString();
            }
            else
            {
                await using var lookup = conn.CreateCommand();
                lookup.Transaction = tx;
                lookup.CommandText = @"
SELECT outbox_id::text
FROM public.payment_outbox_pending
WHERE participant_id = @participant_id
  AND idempotency_key = @idempotency_key
ORDER BY created_at DESC
LIMIT 1;";
                lookup.Parameters.AddWithValue("participant_id", participantId);
                lookup.Parameters.AddWithValue("idempotency_key", input.IdempotencyKey);
                var outboxIdObj = await lookup.ExecuteScalarAsync(cancellationToken);
                outboxId = outboxIdObj?.ToString();
            }

            await tx.CommitAsync(cancellationToken);
            return TenantOnboardingResult.Ok(tenantId, createdAt, outboxId, createdNew);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Npgsql tenant onboarding persistence failed.");
            return TenantOnboardingResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }
}

sealed class FileKycHashBridgeStore(ILogger logger, string? path = null) : IKycHashBridgeStore
{
    private readonly string _path = path
        ?? Environment.GetEnvironmentVariable("KYC_HASH_BRIDGE_FILE")
        ?? "/tmp/symphony_kyc_hash_bridge.ndjson";

    public async Task<KycHashPersistResult> PersistAsync(KycHashBridgeRequest request, CancellationToken cancellationToken)
    {
        var configuredProviders = (Environment.GetEnvironmentVariable("KYC_PROVIDER_CODES") ?? "PROV-001")
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        if (!configuredProviders.Contains(request.provider_code.Trim()))
        {
            return KycHashPersistResult.ProviderNotFound();
        }

        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(_path) ?? "/tmp");
            var now = DateTimeOffset.UtcNow;
            var kycRecordId = Guid.NewGuid().ToString();
            var payload = JsonSerializer.Serialize(new
            {
                kyc_record_id = kycRecordId,
                member_id = request.member_id,
                provider_code = request.provider_code,
                outcome = request.outcome,
                verification_method = request.verification_method,
                verification_hash = request.verification_hash,
                hash_algorithm = request.hash_algorithm,
                provider_signature = request.provider_signature,
                provider_reference = request.provider_reference,
                verified_at_provider = request.verified_at_provider,
                anchored_at = now.ToString("O"),
                retention_class = "FIC_AML_CUSTOMER_ID"
            });
            await File.AppendAllTextAsync(_path, payload + Environment.NewLine, cancellationToken);
            return KycHashPersistResult.Ok(kycRecordId, now.ToString("O"), request.outcome, "FIC_AML_CUSTOMER_ID");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed KYC hash bridge file persistence.");
            return KycHashPersistResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }
}

sealed class NpgsqlKycHashBridgeStore(ILogger logger, NpgsqlDataSource dataSource) : IKycHashBridgeStore
{
    public async Task<KycHashPersistResult> PersistAsync(KycHashBridgeRequest request, CancellationToken cancellationToken)
    {
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);

            await using var provider = conn.CreateCommand();
            provider.Transaction = tx;
            provider.CommandText = @"
SELECT id
FROM public.kyc_provider_registry
WHERE provider_code = @provider_code
  AND COALESCE(is_active, TRUE) = TRUE
ORDER BY created_at DESC
LIMIT 1;";
            provider.Parameters.AddWithValue("provider_code", request.provider_code.Trim());
            var providerObj = await provider.ExecuteScalarAsync(cancellationToken);
            if (providerObj is null)
            {
                await tx.RollbackAsync(cancellationToken);
                return KycHashPersistResult.ProviderNotFound();
            }
            var providerId = (Guid)providerObj;

            await using var insert = conn.CreateCommand();
            insert.Transaction = tx;
            insert.CommandText = @"
INSERT INTO public.kyc_verification_records (
  member_id,
  provider_id,
  provider_code,
  outcome,
  verification_method,
  verification_hash,
  hash_algorithm,
  provider_signature,
  provider_reference,
  verified_at_provider,
  jurisdiction_code,
  retention_class
)
VALUES (
  @member_id,
  @provider_id,
  @provider_code,
  @outcome,
  @verification_method,
  @verification_hash,
  @hash_algorithm,
  @provider_signature,
  @provider_reference,
  @verified_at_provider,
  'ZM',
  'FIC_AML_CUSTOMER_ID'
)
RETURNING id::text, anchored_at::text, outcome, retention_class;";
            insert.Parameters.AddWithValue("member_id", Guid.Parse(request.member_id));
            insert.Parameters.AddWithValue("provider_id", providerId);
            insert.Parameters.AddWithValue("provider_code", request.provider_code.Trim());
            insert.Parameters.AddWithValue("outcome", request.outcome.Trim());
            insert.Parameters.AddWithValue("verification_method", request.verification_method.Trim());
            insert.Parameters.AddWithValue("verification_hash", request.verification_hash.Trim());
            insert.Parameters.AddWithValue("hash_algorithm", request.hash_algorithm.Trim());
            insert.Parameters.AddWithValue("provider_signature", request.provider_signature.Trim());
            insert.Parameters.AddWithValue("provider_reference", request.provider_reference.Trim());
            insert.Parameters.AddWithValue("verified_at_provider", DateTimeOffset.Parse(request.verified_at_provider));

            await using var reader = await insert.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
            {
                await tx.RollbackAsync(cancellationToken);
                return KycHashPersistResult.Fail("db returned no inserted KYC row");
            }

            var id = reader.GetString(0);
            var anchoredAt = reader.GetString(1);
            var outcome = reader.GetString(2);
            var retentionClass = reader.GetString(3);

            await tx.CommitAsync(cancellationToken);
            return KycHashPersistResult.Ok(id, anchoredAt, outcome, retentionClass);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Npgsql KYC hash bridge persistence failed.");
            return KycHashPersistResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }
}

sealed class FileRegulatoryIncidentStore(ILogger logger, string? path = null) : IRegulatoryIncidentStore
{
    private readonly string _path = path
        ?? Environment.GetEnvironmentVariable("REGULATORY_INCIDENTS_FILE")
        ?? "/tmp/symphony_regulatory_incidents.ndjson";

    public async Task<RegulatoryIncidentCreateResult> CreateIncidentAsync(RegulatoryIncidentCreateRequest request, CancellationToken cancellationToken)
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(_path) ?? "/tmp");
            var incidentId = Guid.NewGuid().ToString();
            var now = DateTimeOffset.UtcNow.ToString("O");
            var row = JsonSerializer.Serialize(new
            {
                row_type = "incident",
                incident_id = incidentId,
                tenant_id = request.tenant_id,
                incident_type = request.incident_type.Trim(),
                detected_at = request.detected_at,
                description = request.description.Trim(),
                severity = request.severity.Trim().ToUpperInvariant(),
                status = "OPEN",
                reported_to_boz_at = (string?)null,
                boz_reference = (string?)null,
                created_at = now
            });
            var eventRow = JsonSerializer.Serialize(new
            {
                row_type = "event",
                incident_id = incidentId,
                event_type = "INCIDENT_CREATED",
                event_payload = "{\"status\":\"OPEN\"}",
                created_at = now
            });
            await File.AppendAllTextAsync(_path, row + Environment.NewLine, cancellationToken);
            await File.AppendAllTextAsync(_path, eventRow + Environment.NewLine, cancellationToken);
            await ProjectionFiles.UpsertByKeyAsync(
                ProjectionFiles.IncidentCasePath(),
                "incident_id",
                incidentId,
                new RegulatoryIncidentCaseProjection(
                    incident_id: incidentId,
                    tenant_id: request.tenant_id,
                    incident_type: request.incident_type.Trim(),
                    detected_at: request.detected_at,
                    description: request.description.Trim(),
                    severity: request.severity.Trim().ToUpperInvariant(),
                    status: "OPEN",
                    reported_to_boz_at: null,
                    boz_reference: null,
                    created_at: now,
                    timeline: JsonSerializer.SerializeToElement(new[] { new { event_type = "INCIDENT_CREATED", event_payload = "{\"status\":\"OPEN\"}", created_at = now } }),
                    as_of_utc: now,
                    projection_version: ProjectionMeta.Version),
                cancellationToken);
            return RegulatoryIncidentCreateResult.Ok(incidentId, request.tenant_id, "OPEN", now);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Regulatory incident file create failed.");
            return RegulatoryIncidentCreateResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }

    public async Task<RegulatoryIncidentUpdateResult> UpdateStatusAsync(string incidentId, string status, CancellationToken cancellationToken)
    {
        try
        {
            if (!RegulatoryIncidentValidation.IsAllowedStatus(status))
            {
                return RegulatoryIncidentUpdateResult.Fail("invalid status");
            }

            var lines = File.Exists(_path)
                ? await File.ReadAllLinesAsync(_path, cancellationToken)
                : Array.Empty<string>();

            var current = lines
                .Where(l => !string.IsNullOrWhiteSpace(l))
                .Select(l => JsonDocument.Parse(l).RootElement.Clone())
                .Where(e => e.TryGetProperty("row_type", out var rowType) && rowType.GetString() == "incident")
                .Where(e => e.TryGetProperty("incident_id", out var idProp) && string.Equals(idProp.GetString(), incidentId, StringComparison.Ordinal))
                .OrderByDescending(e => e.TryGetProperty("created_at", out var c) ? c.GetString() : string.Empty, StringComparer.Ordinal)
                .FirstOrDefault();

            if (current.ValueKind == JsonValueKind.Undefined)
            {
                return RegulatoryIncidentUpdateResult.Fail("incident not found");
            }

            var now = DateTimeOffset.UtcNow.ToString("O");
            var rewritten = JsonSerializer.Serialize(new
            {
                row_type = "incident",
                incident_id = incidentId,
                tenant_id = current.GetProperty("tenant_id").GetString(),
                incident_type = current.GetProperty("incident_type").GetString(),
                detected_at = current.GetProperty("detected_at").GetString(),
                description = current.GetProperty("description").GetString(),
                severity = current.GetProperty("severity").GetString(),
                status = status.Trim().ToUpperInvariant(),
                reported_to_boz_at = current.TryGetProperty("reported_to_boz_at", out var rtb) ? rtb.GetString() : null,
                boz_reference = current.TryGetProperty("boz_reference", out var brz) ? brz.GetString() : null,
                created_at = current.GetProperty("created_at").GetString()
            });

            var eventRow = JsonSerializer.Serialize(new
            {
                row_type = "event",
                incident_id = incidentId,
                event_type = "STATUS_UPDATED",
                event_payload = JsonSerializer.Serialize(new { status = status.Trim().ToUpperInvariant() }),
                created_at = now
            });

            await File.AppendAllTextAsync(_path, rewritten + Environment.NewLine, cancellationToken);
            await File.AppendAllTextAsync(_path, eventRow + Environment.NewLine, cancellationToken);
            var lookup = await GetIncidentReportDataAsync(incidentId, cancellationToken);
            if (lookup.Found && lookup.Incident is not null)
            {
                await ProjectionFiles.UpsertByKeyAsync(
                    ProjectionFiles.IncidentCasePath(),
                    "incident_id",
                    incidentId,
                    new RegulatoryIncidentCaseProjection(
                        incident_id: incidentId,
                        tenant_id: lookup.Incident.TenantId,
                        incident_type: lookup.Incident.IncidentType,
                        detected_at: lookup.Incident.DetectedAt,
                        description: lookup.Incident.Description,
                        severity: lookup.Incident.Severity,
                        status: lookup.Incident.Status,
                        reported_to_boz_at: lookup.Incident.ReportedToBozAt,
                        boz_reference: lookup.Incident.BozReference,
                        created_at: lookup.Incident.CreatedAt,
                        timeline: JsonSerializer.SerializeToElement(lookup.Timeline.Select(e => new { event_type = e.EventType, event_payload = e.EventPayload, created_at = e.CreatedAt })),
                        as_of_utc: ProjectionMeta.AsOfUtc(),
                        projection_version: ProjectionMeta.Version),
                    cancellationToken);
            }
            return RegulatoryIncidentUpdateResult.Ok();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Regulatory incident file status update failed.");
            return RegulatoryIncidentUpdateResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }

    public async Task<RegulatoryIncidentReportLookup> GetIncidentReportDataAsync(string incidentId, CancellationToken cancellationToken)
    {
        try
        {
            var projectionPath = ProjectionFiles.IncidentCasePath();
            if (!File.Exists(projectionPath))
            {
                return new RegulatoryIncidentReportLookup(false, null, Array.Empty<RegulatoryIncidentEventRecord>(), "incident store not found");
            }

            var lines = await File.ReadAllLinesAsync(projectionPath, cancellationToken);
            foreach (var line in lines.Where(l => !string.IsNullOrWhiteSpace(l)))
            {
                var projection = JsonSerializer.Deserialize<RegulatoryIncidentCaseProjection>(line);
                if (projection is null || !string.Equals(projection.incident_id, incidentId, StringComparison.Ordinal))
                {
                    continue;
                }

                var incident = new RegulatoryIncidentRecord(
                    IncidentId: projection.incident_id,
                    TenantId: projection.tenant_id,
                    IncidentType: projection.incident_type,
                    DetectedAt: projection.detected_at,
                    Description: projection.description,
                    Severity: projection.severity,
                    Status: projection.status,
                    ReportedToBozAt: projection.reported_to_boz_at,
                    BozReference: projection.boz_reference,
                    CreatedAt: projection.created_at);
                var timeline = projection.timeline.ValueKind == JsonValueKind.Array
                    ? projection.timeline.EnumerateArray().Select(item => new RegulatoryIncidentEventRecord(
                        IncidentId: projection.incident_id,
                        EventType: item.GetProperty("event_type").GetString() ?? string.Empty,
                        EventPayload: item.GetProperty("event_payload").GetString() ?? "{}",
                        CreatedAt: item.GetProperty("created_at").GetString() ?? string.Empty)).ToList()
                    : new List<RegulatoryIncidentEventRecord>();
                return new RegulatoryIncidentReportLookup(true, incident, timeline, null);
            }
            return new RegulatoryIncidentReportLookup(false, null, Array.Empty<RegulatoryIncidentEventRecord>(), "incident not found");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Regulatory incident file read failed.");
            return new RegulatoryIncidentReportLookup(false, null, Array.Empty<RegulatoryIncidentEventRecord>(), StoreErrorMessages.ReportLookupUnavailable);
        }
    }
}

sealed class NpgsqlRegulatoryIncidentStore(ILogger logger, NpgsqlDataSource dataSource) : IRegulatoryIncidentStore
{
    public async Task<RegulatoryIncidentCreateResult> CreateIncidentAsync(RegulatoryIncidentCreateRequest request, CancellationToken cancellationToken)
    {
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);
            var now = DateTimeOffset.UtcNow;
            var incidentId = Guid.NewGuid();

            await using var insertIncident = conn.CreateCommand();
            insertIncident.Transaction = tx;
            insertIncident.CommandText = @"
INSERT INTO public.regulatory_incidents (
  incident_id, tenant_id, incident_type, detected_at, description, severity, status, created_at
) VALUES (
  @incident_id, @tenant_id, @incident_type, @detected_at, @description, @severity, 'OPEN', @created_at
);";
            insertIncident.Parameters.AddWithValue("incident_id", incidentId);
            insertIncident.Parameters.AddWithValue("tenant_id", Guid.Parse(request.tenant_id));
            insertIncident.Parameters.AddWithValue("incident_type", request.incident_type.Trim());
            insertIncident.Parameters.AddWithValue("detected_at", DateTimeOffset.Parse(request.detected_at));
            insertIncident.Parameters.AddWithValue("description", request.description.Trim());
            insertIncident.Parameters.AddWithValue("severity", request.severity.Trim().ToUpperInvariant());
            insertIncident.Parameters.AddWithValue("created_at", now);
            await insertIncident.ExecuteNonQueryAsync(cancellationToken);

            await using var insertEvent = conn.CreateCommand();
            insertEvent.Transaction = tx;
            insertEvent.CommandText = @"
INSERT INTO public.incident_events (
  incident_event_id, incident_id, event_type, event_payload, created_at
) VALUES (
  public.uuid_v7_or_random(), @incident_id, 'INCIDENT_CREATED', @event_payload::jsonb, @created_at
);";
            insertEvent.Parameters.AddWithValue("incident_id", incidentId);
            insertEvent.Parameters.AddWithValue("event_payload", JsonSerializer.Serialize(new { status = "OPEN" }));
            insertEvent.Parameters.AddWithValue("created_at", now);
            await insertEvent.ExecuteNonQueryAsync(cancellationToken);
            await using var projection = conn.CreateCommand();
            projection.Transaction = tx;
            projection.CommandText = @"
INSERT INTO public.incident_case_projection (
  incident_id, tenant_id, status, projection_payload, as_of_utc, projection_version
) VALUES (
  @incident_id, @tenant_id, 'OPEN', @projection_payload::jsonb, @as_of_utc, @projection_version
)
ON CONFLICT (incident_id)
DO UPDATE SET
  tenant_id = EXCLUDED.tenant_id,
  status = EXCLUDED.status,
  projection_payload = EXCLUDED.projection_payload,
  as_of_utc = EXCLUDED.as_of_utc,
  projection_version = EXCLUDED.projection_version;";
            projection.Parameters.AddWithValue("incident_id", incidentId);
            projection.Parameters.AddWithValue("tenant_id", Guid.Parse(request.tenant_id));
            projection.Parameters.AddWithValue("as_of_utc", now);
            projection.Parameters.AddWithValue("projection_version", ProjectionMeta.Version);
            projection.Parameters.AddWithValue("projection_payload", JsonSerializer.Serialize(new RegulatoryIncidentCaseProjection(
                incident_id: incidentId.ToString(),
                tenant_id: request.tenant_id,
                incident_type: request.incident_type.Trim(),
                detected_at: request.detected_at,
                description: request.description.Trim(),
                severity: request.severity.Trim().ToUpperInvariant(),
                status: "OPEN",
                reported_to_boz_at: null,
                boz_reference: null,
                created_at: now.ToString("O"),
                timeline: JsonSerializer.SerializeToElement(new[] { new { event_type = "INCIDENT_CREATED", event_payload = "{\"status\":\"OPEN\"}", created_at = now.ToString("O") } }),
                as_of_utc: now.ToString("O"),
                projection_version: ProjectionMeta.Version)));
            await projection.ExecuteNonQueryAsync(cancellationToken);

            await tx.CommitAsync(cancellationToken);
            return RegulatoryIncidentCreateResult.Ok(incidentId.ToString(), request.tenant_id, "OPEN", now.ToString("O"));
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Regulatory incident db create failed.");
            return RegulatoryIncidentCreateResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }

    public async Task<RegulatoryIncidentUpdateResult> UpdateStatusAsync(string incidentId, string status, CancellationToken cancellationToken)
    {
        try
        {
            if (!RegulatoryIncidentValidation.IsAllowedStatus(status))
            {
                return RegulatoryIncidentUpdateResult.Fail("invalid status");
            }

            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);
            var now = DateTimeOffset.UtcNow;

            await using var update = conn.CreateCommand();
            update.Transaction = tx;
            update.CommandText = @"
UPDATE public.regulatory_incidents
SET status = @status
WHERE incident_id = @incident_id;";
            update.Parameters.AddWithValue("status", status.Trim().ToUpperInvariant());
            update.Parameters.AddWithValue("incident_id", Guid.Parse(incidentId));
            var affected = await update.ExecuteNonQueryAsync(cancellationToken);
            if (affected == 0)
            {
                await tx.RollbackAsync(cancellationToken);
                return RegulatoryIncidentUpdateResult.Fail("incident not found");
            }

            await using var insertEvent = conn.CreateCommand();
            insertEvent.Transaction = tx;
            insertEvent.CommandText = @"
INSERT INTO public.incident_events (
  incident_event_id, incident_id, event_type, event_payload, created_at
) VALUES (
  public.uuid_v7_or_random(), @incident_id, 'STATUS_UPDATED', @event_payload::jsonb, @created_at
);";
            insertEvent.Parameters.AddWithValue("incident_id", Guid.Parse(incidentId));
            insertEvent.Parameters.AddWithValue("event_payload", JsonSerializer.Serialize(new { status = status.Trim().ToUpperInvariant() }));
            insertEvent.Parameters.AddWithValue("created_at", now);
            await insertEvent.ExecuteNonQueryAsync(cancellationToken);
            await using var refresh = conn.CreateCommand();
            refresh.Transaction = tx;
            refresh.CommandText = @"
WITH incident_payload AS (
  SELECT jsonb_build_object(
    'incident_id', ri.incident_id::text,
    'tenant_id', ri.tenant_id::text,
    'incident_type', ri.incident_type,
    'detected_at', ri.detected_at::text,
    'description', ri.description,
    'severity', ri.severity,
    'status', ri.status,
    'reported_to_boz_at', CASE WHEN ri.reported_to_boz_at IS NULL THEN NULL ELSE ri.reported_to_boz_at::text END,
    'boz_reference', ri.boz_reference,
    'created_at', ri.created_at::text,
    'timeline', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'event_type', ie.event_type,
        'event_payload', ie.event_payload::text,
        'created_at', ie.created_at::text
      ) ORDER BY ie.created_at)
      FROM public.incident_events ie
      WHERE ie.incident_id = ri.incident_id
    ), '[]'::jsonb),
    'as_of_utc', @as_of_utc::text,
    'projection_version', @projection_version
  ) AS payload, ri.tenant_id, ri.status
  FROM public.regulatory_incidents ri
  WHERE ri.incident_id = @incident_id
)
INSERT INTO public.incident_case_projection (
  incident_id, tenant_id, status, projection_payload, as_of_utc, projection_version
)
SELECT @incident_id, tenant_id, status, payload, @as_of_utc, @projection_version
FROM incident_payload
ON CONFLICT (incident_id)
DO UPDATE SET
  tenant_id = EXCLUDED.tenant_id,
  status = EXCLUDED.status,
  projection_payload = EXCLUDED.projection_payload,
  as_of_utc = EXCLUDED.as_of_utc,
  projection_version = EXCLUDED.projection_version;";
            refresh.Parameters.AddWithValue("incident_id", Guid.Parse(incidentId));
            refresh.Parameters.AddWithValue("as_of_utc", now);
            refresh.Parameters.AddWithValue("projection_version", ProjectionMeta.Version);
            await refresh.ExecuteNonQueryAsync(cancellationToken);

            await tx.CommitAsync(cancellationToken);
            return RegulatoryIncidentUpdateResult.Ok();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Regulatory incident db update failed.");
            return RegulatoryIncidentUpdateResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }

    public async Task<RegulatoryIncidentReportLookup> GetIncidentReportDataAsync(string incidentId, CancellationToken cancellationToken)
    {
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var incidentCmd = conn.CreateCommand();
            incidentCmd.CommandText = @"
SELECT projection_payload::text
FROM public.incident_case_projection
WHERE incident_id = @incident_id;";
            incidentCmd.Parameters.AddWithValue("incident_id", Guid.Parse(incidentId));
            await using (var reader = await incidentCmd.ExecuteReaderAsync(cancellationToken))
            {
                if (await reader.ReadAsync(cancellationToken))
                {
                    var projection = JsonSerializer.Deserialize<RegulatoryIncidentCaseProjection>(reader.GetString(0));
                    if (projection is null)
                    {
                        return new RegulatoryIncidentReportLookup(false, null, Array.Empty<RegulatoryIncidentEventRecord>(), "projection invalid");
                    }
                    var incident = new RegulatoryIncidentRecord(
                        IncidentId: projection.incident_id,
                        TenantId: projection.tenant_id,
                        IncidentType: projection.incident_type,
                        DetectedAt: projection.detected_at,
                        Description: projection.description,
                        Severity: projection.severity,
                        Status: projection.status,
                        ReportedToBozAt: projection.reported_to_boz_at,
                        BozReference: projection.boz_reference,
                        CreatedAt: projection.created_at
                    );
                    var timeline = projection.timeline.ValueKind == JsonValueKind.Array
                        ? projection.timeline.EnumerateArray().Select(item => new RegulatoryIncidentEventRecord(
                            IncidentId: projection.incident_id,
                            EventType: item.GetProperty("event_type").GetString() ?? string.Empty,
                            EventPayload: item.GetProperty("event_payload").GetString() ?? "{}",
                            CreatedAt: item.GetProperty("created_at").GetString() ?? string.Empty
                        )).ToList()
                        : new List<RegulatoryIncidentEventRecord>();
                    return new RegulatoryIncidentReportLookup(true, incident, timeline, null);
                }
            }
            return new RegulatoryIncidentReportLookup(false, null, Array.Empty<RegulatoryIncidentEventRecord>(), "incident not found");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Regulatory incident db read failed.");
            return new RegulatoryIncidentReportLookup(false, null, Array.Empty<RegulatoryIncidentEventRecord>(), StoreErrorMessages.ReportLookupUnavailable);
        }
    }
}

static class ProjectionPayload
{
    public static (long AmountMinor, string CurrencyCode) ParseAmountAndCurrency(string payloadJson)
    {
        try
        {
            using var doc = JsonDocument.Parse(payloadJson);
            var root = doc.RootElement;
            var amountMinor = root.TryGetProperty("amount_minor", out var amountProp) && amountProp.TryGetInt64(out var parsedAmount)
                ? parsedAmount
                : 0;
            var currencyCode = root.TryGetProperty("currency_code", out var currencyProp) && currencyProp.ValueKind == JsonValueKind.String
                ? (currencyProp.GetString() ?? "ZMW")
                : "ZMW";
            return (amountMinor, currencyCode);
        }
        catch
        {
            return (0, "ZMW");
        }
    }
}

// ─── Onboarding Control-Plane Stores (TSK-P1-217) ──────────────────

sealed class NpgsqlTenantRegistryStore(ILogger logger, NpgsqlDataSource dataSource) : ITenantRegistryStore
{
    public async Task<bool> ExistsAsync(Guid tenantId, CancellationToken cancellationToken, bool bypassRls = false)
    {
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.Transaction = tx;

            if (bypassRls)
            {
                cmd.CommandText = "SELECT set_config('app.bypass_rls', 'on', true)";
                await cmd.ExecuteScalarAsync(cancellationToken);
            }

            cmd.CommandText = "SELECT set_config('app.current_tenant_id', @tenant_id::text, true)";
            cmd.Parameters.AddWithValue("tenant_id", tenantId);
            await cmd.ExecuteScalarAsync(cancellationToken);

            cmd.Parameters.Clear();
            cmd.CommandText = @"
SELECT EXISTS(
  SELECT 1 FROM public.tenant_registry
  WHERE tenant_id = @tenant_id AND status = 'ACTIVE'
  LIMIT 1
);";
            cmd.Parameters.AddWithValue("tenant_id", tenantId);
            var result = await cmd.ExecuteScalarAsync(cancellationToken);
            await tx.CommitAsync(cancellationToken);
            return result is true;
        }
        catch (Exception ex)
        {
            if (ex is Npgsql.PostgresException pex && pex.SqlState == "42P01") throw;
            logger.LogError(ex, "Tenant registry existence check failed.");
            return false;
        }
    }

    public async Task<TenantRegistryEntry?> GetAsync(Guid tenantId, CancellationToken cancellationToken, bool bypassRls = false)
    {
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.Transaction = tx;

            if (bypassRls)
            {
                cmd.CommandText = "SELECT set_config('app.bypass_rls', 'on', true)";
                await cmd.ExecuteScalarAsync(cancellationToken);
            }

            cmd.CommandText = "SELECT set_config('app.current_tenant_id', @tenant_id::text, true)";
            cmd.Parameters.AddWithValue("tenant_id", tenantId);
            await cmd.ExecuteScalarAsync(cancellationToken);

            cmd.Parameters.Clear();
            cmd.CommandText = @"
SELECT tenant_id::text, tenant_key, display_name, status, created_at, updated_at
FROM public.tenant_registry
WHERE tenant_id = @tenant_id
LIMIT 1;";
            cmd.Parameters.AddWithValue("tenant_id", tenantId);
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            if (await reader.ReadAsync(cancellationToken))
            {
                var entry = new TenantRegistryEntry(
                    reader.GetString(0), reader.GetString(1), reader.GetString(2),
                    reader.GetString(3), reader.GetFieldValue<DateTimeOffset>(4), reader.GetFieldValue<DateTimeOffset>(5));
                await reader.DisposeAsync();
                await tx.CommitAsync(cancellationToken);
                return entry;
            }
            await tx.CommitAsync(cancellationToken);
            return null;
        }
        catch (Exception ex)
        {
            if (ex is Npgsql.PostgresException pex && pex.SqlState == "42P01") throw;
            logger.LogError(ex, "Tenant registry get failed.");
            return null;
        }
    }

    public async Task<IReadOnlyList<TenantRegistryEntry>> ListAsync(CancellationToken cancellationToken, bool bypassRls = false)
    {
        var results = new List<TenantRegistryEntry>();
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.Transaction = tx;

            if (bypassRls)
            {
                cmd.CommandText = "SELECT set_config('app.bypass_rls', 'on', true)";
                await cmd.ExecuteScalarAsync(cancellationToken);
            }

            cmd.CommandText = @"
SELECT tenant_id::text, tenant_key, display_name, status, created_at, updated_at
FROM public.tenant_registry
ORDER BY created_at ASC
LIMIT 1000;";
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                results.Add(new TenantRegistryEntry(
                    reader.GetString(0), reader.GetString(1), reader.GetString(2),
                    reader.GetString(3), reader.GetFieldValue<DateTimeOffset>(4), reader.GetFieldValue<DateTimeOffset>(5)));
            }
            await reader.DisposeAsync();
            await tx.CommitAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            if (ex is Npgsql.PostgresException pex && pex.SqlState == "42P01") throw;
            logger.LogError(ex, "Tenant registry list failed.");
        }
        return results;
    }

    public async Task<TenantRegistryResult> UpsertAsync(Guid tenantId, string tenantKey, string displayName, CancellationToken cancellationToken, bool bypassRls = false)
    {
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.Transaction = tx;

            if (bypassRls)
            {
                cmd.CommandText = "SELECT set_config('app.bypass_rls', 'on', true)";
                await cmd.ExecuteScalarAsync(cancellationToken);
            }

            // Set RLS context first
            cmd.CommandText = "SELECT set_config('app.current_tenant_id', @tenant_id::text, true)";
            cmd.Parameters.AddWithValue("tenant_id", tenantId);
            await cmd.ExecuteScalarAsync(cancellationToken);

            // Now perform the upsert on tenant_key for seeding robustness
            cmd.Parameters.Clear();
            cmd.CommandText = @"
INSERT INTO public.tenant_registry (tenant_id, tenant_key, display_name, status)
VALUES (@tenant_id, @tenant_key, @display_name, 'ACTIVE')
ON CONFLICT (tenant_id) DO UPDATE SET
  tenant_key = EXCLUDED.tenant_key,
  display_name = EXCLUDED.display_name,
  updated_at = now()
RETURNING tenant_id::text, tenant_key, display_name, status, created_at, updated_at,
  (xmax = 0) AS created_new;";
            cmd.Parameters.AddWithValue("tenant_id", tenantId);
            cmd.Parameters.AddWithValue("tenant_key", tenantKey);
            cmd.Parameters.AddWithValue("display_name", displayName);
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
            {
                await tx.RollbackAsync(cancellationToken);
                return TenantRegistryResult.Fail("db returned no result");
            }
            var entry = new TenantRegistryEntry(
                reader.GetString(0), reader.GetString(1), reader.GetString(2),
                reader.GetString(3), reader.GetFieldValue<DateTimeOffset>(4), reader.GetFieldValue<DateTimeOffset>(5));
            var createdNew = reader.GetBoolean(6);
            await reader.DisposeAsync();
            await tx.CommitAsync(cancellationToken);
            return TenantRegistryResult.Ok(entry, createdNew);
        }
        catch (Exception ex)
        {
            if (ex is Npgsql.PostgresException pex && pex.SqlState == "42P01") throw;
            logger.LogError(ex, "Tenant registry upsert failed.");
            return TenantRegistryResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }
    public async Task<bool> RegisterSupplierAsync(Guid tenantId, string supplierId, string supplierName, string payoutTarget, string? supplierType, CancellationToken cancellationToken, bool bypassRls = false)
    {
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.Transaction = tx;

            if (bypassRls)
            {
                cmd.CommandText = "SELECT set_config('app.bypass_rls', 'on', true)";
                await cmd.ExecuteScalarAsync(cancellationToken);
            }

            cmd.CommandText = "SELECT set_config('app.current_tenant_id', @tenant_id::text, true)";
            cmd.Parameters.AddWithValue("tenant_id", tenantId);
            await cmd.ExecuteScalarAsync(cancellationToken);

            cmd.Parameters.Clear();
            cmd.CommandText = @"
INSERT INTO public.supplier_registry (tenant_id, supplier_id, supplier_name, payout_target, supplier_type, active, updated_at_utc)
VALUES (@tenant_id, @supplier_id, @supplier_name, @payout_target, @supplier_type, true, timezone('UTC', now())::text)
ON CONFLICT (tenant_id, supplier_id) DO UPDATE SET
  supplier_name = EXCLUDED.supplier_name,
  payout_target = EXCLUDED.payout_target,
  supplier_type = EXCLUDED.supplier_type,
  active = true,
  updated_at_utc = timezone('UTC', now())::text;";
            cmd.Parameters.AddWithValue("tenant_id", tenantId);
            cmd.Parameters.AddWithValue("supplier_id", supplierId);
            cmd.Parameters.AddWithValue("supplier_name", supplierName);
            cmd.Parameters.AddWithValue("payout_target", payoutTarget);
            cmd.Parameters.AddWithValue("supplier_type", (object?)supplierType ?? DBNull.Value);
            await cmd.ExecuteNonQueryAsync(cancellationToken);
            await tx.CommitAsync(cancellationToken);
            return true;
        }
        catch (Exception ex)
        {
            if (ex is Npgsql.PostgresException pex && pex.SqlState == "42P01") throw;
            logger.LogError(ex, "Supplier registry upsert failed.");
            return false;
        }
    }
}

sealed class NpgsqlProgrammeStore(ILogger logger, NpgsqlDataSource dataSource) : IProgrammeStore
{
    public async Task<IReadOnlyList<ProgrammeEntry>> ListAsync(Guid? tenantId, CancellationToken cancellationToken, bool bypassRls = false)
    {
        var results = new List<ProgrammeEntry>();
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.Transaction = tx;

            if (bypassRls)
            {
                cmd.CommandText = "SELECT set_config('app.bypass_rls', 'on', true)";
                await cmd.ExecuteScalarAsync(cancellationToken);
            }

            if (tenantId.HasValue)
            {
                cmd.CommandText = "SELECT set_config('app.current_tenant_id', @tenant_id::text, true)";
                cmd.Parameters.AddWithValue("tenant_id", tenantId.Value);
                await cmd.ExecuteScalarAsync(cancellationToken);
                cmd.Parameters.Clear();
            }

            cmd.CommandText = tenantId.HasValue
                ? @"SELECT p.id::text, p.tenant_id::text, p.programme_key, p.display_name, p.status,
                      b.policy_code, p.created_at, p.updated_at
                    FROM public.programme_registry p
                    LEFT JOIN public.programme_policy_binding b ON b.programme_id = p.id AND b.is_active = true
                    WHERE p.tenant_id = @tenant_id
                    ORDER BY p.created_at ASC LIMIT 1000"
                : @"SELECT p.id::text, p.tenant_id::text, p.programme_key, p.display_name, p.status,
                      b.policy_code, p.created_at, p.updated_at
                    FROM public.programme_registry p
                    LEFT JOIN public.programme_policy_binding b ON b.programme_id = p.id AND b.is_active = true
                    ORDER BY p.created_at ASC LIMIT 1000";
            if (tenantId.HasValue)
                cmd.Parameters.AddWithValue("tenant_id", tenantId.Value);
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                results.Add(new ProgrammeEntry(
                    reader.GetString(0), reader.GetString(1), reader.GetString(2),
                    reader.GetString(3), reader.GetString(4),
                    reader.IsDBNull(5) ? null : reader.GetString(5),
                    reader.GetFieldValue<DateTimeOffset>(6), reader.GetFieldValue<DateTimeOffset>(7)));
            }
            if (tx != null)
            {
                await reader.DisposeAsync();
                await tx.CommitAsync(cancellationToken);
            }
        }
        catch (Exception ex)
        {
            if (ex is Npgsql.PostgresException pex && pex.SqlState == "42P01") throw;
            logger.LogError(ex, "Programme list failed.");
        }
        return results;
    }

    public async Task<ProgrammeResult> CreateAsync(Guid tenantId, string programmeKey, string displayName, CancellationToken cancellationToken, bool bypassRls = false)
    {
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.Transaction = tx;

            if (bypassRls)
            {
                cmd.CommandText = "SELECT set_config('app.bypass_rls', 'on', true)";
                await cmd.ExecuteScalarAsync(cancellationToken);
            }

            // Set RLS context first
            cmd.CommandText = "SELECT set_config('app.current_tenant_id', @tenant_id::text, true)";
            cmd.Parameters.AddWithValue("tenant_id", tenantId);
            await cmd.ExecuteScalarAsync(cancellationToken);

            // Now perform the creation
            cmd.Parameters.Clear();
            cmd.CommandText = @"
INSERT INTO public.programme_registry (tenant_id, programme_key, display_name, status)
VALUES (@tenant_id, @programme_key, @display_name, 'CREATED')
ON CONFLICT (tenant_id, programme_key) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  updated_at = now()
RETURNING id::text, tenant_id::text, programme_key, display_name, status, created_at, updated_at,
  (xmax = 0) AS created_new;";
            cmd.Parameters.AddWithValue("tenant_id", tenantId);
            cmd.Parameters.AddWithValue("programme_key", programmeKey);
            cmd.Parameters.AddWithValue("display_name", displayName);
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
            {
                await tx.RollbackAsync(cancellationToken);
                return ProgrammeResult.Fail("db returned no result");
            }
            var entry = new ProgrammeEntry(
                reader.GetString(0), reader.GetString(1), reader.GetString(2),
                reader.GetString(3), reader.GetString(4), null,
                reader.GetFieldValue<DateTimeOffset>(5), reader.GetFieldValue<DateTimeOffset>(6));
            var createdNew = reader.GetBoolean(7);
            await reader.DisposeAsync();
            await tx.CommitAsync(cancellationToken);
            return ProgrammeResult.Ok(entry, createdNew);
        }
        catch (Exception ex)
        {
            if (ex is Npgsql.PostgresException pex && pex.SqlState == "42P01") throw;
            logger.LogError(ex, "Programme create failed.");
            return ProgrammeResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }

    public async Task<ProgrammeResult> ActivateAsync(Guid programmeId, Guid tenantId, CancellationToken cancellationToken, bool bypassRls = false)
        => await UpdateStatusAsync(programmeId, tenantId, "ACTIVE", cancellationToken, bypassRls);

    public async Task<ProgrammeResult> SuspendAsync(Guid programmeId, Guid tenantId, CancellationToken cancellationToken, bool bypassRls = false)
        => await UpdateStatusAsync(programmeId, tenantId, "SUSPENDED", cancellationToken, bypassRls);

    private async Task<ProgrammeResult> UpdateStatusAsync(Guid programmeId, Guid tenantId, string newStatus, CancellationToken cancellationToken, bool bypassRls = false)
    {
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.Transaction = tx;

            if (bypassRls)
            {
                cmd.CommandText = "SELECT set_config('app.bypass_rls', 'on', true)";
                await cmd.ExecuteScalarAsync(cancellationToken);
            }

            // Set RLS context first
            cmd.CommandText = "SELECT set_config('app.current_tenant_id', @tenant_id::text, true)";
            cmd.Parameters.AddWithValue("tenant_id", tenantId);
            await cmd.ExecuteScalarAsync(cancellationToken);

            // Now perform the update
            cmd.Parameters.Clear();
            cmd.CommandText = @"
UPDATE public.programme_registry
SET status = @status, updated_at = now()
WHERE id = @programme_id
RETURNING id::text, tenant_id::text, programme_key, display_name, status, created_at, updated_at;";
            cmd.Parameters.AddWithValue("tenant_id", tenantId);
            cmd.Parameters.AddWithValue("programme_id", programmeId);
            cmd.Parameters.AddWithValue("status", newStatus);
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
            {
                await tx.RollbackAsync(cancellationToken);
                return ProgrammeResult.Fail("programme not found");
            }
            var entry = new ProgrammeEntry(
                reader.GetString(0), reader.GetString(1), reader.GetString(2),
                reader.GetString(3), reader.GetString(4), null,
                reader.GetFieldValue<DateTimeOffset>(5), reader.GetFieldValue<DateTimeOffset>(6));
            await reader.DisposeAsync();
            await tx.CommitAsync(cancellationToken);
            return ProgrammeResult.Ok(entry, false);
        }
        catch (Exception ex)
        {
            if (ex is Npgsql.PostgresException pex && pex.SqlState == "42P01") throw;
            logger.LogError(ex, "Programme status update failed.");
            return ProgrammeResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }

    public async Task<ProgrammeResult> BindPolicyAsync(Guid programmeId, Guid tenantId, string policyCode, CancellationToken cancellationToken, bool bypassRls = false)
    {
        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var tx = await conn.BeginTransactionAsync(cancellationToken);

            if (bypassRls)
            {
                await using var bypassCmd = conn.CreateCommand();
                bypassCmd.Transaction = tx;
                bypassCmd.CommandText = "SELECT set_config('app.bypass_rls', 'on', true)";
                await bypassCmd.ExecuteScalarAsync(cancellationToken);
            }

            // Set RLS context first
            await using var setConfig = conn.CreateCommand();
            setConfig.Transaction = tx;
            setConfig.CommandText = "SELECT set_config('app.current_tenant_id', @tenant_id::text, true)";
            setConfig.Parameters.AddWithValue("tenant_id", tenantId);
            await setConfig.ExecuteScalarAsync(cancellationToken);

            // Deactivate any existing binding
            await using var deactivate = conn.CreateCommand();
            deactivate.Transaction = tx;
            deactivate.CommandText = @"
UPDATE public.programme_policy_binding
SET is_active = false
WHERE programme_id = @programme_id AND is_active = true;";
            deactivate.Parameters.AddWithValue("programme_id", programmeId);
            await deactivate.ExecuteNonQueryAsync(cancellationToken);

            // Insert new active binding
            await using var insert = conn.CreateCommand();
            insert.Transaction = tx;
            insert.CommandText = @"
INSERT INTO public.programme_policy_binding (programme_id, tenant_id, policy_code, version, is_active)
SELECT @programme_id, @tenant_id, @policy_code,
  COALESCE((
      SELECT MAX(version) FROM public.programme_policy_binding WHERE programme_id = @programme_id LIMIT 1
  ), 0) + 1,
  true
RETURNING programme_id::text;";
            insert.Parameters.AddWithValue("programme_id", programmeId);
            insert.Parameters.AddWithValue("tenant_id", tenantId);
            insert.Parameters.AddWithValue("policy_code", policyCode);
            var result = await insert.ExecuteScalarAsync(cancellationToken);
            if (result is null)
            {
                await tx.RollbackAsync(cancellationToken);
                return ProgrammeResult.Fail("policy binding insert failed");
            }

            // Re-read the programme with the new binding
            await using var read = conn.CreateCommand();
            read.Transaction = tx;
            read.CommandText = @"
SELECT p.id::text, p.tenant_id::text, p.programme_key, p.display_name, p.status,
       b.policy_code, p.created_at, p.updated_at
FROM public.programme_registry p
LEFT JOIN public.programme_policy_binding b ON b.programme_id = p.id AND b.is_active = true
WHERE p.id = @programme_id
LIMIT 1;";
            read.Parameters.AddWithValue("programme_id", programmeId);
            await using var reader = await read.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
            {
                await tx.RollbackAsync(cancellationToken);
                return ProgrammeResult.Fail("programme not found after binding");
            }
            var entry = new ProgrammeEntry(
                reader.GetString(0), reader.GetString(1), reader.GetString(2),
                reader.GetString(3), reader.GetString(4),
                reader.IsDBNull(5) ? null : reader.GetString(5),
                reader.GetFieldValue<DateTimeOffset>(6), reader.GetFieldValue<DateTimeOffset>(7));
            await reader.DisposeAsync();
            await tx.CommitAsync(cancellationToken);
            return ProgrammeResult.Ok(entry, false);
        }
        catch (Exception ex)
        {
            if (ex is Npgsql.PostgresException pex)
            {
                if (pex.SqlState == "42P01") throw;
                if (pex.SqlState == "23505") return ProgrammeResult.Fail("policy binding already exists");
            }
            logger.LogError(ex, "Programme policy binding failed.");
            return ProgrammeResult.Fail(StoreErrorMessages.PersistenceUnavailable);
        }
    }
}
