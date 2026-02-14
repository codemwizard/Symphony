using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
var logger = app.Logger;

if (args.Contains("--self-test", StringComparer.OrdinalIgnoreCase))
{
    var code = await IngressSelfTestRunner.RunAsync(logger, CancellationToken.None);
    Environment.ExitCode = code;
    return;
}
if (args.Contains("--self-test-evidence-pack", StringComparer.OrdinalIgnoreCase))
{
    var code = await EvidencePackSelfTestRunner.RunAsync(logger, CancellationToken.None);
    Environment.ExitCode = code;
    return;
}
if (args.Contains("--self-test-case-pack", StringComparer.OrdinalIgnoreCase))
{
    var code = await ExceptionCasePackSelfTestRunner.RunAsync(logger, CancellationToken.None);
    Environment.ExitCode = code;
    return;
}
if (args.Contains("--self-test-authz", StringComparer.OrdinalIgnoreCase))
{
    var code = await PilotAuthSelfTestRunner.RunAsync(CancellationToken.None);
    Environment.ExitCode = code;
    return;
}

var storageMode = (Environment.GetEnvironmentVariable("INGRESS_STORAGE_MODE") ?? "file").Trim().ToLowerInvariant();
IIngressDurabilityStore store = storageMode switch
{
    "db_psql" => new PsqlIngressDurabilityStore(logger),
    _ => new FileIngressDurabilityStore(logger)
};
IEvidencePackStore evidenceStore = storageMode switch
{
    "db_psql" => new PsqlEvidencePackStore(logger),
    _ => new FileEvidencePackStore(logger)
};
IExceptionCasePackStore casePackStore = storageMode switch
{
    "db_psql" => new PsqlExceptionCasePackStore(logger),
    _ => new FileExceptionCasePackStore(logger)
};

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapPost("/v1/ingress/instructions", async (IngressRequest request, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var auth = PilotAuth.AuthorizeIngress(httpContext, request);
    if (!auth.Allowed)
    {
        return Results.Json(new
        {
            ack = false,
            error_code = auth.ErrorCode
        }, statusCode: auth.StatusCode);
    }

    var forceFailure = httpContext.Request.Headers.TryGetValue("x-symphony-force-attestation-fail", out var forceHeader)
        && forceHeader.ToString() == "1";

    var result = await IngressHandler.HandleAsync(request, store, logger, forceFailure, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
});

app.MapGet("/v1/evidence-packs/{instruction_id}", async (string instruction_id, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var tenantId = httpContext.Request.Headers.TryGetValue("x-tenant-id", out var tenantHeader)
        ? tenantHeader.ToString()
        : string.Empty;

    var auth = PilotAuth.AuthorizeRead(httpContext, tenantId);
    if (!auth.Allowed)
    {
        return Results.Json(new
        {
            error_code = auth.ErrorCode
        }, statusCode: auth.StatusCode);
    }

    var result = await EvidencePackHandler.HandleAsync(instruction_id, tenantId, evidenceStore, logger, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
});
app.MapGet("/v1/exceptions/{instruction_id}/case-pack", async (string instruction_id, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var tenantId = httpContext.Request.Headers.TryGetValue("x-tenant-id", out var tenantHeader)
        ? tenantHeader.ToString()
        : string.Empty;

    var auth = PilotAuth.AuthorizeRead(httpContext, tenantId);
    if (!auth.Allowed)
    {
        return Results.Json(new
        {
            error_code = auth.ErrorCode
        }, statusCode: auth.StatusCode);
    }

    var result = await ExceptionCasePackHandler.HandleAsync(instruction_id, tenantId, casePackStore, logger, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
});

await app.RunAsync();

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

record AuthDecision(bool Allowed, int StatusCode, string? ErrorCode)
{
    public static AuthDecision Pass() => new(true, StatusCodes.Status200OK, null);
    public static AuthDecision Deny(int statusCode, string errorCode) => new(false, statusCode, errorCode);
}

record PilotApiPrincipal(string ApiKey, string TenantId, string ParticipantId, string Role);

static class PilotAuth
{
    private const string ApiKeyHeader = "x-symphony-api-key";
    private static readonly string DefaultTenant = "11111111-1111-1111-1111-111111111111";
    private static readonly Dictionary<string, PilotApiPrincipal> DefaultCatalog = new(StringComparer.Ordinal)
    {
        ["pilot-participant-key"] = new PilotApiPrincipal("pilot-participant-key", DefaultTenant, "bank-a", "participant"),
        ["pilot-boz-key"] = new PilotApiPrincipal("pilot-boz-key", "*", "*", "boz_readonly"),
    };

    public static AuthDecision AuthorizeIngress(HttpContext context, IngressRequest request)
    {
        var principal = ResolvePrincipal(context);
        if (principal is null)
        {
            return AuthDecision.Deny(StatusCodes.Status401Unauthorized, "AUTH_REQUIRED");
        }

        if (string.Equals(principal.Role, "boz_readonly", StringComparison.Ordinal))
        {
            return AuthDecision.Deny(StatusCodes.Status403Forbidden, "BOZ_READ_ONLY_ROLE");
        }

        if (!string.Equals(principal.TenantId, request.tenant_id, StringComparison.Ordinal))
        {
            return AuthDecision.Deny(StatusCodes.Status403Forbidden, "TENANT_SCOPE_DENIED");
        }

        if (!string.Equals(principal.ParticipantId, request.participant_id, StringComparison.Ordinal))
        {
            return AuthDecision.Deny(StatusCodes.Status403Forbidden, "PARTICIPANT_SCOPE_DENIED");
        }

        return AuthDecision.Pass();
    }

    public static AuthDecision AuthorizeRead(HttpContext context, string tenantId)
    {
        var principal = ResolvePrincipal(context);
        if (principal is null)
        {
            return AuthDecision.Deny(StatusCodes.Status401Unauthorized, "AUTH_REQUIRED");
        }

        if (string.Equals(principal.Role, "boz_readonly", StringComparison.Ordinal))
        {
            return AuthDecision.Pass();
        }

        if (!string.Equals(principal.TenantId, tenantId, StringComparison.Ordinal))
        {
            return AuthDecision.Deny(StatusCodes.Status403Forbidden, "TENANT_SCOPE_DENIED");
        }

        return AuthDecision.Pass();
    }

    private static PilotApiPrincipal? ResolvePrincipal(HttpContext context)
    {
        if (!context.Request.Headers.TryGetValue(ApiKeyHeader, out var apiKeyHeader))
        {
            return null;
        }

        var apiKey = apiKeyHeader.ToString().Trim();
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            return null;
        }

        var catalog = LoadCatalog();
        return catalog.TryGetValue(apiKey, out var principal) ? principal : null;
    }

    private static Dictionary<string, PilotApiPrincipal> LoadCatalog()
    {
        var configured = Environment.GetEnvironmentVariable("SYMPHONY_PILOT_API_KEYS");
        if (string.IsNullOrWhiteSpace(configured))
        {
            return DefaultCatalog;
        }

        var map = new Dictionary<string, PilotApiPrincipal>(StringComparer.Ordinal);
        var rows = configured.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        foreach (var row in rows)
        {
            var parts = row.Split(':', StringSplitOptions.TrimEntries);
            if (parts.Length != 4)
            {
                continue;
            }

            var key = parts[0];
            if (string.IsNullOrWhiteSpace(key))
            {
                continue;
            }

            map[key] = new PilotApiPrincipal(key, parts[1], parts[2], parts[3]);
        }

        return map.Count == 0 ? DefaultCatalog : map;
    }
}

record HandlerResult(int StatusCode, object Body);

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

        if (forceFailure || IngressValidation.IsForcedFailureEnabled())
        {
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                ack = false,
                error_code = "ATTESTATION_DURABILITY_FAILED"
            });
        }

        var payloadHash = string.IsNullOrWhiteSpace(request.payload_hash)
            ? IngressValidation.Sha256Hex(request.payload.GetRawText())
            : request.payload_hash.Trim();

        var persistInput = new PersistInput(
            instruction_id: request.instruction_id.Trim(),
            participant_id: request.participant_id.Trim(),
            idempotency_key: request.idempotency_key.Trim(),
            rail_type: request.rail_type.Trim(),
            payload_json: request.payload.GetRawText(),
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
}

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
                written_at_utc = DateTime.UtcNow.ToString("O")
            });

            await File.AppendAllTextAsync(_path, line + Environment.NewLine, cancellationToken);
            return PersistResult.Ok(attestationId, outboxId);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to persist ingress attestation to file store.");
            return PersistResult.Fail(ex.Message);
        }
    }
}

