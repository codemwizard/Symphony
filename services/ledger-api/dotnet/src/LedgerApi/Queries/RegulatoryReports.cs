using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Npgsql;

record RegulatoryIncidentReportResult(
    bool Success,
    int StatusCode,
    object? Report,
    string Signature,
    string KeyId,
    string? ErrorCode,
    string? Error)
{
    public IResult ToHttpResult()
    {
        if (!Success)
        {
            var status = ErrorCode == RegulatoryErrors.SigningCapabilityMissing
                ? StatusCodes.Status503ServiceUnavailable
                : StatusCode;

            return Results.Json(new
            {
                error_code = ErrorCode ?? "INCIDENT_REPORT_FAILED",
                errors = new[] { Error ?? "unknown" }
            }, statusCode: status);
        }

        return Results.Json(Report!, statusCode: StatusCodes.Status200OK)
            .WithHeader("X-Symphony-Signature", Signature)
            .WithHeader("X-Symphony-Key-Id", KeyId);
    }
}

static class RegulatoryIncidentReportHandler
{
    public static async Task<RegulatoryIncidentReportResult> GenerateIncidentReportAsync(
        string incidentId,
        IRegulatoryIncidentStore store,
        CancellationToken cancellationToken,
        string? evidenceSigningKey = null,
        string? evidenceSigningKeyId = null)
    {
        if (!Guid.TryParse(incidentId, out _))
        {
            return new RegulatoryIncidentReportResult(false, StatusCodes.Status400BadRequest, null, string.Empty, string.Empty, "INVALID_INCIDENT_ID", "incident_id must be UUID");
        }

        var lookup = await store.GetIncidentReportDataAsync(incidentId, cancellationToken);
        if (!lookup.Found || lookup.Incident is null)
        {
            return new RegulatoryIncidentReportResult(false, StatusCodes.Status404NotFound, null, string.Empty, string.Empty, "INCIDENT_NOT_FOUND", lookup.Error ?? "incident not found");
        }

        var incident = lookup.Incident;
        if (string.Equals(incident.Status, "OPEN", StringComparison.OrdinalIgnoreCase))
        {
            return new RegulatoryIncidentReportResult(false, StatusCodes.Status409Conflict, null, string.Empty, string.Empty, "INCIDENT_NOT_REPORTABLE", "incident must be UNDER_INVESTIGATION or beyond");
        }

        var timeline = lookup.Timeline
            .OrderBy(e => e.CreatedAt, StringComparer.Ordinal)
            .Select(e => new { event_type = e.EventType, event_payload = e.EventPayload, created_at = e.CreatedAt })
            .ToArray();

        var asOfUtc = ProjectionMeta.AsOfUtc();
        var reportWithoutTimestamp = new
        {
            incident_id = incident.IncidentId,
            tenant_id = incident.TenantId,
            incident_type = incident.IncidentType,
            detected_at = incident.DetectedAt,
            description = incident.Description,
            severity = incident.Severity,
            status = incident.Status,
            reported_to_boz_at = incident.ReportedToBozAt,
            boz_reference = incident.BozReference,
            created_at = incident.CreatedAt,
            projection_version = ProjectionMeta.Version,
            as_of_utc = asOfUtc,
            timeline
        };

        var reportJson = JsonSerializer.Serialize(reportWithoutTimestamp);
        var keyMaterial = evidenceSigningKey ?? Environment.GetEnvironmentVariable("EVIDENCE_SIGNING_KEY");
        if (string.IsNullOrWhiteSpace(keyMaterial))
        {
            return new RegulatoryIncidentReportResult(false, StatusCodes.Status503ServiceUnavailable, null, string.Empty, string.Empty, RegulatoryErrors.SigningCapabilityMissing, "EVIDENCE_SIGNING_KEY must be configured");
        }

        var keyId = evidenceSigningKeyId ?? Environment.GetEnvironmentVariable("EVIDENCE_SIGNING_KEY_ID") ?? string.Empty;
        var signature = RegulatoryReportHandler.VerifySignature(reportJson, RegulatoryReportComputeHmac(reportJson, keyMaterial), keyMaterial)
            ? RegulatoryReportComputeHmac(reportJson, keyMaterial)
            : string.Empty;

        var report = new
        {
            incident_id = incident.IncidentId,
            tenant_id = incident.TenantId,
            incident_type = incident.IncidentType,
            detected_at = incident.DetectedAt,
            description = incident.Description,
            severity = incident.Severity,
            status = incident.Status,
            reported_to_boz_at = incident.ReportedToBozAt,
            boz_reference = incident.BozReference,
            created_at = incident.CreatedAt,
            projection_version = ProjectionMeta.Version,
            as_of_utc = asOfUtc,
            timeline,
            produced_at_utc = DateTimeOffset.UtcNow.ToString("O")
        };

        return new RegulatoryIncidentReportResult(true, StatusCodes.Status200OK, report, signature, keyId, null, null);
    }

