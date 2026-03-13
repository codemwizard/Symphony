using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using Npgsql;
using Symphony.LedgerApi.Demo;

var builder = WebApplication.CreateBuilder(args);
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.KnownIPNetworks.Clear();
    options.KnownProxies.Clear();
    options.ForwardLimit = 1;

    var rawTrustedProxies = (Environment.GetEnvironmentVariable("SYMPHONY_TRUSTED_PROXIES") ?? string.Empty).Trim();
    var trustedProxies = rawTrustedProxies
        .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
        .Where(value => !string.IsNullOrWhiteSpace(value))
        .ToArray();

    if (trustedProxies.Length == 0)
    {
        options.ForwardedHeaders = ForwardedHeaders.None;
        return;
    }

    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    foreach (var proxy in trustedProxies)
    {
        if (IPAddress.TryParse(proxy, out var address))
        {
            options.KnownProxies.Add(address);
        }
    }
});
builder.Services.AddRateLimiter(options =>
{
    var permitLimit = int.TryParse(Environment.GetEnvironmentVariable("SYMPHONY_RATE_LIMIT_PERMITS"), out var parsedPermit)
        ? parsedPermit
        : 60;
    var windowSeconds = int.TryParse(Environment.GetEnvironmentVariable("SYMPHONY_RATE_LIMIT_WINDOW_SECONDS"), out var parsedWindow)
        ? parsedWindow
        : 60;
    var sensitivePermitLimit = int.TryParse(Environment.GetEnvironmentVariable("SYMPHONY_SENSITIVE_RATE_LIMIT_PERMITS"), out var parsedSensitivePermit)
        ? parsedSensitivePermit
        : 10;
    var sensitiveWindowSeconds = int.TryParse(Environment.GetEnvironmentVariable("SYMPHONY_SENSITIVE_RATE_LIMIT_WINDOW_SECONDS"), out var parsedSensitiveWindow)
        ? parsedSensitiveWindow
        : 60;
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: RequestSecurityGuards.BuildRateLimitPartitionKey(context),
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = Math.Max(1, permitLimit),
                Window = TimeSpan.FromSeconds(Math.Max(1, windowSeconds)),
                QueueLimit = 0
            }));
    options.AddPolicy("sensitive-endpoint", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: $"{RequestSecurityGuards.BuildRateLimitPartitionKey(context)}:sensitive",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = Math.Max(1, sensitivePermitLimit),
                Window = TimeSpan.FromSeconds(Math.Max(1, sensitiveWindowSeconds)),
                QueueLimit = 0
            }));
});
var app = builder.Build();
var logger = app.Logger;
var runtimeProfile = (Environment.GetEnvironmentVariable("SYMPHONY_RUNTIME_PROFILE") ?? "production").Trim().ToLowerInvariant();

var maxBodyBytes = long.TryParse(Environment.GetEnvironmentVariable("SYMPHONY_MAX_BODY_BYTES"), out var parsedMaxBodyBytes)
    ? parsedMaxBodyBytes
    : 1_048_576;
app.UseForwardedHeaders();
app.Use(async (httpContext, next) =>
{
    var maxRequestBodySizeFeature = httpContext.Features.Get<IHttpMaxRequestBodySizeFeature>();
    if (maxRequestBodySizeFeature is { IsReadOnly: false })
    {
        maxRequestBodySizeFeature.MaxRequestBodySize = maxBodyBytes;
    }

    if (await RequestSecurityGuards.IsBodyTooLargeAsync(httpContext.Request, maxBodyBytes, httpContext.RequestAborted))
    {
        httpContext.Response.StatusCode = StatusCodes.Status413PayloadTooLarge;
        await httpContext.Response.WriteAsJsonAsync(new
        {
            error_code = "PAYLOAD_TOO_LARGE",
            errors = new[] { $"request body exceeds {maxBodyBytes} bytes" }
        });
        return;
    }
    await next();
});
app.UseRateLimiter();

if (await DemoSelfTestEntryPoint.TryRunAsync(args, runtimeProfile, logger, CancellationToken.None) is int demoExitCode)
{
    Environment.ExitCode = demoExitCode;
    return;
}

var storageMode = (Environment.GetEnvironmentVariable("INGRESS_STORAGE_MODE") ?? "file").Trim().ToLowerInvariant();
StorageModePolicy.ValidateOrThrow(storageMode);
var dataSource = StorageModePolicy.IsDatabaseMode(storageMode)
    ? DbDataSourceFactory.Create(logger)
    : null;

IIngressDurabilityStore store = storageMode switch
{
    "db" or "db_psql" or "db_npgsql" => new NpgsqlIngressDurabilityStore(logger, dataSource!),
    "file" => new FileIngressDurabilityStore(logger),
    _ => new FileIngressDurabilityStore(logger)
};
IEvidencePackStore evidenceStore = storageMode switch
{
    "db" or "db_psql" or "db_npgsql" => new NpgsqlEvidencePackStore(logger, dataSource!),
    "file" => new FileEvidencePackStore(logger),
    _ => new FileEvidencePackStore(logger)
};
ITenantOnboardingStore tenantOnboardingStore = storageMode switch
{
    "db" or "db_psql" or "db_npgsql" => new NpgsqlTenantOnboardingStore(logger, dataSource!),
    "file" => new FileTenantOnboardingStore(logger),
    _ => new FileTenantOnboardingStore(logger)
};
IKycHashBridgeStore kycHashBridgeStore = storageMode switch
{
    "db" or "db_psql" or "db_npgsql" => new NpgsqlKycHashBridgeStore(logger, dataSource!),
    "file" => new FileKycHashBridgeStore(logger),
    _ => new FileKycHashBridgeStore(logger)
};
IRegulatoryIncidentStore regulatoryIncidentStore = storageMode switch
{
    "db" or "db_psql" or "db_npgsql" => new NpgsqlRegulatoryIncidentStore(logger, dataSource!),
    "file" => new FileRegulatoryIncidentStore(logger),
    _ => new FileRegulatoryIncidentStore(logger)
};

// Startup capability probes
var signingKeyPresent = !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("EVIDENCE_SIGNING_KEY"));
var rawAllowlist = (Environment.GetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS") ?? string.Empty).Trim();
var tenantAllowlistConfigured = !string.IsNullOrWhiteSpace(rawAllowlist);

if (!tenantAllowlistConfigured)
{
    logger.LogWarning("SECURITY ALERT: tenant_allowlist_configured=false. All tenant requests will be rejected with 503.");
}

var repoRoot = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
var supervisoryUiDir = Path.Combine(repoRoot, "src", "supervisory-dashboard");

app.MapGet("/pilot-demo/supervisory", () =>
{
    if (!string.Equals(runtimeProfile, "pilot-demo", StringComparison.OrdinalIgnoreCase))
    {
        return Results.NotFound();
    }

    var templatePath = Path.Combine(supervisoryUiDir, "index.html");
    var fallbackPath = Path.Combine(supervisoryUiDir, "data", "supervisory_hybrid_fallback.json");
    if (!File.Exists(templatePath) || !File.Exists(fallbackPath))
    {
        return Results.NotFound();
    }

    var html = File.ReadAllText(templatePath);
    var fallbackJson = File.ReadAllText(fallbackPath);
    var contextJson = JsonSerializer.Serialize(new
    {
        dataMode = "HYBRID",
        tenantId = Environment.GetEnvironmentVariable("SYMPHONY_UI_TENANT_ID") ?? string.Empty,
        apiKey = Environment.GetEnvironmentVariable("SYMPHONY_UI_API_KEY") ?? string.Empty
    });

    html = html.Replace("__SYMPHONY_UI_CONTEXT__", contextJson)
               .Replace("__SYMPHONY_HYBRID_FALLBACK__", fallbackJson);
    return Results.Content(html, "text/html; charset=utf-8");
});

app.MapGet("/pilot-demo/supervisory-legacy", () =>
{
    if (!string.Equals(runtimeProfile, "pilot-demo", StringComparison.OrdinalIgnoreCase))
    {
        return Results.NotFound();
    }

    var legacyPath = Path.Combine(supervisoryUiDir, "legacy.html");
    if (!File.Exists(legacyPath))
    {
        return Results.NotFound();
    }

    return Results.Content(File.ReadAllText(legacyPath), "text/html; charset=utf-8");
});

app.MapGet("/health", () => Results.Ok(new
{
    status = "ok",
    signing_key_present = signingKeyPresent,
    tenant_allowlist_configured = tenantAllowlistConfigured,
    git_sha = EvidenceMeta.Load(EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory())).GitSha,
    env_profile = Environment.GetEnvironmentVariable("SYMPHONY_ENV") ?? "unknown",
    runtime_profile = runtimeProfile
}));