sealed class PsqlIngressDurabilityStore(ILogger logger) : IIngressDurabilityStore
{
    private readonly string? _databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");

    public async Task<PersistResult> PersistAsync(PersistInput input, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_databaseUrl))
        {
            return PersistResult.Fail("DATABASE_URL is required for db_psql mode");
        }

        var sql = $@"
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
    {SqlEscaping.Literal(input.instruction_id)},
    {SqlEscaping.Literal(input.tenant_id)},
    {SqlEscaping.Literal(input.payload_hash)},
    {SqlEscaping.Literal(input.signature_hash)},
    {SqlEscaping.Literal(input.correlation_id)}::uuid,
    {SqlEscaping.Literal(input.upstream_ref)},
    {SqlEscaping.Literal(input.downstream_ref)},
    {SqlEscaping.Literal(input.nfs_sequence_ref)}
  )
  RETURNING attestation_id::text
), enqueued AS (
  SELECT outbox_id::text
  FROM public.enqueue_payment_outbox(
    {SqlEscaping.Literal(input.instruction_id)},
    {SqlEscaping.Literal(input.participant_id)},
    {SqlEscaping.Literal(input.idempotency_key)},
    {SqlEscaping.Literal(input.rail_type)},
    {SqlEscaping.Literal(input.payload_json)}::jsonb
  )
)
SELECT (SELECT attestation_id FROM inserted), (SELECT outbox_id FROM enqueued LIMIT 1);
";

        var psi = new ProcessStartInfo
        {
            FileName = "psql",
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false
        };
        psi.ArgumentList.Add(_databaseUrl);
        psi.ArgumentList.Add("-v");
        psi.ArgumentList.Add("ON_ERROR_STOP=1");
        psi.ArgumentList.Add("-X");
        psi.ArgumentList.Add("-t");
        psi.ArgumentList.Add("-A");

        using var process = Process.Start(psi);
        if (process is null)
        {
            return PersistResult.Fail("Unable to start psql process");
        }

        await process.StandardInput.WriteLineAsync(sql);
        await process.StandardInput.FlushAsync(cancellationToken);
        process.StandardInput.Close();

        var stdout = await process.StandardOutput.ReadToEndAsync(cancellationToken);
        var stderr = await process.StandardError.ReadToEndAsync(cancellationToken);
        await process.WaitForExitAsync(cancellationToken);

        if (process.ExitCode != 0)
        {
            logger.LogError("psql persistence failed: {Error}", stderr);
            return PersistResult.Fail($"psql_failed:{stderr.Trim()}");
        }

        var lines = stdout
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToList();
        if (lines.Count == 0)
        {
            return PersistResult.Fail("psql returned no output");
        }

        var parts = lines[^1].Split('|', StringSplitOptions.TrimEntries);
        if (parts.Length < 2 || string.IsNullOrWhiteSpace(parts[0]) || string.IsNullOrWhiteSpace(parts[1]))
        {
            return PersistResult.Fail("psql returned malformed attestation/outbox output");
        }

        return PersistResult.Ok(parts[0], parts[1]);
    }
}

static class SqlEscaping
{
    public static string Literal(string? value)
    {
        if (value is null)
        {
            return "NULL";
        }

        return $"'{value.Replace("'", "''")}'";
    }
}

record EvidencePack(
    string api_version,
    string schema_version,
    string instruction_id,
    string tenant_id,
    string attestation_id,
    string outbox_id,
    string payload_hash,
    string? signature_hash,
    string? correlation_id,
    string? upstream_ref,
    string? downstream_ref,
    string? nfs_sequence_ref,
    string written_at_utc,
    object[] timeline
);

record EvidenceLookupResult(bool Found, EvidencePack? Pack)
{
    public static EvidenceLookupResult Hit(EvidencePack pack) => new(true, pack);
    public static EvidenceLookupResult Miss() => new(false, null);
}

interface IEvidencePackStore
{
    Task<EvidenceLookupResult> FindAsync(string instructionId, string tenantId, CancellationToken cancellationToken);
}

record CasePackAttempt(int attempt_no, string state, string? error_code, string? completed_at_utc);

record ExceptionCasePack(
    string api_version,
    string schema_version,
    string instruction_id,
    string tenant_id,
    string classification,
    string attestation_id,
    string outbox_id,
    string correlation_id,
    string nfs_sequence_ref,
    string payload_hash,
    string? upstream_ref,
    string? downstream_ref,
    string created_at_utc,
    CasePackAttempt[] attempts,
    string recommended_next_action
);

record CasePackMaterial(
    string instruction_id,
    string tenant_id,
    string attestation_id,
    string? outbox_id,
    string payload_hash,
    string? correlation_id,
    string? upstream_ref,
    string? downstream_ref,
    string? nfs_sequence_ref,
    string created_at_utc,
    CasePackAttempt[] attempts
);

record CasePackLookupResult(bool Found, CasePackMaterial? Material)
{
    public static CasePackLookupResult Hit(CasePackMaterial material) => new(true, material);
    public static CasePackLookupResult Miss() => new(false, null);
}

interface IExceptionCasePackStore
{
    Task<CasePackLookupResult> FindMaterialAsync(string instructionId, string tenantId, CancellationToken cancellationToken);
}

static class EvidencePackHandler
{
    public static async Task<HandlerResult> HandleAsync(
        string instructionId,
        string tenantId,
        IEvidencePackStore store,
        ILogger logger,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(instructionId))
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors = new[] { "instruction_id is required" }
            });
        }

        if (string.IsNullOrWhiteSpace(tenantId))
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors = new[] { "x-tenant-id header is required" }
            });
        }

        var lookup = await store.FindAsync(instructionId.Trim(), tenantId.Trim(), cancellationToken);
        if (!lookup.Found || lookup.Pack is null)
        {
            return new HandlerResult(StatusCodes.Status404NotFound, new
            {
                error_code = "EVIDENCE_PACK_NOT_FOUND"
            });
        }

        return new HandlerResult(StatusCodes.Status200OK, lookup.Pack);
    }
}