    public static bool VerifySignature(string canonicalJson, string signatureHex, string keyMaterial)
        => RegulatoryReportHandler.VerifySignature(canonicalJson, signatureHex, keyMaterial);

    private static string RegulatoryReportComputeHmac(string payload, string keyMaterial)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(keyMaterial));
        var sig = hmac.ComputeHash(Encoding.UTF8.GetBytes(payload));
        return Convert.ToHexString(sig).ToLowerInvariant();
    }
}

record RegulatoryReportResult(
    bool Success,
    object? Report,
    string Signature,
    string KeyId,
    bool Deterministic,
    string? ErrorCode,
    string? Error)
{
    public static RegulatoryReportResult Fail(string errorCode, string error)
        => new(false, null, string.Empty, string.Empty, false, errorCode, error);

    public IResult ToHttpResult()
    {
        if (!Success)
        {
            var status = ErrorCode == RegulatoryErrors.SigningCapabilityMissing
                ? StatusCodes.Status503ServiceUnavailable
                : StatusCodes.Status400BadRequest;

            return Results.Json(new
            {
                error_code = ErrorCode ?? "REPORT_GENERATION_FAILED",
                errors = new[] { Error ?? "unknown" }
            }, statusCode: status);
        }

        return Results.Json(Report!, statusCode: StatusCodes.Status200OK)
            .WithHeader("X-Symphony-Signature", Signature)
            .WithHeader("X-Symphony-Key-Id", KeyId);
    }
}

public static class RegulatoryErrors
{
    public const string SigningCapabilityMissing = "SIGNING_CAPABILITY_MISSING";
    public const string TenantAllowlistUnconfigured = "TENANT_ALLOWLIST_UNCONFIGURED";
}

public static class ResultExtensions
{
    public static IResult WithHeader(this IResult result, string header, string value)
    {
        return new ResultWithHeader(result, header, value);
    }

    private sealed class ResultWithHeader(IResult inner, string header, string value) : IResult
    {
        public async Task ExecuteAsync(HttpContext httpContext)
        {
            httpContext.Response.Headers[header] = value;
            await inner.ExecuteAsync(httpContext);
        }
    }
}