app.MapPost("/v1/ingress/instructions", async (IngressRequest request, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var authFailure = ApiAuthorization.AuthorizeIngressWrite(httpContext, request);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    if (RequestSecurityGuards.DevOnlyHeadersPresent(httpContext.Request)
        && !RequestSecurityGuards.IsDevOrCi(Environment.GetEnvironmentVariable("SYMPHONY_ENV")))
    {
        return Results.Json(new
        {
            ack = false,
            error_code = "FORBIDDEN_DEV_HEADER",
            errors = new[] { "dev-only headers are not allowed outside development/ci" }
        }, statusCode: StatusCodes.Status403Forbidden);
    }

    var forceFailure = httpContext.Request.Headers.TryGetValue(RequestSecurityGuards.ForceAttestationFailHeader, out var forceHeader)
        && forceHeader.ToString() == "1";

    var result = await IngressHandler.HandleAsync(request, store, logger, forceFailure, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapGet("/v1/evidence-packs/{instruction_id}", async (string instruction_id, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var authFailure = ApiAuthorization.AuthorizeEvidenceRead(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var tenantId = httpContext.Request.Headers.TryGetValue("x-tenant-id", out var tenantHeader)
        ? tenantHeader.ToString()
        : string.Empty;

    var tenantAuthFailure = ApiAuthorization.AuthorizeTenantScope(tenantId);
    if (tenantAuthFailure is not null)
    {
        return Results.Json(tenantAuthFailure.Body, statusCode: tenantAuthFailure.StatusCode);
    }

    var result = await EvidencePackHandler.HandleAsync(instruction_id, tenantId, evidenceStore, logger, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapPost("/v1/admin/tenants", async (TenantOnboardingRequest request, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var authFailure = ApiAuthorization.AuthorizeAdminTenantOnboarding(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var validationErrors = TenantOnboardingValidation.Validate(request);
    if (validationErrors.Count > 0)
    {
        return Results.Json(new
        {
            error_code = "INVALID_REQUEST",
            errors = validationErrors
        }, statusCode: StatusCodes.Status400BadRequest);
    }

    var tenantId = Guid.Parse(request.tenant_id.Trim());
    var idempotencyKey = $"tenant_onboarding:{tenantId.ToString("N").ToLowerInvariant()}";
    var input = new TenantOnboardingInput(
        TenantId: tenantId,
        DisplayName: request.display_name.Trim(),
        JurisdictionCode: request.jurisdiction_code.Trim().ToUpperInvariant(),
        Plan: request.plan.Trim(),
        IdempotencyKey: idempotencyKey
    );

    var onboarding = await tenantOnboardingStore.OnboardAsync(input, cancellationToken);
    if (!onboarding.Success || onboarding.CreatedAt is null || string.IsNullOrWhiteSpace(onboarding.TenantId))
    {
        return Results.Json(new
        {
            error_code = "TENANT_ONBOARDING_FAILED",
            errors = new[] { onboarding.Error ?? "tenant onboarding store failed" }
        }, statusCode: StatusCodes.Status503ServiceUnavailable);
    }

    return Results.Json(new
    {
        tenant_id = onboarding.TenantId,
        created_at = onboarding.CreatedAt.Value.ToString("O")
    }, statusCode: StatusCodes.Status200OK);
}).RequireRateLimiting("sensitive-endpoint");

app.MapPost("/v1/evidence-links/issue", async (EvidenceLinkIssueRequest request, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var authFailure = ApiAuthorization.AuthorizeAdminTenantOnboarding(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var tenantAuthFailure = ApiAuthorization.AuthorizeTenantScope(request.tenant_id);
    if (tenantAuthFailure is not null)
    {
        return Results.Json(tenantAuthFailure.Body, statusCode: tenantAuthFailure.StatusCode);
    }

    var result = await EvidenceLinkIssueHandler.HandleAsync(request, logger, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapPost("/pilot-demo/api/evidence-links/issue", async (EvidenceLinkIssueRequest request, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    if (!string.Equals(runtimeProfile, "pilot-demo", StringComparison.OrdinalIgnoreCase))
    {
        return Results.NotFound();
    }

    var authFailure = ApiAuthorization.AuthorizeEvidenceRead(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var tenantAuthFailure = ApiAuthorization.AuthorizeTenantScope(request.tenant_id);
    if (tenantAuthFailure is not null)
    {
        return Results.Json(tenantAuthFailure.Body, statusCode: tenantAuthFailure.StatusCode);
    }

    var result = await EvidenceLinkIssueHandler.HandleAsync(request, logger, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapPost("/v1/evidence-links/submit", async (EvidenceLinkSubmitRequest request, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var result = await EvidenceLinkSubmitHandler.HandleAsync(request, httpContext, logger, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapPost("/v1/admin/suppliers/upsert", async (SupplierRegistryUpsertRequest request, HttpContext httpContext) =>
{
    var authFailure = ApiAuthorization.AuthorizeAdminTenantOnboarding(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var tenantAuthFailure = ApiAuthorization.AuthorizeTenantScope(request.tenant_id);
    if (tenantAuthFailure is not null)
    {
        return Results.Json(tenantAuthFailure.Body, statusCode: tenantAuthFailure.StatusCode);
    }

    var result = await SupplierRegistryUpsertHandler.HandleAsync(request);
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapPost("/v1/admin/program-supplier-allowlist/upsert", async (ProgramSupplierAllowlistUpsertRequest request, HttpContext httpContext) =>
{
    var authFailure = ApiAuthorization.AuthorizeAdminTenantOnboarding(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var tenantAuthFailure = ApiAuthorization.AuthorizeTenantScope(request.tenant_id);
    if (tenantAuthFailure is not null)
    {
        return Results.Json(tenantAuthFailure.Body, statusCode: tenantAuthFailure.StatusCode);
    }

    var result = await ProgramSupplierAllowlistUpsertHandler.HandleAsync(request);
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapGet("/v1/programs/{programId}/suppliers/{supplierId}/policy", (string programId, string supplierId, HttpContext httpContext) =>
{
    var authFailure = ApiAuthorization.AuthorizeEvidenceRead(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var tenantId = httpContext.Request.Headers.TryGetValue("x-tenant-id", out var tenantHeader)
        ? tenantHeader.ToString().Trim()
        : string.Empty;
    var tenantAuthFailure = ApiAuthorization.AuthorizeTenantScope(tenantId);
    if (tenantAuthFailure is not null)
    {
        return Results.Json(tenantAuthFailure.Body, statusCode: tenantAuthFailure.StatusCode);
    }

    var result = ProgramSupplierPolicyReadHandler.Handle(tenantId, programId.Trim(), supplierId.Trim());
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapPost("/v1/instruction-files/generate", async (SignedInstructionGenerateRequest request, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var authFailure = ApiAuthorization.AuthorizeAdminTenantOnboarding(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var tenantAuthFailure = ApiAuthorization.AuthorizeTenantScope(request.tenant_id);
    if (tenantAuthFailure is not null)
    {
        return Results.Json(tenantAuthFailure.Body, statusCode: tenantAuthFailure.StatusCode);
    }

    var result = await SignedInstructionFileHandler.GenerateAsync(request, logger, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapPost("/pilot-demo/api/instruction-files/generate", async (SignedInstructionGenerateRequest request, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    if (!string.Equals(runtimeProfile, "pilot-demo", StringComparison.OrdinalIgnoreCase))
    {
        return Results.NotFound();
    }

    var authFailure = ApiAuthorization.AuthorizeEvidenceRead(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var tenantAuthFailure = ApiAuthorization.AuthorizeTenantScope(request.tenant_id);
    if (tenantAuthFailure is not null)
    {
        return Results.Json(tenantAuthFailure.Body, statusCode: tenantAuthFailure.StatusCode);
    }

    var result = await SignedInstructionFileHandler.GenerateAsync(request, logger, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapPost("/v1/instruction-files/verify", async (SignedInstructionVerifyRequest request, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var authFailure = ApiAuthorization.AuthorizeEvidenceRead(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var result = await SignedInstructionFileHandler.VerifyAsync(request, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapGet("/v1/supervisory/programmes/{programId}/reveal", (string programId, HttpContext httpContext) =>
{
    var authFailure = ApiAuthorization.AuthorizeEvidenceRead(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var tenantId = httpContext.Request.Headers.TryGetValue("x-tenant-id", out var tenantHeader)
        ? tenantHeader.ToString().Trim()
        : string.Empty;

    var tenantAuthFailure = ApiAuthorization.AuthorizeTenantScope(tenantId);
    if (tenantAuthFailure is not null)
    {
        return Results.Json(tenantAuthFailure.Body, statusCode: tenantAuthFailure.StatusCode);
    }

    var result = SupervisoryRevealReadModelHandler.Handle(tenantId, programId.Trim());
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapPost("/v1/kyc/hash", async (JsonElement requestBody, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var authFailure = ApiAuthorization.AuthorizeEvidenceRead(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    if (KycHashBridgeValidation.TryRejectPiiFields(requestBody, out var piiField))
    {
        return Results.Json(new
        {
            error_code = "PII_FIELD_REJECTED",
            field = piiField
        }, statusCode: StatusCodes.Status400BadRequest);
    }

    var parse = KycHashBridgeValidation.Parse(requestBody);
    if (parse.Request is null)
    {
        return Results.Json(new
        {
            error_code = "INVALID_REQUEST",
            errors = parse.Errors
        }, statusCode: StatusCodes.Status400BadRequest);
    }

    var result = await KycHashBridgeHandler.HandleAsync(parse.Request, kycHashBridgeStore, logger, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
}).RequireRateLimiting("sensitive-endpoint");

app.MapGet("/v1/regulatory/reports/daily", async (string date, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var authFailure = ApiAuthorization.AuthorizeEvidenceRead(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var tenantId = httpContext.Request.Headers.TryGetValue("x-tenant-id", out var tenantHeader)
        ? tenantHeader.ToString()
        : string.Empty;

    var tenantAuthFailure = ApiAuthorization.AuthorizeTenantScope(tenantId);
    if (tenantAuthFailure is not null)
    {
        return Results.Json(tenantAuthFailure.Body, statusCode: tenantAuthFailure.StatusCode);
    }

    var generated = await RegulatoryReportHandler.GenerateDailyReportAsync(date, tenantId, storageMode, dataSource, cancellationToken);
    return generated.ToHttpResult();
}).RequireRateLimiting("sensitive-endpoint");

app.MapPost("/v1/admin/incidents", async (RegulatoryIncidentCreateRequest request, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var authFailure = ApiAuthorization.AuthorizeAdminTenantOnboarding(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var validationErrors = RegulatoryIncidentValidation.ValidateCreateRequest(request);
    if (validationErrors.Count > 0)
    {
        return Results.Json(new
        {
            error_code = "INVALID_REQUEST",
            errors = validationErrors
        }, statusCode: StatusCodes.Status400BadRequest);
    }

    var created = await regulatoryIncidentStore.CreateIncidentAsync(request, cancellationToken);
    if (!created.Success || string.IsNullOrWhiteSpace(created.IncidentId))
    {
        return Results.Json(new
        {
            error_code = "INCIDENT_CREATE_FAILED",
            errors = new[] { created.Error ?? "unknown" }
        }, statusCode: StatusCodes.Status503ServiceUnavailable);
    }

    return Results.Json(new
    {
        incident_id = created.IncidentId,
        tenant_id = created.TenantId,
        status = created.Status,
        created_at = created.CreatedAt
    }, statusCode: StatusCodes.Status200OK);
}).RequireRateLimiting("sensitive-endpoint");

app.MapGet("/v1/regulatory/incidents/{incident_id}/report", async (string incident_id, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var authFailure = ApiAuthorization.AuthorizeEvidenceRead(httpContext);
    if (authFailure is not null)
    {
        return Results.Json(authFailure.Body, statusCode: authFailure.StatusCode);
    }

    var result = await RegulatoryIncidentReportHandler.GenerateIncidentReportAsync(incident_id, regulatoryIncidentStore, cancellationToken);
    return result.ToHttpResult();
}).RequireRateLimiting("sensitive-endpoint");

await app.RunAsync();







static class PerfBatchingMetrics
{
    public const string MeterName = "Symphony.Perf.Batching";

    private static readonly Meter Meter = new(MeterName, "1.0.0");
    public static readonly Counter<long> DriverBatchedOperations =
        Meter.CreateCounter<long>("driver_batched_operations", unit: "operations");
    public static readonly Counter<long> DriverNonBatchedOperations =
        Meter.CreateCounter<long>("driver_non_batched_operations", unit: "operations");
    public static readonly Counter<long> DriverBatchExecutions =
        Meter.CreateCounter<long>("driver_batch_executions", unit: "batches");
}

static class IngressSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var storageFile = $"/tmp/symphony_ingress_selftest_{Guid.NewGuid():N}.ndjson";
        using var projectionScope = SelfTestProjectionScope.Create("ingress");
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
            var tenantId = tenantIdOverride ?? Guid.NewGuid().ToString();
            var canonicalInstructionId = string.IsNullOrWhiteSpace(instructionId)
                ? instructionId
                : (Guid.TryParse(instructionId, out _) ? instructionId : Guid.NewGuid().ToString());
            var payload = JsonSerializer.Deserialize<JsonElement>(
                $$"""
                {
                  "instruction_id": "{{canonicalInstructionId}}",
                  "tenant_id": "{{tenantId}}",
                  "rail_type": "RTGS",
                  "amount_minor": 100,
                  "currency_code": "ZMW",
                  "beneficiary_ref_hash": "hash-self-test",
                  "idempotency_key": "idem-self-test",
                  "submitted_at_utc": "2026-02-26T00:00:00Z"
                }
                """
            );
            return new IngressRequest(
                instruction_id: canonicalInstructionId,
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

sealed class SelfTestProjectionScope : IDisposable
{
    private readonly Dictionary<string, string?> _previousValues = new(StringComparer.Ordinal);

    private SelfTestProjectionScope()
    {
    }

    public static SelfTestProjectionScope Create(string prefix)
    {
        var scope = new SelfTestProjectionScope();
        var suffix = Guid.NewGuid().ToString("N");
        scope.Set("INSTRUCTION_STATUS_PROJECTION_FILE", $"/tmp/symphony_{prefix}_instruction_status_{suffix}.ndjson");
        scope.Set("EVIDENCE_BUNDLE_PROJECTION_FILE", $"/tmp/symphony_{prefix}_evidence_bundle_{suffix}.ndjson");
        scope.Set("INCIDENT_CASE_PROJECTION_FILE", $"/tmp/symphony_{prefix}_incident_case_{suffix}.ndjson");
        return scope;
    }

    private void Set(string key, string value)
    {
        _previousValues[key] = Environment.GetEnvironmentVariable(key);
        Environment.SetEnvironmentVariable(key, value);
    }

    public void Dispose()
    {
        foreach (var (key, previousValue) in _previousValues)
        {
            Environment.SetEnvironmentVariable(key, previousValue);
        }
    }
}

sealed class SelfTestEnvironmentScope : IDisposable
{
    private readonly Dictionary<string, string?> _previousValues = new(StringComparer.Ordinal);

    public void Set(string key, string value)
    {
        _previousValues[key] = Environment.GetEnvironmentVariable(key);
        Environment.SetEnvironmentVariable(key, value);
    }

    public void Dispose()
    {
        foreach (var (key, previousValue) in _previousValues)
        {
            Environment.SetEnvironmentVariable(key, previousValue);
        }
    }
}

static class SelfTestSecrets
{
    public static string CreateApiKey(string purpose)
        => $"sym-{purpose}-{Convert.ToHexString(RandomNumberGenerator.GetBytes(16)).ToLowerInvariant()}";

    public static string CreateSigningKey()
        => Convert.ToHexString(RandomNumberGenerator.GetBytes(32)).ToLowerInvariant();
}

static class BatchingTelemetrySelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidencePath = Path.Combine(evidenceDir, "perf_driver_batching_telemetry.json");

        const int nonBatchedOps = 32;
        const int batchedBatches = 8;
        const int batchSize = 16;
        var expectedBatchedOps = batchedBatches * batchSize;
        var workloadProfile = $"non_batched={nonBatchedOps};batched_batches={batchedBatches};batch_size={batchSize}";

        var measured = new Dictionary<string, long>(StringComparer.Ordinal);

        using var listener = new MeterListener();
        listener.InstrumentPublished = (instrument, meterListener) =>
        {
            if (instrument.Meter.Name == PerfBatchingMetrics.MeterName)
            {
                meterListener.EnableMeasurementEvents(instrument);
            }
        };
        listener.SetMeasurementEventCallback<long>((instrument, measurement, _, _) =>
        {
            var name = instrument.Name;
            measured[name] = measured.TryGetValue(name, out var current) ? current + measurement : measurement;
        });
        listener.Start();

        string status = "PASS";
        string? error = null;
        long rowsInserted = 0;

        try
        {
            await using var dataSource = DbDataSourceFactory.Create(logger);
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);

            await using (var init = conn.CreateCommand())
            {
                init.CommandText = @"
DROP TABLE IF EXISTS pg_temp.perf_batch_probe;
CREATE TEMP TABLE perf_batch_probe (
  id bigint PRIMARY KEY,
  payload text NOT NULL
);";
                await init.ExecuteNonQueryAsync(cancellationToken);
            }

            for (var i = 0; i < nonBatchedOps; i++)
            {
                await using var cmd = conn.CreateCommand();
                cmd.CommandText = "INSERT INTO pg_temp.perf_batch_probe (id, payload) VALUES (@id, @payload);";
                cmd.Parameters.AddWithValue("id", i + 1L);
                cmd.Parameters.AddWithValue("payload", $"non_batched_{i:D4}");
                await cmd.ExecuteNonQueryAsync(cancellationToken);
                PerfBatchingMetrics.DriverNonBatchedOperations.Add(1);
            }

            var baseId = 100000L;
            for (var batchNo = 0; batchNo < batchedBatches; batchNo++)
            {
                var batch = new NpgsqlBatch(conn);
                for (var j = 0; j < batchSize; j++)
                {
                    var id = baseId + (batchNo * batchSize) + j;
                    var cmd = new NpgsqlBatchCommand("INSERT INTO pg_temp.perf_batch_probe (id, payload) VALUES (@id, @payload);");
                    cmd.Parameters.AddWithValue("id", id);
                    cmd.Parameters.AddWithValue("payload", $"batched_{batchNo:D2}_{j:D2}");
                    batch.BatchCommands.Add(cmd);
                }

                await batch.ExecuteNonQueryAsync(cancellationToken);
                PerfBatchingMetrics.DriverBatchExecutions.Add(1);
                PerfBatchingMetrics.DriverBatchedOperations.Add(batchSize);
            }

            await using (var countCmd = conn.CreateCommand())
            {
                countCmd.CommandText = "SELECT COUNT(*) FROM pg_temp.perf_batch_probe;";
                rowsInserted = (long)(await countCmd.ExecuteScalarAsync(cancellationToken) ?? 0L);
            }
        }
        catch (Exception ex)
        {
            status = "FAIL";
            error = ex.Message;
        }

        listener.RecordObservableInstruments();

        var measuredBatchedOps = measured.TryGetValue("driver_batched_operations", out var batchedCount) ? batchedCount : 0L;
        var measuredNonBatchedOps = measured.TryGetValue("driver_non_batched_operations", out var nonBatchedCount) ? nonBatchedCount : 0L;
        var measuredBatchExecutions = measured.TryGetValue("driver_batch_executions", out var batchExecCount) ? batchExecCount : 0L;

        var deterministic = status == "PASS"
            && measuredBatchedOps == expectedBatchedOps
            && measuredNonBatchedOps == nonBatchedOps
            && measuredBatchExecutions == batchedBatches
            && rowsInserted == nonBatchedOps + expectedBatchedOps;

        if (!deterministic)
        {
            status = "FAIL";
            error ??= "determinism_check_failed";
        }

        var meta = EvidenceMeta.Load(rootDir);
        await File.WriteAllTextAsync(evidencePath, JsonSerializer.Serialize(new
        {
            check_id = "TSK-P1-057",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status,
            details = new
            {
                runtime_version = ".NET 10",
                batching_enabled = true,
                batched_operations = measuredBatchedOps,
                non_batched_operations = measuredNonBatchedOps,
                batch_executions = measuredBatchExecutions,
                workload_profile = workloadProfile,
                telemetry_source = "OpenTelemetry",
                metric_api = "System.Diagnostics.Metrics",
                rows_inserted = rowsInserted,
                deterministic,
                error
            }
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Batching telemetry self-test status: {status}");
        Console.WriteLine($"Evidence: {evidencePath}");
        return status == "PASS" ? 0 : 1;
    }
}

static class TenantContextSelfTestRunner
{
    public static async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var apiKey = SelfTestSecrets.CreateApiKey("tenant-context");
        var validTenant = "11111111-1111-1111-1111-111111111111";
        var unknownTenant = "22222222-2222-2222-2222-222222222222";

        using var env = new SelfTestEnvironmentScope();
        env.Set("INGRESS_API_KEY", apiKey);
        env.Set("SYMPHONY_KNOWN_TENANTS", validTenant);

        var payload = JsonSerializer.Deserialize<JsonElement>("{\"amount\":100,\"currency\":\"ZMW\"}");
        var results = new List<SelfTestCase>();
        var pass = 0;
        var fail = 0;

        RunCase(
            "missing_tenant_context_rejected",
            ContextWithoutTenant(apiKey, "bank-a"),
            Request(validTenant, "bank-a", payload),
            expectedStatus: StatusCodes.Status403Forbidden,
            expectedErrorCode: "FORBIDDEN_TENANT_CONTEXT_REQUIRED"
        );

        RunCase(
            "unknown_tenant_context_rejected",
            ContextWithTenant(apiKey, unknownTenant, "bank-a"),
            Request(unknownTenant, "bank-a", payload),
            expectedStatus: StatusCodes.Status403Forbidden,
            expectedErrorCode: "FORBIDDEN_UNKNOWN_TENANT"
        );

        RunCase(
            "valid_tenant_context_allowed",
            ContextWithTenant(apiKey, validTenant, "bank-a"),
            Request(validTenant, "bank-a", payload),
            expectedStatus: StatusCodes.Status200OK,
            expectedErrorCode: null
        );

        var status = fail == 0 ? "PASS" : "FAIL";
        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = EvidenceMeta.Load(rootDir);
        var path = Path.Combine(evidenceDir, "ten_001_ingress_tenant_context.json");

        await File.WriteAllTextAsync(path, JsonSerializer.Serialize(new
        {
            check_id = "TSK-P1-TEN-001",
            task_id = "TSK-P1-TEN-001",
            timestamp_utc = evidenceMeta.TimestampUtc,
            git_sha = evidenceMeta.GitSha,
            schema_fingerprint = evidenceMeta.SchemaFingerprint,
            status,
            pass = fail == 0,
            details = new
            {
                tenant_context_source = "x-tenant-id header (authoritative)",
                missing_tenant_rejected = results.Any(r => r.Name == "missing_tenant_context_rejected" && r.Status == "PASS"),
                unknown_tenant_rejected = results.Any(r => r.Name == "unknown_tenant_context_rejected" && r.Status == "PASS"),
                valid_tenant_accepted = results.Any(r => r.Name == "valid_tenant_context_allowed" && r.Status == "PASS")
            },
            negative_tests = results.Where(r => r.Name.Contains("rejected", StringComparison.Ordinal)).ToArray(),
            results
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Tenant context self-test status: {status}");
        Console.WriteLine($"Evidence: {path}");
        return fail == 0 ? 0 : 1;

        void RunCase(string name, DefaultHttpContext ctx, IngressRequest req, int expectedStatus, string? expectedErrorCode)
        {
            var result = ApiAuthorization.AuthorizeIngressWrite(ctx, req);
            var actualStatus = result?.StatusCode ?? StatusCodes.Status200OK;
            string? actualErrorCode = null;
            if (result is not null)
            {
                using var doc = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
                if (doc.RootElement.TryGetProperty("error_code", out var e))
                {
                    actualErrorCode = e.GetString();
                }
            }

            var tenantItem = ctx.Items.TryGetValue("tenant_id", out var v) ? Convert.ToString(v) : null;
            var expectedTenantItem = expectedStatus == StatusCodes.Status200OK ? req.tenant_id : null;
            var ok = actualStatus == expectedStatus
                     && actualErrorCode == expectedErrorCode
                     && string.Equals(tenantItem, expectedTenantItem, StringComparison.Ordinal);

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
                    $"expected status={expectedStatus} error={expectedErrorCode} tenant_item={expectedTenantItem}; got status={actualStatus} error={actualErrorCode} tenant_item={tenantItem}"
                ));
            }
        }

        static DefaultHttpContext ContextWithoutTenant(string key, string participantId)
        {
            var ctx = new DefaultHttpContext();
            ctx.Request.Headers["x-api-key"] = key;
            ctx.Request.Headers["x-participant-id"] = participantId;
            return ctx;
        }

        static DefaultHttpContext ContextWithTenant(string key, string tenantId, string participantId)
        {
            var ctx = ContextWithoutTenant(key, participantId);
            ctx.Request.Headers["x-tenant-id"] = tenantId;
            return ctx;
        }

        static IngressRequest Request(string tenantId, string participantId, JsonElement payload) =>
            new(
                instruction_id: $"ten001-{Guid.NewGuid():N}",
                participant_id: participantId,
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
}

static class EvidencePackSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var evidenceDir = Path.Combine(EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory()), "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);

        var storageFile = $"/tmp/symphony_evidence_pack_selftest_{Guid.NewGuid():N}.ndjson";
        using var projectionScope = SelfTestProjectionScope.Create("evidence_pack");
        var ingressStore = new FileIngressDurabilityStore(logger, storageFile);
        var evidenceStore = new FileEvidencePackStore(logger, ProjectionFiles.EvidenceBundlePath());

        var tenantA = Guid.NewGuid().ToString();
        var tenantB = Guid.NewGuid().ToString();
        var instructionId = "evp-ins-001";

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
        await RunCase("cross_tenant_fail_closed", instructionId, tenantB, StatusCodes.Status404NotFound, null);
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
        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);

        var storageFile = $"/tmp/symphony_case_pack_selftest_{Guid.NewGuid():N}.ndjson";
        using var projectionScope = SelfTestProjectionScope.Create("case_pack");
        var ingressStore = new FileIngressDurabilityStore(logger, storageFile);
        var evidenceStore = new FileEvidencePackStore(logger, ProjectionFiles.EvidenceBundlePath());

        var tenantA = Guid.NewGuid().ToString();
        var tenantB = Guid.NewGuid().ToString();
        var instructionId = "case-ins-complete";

        await ingressStore.PersistAsync(new PersistInput(
            instruction_id: instructionId,
            participant_id: "bank-a",
            idempotency_key: Guid.NewGuid().ToString("N"),
            rail_type: "RTGS",
            payload_json: "{\"amount\":100}",
            payload_hash: IngressValidation.Sha256Hex("{\"amount\":100}"),
            signature_hash: null,
            tenant_id: tenantA,
            correlation_id: "CASE-CORR-1",
            upstream_ref: "UP-REF-1",
            downstream_ref: "DOWN-REF-1",
            nfs_sequence_ref: "NFS-SEQ-1"
        ), cancellationToken);

        var tests = new List<SelfTestCase>();
        var pass = 0;
        var fail = 0;

        await RunCase("case_pack_complete_success", instructionId, tenantA, StatusCodes.Status200OK);
        await RunCase("case_pack_incomplete_fail_closed", "case-ins-incomplete", tenantA, StatusCodes.Status404NotFound);
        await RunCase("case_pack_cross_tenant_fail_closed", instructionId, tenantB, StatusCodes.Status404NotFound);
        await RunCase("case_pack_missing_tenant_header_fail_closed", instructionId, "", StatusCodes.Status400BadRequest);
        await RunCase("case_pack_missing_instruction_fail_closed", "case-ins-missing", tenantA, StatusCodes.Status404NotFound);

        var status = fail == 0 ? "PASS" : "FAIL";
        var meta = EvidenceMeta.Load(rootDir);
        var generationPath = Path.Combine(evidenceDir, "exception_case_pack_generation.json");
        var completenessPath = Path.Combine(evidenceDir, "exception_case_pack_completeness.json");

        await File.WriteAllTextAsync(generationPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-EXCEPTION-CASE-PACK-GENERATION",
            task_id = "TSK-P1-018",
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
            task_id = "TSK-P1-018",
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

        async Task RunCase(string name, string localInstructionId, string localTenantId, int expectedStatus)
        {
            var result = await EvidencePackHandler.HandleAsync(localInstructionId, localTenantId, evidenceStore, logger, cancellationToken);
            var ok = result.StatusCode == expectedStatus;

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

static class TenantOnboardingAdminSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidencePath = Path.Combine(evidenceDir, "ten_003_tenant_onboarding_admin.json");

        var storageFile = $"/tmp/symphony_tenant_onboarding_selftest_{Guid.NewGuid():N}.ndjson";
        var store = new FileTenantOnboardingStore(logger, storageFile);
        var tenantId = Guid.NewGuid().ToString();

        using var env = new SelfTestEnvironmentScope();
        env.Set("ADMIN_API_KEY", SelfTestSecrets.CreateApiKey("tenant-admin"));

        var tenantCreated = false;
        var outboxEventEmitted = false;
        var idempotencyConfirmed = false;
        var nonAdminRejected = false;

        // Non-admin request must fail closed.
        {
            var nonAdminCtx = new DefaultHttpContext();
            var authz = ApiAuthorization.AuthorizeAdminTenantOnboarding(nonAdminCtx);
            nonAdminRejected = authz is not null && authz.StatusCode == StatusCodes.Status403Forbidden;
        }

        var request = new TenantOnboardingRequest(
            tenant_id: tenantId,
            display_name: "TEN-003 SelfTest Tenant",
            jurisdiction_code: "ZM",
            plan: "pilot"
        );
        var input = new TenantOnboardingInput(
            TenantId: Guid.Parse(request.tenant_id),
            DisplayName: request.display_name,
            JurisdictionCode: request.jurisdiction_code,
            Plan: request.plan,
            IdempotencyKey: $"tenant_onboarding:{Guid.Parse(request.tenant_id).ToString("N").ToLowerInvariant()}"
        );

        var first = await store.OnboardAsync(input, cancellationToken);
        tenantCreated = first.Success && string.Equals(first.TenantId, tenantId, StringComparison.OrdinalIgnoreCase);
        outboxEventEmitted = first.Success && first.CreatedNew && !string.IsNullOrWhiteSpace(first.OutboxId);

        var second = await store.OnboardAsync(input, cancellationToken);
        idempotencyConfirmed = second.Success
            && !second.CreatedNew
            && string.Equals(first.TenantId, second.TenantId, StringComparison.OrdinalIgnoreCase)
            && first.CreatedAt == second.CreatedAt;

        var status = tenantCreated && outboxEventEmitted && idempotencyConfirmed && nonAdminRejected
            ? "PASS"
            : "FAIL";
        var meta = EvidenceMeta.Load(rootDir);

        await File.WriteAllTextAsync(evidencePath, JsonSerializer.Serialize(new
        {
            check_id = "TEN-003-TENANT-ONBOARDING-ADMIN",
            task_id = "TSK-P1-TEN-003",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status,
            pass = status == "PASS",
            tenant_created = tenantCreated,
            outbox_event_emitted = outboxEventEmitted,
            idempotency_confirmed = idempotencyConfirmed,
            non_admin_rejected = nonAdminRejected,
            details = new
            {
                endpoint = "POST /v1/admin/tenants",
                idempotency_key = input.IdempotencyKey,
                tenant_created = tenantCreated,
                outbox_event_emitted = outboxEventEmitted,
                idempotency_confirmed = idempotencyConfirmed,
                non_admin_rejected = nonAdminRejected
            }
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Tenant onboarding admin self-test status: {status}");
        Console.WriteLine($"Evidence: {evidencePath}");
        return status == "PASS" ? 0 : 1;
    }
}

static class PilotAuthSelfTestRunner
{
    public static async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        await Task.Yield();
        var tests = new List<SelfTestCase>();
        var pass = 0;
        var fail = 0;

        var apiKey = SelfTestSecrets.CreateApiKey("pilot-auth");
        using var env = new SelfTestEnvironmentScope();
        env.Set("INGRESS_API_KEY", apiKey);

        var tenantA = "11111111-1111-1111-1111-111111111111";
        var tenantB = "22222222-2222-2222-2222-222222222222";
        env.Set("SYMPHONY_KNOWN_TENANTS", $"{tenantA},{tenantB}");
        var payload = JsonSerializer.Deserialize<JsonElement>("{\"amount\":100}");

        await RunCase("ingress_valid_scope_allowed", () =>
        {
            var ctx = ContextWithHeaders(apiKey, tenantA, "bank-a");
            var req = Request(tenantA, "bank-a", payload);
            return ApiAuthorization.AuthorizeIngressWrite(ctx, req) is null;
        });

        await RunCase("ingress_cross_tenant_denied", () =>
        {
            var ctx = ContextWithHeaders(apiKey, tenantA, "bank-a");
            var req = Request(tenantB, "bank-a", payload);
            var result = ApiAuthorization.AuthorizeIngressWrite(ctx, req);
            return result is not null && result.StatusCode == StatusCodes.Status403Forbidden;
        });

        await RunCase("ingress_cross_participant_denied", () =>
        {
            var ctx = ContextWithHeaders(apiKey, tenantA, "bank-a");
            var req = Request(tenantA, "bank-b", payload);
            var result = ApiAuthorization.AuthorizeIngressWrite(ctx, req);
            return result is not null && result.StatusCode == StatusCodes.Status403Forbidden;
        });

        await RunCase("missing_api_key_denied", () =>
        {
            var ctx = new DefaultHttpContext();
            ctx.Request.Headers["x-tenant-id"] = tenantA;
            ctx.Request.Headers["x-participant-id"] = "bank-a";
            var req = Request(tenantA, "bank-a", payload);
            var result = ApiAuthorization.AuthorizeIngressWrite(ctx, req);
            return result is not null && result.StatusCode == StatusCodes.Status401Unauthorized;
        });

        await RunCase("read_with_valid_key_allowed", () =>
        {
            var ctx = new DefaultHttpContext();
            ctx.Request.Headers["x-api-key"] = apiKey;
            return ApiAuthorization.AuthorizeEvidenceRead(ctx) is null;
        });

        await RunCase("read_missing_key_denied", () =>
        {
            var ctx = new DefaultHttpContext();
            var result = ApiAuthorization.AuthorizeEvidenceRead(ctx);
            return result is not null && result.StatusCode == StatusCodes.Status401Unauthorized;
        });

        var status = fail == 0 ? "PASS" : "FAIL";
        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var meta = EvidenceMeta.Load(rootDir);

        var tenantPath = Path.Combine(evidenceDir, "authz_tenant_boundary.json");
        var bozPath = Path.Combine(evidenceDir, "boz_access_boundary_runtime.json");

        await File.WriteAllTextAsync(tenantPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-AUTHZ-TENANT-BOUNDARY",
            task_id = "TSK-P1-022",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status,
            tests_passed = pass,
            tests_failed = fail,
            results = tests
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        var bozLikeBoundaryOk = tests.Any(t => t.Name == "read_with_valid_key_allowed" && t.Status == "PASS")
                                && tests.Any(t => t.Name == "ingress_cross_participant_denied" && t.Status == "PASS");
        await File.WriteAllTextAsync(bozPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-BOZ-ACCESS-BOUNDARY-RUNTIME",
            task_id = "TSK-P1-022",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status = bozLikeBoundaryOk ? "PASS" : "FAIL",
            boz_read_only_boundary_enforced = bozLikeBoundaryOk
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Pilot auth self-test status: {status}");
        Console.WriteLine($"Evidence: {tenantPath}");
        Console.WriteLine($"Evidence: {bozPath}");
        return fail == 0 ? 0 : 1;

        static DefaultHttpContext ContextWithHeaders(string key, string tenantId, string participantId)
        {
            var ctx = new DefaultHttpContext();
            ctx.Request.Headers["x-api-key"] = key;
            ctx.Request.Headers["x-tenant-id"] = tenantId;
            ctx.Request.Headers["x-participant-id"] = participantId;
            return ctx;
        }

        static IngressRequest Request(string tenantId, string participantId, JsonElement payload)
            => new(
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

        async Task RunCase(string name, Func<bool> probe)
        {
            await Task.Yield();
            try
            {
                if (probe())
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

static class CanonicalMessageModelSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var storageFile = $"/tmp/symphony_led003_{Guid.NewGuid():N}.ndjson";
        var store = new FileIngressDurabilityStore(logger, storageFile);
        var tests = new List<SelfTestCase>();

        var validTenant = "11111111-1111-1111-1111-111111111111";
        var validInstruction = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";

        var validPayload = JsonSerializer.Deserialize<JsonElement>(
            $$"""
            {
              "instruction_id": "{{validInstruction}}",
              "tenant_id": "{{validTenant}}",
              "rail_type": "RTGS",
              "amount_minor": 1050,
              "currency_code": "ZMW",
              "beneficiary_ref_hash": "hash-abc-001",
              "idempotency_key": "led003-idem-1",
              "submitted_at_utc": "2026-02-26T01:00:00Z"
            }
            """
        );

        var missingFieldPayload = JsonSerializer.Deserialize<JsonElement>(
            $$"""
            {
              "instruction_id": "{{validInstruction}}",
              "tenant_id": "{{validTenant}}",
              "rail_type": "RTGS",
              "currency_code": "ZMW",
              "beneficiary_ref_hash": "hash-abc-001",
              "idempotency_key": "led003-idem-2",
              "submitted_at_utc": "2026-02-26T01:01:00Z"
            }
            """
        );

        var wrongTypePayload = JsonSerializer.Deserialize<JsonElement>(
            $$"""
            {
              "instruction_id": "{{validInstruction}}",
              "tenant_id": "{{validTenant}}",
              "rail_type": "RTGS",
              "amount_minor": "1050",
              "currency_code": "ZMW",
              "beneficiary_ref_hash": "hash-abc-001",
              "idempotency_key": "led003-idem-3",
              "submitted_at_utc": "2026-02-26T01:02:00Z"
            }
            """
        );

        var fractionalAmountPayload = JsonSerializer.Deserialize<JsonElement>(
            $$"""
            {
              "instruction_id": "{{validInstruction}}",
              "tenant_id": "{{validTenant}}",
              "rail_type": "RTGS",
              "amount_minor": 10.5,
              "currency_code": "ZMW",
              "beneficiary_ref_hash": "hash-abc-001",
              "idempotency_key": "led003-idem-4",
              "submitted_at_utc": "2026-02-26T01:03:00Z"
            }
            """
        );

        var oversizedAmountPayload = JsonSerializer.Deserialize<JsonElement>(
            $$"""
            {
              "instruction_id": "{{validInstruction}}",
              "tenant_id": "{{validTenant}}",
              "rail_type": "RTGS",
              "amount_minor": 1000000000001,
              "currency_code": "ZMW",
              "beneficiary_ref_hash": "hash-abc-001",
              "idempotency_key": "led003-idem-5",
              "submitted_at_utc": "2026-02-26T01:04:00Z"
            }
            """
        );

        var validResult = await IngressHandler.HandleAsync(
            BuildRequest(validInstruction, validTenant, "idem-valid", validPayload),
            store,
            logger,
            forceFailure: false,
            cancellationToken
        );
        tests.Add(ToCase("valid_payload_accepted", validResult.StatusCode == StatusCodes.Status202Accepted, validResult.Body));

        var missingResult = await IngressHandler.HandleAsync(
            BuildRequest(Guid.NewGuid().ToString(), validTenant, "idem-missing", missingFieldPayload),
            store,
            logger,
            forceFailure: false,
            cancellationToken
        );
        tests.Add(ToCase("missing_required_field_rejected", IsSchemaFailure(missingResult), missingResult.Body));

        var wrongTypeResult = await IngressHandler.HandleAsync(
            BuildRequest(Guid.NewGuid().ToString(), validTenant, "idem-wrong-type", wrongTypePayload),
            store,
            logger,
            forceFailure: false,
            cancellationToken
        );
        tests.Add(ToCase("wrong_type_rejected", IsSchemaFailure(wrongTypeResult), wrongTypeResult.Body));

        var fractionalAmountResult = await IngressHandler.HandleAsync(
            BuildRequest(Guid.NewGuid().ToString(), validTenant, "idem-fractional", fractionalAmountPayload),
            store,
            logger,
            forceFailure: false,
            cancellationToken
        );
        tests.Add(ToCase("fractional_amount_rejected", IsSchemaFailure(fractionalAmountResult), fractionalAmountResult.Body));

        var oversizedAmountResult = await IngressHandler.HandleAsync(
            BuildRequest(Guid.NewGuid().ToString(), validTenant, "idem-oversized", oversizedAmountPayload),
            store,
            logger,
            forceFailure: false,
            cancellationToken
        );
        tests.Add(ToCase("oversized_amount_rejected", IsSchemaFailure(oversizedAmountResult), oversizedAmountResult.Body));

        var status = tests.All(t => t.Status == "PASS") ? "PASS" : "FAIL";

        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidencePath = Path.Combine(evidenceDir, "led_003_canonical_message_model.json");
        var schemaPath = Path.Combine(rootDir, "schema", "messages", "canonical_instruction_v1.json");
        var schemaExists = File.Exists(schemaPath);

        var meta = EvidenceMeta.Load(rootDir);
        await File.WriteAllTextAsync(evidencePath, JsonSerializer.Serialize(new
        {
            check_id = "LED-003-CANONICAL-MESSAGE-MODEL",
            task_id = "TSK-P1-LED-003",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status,
            pass = status == "PASS",
            details = new
            {
                schema_path = "schema/messages/canonical_instruction_v1.json",
                schema_exists = schemaExists,
                tests
            }
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Canonical message model self-test status: {status}");
        Console.WriteLine($"Evidence: {evidencePath}");
        return status == "PASS" ? 0 : 1;

        static IngressRequest BuildRequest(string instructionId, string tenantId, string idempotencyKey, JsonElement payload)
            => new(
                instruction_id: instructionId,
                participant_id: "bank-led003",
                idempotency_key: idempotencyKey,
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

        static SelfTestCase ToCase(string name, bool ok, object body)
            => new(name, ok ? "PASS" : "FAIL", JsonSerializer.Serialize(body));

        static bool IsSchemaFailure(HandlerResult result)
        {
            if (result.StatusCode != StatusCodes.Status400BadRequest)
            {
                return false;
            }

            var json = JsonSerializer.Serialize(result.Body);
            using var doc = JsonDocument.Parse(json);
            if (!doc.RootElement.TryGetProperty("error", out var err))
            {
                return false;
            }

            if (!string.Equals(err.GetString(), "SCHEMA_VALIDATION_FAILED", StringComparison.Ordinal))
            {
                return false;
            }

            return doc.RootElement.TryGetProperty("violations", out var violations)
                   && violations.ValueKind == JsonValueKind.Array
                   && violations.GetArrayLength() > 0;
        }
    }
}

static class KycHashBridgeSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var filePath = $"/tmp/symphony_led004_{Guid.NewGuid():N}.ndjson";
        Environment.SetEnvironmentVariable("KYC_HASH_BRIDGE_FILE", filePath);
        Environment.SetEnvironmentVariable("KYC_PROVIDER_CODES", "PROV-001");

        var store = new FileKycHashBridgeStore(logger, filePath);
        var tests = new List<SelfTestCase>();

        var validPayload = JsonSerializer.Deserialize<JsonElement>(
            """
            {
              "member_id": "11111111-1111-1111-1111-111111111111",
              "provider_code": "PROV-001",
              "outcome": "VERIFIED",
              "verification_method": "NRC_HASH",
              "verification_hash": "sha256:abc123",
              "hash_algorithm": "SHA-256",
              "provider_signature": "sig:xyz",
              "provider_reference": "REF-001",
              "verified_at_provider": "2026-02-26T01:10:00Z"
            }
            """
        );

        var piiPayload = JsonSerializer.Deserialize<JsonElement>(
            """
            {
              "member_id": "11111111-1111-1111-1111-111111111111",
              "provider_code": "PROV-001",
              "outcome": "VERIFIED",
              "verification_method": "NRC_HASH",
              "verification_hash": "sha256:abc123",
              "hash_algorithm": "SHA-256",
              "provider_signature": "sig:xyz",
              "provider_reference": "REF-002",
              "verified_at_provider": "2026-02-26T01:10:00Z",
              "full_name": "should-not-pass"
            }
            """
        );

        var validParse = KycHashBridgeValidation.Parse(validPayload);
        if (validParse.Request is null)
        {
            tests.Add(new SelfTestCase("valid_hash_accepted", "FAIL", "valid parse failed"));
        }
        else
        {
            var validResult = await KycHashBridgeHandler.HandleAsync(validParse.Request, store, logger, cancellationToken);
            tests.Add(new SelfTestCase(
                "valid_hash_accepted",
                validResult.StatusCode == StatusCodes.Status200OK ? "PASS" : "FAIL",
                JsonSerializer.Serialize(validResult.Body)
            ));
        }

        var unknownProviderPayload = JsonSerializer.Deserialize<JsonElement>(
            """
            {
              "member_id": "11111111-1111-1111-1111-111111111111",
              "provider_code": "UNKNOWN",
              "outcome": "VERIFIED",
              "verification_method": "NRC_HASH",
              "verification_hash": "sha256:abc123",
              "hash_algorithm": "SHA-256",
              "provider_signature": "sig:xyz",
              "provider_reference": "REF-003",
              "verified_at_provider": "2026-02-26T01:10:00Z"
            }
            """
        );
        var unknownParse = KycHashBridgeValidation.Parse(unknownProviderPayload);
        if (unknownParse.Request is null)
        {
            tests.Add(new SelfTestCase("unknown_provider_rejected", "FAIL", "unknown parse failed"));
        }
        else
        {
            var unknownResult = await KycHashBridgeHandler.HandleAsync(unknownParse.Request, store, logger, cancellationToken);
            tests.Add(new SelfTestCase(
                "unknown_provider_rejected",
                unknownResult.StatusCode == StatusCodes.Status404NotFound ? "PASS" : "FAIL",
                JsonSerializer.Serialize(unknownResult.Body)
            ));
        }

        var piiRejected = KycHashBridgeValidation.TryRejectPiiFields(piiPayload, out var piiField);
        tests.Add(new SelfTestCase(
            "pii_field_rejected",
            piiRejected && piiField == "full_name" ? "PASS" : "FAIL",
            piiRejected ? $"rejected:{piiField}" : "not_rejected"
        ));

        var retentionClassConfirmed = false;
        if (File.Exists(filePath))
        {
            foreach (var line in await File.ReadAllLinesAsync(filePath, cancellationToken))
            {
                if (string.IsNullOrWhiteSpace(line))
                {
                    continue;
                }
                using var doc = JsonDocument.Parse(line);
                if (doc.RootElement.TryGetProperty("retention_class", out var rc)
                    && string.Equals(rc.GetString(), "FIC_AML_CUSTOMER_ID", StringComparison.Ordinal))
                {
                    retentionClassConfirmed = true;
                    break;
                }
            }
        }

        var status = tests.All(t => t.Status == "PASS") && retentionClassConfirmed ? "PASS" : "FAIL";

        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidencePath = Path.Combine(evidenceDir, "led_004_kyc_hash_bridge_endpoint.json");
        var meta = EvidenceMeta.Load(rootDir);

        await File.WriteAllTextAsync(evidencePath, JsonSerializer.Serialize(new
        {
            check_id = "LED-004-KYC-HASH-BRIDGE-ENDPOINT",
            task_id = "TSK-P1-LED-004",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status,
            pass = status == "PASS",
            details = new
            {
                endpoint = "POST /v1/kyc/hash",
                retention_class = "FIC_AML_CUSTOMER_ID",
                retention_class_confirmed = retentionClassConfirmed,
                tests
            }
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"KYC hash bridge self-test status: {status}");
        Console.WriteLine($"Evidence: {evidencePath}");
        return status == "PASS" ? 0 : 1;
    }
}

static class RegulatoryDailyReportSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var ingressFile = $"/tmp/symphony_reg002_{Guid.NewGuid():N}.ndjson";
        var projectionFile = $"/tmp/symphony_reg002_projection_{Guid.NewGuid():N}.ndjson";
        using var env = new SelfTestEnvironmentScope();
        env.Set("INGRESS_STORAGE_FILE", ingressFile);
        env.Set("INSTRUCTION_STATUS_PROJECTION_FILE", projectionFile);
        env.Set("EVIDENCE_SIGNING_KEY", SelfTestSecrets.CreateSigningKey());
        env.Set("EVIDENCE_SIGNING_KEY_ID", "phase1-reg-002-key");

        var ingressStore = new FileIngressDurabilityStore(logger, ingressFile);
        var reportDate = DateTimeOffset.UtcNow.ToString("yyyy-MM-dd");
        var tenant = "11111111-1111-1111-1111-111111111111";

        await ingressStore.PersistAsync(new PersistInput(
            instruction_id: $"reg002-{Guid.NewGuid():N}",
            participant_id: "bank-reg-1",
            idempotency_key: "reg-002-idem-1",
            rail_type: "RTGS",
            payload_json: "{}",
            payload_hash: "hash",
            signature_hash: null,
            tenant_id: tenant,
            correlation_id: Guid.NewGuid().ToString(),
            upstream_ref: "upstream-ref",
            downstream_ref: "downstream-ref",
            nfs_sequence_ref: null
        ), cancellationToken);

        var first = await RegulatoryReportHandler.GenerateDailyReportAsync(reportDate, tenant, "file", null, cancellationToken);
        var second = await RegulatoryReportHandler.GenerateDailyReportAsync(reportDate, tenant, "file", null, cancellationToken);
        if (!first.Success || !second.Success || first.Report is null || second.Report is null)
        {
            return 1;
        }

        static string CanonicalizeWithoutProducedAt(object report)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(report));
            using var stream = new MemoryStream();
            using (var writer = new Utf8JsonWriter(stream))
            {
                writer.WriteStartObject();
                foreach (var p in doc.RootElement.EnumerateObject())
                {
                    if (p.NameEquals("produced_at_utc"))
                    {
                        continue;
                    }
                    p.WriteTo(writer);
                }
                writer.WriteEndObject();
            }
            return Encoding.UTF8.GetString(stream.ToArray());
        }

        var firstCanonical = CanonicalizeWithoutProducedAt(first.Report);
        var secondCanonical = CanonicalizeWithoutProducedAt(second.Report);
        var determinismConfirmed = string.Equals(firstCanonical, secondCanonical, StringComparison.Ordinal);
        var signatureVerified = RegulatoryReportHandler.VerifySignature(
            firstCanonical,
            first.Signature,
            Environment.GetEnvironmentVariable("EVIDENCE_SIGNING_KEY") ?? string.Empty
        );

        var status = determinismConfirmed && signatureVerified ? "PASS" : "FAIL";
        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidencePath = Path.Combine(evidenceDir, "reg_002_daily_report_signed_output.json");
        var meta = EvidenceMeta.Load(rootDir);

        await File.WriteAllTextAsync(evidencePath, JsonSerializer.Serialize(new
        {
            check_id = "REG-002-DAILY-REPORT-SIGNED-DETERMINISTIC",
            task_id = "TSK-P1-REG-002",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            status,
            pass = status == "PASS",
            report_generated = first.Success,
            signature_verified = signatureVerified,
            determinism_confirmed = determinismConfirmed,
            details = new
            {
                report_date = reportDate,
                signature_header = "X-Symphony-Signature",
                key_id_header = "X-Symphony-Key-Id"
            }
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Reg daily report self-test status: {status}");
        Console.WriteLine($"Evidence: {evidencePath}");
        return status == "PASS" ? 0 : 1;
    }
}

static class RegulatoryIncident48hSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var incidentFile = $"/tmp/symphony_reg003_{Guid.NewGuid():N}.ndjson";
        var projectionFile = $"/tmp/symphony_reg003_projection_{Guid.NewGuid():N}.ndjson";
        using var env = new SelfTestEnvironmentScope();
        env.Set("REGULATORY_INCIDENTS_FILE", incidentFile);
        env.Set("INCIDENT_CASE_PROJECTION_FILE", projectionFile);
        env.Set("EVIDENCE_SIGNING_KEY", SelfTestSecrets.CreateSigningKey());
        env.Set("EVIDENCE_SIGNING_KEY_ID", "phase1-reg-003-key");

        var store = new FileRegulatoryIncidentStore(logger, incidentFile);
        var tenantId = "11111111-1111-1111-1111-111111111111";
        var created = await store.CreateIncidentAsync(new RegulatoryIncidentCreateRequest(
            tenant_id: tenantId,
            incident_type: "RAIL_CONFLICT",
            detected_at: DateTimeOffset.UtcNow.ToString("O"),
            description: "simulated contradiction from rail callback stream",
            severity: "HIGH"
        ), cancellationToken);

        if (!created.Success || string.IsNullOrWhiteSpace(created.IncidentId))
        {
            return 1;
        }

        var blocked = await RegulatoryIncidentReportHandler.GenerateIncidentReportAsync(created.IncidentId, store, cancellationToken);
        var blockedOpenState = !blocked.Success && string.Equals(blocked.ErrorCode, "INCIDENT_NOT_REPORTABLE", StringComparison.Ordinal);

        var update = await store.UpdateStatusAsync(created.IncidentId, "UNDER_INVESTIGATION", cancellationToken);
        if (!update.Success)
        {
            return 1;
        }

        var reportResult = await RegulatoryIncidentReportHandler.GenerateIncidentReportAsync(created.IncidentId, store, cancellationToken);
        if (!reportResult.Success || reportResult.Report is null)
        {
            return 1;
        }

        static string CanonicalizeWithoutProducedAt(object report)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(report));
            using var stream = new MemoryStream();
            using (var writer = new Utf8JsonWriter(stream))
            {
                writer.WriteStartObject();
                foreach (var p in doc.RootElement.EnumerateObject())
                {
                    if (p.NameEquals("produced_at_utc"))
                    {
                        continue;
                    }
                    p.WriteTo(writer);
                }
                writer.WriteEndObject();
            }
            return Encoding.UTF8.GetString(stream.ToArray());
        }

        var canonical = CanonicalizeWithoutProducedAt(reportResult.Report);
        var signatureVerified = RegulatoryIncidentReportHandler.VerifySignature(
            canonical,
            reportResult.Signature,
            Environment.GetEnvironmentVariable("EVIDENCE_SIGNING_KEY") ?? string.Empty
        );

        using var reportDoc = JsonDocument.Parse(JsonSerializer.Serialize(reportResult.Report));
        var root = reportDoc.RootElement;
        var hasRequiredFields =
            root.TryGetProperty("incident_id", out _) &&
            root.TryGetProperty("tenant_id", out _) &&
            root.TryGetProperty("incident_type", out _) &&
            root.TryGetProperty("detected_at", out _) &&
            root.TryGetProperty("description", out _) &&
            root.TryGetProperty("severity", out _) &&
            root.TryGetProperty("status", out _) &&
            root.TryGetProperty("reported_to_boz_at", out _) &&
            root.TryGetProperty("boz_reference", out _) &&
            root.TryGetProperty("created_at", out _) &&
            root.TryGetProperty("timeline", out var timelineProp) &&
            timelineProp.ValueKind == JsonValueKind.Array &&
            timelineProp.GetArrayLength() >= 2;

        var status = blockedOpenState && signatureVerified && hasRequiredFields ? "PASS" : "FAIL";

        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidencePath = Path.Combine(evidenceDir, "reg_003_incident_48h_export.json");
        var meta = EvidenceMeta.Load(rootDir);

        await File.WriteAllTextAsync(evidencePath, JsonSerializer.Serialize(new
        {
            check_id = "REG-003-INCIDENT-48H-EXPORT",
            task_id = "TSK-P1-REG-003",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            status,
            pass = status == "PASS",
            incident_registered = created.Success,
            status_updated_under_investigation = update.Success,
            report_generated = reportResult.Success,
            signature_verified = signatureVerified,
            open_status_report_blocked = blockedOpenState,
            details = new
            {
                incident_id = created.IncidentId,
                blocked_error_code = blocked.ErrorCode,
                key_id = reportResult.KeyId
            }
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Reg incident 48h self-test status: {status}");
        Console.WriteLine($"Evidence: {evidencePath}");
        return status == "PASS" ? 0 : 1;
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