static class ExceptionCasePackHandler
{
    public static async Task<HandlerResult> HandleAsync(
        string instructionId,
        string tenantId,
        IExceptionCasePackStore store,
        ILogger logger,
        CancellationToken cancellationToken)
    {
        _ = logger;

        if (string.IsNullOrWhiteSpace(instructionId))
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors = new[] { "instruction_id is required" }
            });
        }

        if (string.IsNullOrWhiteSpace(tenantId))
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors = new[] { "x-tenant-id header is required" }
            });
        }

        var lookup = await store.FindMaterialAsync(instructionId.Trim(), tenantId.Trim(), cancellationToken);
        if (!lookup.Found || lookup.Material is null)
        {
            return new HandlerResult(StatusCodes.Status404NotFound, new
            {
                error_code = "CASE_PACK_NOT_FOUND"
            });
        }

        var material = lookup.Material;
        var missing = new List<string>();
        if (string.IsNullOrWhiteSpace(material.outbox_id))
        {
            missing.Add("outbox_id");
        }
        if (string.IsNullOrWhiteSpace(material.correlation_id))
        {
            missing.Add("correlation_id");
        }
        if (string.IsNullOrWhiteSpace(material.nfs_sequence_ref))
        {
            missing.Add("nfs_sequence_ref");
        }
        if (material.attempts.Length == 0)
        {
            missing.Add("attempts");
        }

        if (missing.Count > 0)
        {
            return new HandlerResult(StatusCodes.Status422UnprocessableEntity, new
            {
                error_code = "CASE_PACK_INCOMPLETE",
                missing_references = missing
            });
        }

        var terminalAttempt = material.attempts
            .OrderByDescending(x => x.attempt_no)
            .FirstOrDefault(x => x.state is "FAILED" or "DISPATCHED");
        if (terminalAttempt is null)
        {
            return new HandlerResult(StatusCodes.Status422UnprocessableEntity, new
            {
                error_code = "CASE_PACK_INCOMPLETE",
                missing_references = new[] { "terminal_attempt_state" }
            });
        }

        var classification = terminalAttempt.state == "FAILED" ? "DISPATCH_FAILURE" : "AMBIGUOUS_SETTLEMENT";
        var nextAction = terminalAttempt.state == "FAILED"
            ? "Escalate with rail evidence and retry/correction decision."
            : "Validate settlement confirmation against rail anchor.";

        var pack = new ExceptionCasePack(
            api_version: "v1",
            schema_version: "phase1-exception-case-pack-v1",
            instruction_id: material.instruction_id,
            tenant_id: material.tenant_id,
            classification: classification,
            attestation_id: material.attestation_id,
            outbox_id: material.outbox_id!,
            correlation_id: material.correlation_id!,
            nfs_sequence_ref: material.nfs_sequence_ref!,
            payload_hash: material.payload_hash,
            upstream_ref: material.upstream_ref,
            downstream_ref: material.downstream_ref,
            created_at_utc: material.created_at_utc,
            attempts: material.attempts.OrderBy(x => x.attempt_no).ToArray(),
            recommended_next_action: nextAction
        );

        return new HandlerResult(StatusCodes.Status200OK, pack);
    }
}

sealed class FileExceptionCasePackStore(ILogger logger, string? path = null) : IExceptionCasePackStore
{
    private readonly string _path = path
        ?? Environment.GetEnvironmentVariable("INGRESS_STORAGE_FILE")
        ?? "/tmp/symphony_ingress_attestations.ndjson";

    public async Task<CasePackLookupResult> FindMaterialAsync(string instructionId, string tenantId, CancellationToken cancellationToken)
    {
        if (!File.Exists(_path))
        {
            return CasePackLookupResult.Miss();
        }

        try
        {
            await using var stream = File.OpenRead(_path);
            using var reader = new StreamReader(stream);
            while (await reader.ReadLineAsync(cancellationToken) is { } line)
            {
                if (string.IsNullOrWhiteSpace(line))
                {
                    continue;
                }

                using var doc = JsonDocument.Parse(line);
                var root = doc.RootElement;

                var rowInstructionId = root.TryGetProperty("instruction_id", out var instructionProp)
                    ? instructionProp.GetString()
                    : null;
                if (!string.Equals(rowInstructionId, instructionId, StringComparison.Ordinal))
                {
                    continue;
                }

                var rowTenantId = root.TryGetProperty("tenant_id", out var tenantProp) ? tenantProp.GetString() : null;
                if (!string.Equals(rowTenantId, tenantId, StringComparison.Ordinal))
                {
                    // fail-closed: do not disclose cross-tenant existence
                    return CasePackLookupResult.Miss();
                }

                var attemptCount = root.TryGetProperty("attempt_count", out var attemptsProp) && attemptsProp.TryGetInt32(out var c)
                    ? c
                    : 0;
                var terminalState = root.TryGetProperty("terminal_state", out var terminalProp) ? terminalProp.GetString() : null;
                var terminalError = root.TryGetProperty("terminal_error_code", out var errProp) ? errProp.GetString() : null;
                var createdAt = root.TryGetProperty("written_at_utc", out var writtenProp) ? writtenProp.GetString() : DateTime.UtcNow.ToString("O");

                var attempts = new List<CasePackAttempt>();
                for (var i = 1; i <= attemptCount; i++)
                {
                    var state = i == attemptCount && !string.IsNullOrWhiteSpace(terminalState) ? terminalState : "RETRYABLE";
                    attempts.Add(new CasePackAttempt(
                        attempt_no: i,
                        state: state ?? "RETRYABLE",
                        error_code: i == attemptCount ? terminalError : null,
                        completed_at_utc: createdAt
                    ));
                }

                return CasePackLookupResult.Hit(new CasePackMaterial(
                    instruction_id: instructionId,
                    tenant_id: tenantId,
                    attestation_id: root.TryGetProperty("attestation_id", out var attestationProp) ? attestationProp.GetString() ?? string.Empty : string.Empty,
                    outbox_id: root.TryGetProperty("outbox_id", out var outboxProp) ? outboxProp.GetString() : null,
                    payload_hash: root.TryGetProperty("payload_hash", out var payloadHashProp) ? payloadHashProp.GetString() ?? string.Empty : string.Empty,
                    correlation_id: root.TryGetProperty("correlation_id", out var correlationProp) ? correlationProp.GetString() : null,
                    upstream_ref: root.TryGetProperty("upstream_ref", out var upProp) ? upProp.GetString() : null,
                    downstream_ref: root.TryGetProperty("downstream_ref", out var downProp) ? downProp.GetString() : null,
                    nfs_sequence_ref: root.TryGetProperty("nfs_sequence_ref", out var nfsProp) ? nfsProp.GetString() : null,
                    created_at_utc: createdAt ?? DateTime.UtcNow.ToString("O"),
                    attempts: attempts.ToArray()
                ));
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to read exception case pack from file store.");
            return CasePackLookupResult.Miss();
        }

        return CasePackLookupResult.Miss();
    }
}

sealed class PsqlExceptionCasePackStore(ILogger logger) : IExceptionCasePackStore
{
    private readonly string? _databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");