static class RegulatoryReportHandler
{
    public static async Task<RegulatoryReportResult> GenerateDailyReportAsync(
        string reportDate,
        string? tenantId,
        string storageMode,
        NpgsqlDataSource? dataSource,
        CancellationToken cancellationToken,
        string? evidenceSigningKey = null,
        string? evidenceSigningKeyId = null)
    {
        await Task.Yield();
        if (!DateOnly.TryParse(reportDate, out var parsedDate))
        {
            return RegulatoryReportResult.Fail("INVALID_DATE", "date must be YYYY-MM-DD");
        }

        var repoRoot = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var instructionCount = 0;
        long instructionTotalMinor = 0;
        var currency = "ZMW";
        var exceptionCountByType = new Dictionary<string, int>(StringComparer.Ordinal);
        var asOfUtc = ProjectionMeta.AsOfUtc();

        if (StorageModePolicy.IsDatabaseMode(storageMode))
        {
            if (dataSource is null)
            {
                return RegulatoryReportResult.Fail("PROJECTION_STORE_UNAVAILABLE", "projection datasource unavailable");
            }

            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = @"
SELECT COUNT(*), COALESCE(SUM(amount_minor), 0), COALESCE(MAX(as_of_utc), NOW())
FROM public.instruction_status_projection
WHERE (@tenant_id::uuid IS NULL OR tenant_id = @tenant_id)
  AND DATE(as_of_utc AT TIME ZONE 'UTC') = @report_date;";
            cmd.Parameters.AddWithValue("tenant_id", string.IsNullOrWhiteSpace(tenantId) ? DBNull.Value : Guid.Parse(tenantId));
            cmd.Parameters.AddWithValue("report_date", parsedDate.ToDateTime(TimeOnly.MinValue));
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            if (await reader.ReadAsync(cancellationToken))
            {
                instructionCount = reader.GetInt32(0);
                instructionTotalMinor = reader.GetInt64(1);
                asOfUtc = reader.GetFieldValue<DateTime>(2).ToUniversalTime().ToString("O");
            }
        }
        else
        {
            var projectionPath = ProjectionFiles.InstructionStatusPath();
            if (File.Exists(projectionPath))
            {
                foreach (var line in await File.ReadAllLinesAsync(projectionPath, cancellationToken))
                {
                    if (string.IsNullOrWhiteSpace(line))
                    {
                        continue;
                    }

                    var projection = JsonSerializer.Deserialize<InstructionStatusProjection>(line);
                    if (projection is null)
                    {
                        continue;
                    }

                    if (!string.IsNullOrWhiteSpace(tenantId) && !string.Equals(projection.tenant_id, tenantId, StringComparison.Ordinal))
                    {
                        continue;
                    }

                    if (!DateTimeOffset.TryParse(projection.as_of_utc, out var projectedAt)
                        || DateOnly.FromDateTime(projectedAt.UtcDateTime) != parsedDate)
                    {
                        continue;
                    }

                    instructionCount++;
                    instructionTotalMinor += projection.amount_minor;
                    asOfUtc = projection.as_of_utc;
                }
            }
        }

        exceptionCountByType.TryAdd("NONE", 0);
        var reportWithoutTimestamp = new
        {
            report_date = parsedDate.ToString("yyyy-MM-dd"),
            tenant_id = tenantId,
            instruction_count = instructionCount,
            instruction_total_minor = instructionTotalMinor,
            instruction_currency = currency,
            exception_count_by_type = exceptionCountByType,
            settlement_success_pct = instructionCount > 0 ? 100.0 : 0.0,
            settlement_failure_pct = 0.0,
            git_sha = EvidenceMeta.Load(repoRoot).GitSha,
            projection_version = ProjectionMeta.Version,
            as_of_utc = asOfUtc
        };

        var reportJson = JsonSerializer.Serialize(reportWithoutTimestamp);
        var keyMaterial = evidenceSigningKey ?? Environment.GetEnvironmentVariable("EVIDENCE_SIGNING_KEY");
        if (string.IsNullOrWhiteSpace(keyMaterial))
        {
            return RegulatoryReportResult.Fail(RegulatoryErrors.SigningCapabilityMissing, "EVIDENCE_SIGNING_KEY must be configured");
        }

        var keyId = evidenceSigningKeyId ?? Environment.GetEnvironmentVariable("EVIDENCE_SIGNING_KEY_ID") ?? string.Empty;
        var signature = ComputeHmac(reportJson, keyMaterial);

        var report = new
        {
            report_date = parsedDate.ToString("yyyy-MM-dd"),
            tenant_id = tenantId,
            instruction_count = instructionCount,
            instruction_total_minor = instructionTotalMinor,
            instruction_currency = currency,
            exception_count_by_type = exceptionCountByType,
            settlement_success_pct = instructionCount > 0 ? 100.0 : 0.0,
            settlement_failure_pct = 0.0,
            git_sha = EvidenceMeta.Load(repoRoot).GitSha,
            projection_version = ProjectionMeta.Version,
            as_of_utc = asOfUtc,
            produced_at_utc = DateTimeOffset.UtcNow.ToString("O")
        };

        return new RegulatoryReportResult(true, report, signature, keyId, true, null, null);
    }

    public static bool VerifySignature(string canonicalJson, string signatureHex, string keyMaterial)
        => string.Equals(signatureHex, ComputeHmac(canonicalJson, keyMaterial), StringComparison.OrdinalIgnoreCase);

    private static string ComputeHmac(string payload, string keyMaterial)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(keyMaterial));
        var sig = hmac.ComputeHash(Encoding.UTF8.GetBytes(payload));
        return Convert.ToHexString(sig).ToLowerInvariant();
    }
}