    public async Task<CasePackLookupResult> FindMaterialAsync(string instructionId, string tenantId, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_databaseUrl))
        {
            return CasePackLookupResult.Miss();
        }

        var sql = $@"
WITH ingress AS (
  SELECT
    ia.attestation_id::text AS attestation_id,
    ia.instruction_id,
    ia.tenant_id::text AS tenant_id,
    ia.payload_hash,
    COALESCE(ia.correlation_id::text, '') AS correlation_id,
    COALESCE(ia.upstream_ref, '') AS upstream_ref,
    COALESCE(ia.downstream_ref, '') AS downstream_ref,
    COALESCE(ia.nfs_sequence_ref, '') AS nfs_sequence_ref,
    to_char(ia.received_at AT TIME ZONE 'UTC', 'YYYY-MM-DD""T""HH24:MI:SS""Z""') AS created_at_utc
  FROM public.ingress_attestations ia
  WHERE ia.instruction_id = {SqlEscaping.Literal(instructionId)}
    AND ia.tenant_id::text = {SqlEscaping.Literal(tenantId)}
  LIMIT 1
), attempts AS (
  SELECT
    a.outbox_id::text AS outbox_id,
    count(*)::int AS attempt_count,
    COALESCE(max(a.nfs_sequence_ref), '') AS nfs_sequence_ref,
    COALESCE(max(a.correlation_id::text), '') AS correlation_id,
    COALESCE(max(a.state::text) FILTER (WHERE a.state IN ('FAILED','DISPATCHED')), '') AS terminal_state,
    COALESCE(max(a.error_code) FILTER (WHERE a.state = 'FAILED'), '') AS terminal_error_code,
    COALESCE(to_char(max(a.completed_at) AT TIME ZONE 'UTC', 'YYYY-MM-DD""T""HH24:MI:SS""Z""'), '') AS completed_at_utc
  FROM public.payment_outbox_attempts a
  WHERE a.instruction_id = {SqlEscaping.Literal(instructionId)}
    AND a.tenant_id::text = {SqlEscaping.Literal(tenantId)}
  GROUP BY a.outbox_id
  ORDER BY count(*) DESC
  LIMIT 1
)
SELECT
  i.attestation_id,
  i.instruction_id,
  i.tenant_id,
  i.payload_hash,
  i.correlation_id,
  i.upstream_ref,
  i.downstream_ref,
  i.nfs_sequence_ref,
  i.created_at_utc,
  COALESCE(at.outbox_id, '') AS outbox_id,
  COALESCE(at.attempt_count, 0)::text AS attempt_count,
  COALESCE(at.terminal_state, '') AS terminal_state,
  COALESCE(at.terminal_error_code, '') AS terminal_error_code,
  COALESCE(at.completed_at_utc, '') AS completed_at_utc,
  COALESCE(NULLIF(at.correlation_id, ''), i.correlation_id) AS corr_effective,
  COALESCE(NULLIF(at.nfs_sequence_ref, ''), i.nfs_sequence_ref) AS nfs_effective
FROM ingress i
LEFT JOIN attempts at ON TRUE;
";

        var psi = new ProcessStartInfo
        {
            FileName = "psql",
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false
        };
        psi.ArgumentList.Add(_databaseUrl);
        psi.ArgumentList.Add("-v");
        psi.ArgumentList.Add("ON_ERROR_STOP=1");
        psi.ArgumentList.Add("-X");
        psi.ArgumentList.Add("-t");
        psi.ArgumentList.Add("-A");

        using var process = Process.Start(psi);
        if (process is null)
        {
            return CasePackLookupResult.Miss();
        }

        await process.StandardInput.WriteLineAsync(sql);
        await process.StandardInput.FlushAsync(cancellationToken);
        process.StandardInput.Close();

        var stdout = await process.StandardOutput.ReadToEndAsync(cancellationToken);
        var stderr = await process.StandardError.ReadToEndAsync(cancellationToken);
        await process.WaitForExitAsync(cancellationToken);

        if (process.ExitCode != 0)
        {
            logger.LogError("psql case pack query failed: {Error}", stderr);
            return CasePackLookupResult.Miss();
        }

        var row = stdout
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .LastOrDefault();
        if (string.IsNullOrWhiteSpace(row))
        {
            return CasePackLookupResult.Miss();
        }

        var parts = row.Split('|');
        if (parts.Length < 16)
        {
            return CasePackLookupResult.Miss();
        }

        var attemptCount = int.TryParse(parts[10], out var count) ? count : 0;
        var attempts = new List<CasePackAttempt>();
        for (var i = 1; i <= attemptCount; i++)
        {
            var state = i == attemptCount && !string.IsNullOrWhiteSpace(parts[11]) ? parts[11] : "RETRYABLE";
            attempts.Add(new CasePackAttempt(i, state, i == attemptCount ? NullIfEmpty(parts[12]) : null, NullIfEmpty(parts[13])));
        }

        return CasePackLookupResult.Hit(new CasePackMaterial(
            instruction_id: parts[1],
            tenant_id: parts[2],
            attestation_id: parts[0],
            outbox_id: NullIfEmpty(parts[9]),
            payload_hash: parts[3],
            correlation_id: NullIfEmpty(parts[14]),
            upstream_ref: NullIfEmpty(parts[5]),
            downstream_ref: NullIfEmpty(parts[6]),
            nfs_sequence_ref: NullIfEmpty(parts[15]),
            created_at_utc: string.IsNullOrWhiteSpace(parts[8]) ? DateTime.UtcNow.ToString("O") : parts[8],
            attempts: attempts.ToArray()
        ));
    }

    private static string? NullIfEmpty(string value) => string.IsNullOrWhiteSpace(value) ? null : value;
}

sealed class FileEvidencePackStore(ILogger logger, string? path = null) : IEvidencePackStore
{
    private readonly string _path = path
        ?? Environment.GetEnvironmentVariable("INGRESS_STORAGE_FILE")
        ?? "/tmp/symphony_ingress_attestations.ndjson";

    public async Task<EvidenceLookupResult> FindAsync(string instructionId, string tenantId, CancellationToken cancellationToken)
    {
        if (!File.Exists(_path))
        {
            return EvidenceLookupResult.Miss();
        }

        try
        {
            await using var stream = File.OpenRead(_path);
            using var reader = new StreamReader(stream);
            while (await reader.ReadLineAsync(cancellationToken) is { } line)
            {
                if (string.IsNullOrWhiteSpace(line))
                {
                    continue;
                }

                using var doc = JsonDocument.Parse(line);
                var root = doc.RootElement;
                var rowInstructionId = root.GetProperty("instruction_id").GetString();
                var rowTenantId = root.TryGetProperty("tenant_id", out var tenantProp) ? tenantProp.GetString() : null;

                if (!string.Equals(rowInstructionId, instructionId, StringComparison.Ordinal))
                {
                    continue;
                }

                if (!string.Equals(rowTenantId, tenantId, StringComparison.Ordinal))
                {
                    // fail-closed for this row: continue scanning in case a later row
                    // has the same instruction_id for the requested tenant.
                    continue;
                }

                var attestationId = root.GetProperty("attestation_id").GetString() ?? string.Empty;
                var outboxId = root.GetProperty("outbox_id").GetString() ?? string.Empty;
                var payloadHash = root.GetProperty("payload_hash").GetString() ?? string.Empty;
                var signatureHash = root.TryGetProperty("signature_hash", out var sigProp) ? sigProp.GetString() : null;
                var correlationId = root.TryGetProperty("correlation_id", out var corrProp) ? corrProp.GetString() : null;
                var upstreamRef = root.TryGetProperty("upstream_ref", out var upProp) ? upProp.GetString() : null;
                var downstreamRef = root.TryGetProperty("downstream_ref", out var downProp) ? downProp.GetString() : null;
                var nfsRef = root.TryGetProperty("nfs_sequence_ref", out var nfsProp) ? nfsProp.GetString() : null;
                var writtenAt = root.TryGetProperty("written_at_utc", out var writtenProp) ? writtenProp.GetString() : DateTime.UtcNow.ToString("O");

                var pack = new EvidencePack(
                    api_version: "v1",
                    schema_version: "phase1-evidence-pack-v1",
                    instruction_id: instructionId,
                    tenant_id: tenantId,
                    attestation_id: attestationId,
                    outbox_id: outboxId,
                    payload_hash: payloadHash,
                    signature_hash: signatureHash,
                    correlation_id: correlationId,
                    upstream_ref: upstreamRef,
                    downstream_ref: downstreamRef,
                    nfs_sequence_ref: nfsRef,
                    written_at_utc: writtenAt ?? DateTime.UtcNow.ToString("O"),
                    timeline: new object[]
                    {
                        new { event_name = "ATTESTED", at_utc = writtenAt, actor = "ingress_api" },
                        new { event_name = "OUTBOX_ENQUEUED", at_utc = writtenAt, actor = "ingress_api" }
                    }
                );

                return EvidenceLookupResult.Hit(pack);
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to read evidence pack from file store.");
            return EvidenceLookupResult.Miss();
        }

        return EvidenceLookupResult.Miss();
    }
}

sealed class PsqlEvidencePackStore(ILogger logger) : IEvidencePackStore
{
    private readonly string? _databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");

    public async Task<EvidenceLookupResult> FindAsync(string instructionId, string tenantId, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_databaseUrl))
        {
            return EvidenceLookupResult.Miss();
        }

        var sql = $@"
SELECT
  ia.attestation_id::text,
  ia.payload_hash,
  COALESCE(ia.signature_hash, ''),
  COALESCE(ia.correlation_id::text, ''),
  COALESCE(ia.upstream_ref, ''),
  COALESCE(ia.downstream_ref, ''),
  COALESCE(ia.nfs_sequence_ref, ''),
  to_char(ia.received_at AT TIME ZONE 'UTC', 'YYYY-MM-DD""T""HH24:MI:SS""Z""'),
  (
    SELECT pop.outbox_id::text
    FROM public.payment_outbox_pending pop
    WHERE pop.instruction_id = ia.instruction_id
    LIMIT 1
  ) AS outbox_id
FROM public.ingress_attestations ia
WHERE ia.instruction_id = {SqlEscaping.Literal(instructionId)}
  AND ia.tenant_id::text = {SqlEscaping.Literal(tenantId)}
LIMIT 1;
";

        var psi = new ProcessStartInfo
        {
            FileName = "psql",
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false
        };
        psi.ArgumentList.Add(_databaseUrl);
        psi.ArgumentList.Add("-v");
        psi.ArgumentList.Add("ON_ERROR_STOP=1");
        psi.ArgumentList.Add("-X");
        psi.ArgumentList.Add("-t");
        psi.ArgumentList.Add("-A");

        using var process = Process.Start(psi);
        if (process is null)
        {
            return EvidenceLookupResult.Miss();
        }

        await process.StandardInput.WriteLineAsync(sql);
        await process.StandardInput.FlushAsync(cancellationToken);
        process.StandardInput.Close();

        var stdout = await process.StandardOutput.ReadToEndAsync(cancellationToken);
        var stderr = await process.StandardError.ReadToEndAsync(cancellationToken);
        await process.WaitForExitAsync(cancellationToken);

        if (process.ExitCode != 0)
        {
            logger.LogError("psql evidence pack query failed: {Error}", stderr);
            return EvidenceLookupResult.Miss();
        }

        var row = stdout
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .LastOrDefault();
        if (string.IsNullOrWhiteSpace(row))
        {
            return EvidenceLookupResult.Miss();
        }

        var parts = row.Split('|');
        if (parts.Length < 9)
        {
            return EvidenceLookupResult.Miss();
        }

        var writtenAt = string.IsNullOrWhiteSpace(parts[7]) ? DateTime.UtcNow.ToString("O") : parts[7];
        var outboxId = string.IsNullOrWhiteSpace(parts[8]) ? "UNKNOWN" : parts[8];
        var pack = new EvidencePack(
            api_version: "v1",
            schema_version: "phase1-evidence-pack-v1",
            instruction_id: instructionId,
            tenant_id: tenantId,
            attestation_id: parts[0],
            outbox_id: outboxId,
            payload_hash: parts[1],
            signature_hash: string.IsNullOrWhiteSpace(parts[2]) ? null : parts[2],
            correlation_id: string.IsNullOrWhiteSpace(parts[3]) ? null : parts[3],
            upstream_ref: string.IsNullOrWhiteSpace(parts[4]) ? null : parts[4],
            downstream_ref: string.IsNullOrWhiteSpace(parts[5]) ? null : parts[5],
            nfs_sequence_ref: string.IsNullOrWhiteSpace(parts[6]) ? null : parts[6],
            written_at_utc: writtenAt,
            timeline: new object[]
            {
                new { event_name = "ATTESTED", at_utc = writtenAt, actor = "ingress_api" },
                new { event_name = "OUTBOX_ENQUEUED", at_utc = writtenAt, actor = "ingress_api" }
            }
        );

        return EvidenceLookupResult.Hit(pack);
    }
}

record SelfTestCase(string Name, string Status, string Detail);

static class IngressSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var storageFile = $"/tmp/symphony_ingress_selftest_{Guid.NewGuid():N}.ndjson";
        var store = new FileIngressDurabilityStore(logger, storageFile);

        var pass = 0;
        var fail = 0;
        var results = new List<SelfTestCase>();

        await RunCase(
            "ack_after_durable_attestation",
            CreateRequest("ins-p1-001"),
            forceFailure: false,
            expectedStatus: StatusCodes.Status202Accepted,
            expectedAck: true,
            expectedErrorCode: null,
            expectedLinesDelta: 1
        );

        await RunCase(
            "invalid_payload_fail_closed",
            CreateRequest(""),
            forceFailure: false,
            expectedStatus: StatusCodes.Status400BadRequest,
            expectedAck: false,
            expectedErrorCode: "INVALID_REQUEST",
            expectedLinesDelta: 0
        );

        await RunCase(
            "missing_tenant_fail_closed",
            CreateRequest("ins-p1-002", tenantIdOverride: ""),
            forceFailure: false,
            expectedStatus: StatusCodes.Status400BadRequest,
            expectedAck: false,
            expectedErrorCode: "INVALID_REQUEST",
            expectedLinesDelta: 0
        );

        await RunCase(
            "forced_durability_failure_fail_closed",
            CreateRequest("ins-p1-003"),
            forceFailure: true,
            expectedStatus: StatusCodes.Status503ServiceUnavailable,
            expectedAck: false,
            expectedErrorCode: "ATTESTATION_DURABILITY_FAILED",
            expectedLinesDelta: 0
        );

        var status = fail == 0 ? "PASS" : "FAIL";
        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);

        var evidenceMeta = EvidenceMeta.Load(rootDir);
        var contractPath = Path.Combine(evidenceDir, "ingress_api_contract_tests.json");
        var ackPath = Path.Combine(evidenceDir, "ingress_ack_attestation_semantics.json");

        await File.WriteAllTextAsync(contractPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-INGRESS-API-CONTRACT-TESTS",
            timestamp_utc = evidenceMeta.TimestampUtc,
            git_sha = evidenceMeta.GitSha,
            schema_fingerprint = evidenceMeta.SchemaFingerprint,
            status,
            tests_passed = pass,
            tests_failed = fail,
            results
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        await File.WriteAllTextAsync(ackPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-INGRESS-ACK-ATTESTATION",
            timestamp_utc = evidenceMeta.TimestampUtc,
            git_sha = evidenceMeta.GitSha,
            schema_fingerprint = evidenceMeta.SchemaFingerprint,
            status,
            ack_after_durable_write = fail == 0,
            negative_cases_fail_closed = fail == 0,
            storage_mode = "file"
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Ingress self-test status: {status}");
        Console.WriteLine($"Evidence: {contractPath}");
        Console.WriteLine($"Evidence: {ackPath}");

        return fail == 0 ? 0 : 1;

        static IngressRequest CreateRequest(string instructionId, string? tenantIdOverride = null)
        {
            var payload = JsonSerializer.Deserialize<JsonElement>("{\"amount\":100,\"currency\":\"ZMW\"}");
            var tenantId = tenantIdOverride ?? Guid.NewGuid().ToString();
            return new IngressRequest(
                instruction_id: instructionId,
                participant_id: "bank-a",
                idempotency_key: Guid.NewGuid().ToString("N"),
                rail_type: "RTGS",
                payload: payload,
                payload_hash: null,
                signature_hash: null,
                tenant_id: tenantId,
                correlation_id: null,
                upstream_ref: null,
                downstream_ref: null,
                nfs_sequence_ref: null
            );
        }

        async Task RunCase(string name, IngressRequest request, bool forceFailure, int expectedStatus, bool expectedAck, string? expectedErrorCode, int expectedLinesDelta)
        {
            var beforeCount = await CountLines(storageFile, cancellationToken);
            var result = await IngressHandler.HandleAsync(request, store, logger, forceFailure, cancellationToken);
            var afterCount = await CountLines(storageFile, cancellationToken);
            var delta = afterCount - beforeCount;

            var bodyDoc = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
            var body = bodyDoc.RootElement;
            var actualAck = body.TryGetProperty("ack", out var ackProp) && ackProp.GetBoolean();
            string? actualErrorCode = body.TryGetProperty("error_code", out var errProp) ? errProp.GetString() : null;

            var ok = result.StatusCode == expectedStatus
                     && actualAck == expectedAck
                     && actualErrorCode == expectedErrorCode
                     && delta == expectedLinesDelta;

            if (ok)
            {
                pass++;
                results.Add(new SelfTestCase(name, "PASS", "deterministic expectation met"));
            }
            else
            {
                fail++;
                results.Add(new SelfTestCase(
                    name,
                    "FAIL",
                    $"expected status={expectedStatus} ack={expectedAck} error={expectedErrorCode} delta={expectedLinesDelta}; got status={result.StatusCode} ack={actualAck} error={actualErrorCode} delta={delta}"
                ));
            }
        }
    }

    private static async Task<int> CountLines(string path, CancellationToken cancellationToken)
    {
        if (!File.Exists(path))
        {
            return 0;
        }

        var count = 0;
        await using var stream = File.OpenRead(path);
        using var reader = new StreamReader(stream);
        while (await reader.ReadLineAsync(cancellationToken) is not null)
        {
            count++;
        }

        return count;
    }
}

static class EvidencePackSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var evidenceDir = Path.Combine(EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory()), "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);

        var storageFile = $"/tmp/symphony_evidence_pack_selftest_{Guid.NewGuid():N}.ndjson";
        var ingressStore = new FileIngressDurabilityStore(logger, storageFile);
        var evidenceStore = new FileEvidencePackStore(logger, storageFile);

        var tenantA = Guid.NewGuid().ToString();
        var tenantB = Guid.NewGuid().ToString();
        var tenantC = Guid.NewGuid().ToString();
        var instructionId = "evp-ins-001";

        // Write a mismatched-tenant row first to verify lookup continues scanning.
        await File.WriteAllTextAsync(storageFile, JsonSerializer.Serialize(new
        {
            attestation_id = Guid.NewGuid().ToString(),
            outbox_id = Guid.NewGuid().ToString(),
            instruction_id = instructionId,
            participant_id = "bank-z",
            idempotency_key = Guid.NewGuid().ToString("N"),
            rail_type = "RTGS",
            payload_hash = IngressValidation.Sha256Hex("{\"amount\":999}"),
            tenant_id = tenantB,
            written_at_utc = DateTime.UtcNow.ToString("O")
        }) + Environment.NewLine, cancellationToken);

        await ingressStore.PersistAsync(new PersistInput(
            instruction_id: instructionId,
            participant_id: "bank-a",
            idempotency_key: Guid.NewGuid().ToString("N"),
            rail_type: "RTGS",
            payload_json: "{\"amount\":100}",
            payload_hash: IngressValidation.Sha256Hex("{\"amount\":100}"),
            signature_hash: null,
            tenant_id: tenantA,
            correlation_id: null,
            upstream_ref: null,
            downstream_ref: null,
            nfs_sequence_ref: null
        ), cancellationToken);

        var tests = new List<SelfTestCase>();
        var pass = 0;
        var fail = 0;

        await RunCase("contract_success_same_tenant", instructionId, tenantA, StatusCodes.Status200OK, "phase1-evidence-pack-v1");
        await RunCase("continues_scan_after_tenant_mismatch", instructionId, tenantA, StatusCodes.Status200OK, "phase1-evidence-pack-v1");
        await RunCase("cross_tenant_fail_closed", instructionId, tenantC, StatusCodes.Status404NotFound, null);
        await RunCase("missing_tenant_header_fail_closed", instructionId, "", StatusCodes.Status400BadRequest, null);
        await RunCase("missing_instruction_fail_closed", "missing-ins", tenantA, StatusCodes.Status404NotFound, null);

        var status = fail == 0 ? "PASS" : "FAIL";
        var meta = EvidenceMeta.Load(EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory()));
        var contractPath = Path.Combine(evidenceDir, "evidence_pack_api_contract.json");
        var accessPath = Path.Combine(evidenceDir, "evidence_pack_api_access_control.json");

        await File.WriteAllTextAsync(contractPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-EVIDENCE-PACK-API-CONTRACT",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status,
            api_version = "v1",
            schema_version = "phase1-evidence-pack-v1",
            tests_passed = pass,
            tests_failed = fail,
            results = tests
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        var accessOk = tests.Any(t => t.Name == "cross_tenant_fail_closed" && t.Status == "PASS")
                       && tests.Any(t => t.Name == "missing_tenant_header_fail_closed" && t.Status == "PASS");
        await File.WriteAllTextAsync(accessPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-EVIDENCE-PACK-ACCESS-CONTROL",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status = accessOk ? "PASS" : "FAIL",
            cross_tenant_fail_closed = accessOk
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Evidence pack self-test status: {status}");
        Console.WriteLine($"Evidence: {contractPath}");
        Console.WriteLine($"Evidence: {accessPath}");
        return fail == 0 ? 0 : 1;

        async Task RunCase(string name, string localInstructionId, string localTenantId, int expectedStatus, string? expectedSchemaVersion)
        {
            var result = await EvidencePackHandler.HandleAsync(localInstructionId, localTenantId, evidenceStore, logger, cancellationToken);
            var bodyJson = JsonSerializer.Serialize(result.Body);
            using var doc = JsonDocument.Parse(bodyJson);

            var ok = result.StatusCode == expectedStatus;
            if (ok && expectedSchemaVersion is not null)
            {
                ok = doc.RootElement.TryGetProperty("schema_version", out var schemaProp)
                     && schemaProp.GetString() == expectedSchemaVersion;
            }

            if (ok)
            {
                pass++;
                tests.Add(new SelfTestCase(name, "PASS", "deterministic expectation met"));
            }
            else
            {
                fail++;
                tests.Add(new SelfTestCase(name, "FAIL", $"expected status={expectedStatus} got={result.StatusCode}"));
            }
        }
    }
}

static class ExceptionCasePackSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var evidenceDir = Path.Combine(EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory()), "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);

        var storageFile = $"/tmp/symphony_case_pack_selftest_{Guid.NewGuid():N}.ndjson";
        var tenantA = Guid.NewGuid().ToString();
        var tenantB = Guid.NewGuid().ToString();

        await File.WriteAllTextAsync(storageFile, string.Join(Environment.NewLine, new[]
        {
            JsonSerializer.Serialize(new
            {
                attestation_id = Guid.NewGuid().ToString(),
                outbox_id = Guid.NewGuid().ToString(),
                instruction_id = "case-ins-complete",
                payload_hash = IngressValidation.Sha256Hex("{\"amount\":100}"),
                tenant_id = tenantA,
                correlation_id = Guid.NewGuid().ToString(),
                upstream_ref = "UP-REF-1",
                downstream_ref = "DOWN-REF-1",
                nfs_sequence_ref = "NFS-SEQ-1",
                attempt_count = 2,
                terminal_state = "FAILED",
                terminal_error_code = "RAIL_TIMEOUT",
                written_at_utc = DateTime.UtcNow.ToString("O")
            }),
            JsonSerializer.Serialize(new
            {
                attestation_id = Guid.NewGuid().ToString(),
                outbox_id = Guid.NewGuid().ToString(),
                instruction_id = "case-ins-incomplete",
                payload_hash = IngressValidation.Sha256Hex("{\"amount\":200}"),
                tenant_id = tenantA,
                correlation_id = Guid.NewGuid().ToString(),
                upstream_ref = "UP-REF-2",
                downstream_ref = "DOWN-REF-2",
                nfs_sequence_ref = "",
                attempt_count = 1,
                terminal_state = "FAILED",
                terminal_error_code = "MISSING_RAIL_ANCHOR",
                written_at_utc = DateTime.UtcNow.ToString("O")
            })
        }) + Environment.NewLine, cancellationToken);

        var tests = new List<SelfTestCase>();
        var pass = 0;
        var fail = 0;
        var store = new FileExceptionCasePackStore(logger, storageFile);

        await RunCase("case_pack_complete_success", "case-ins-complete", tenantA, StatusCodes.Status200OK, "phase1-exception-case-pack-v1", "DISPATCH_FAILURE");
        await RunCase("case_pack_incomplete_fail_closed", "case-ins-incomplete", tenantA, StatusCodes.Status422UnprocessableEntity, null, null, "CASE_PACK_INCOMPLETE");
        await RunCase("case_pack_cross_tenant_fail_closed", "case-ins-complete", tenantB, StatusCodes.Status404NotFound, null, null, "CASE_PACK_NOT_FOUND");
        await RunCase("case_pack_missing_tenant_header_fail_closed", "case-ins-complete", "", StatusCodes.Status400BadRequest, null, null, "INVALID_REQUEST");
        await RunCase("case_pack_missing_instruction_fail_closed", "case-ins-missing", tenantA, StatusCodes.Status404NotFound, null, null, "CASE_PACK_NOT_FOUND");

        var status = fail == 0 ? "PASS" : "FAIL";
        var meta = EvidenceMeta.Load(EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory()));
        var generationPath = Path.Combine(evidenceDir, "exception_case_pack_generation.json");
        var completenessPath = Path.Combine(evidenceDir, "exception_case_pack_completeness.json");

        await File.WriteAllTextAsync(generationPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-EXCEPTION-CASE-PACK-GENERATION",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status,
            schema_version = "phase1-exception-case-pack-v1",
            tests_passed = pass,
            tests_failed = fail,
            results = tests
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        var completenessOk = tests.Any(t => t.Name == "case_pack_complete_success" && t.Status == "PASS")
                             && tests.Any(t => t.Name == "case_pack_incomplete_fail_closed" && t.Status == "PASS");
        await File.WriteAllTextAsync(completenessPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-EXCEPTION-CASE-PACK-COMPLETENESS",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status = completenessOk ? "PASS" : "FAIL",
            deterministic_completeness_enforced = completenessOk
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Exception case pack self-test status: {status}");
        Console.WriteLine($"Evidence: {generationPath}");
        Console.WriteLine($"Evidence: {completenessPath}");
        return fail == 0 ? 0 : 1;

        async Task RunCase(
            string name,
            string instructionId,
            string tenantId,
            int expectedStatus,
            string? expectedSchemaVersion,
            string? expectedClassification,
            string? expectedErrorCode = null)
        {
            var result = await ExceptionCasePackHandler.HandleAsync(instructionId, tenantId, store, logger, cancellationToken);
            var bodyJson = JsonSerializer.Serialize(result.Body);
            using var doc = JsonDocument.Parse(bodyJson);

            var ok = result.StatusCode == expectedStatus;
            if (ok && expectedSchemaVersion is not null)
            {
                ok = doc.RootElement.TryGetProperty("schema_version", out var schemaProp)
                     && schemaProp.GetString() == expectedSchemaVersion;
            }
            if (ok && expectedClassification is not null)
            {
                ok = doc.RootElement.TryGetProperty("classification", out var classProp)
                     && classProp.GetString() == expectedClassification;
            }
            if (ok && expectedErrorCode is not null)
            {
                ok = doc.RootElement.TryGetProperty("error_code", out var errorProp)
                     && errorProp.GetString() == expectedErrorCode;
            }

            if (ok)
            {
                pass++;
                tests.Add(new SelfTestCase(name, "PASS", "deterministic expectation met"));
            }
            else
            {
                fail++;
                tests.Add(new SelfTestCase(name, "FAIL", $"expected status={expectedStatus} got={result.StatusCode}"));
            }
        }
    }
}

static class PilotAuthSelfTestRunner
{
    public static async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var tests = new List<SelfTestCase>();
        var pass = 0;
        var fail = 0;
        var tenant = "11111111-1111-1111-1111-111111111111";

        await RunCase("participant_ingress_allowed", () =>
        {
            var ctx = NewContext("pilot-participant-key");
            var request = BuildRequest(tenant, "bank-a");
            var auth = PilotAuth.AuthorizeIngress(ctx, request);
            return auth.Allowed;
        });

        await RunCase("participant_cross_tenant_denied", () =>
        {
            var ctx = NewContext("pilot-participant-key");
            var request = BuildRequest(Guid.NewGuid().ToString(), "bank-a");
            var auth = PilotAuth.AuthorizeIngress(ctx, request);
            return !auth.Allowed && auth.StatusCode == StatusCodes.Status403Forbidden && auth.ErrorCode == "TENANT_SCOPE_DENIED";
        });

        await RunCase("participant_cross_participant_denied", () =>
        {
            var ctx = NewContext("pilot-participant-key");
            var request = BuildRequest(tenant, "bank-b");
            var auth = PilotAuth.AuthorizeIngress(ctx, request);
            return !auth.Allowed && auth.StatusCode == StatusCodes.Status403Forbidden && auth.ErrorCode == "PARTICIPANT_SCOPE_DENIED";
        });

        await RunCase("boz_read_only_denied_for_ingress", () =>
        {
            var ctx = NewContext("pilot-boz-key");
            var request = BuildRequest(tenant, "bank-a");
            var auth = PilotAuth.AuthorizeIngress(ctx, request);
            return !auth.Allowed && auth.StatusCode == StatusCodes.Status403Forbidden && auth.ErrorCode == "BOZ_READ_ONLY_ROLE";
        });

        await RunCase("boz_read_only_allowed_for_read", () =>
        {
            var ctx = NewContext("pilot-boz-key");
            var auth = PilotAuth.AuthorizeRead(ctx, Guid.NewGuid().ToString());
            return auth.Allowed;
        });

        await RunCase("participant_cross_tenant_read_denied", () =>
        {
            var ctx = NewContext("pilot-participant-key");
            var auth = PilotAuth.AuthorizeRead(ctx, Guid.NewGuid().ToString());
            return !auth.Allowed && auth.StatusCode == StatusCodes.Status403Forbidden && auth.ErrorCode == "TENANT_SCOPE_DENIED";
        });

        await RunCase("missing_api_key_denied", () =>
        {
            var ctx = new DefaultHttpContext();
            var request = BuildRequest(tenant, "bank-a");
            var auth = PilotAuth.AuthorizeIngress(ctx, request);
            return !auth.Allowed && auth.StatusCode == StatusCodes.Status401Unauthorized && auth.ErrorCode == "AUTH_REQUIRED";
        });

        var status = fail == 0 ? "PASS" : "FAIL";
        var root = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(root, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var meta = EvidenceMeta.Load(root);

        var tenantPath = Path.Combine(evidenceDir, "authz_tenant_boundary.json");
        var bozPath = Path.Combine(evidenceDir, "boz_access_boundary_runtime.json");

        await File.WriteAllTextAsync(tenantPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-AUTHZ-TENANT-BOUNDARY",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status,
            tests_passed = pass,
            tests_failed = fail,
            results = tests
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        var bozOk = tests.Any(t => t.Name == "boz_read_only_denied_for_ingress" && t.Status == "PASS")
                    && tests.Any(t => t.Name == "boz_read_only_allowed_for_read" && t.Status == "PASS");
        await File.WriteAllTextAsync(bozPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-BOZ-ACCESS-BOUNDARY-RUNTIME",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status = bozOk ? "PASS" : "FAIL",
            boz_read_only_boundary_enforced = bozOk
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Pilot auth self-test status: {status}");
        Console.WriteLine($"Evidence: {tenantPath}");
        Console.WriteLine($"Evidence: {bozPath}");
        return fail == 0 ? 0 : 1;

        static DefaultHttpContext NewContext(string apiKey)
        {
            var ctx = new DefaultHttpContext();
            ctx.Request.Headers["x-symphony-api-key"] = apiKey;
            return ctx;
        }

        static IngressRequest BuildRequest(string tenantId, string participantId)
        {
            var payload = JsonSerializer.Deserialize<JsonElement>("{\"amount\":100}");
            return new IngressRequest(
                instruction_id: "auth-ins-001",
                participant_id: participantId,
                idempotency_key: "auth-idem-001",
                rail_type: "RTGS",
                payload: payload,
                payload_hash: null,
                signature_hash: null,
                tenant_id: tenantId,
                correlation_id: null,
                upstream_ref: null,
                downstream_ref: null,
                nfs_sequence_ref: null
            );
        }

        async Task RunCase(string name, Func<bool> test)
        {
            await Task.Yield();
            try
            {
                if (test())
                {
                    pass++;
                    tests.Add(new SelfTestCase(name, "PASS", "deterministic expectation met"));
                }
                else
                {
                    fail++;
                    tests.Add(new SelfTestCase(name, "FAIL", "expectation not met"));
                }
            }
            catch (Exception ex)
            {
                fail++;
                tests.Add(new SelfTestCase(name, "FAIL", ex.Message));
            }
        }
    }
}

record EvidenceMeta(string TimestampUtc, string GitSha, string SchemaFingerprint)
{
    public static string ResolveRepoRoot(string startDir)
    {
        var dir = new DirectoryInfo(startDir);
        while (dir is not null)
        {
            if (Directory.Exists(Path.Combine(dir.FullName, ".git")))
            {
                return dir.FullName;
            }
            dir = dir.Parent;
        }

        return startDir;
    }

    public static EvidenceMeta Load(string rootDir)
    {
        var ts = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");
        var sha = Run("git", "rev-parse HEAD", rootDir) ?? "UNKNOWN";
        var fp = Run("git", "rev-parse --short HEAD", rootDir) ?? "UNKNOWN";
        return new EvidenceMeta(ts, sha, fp);
    }

    private static string? Run(string fileName, string args, string cwd)
    {
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = fileName,
                Arguments = args,
                WorkingDirectory = cwd,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false
            };
            using var process = Process.Start(psi);
            if (process is null)
            {
                return null;
            }

            var output = process.StandardOutput.ReadToEnd().Trim();
            process.WaitForExit();
            return process.ExitCode == 0 ? output : null;
        }
        catch
        {
            return null;
        }
    }
}
