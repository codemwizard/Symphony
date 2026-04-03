using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Http;

static class EvidenceLinkIssueHandler
{
    private static readonly Regex MsisdnRegex = new(@"^\+?[0-9]{8,15}$", RegexOptions.Compiled);
    private static readonly HashSet<string> ValidSubmitterClasses =
        new(StringComparer.Ordinal)
        { "VENDOR", "FIELD_OFFICER", "BORROWER", "SUPPLIER", "WASTE_COLLECTOR" };

    public static async Task<HandlerResult> HandleAsync(EvidenceLinkIssueRequest request, ILogger logger, CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        if (string.IsNullOrWhiteSpace(request.tenant_id) || !Guid.TryParse(request.tenant_id, out _))
        {
            errors.Add("tenant_id must be a valid UUID");
        }
        if (string.IsNullOrWhiteSpace(request.instruction_id))
        {
            errors.Add("instruction_id is required");
        }
        if (string.IsNullOrWhiteSpace(request.program_id))
        {
            errors.Add("program_id is required");
        }
        if (string.IsNullOrWhiteSpace(request.submitter_class))
        {
            errors.Add("submitter_class is required");
        }
        else if (!ValidSubmitterClasses.Contains(request.submitter_class.Trim()))
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_SUBMITTER_CLASS",
                errors = new[] { $"submitter_class '{request.submitter_class}' is not valid" }
            });
        }
        if (string.IsNullOrWhiteSpace(request.submitter_msisdn) || !MsisdnRegex.IsMatch(request.submitter_msisdn.Trim()))
        {
            errors.Add("submitter_msisdn must be a valid MSISDN");
        }
        if ((request.expected_latitude is null) ^ (request.expected_longitude is null))
        {
            errors.Add("expected_latitude and expected_longitude must be provided together");
        }
        if (request.max_distance_meters is not null && request.max_distance_meters <= 0)
        {
            errors.Add("max_distance_meters must be > 0 when provided");
        }
        var ttlSeconds = request.expires_in_seconds ?? 900;
        if (ttlSeconds < 60 || ttlSeconds > 86400)
        {
            errors.Add("expires_in_seconds must be between 60 and 86400");
        }

        if (errors.Count > 0)
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors
            });
        }

        var signingKey = ResolveSigningKey();
        if (string.IsNullOrWhiteSpace(signingKey))
        {
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                error_code = "SECURE_LINK_CONFIG_MISSING",
                errors = new[] { "DEMO_EVIDENCE_LINK_SIGNING_KEY or EVIDENCE_SIGNING_KEY must be configured" }
            });
        }

        var expiresAt = DateTimeOffset.UtcNow.AddSeconds(ttlSeconds);
        var token = EvidenceLinkTokenService.CreateToken(
            request.tenant_id.Trim(),
            request.instruction_id.Trim(),
            request.program_id.Trim(),
            request.submitter_class.Trim(),
            request.submitter_msisdn.Trim(),
            request.expected_latitude,
            request.expected_longitude,
            request.max_distance_meters,
            expiresAt,
            signingKey);

        await EvidenceLinkSmsDispatchLog.AppendAsync(new
        {
            tenant_id = request.tenant_id.Trim(),
            instruction_id = request.instruction_id.Trim(),
            program_id = request.program_id.Trim(),
            submitter_class = request.submitter_class.Trim(),
            submitter_msisdn = request.submitter_msisdn.Trim(),
            dispatched_at_utc = DateTimeOffset.UtcNow.ToString("O"),
            status = "SIMULATED_DISPATCHED"
        }, cancellationToken);

        logger.LogInformation("Issued secure evidence link for instruction {InstructionId}", request.instruction_id);
        return new HandlerResult(StatusCodes.Status200OK, new
        {
            issued = true,
            tenant_id = request.tenant_id.Trim(),
            instruction_id = request.instruction_id.Trim(),
            program_id = request.program_id.Trim(),
            submitter_class = request.submitter_class.Trim(),
            submitter_msisdn = request.submitter_msisdn.Trim(),
            expires_at_utc = expiresAt.ToString("O"),
            token,
            landing_url = $"/pilot-demo/evidence-link#token={token}",
            upload_path = "/v1/evidence-links/submit",
            sms_dispatch_status = "SIMULATED_DISPATCHED"
        });
    }

    public static string ResolveSigningKey(string? demoLinkSigningKey = null, string? evidenceSigningKey = null)
        => (demoLinkSigningKey
            ?? evidenceSigningKey
            ?? Environment.GetEnvironmentVariable("DEMO_EVIDENCE_LINK_SIGNING_KEY")
            ?? Environment.GetEnvironmentVariable("EVIDENCE_SIGNING_KEY")
            ?? string.Empty).Trim();
}

static class EvidenceLinkSubmitHandler
{
    public static async Task<HandlerResult> HandleAsync(EvidenceLinkSubmitRequest request, HttpContext httpContext, ILogger logger, CancellationToken cancellationToken)
    {
        var token = TryReadToken(httpContext);
        if (string.IsNullOrWhiteSpace(token))
        {
            return new HandlerResult(StatusCodes.Status401Unauthorized, new
            {
                error_code = "LINK_TOKEN_MISSING",
                errors = new[] { "Authorization header credential or x-evidence-link-token is required" }
            });
        }

        var signingKey = EvidenceLinkIssueHandler.ResolveSigningKey();
        if (string.IsNullOrWhiteSpace(signingKey))
        {
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                error_code = "SECURE_LINK_CONFIG_MISSING",
                errors = new[] { "DEMO_EVIDENCE_LINK_SIGNING_KEY or EVIDENCE_SIGNING_KEY must be configured" }
            });
        }

        var validation = EvidenceLinkTokenService.ValidateToken(token, signingKey, DateTimeOffset.UtcNow);
        if (!validation.Success)
        {
            return new HandlerResult(StatusCodes.Status401Unauthorized, new
            {
                error_code = validation.ErrorCode,
                errors = new[] { validation.ErrorMessage }
            });
        }

        var tenantHeader = httpContext.Request.Headers.TryGetValue("x-tenant-id", out var tenant) ? tenant.ToString().Trim() : string.Empty;
        if (string.IsNullOrWhiteSpace(tenantHeader) || !string.Equals(tenantHeader, validation.TenantId, StringComparison.Ordinal))
        {
            return new HandlerResult(StatusCodes.Status403Forbidden, new
            {
                error_code = "FORBIDDEN_TENANT_SCOPE",
                errors = new[] { "x-tenant-id must match secure-link tenant scope" }
            });
        }

        var submitterMsisdn = httpContext.Request.Headers.TryGetValue("x-submitter-msisdn", out var msisdnHeader)
            ? msisdnHeader.ToString().Trim()
            : string.Empty;
        if (string.IsNullOrWhiteSpace(submitterMsisdn) || !string.Equals(submitterMsisdn, validation.SubmitterMsisdn, StringComparison.Ordinal))
        {
            return new HandlerResult(StatusCodes.Status403Forbidden, new
            {
                error_code = "FORBIDDEN_SUBMITTER_SCOPE",
                errors = new[] { "x-submitter-msisdn must match secure-link submitter scope" }
            });
        }

        if (string.IsNullOrWhiteSpace(request.artifact_type) || string.IsNullOrWhiteSpace(request.artifact_ref))
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors = new[] { "artifact_type and artifact_ref are required" }
            });
        }

        if (validation.ExpectedLatitude is not null && validation.ExpectedLongitude is not null)
        {
            if (request.latitude is null || request.longitude is null)
            {
                return new HandlerResult(StatusCodes.Status422UnprocessableEntity, new
                {
                    error_code = "GPS_REQUIRED",
                    errors = new[] { "latitude and longitude are required for this secure link" }
                });
            }

            var distanceMeters = GeoMath.HaversineMeters(
                request.latitude.Value,
                request.longitude.Value,
                validation.ExpectedLatitude.Value,
                validation.ExpectedLongitude.Value);

            var maxDistance = validation.MaxDistanceMeters ?? 100m;
            if (distanceMeters > maxDistance)
            {
                return new HandlerResult(StatusCodes.Status422UnprocessableEntity, new
                {
                    error_code = "GPS_MATCH_FAILED",
                    distance_meters = distanceMeters,
                    max_distance_meters = maxDistance
                });
            }
        }

        // FIX F11: WEIGHBRIDGE_RECORD requires structured_payload (pilot policy, no exceptions)
        decimal? storedNetWeight = null;
        if (string.Equals(request.artifact_type.Trim(), Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD, StringComparison.Ordinal))
        {
            if (request.structured_payload is null ||
                request.structured_payload.Value.ValueKind == JsonValueKind.Null)
            {
                return new HandlerResult(StatusCodes.Status400BadRequest, new
                {
                    error_code = "INVALID_REQUEST",
                    errors = new[] { "structured_payload is required for WEIGHBRIDGE_RECORD" }
                });
            }

            // FIX F14: backend recomputes net; violations include tolerance check
            var (violations, backendNet) = Pwrm0001WeighbridgePayloadValidator.Validate(
                request.structured_payload.Value);

            if (violations.Length > 0)
            {
                return new HandlerResult(StatusCodes.Status400BadRequest, new
                {
                    error_code = "INVALID_WEIGHBRIDGE_PAYLOAD",
                    violations   // non-null, non-empty
                });
            }
            storedNetWeight = backendNet;  // backend value, not client value
        }

        var existingSubmissions = EvidenceLinkSubmissionLog.ReadAll();
        var alreadySubmitted = existingSubmissions.Any(e =>
            e.TryGetProperty("instruction_id", out var iid) &&
            string.Equals(iid.GetString(), validation.InstructionId, StringComparison.Ordinal));

        if (alreadySubmitted)
        {
            return new HandlerResult(StatusCodes.Status409Conflict, new
            {
                error_code = "DUPLICATE_SUBMISSION",
                errors = new[] { "evidence for this instruction has already been submitted" },
                instruction_id = validation.InstructionId
            });
        }

        // Build payload with structured_payload and backend-computed net_weight_kg
        var payloadToStore = new Dictionary<string, object?>
        {
            ["tenant_id"] = validation.TenantId,
            ["instruction_id"] = validation.InstructionId,
            ["program_id"] = validation.ProgramId,
            ["submitter_class"] = validation.SubmitterClass,
            ["submitter_msisdn"] = validation.SubmitterMsisdn,
            ["artifact_type"] = request.artifact_type.Trim(),
            ["artifact_ref"] = request.artifact_ref.Trim(),
            ["latitude"] = request.latitude,
            ["longitude"] = request.longitude,
            ["submitted_at_utc"] = DateTimeOffset.UtcNow.ToString("O")
        };

        // Store structured_payload as raw JsonElement (not double-stringified)
        if (request.structured_payload is not null)
        {
            payloadToStore["structured_payload"] = request.structured_payload.Value;
        }

        // Store backend-computed net_weight_kg (not client value)
        if (storedNetWeight is not null)
        {
            payloadToStore["net_weight_kg"] = storedNetWeight.Value;
        }

        await EvidenceLinkSubmissionLog.AppendAsync(payloadToStore, cancellationToken);

        logger.LogInformation("Evidence submitted through secure-link for instruction {InstructionId}", validation.InstructionId);
        return new HandlerResult(StatusCodes.Status202Accepted, new
        {
            accepted = true,
            tenant_id = validation.TenantId,
            instruction_id = validation.InstructionId,
            program_id = validation.ProgramId,
            submitter_class = validation.SubmitterClass,
            submitter_msisdn = validation.SubmitterMsisdn
        });
    }

    private static string TryReadToken(HttpContext httpContext)
    {
        if (httpContext.Request.Headers.TryGetValue("x-evidence-link-token", out var explicitToken))
        {
            var token = explicitToken.ToString().Trim();
            if (!string.IsNullOrWhiteSpace(token))
            {
                return token;
            }
        }

        if (!httpContext.Request.Headers.TryGetValue("Authorization", out var auth))
        {
            return string.Empty;
        }

        var raw = auth.ToString();
        var parts = raw.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (parts.Length == 2 && string.Equals(parts[0], "Bearer", StringComparison.OrdinalIgnoreCase))
        {
            return parts[1];
        }
        return string.Empty;
    }
}

static class EvidenceLinkTokenService
{
    public static string CreateToken(
        string tenantId,
        string instructionId,
        string programId,
        string submitterClass,
        string submitterMsisdn,
        decimal? expectedLatitude,
        decimal? expectedLongitude,
        decimal? maxDistanceMeters,
        DateTimeOffset expiresAt,
        string signingKey)
    {
        var payload = JsonSerializer.Serialize(new
        {
            tenant_id = tenantId,
            instruction_id = instructionId,
            program_id = programId,
            submitter_class = submitterClass,
            submitter_msisdn = submitterMsisdn,
            expected_latitude = expectedLatitude,
            expected_longitude = expectedLongitude,
            max_distance_meters = maxDistanceMeters,
            exp = expiresAt.ToUnixTimeSeconds()
        });
        var payloadB64 = ToBase64Url(Encoding.UTF8.GetBytes(payload));
        var sig = ComputeSignature(payloadB64, signingKey);
        return $"{payloadB64}.{sig}";
    }

    public static EvidenceLinkTokenValidation ValidateToken(string token, string signingKey, DateTimeOffset now)
    {
        var parts = token.Split('.', 2, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (parts.Length != 2)
        {
            return EvidenceLinkTokenValidation.Fail("LINK_TOKEN_INVALID", "invalid token format");
        }

        var payloadB64 = parts[0];
        var providedSig = parts[1];
        var expectedSig = ComputeSignature(payloadB64, signingKey);
        if (!SecureEquals(providedSig, expectedSig))
        {
            return EvidenceLinkTokenValidation.Fail("LINK_TOKEN_INVALID", "token signature verification failed");
        }

        string json;
        try
        {
            json = Encoding.UTF8.GetString(FromBase64Url(payloadB64));
        }
        catch
        {
            return EvidenceLinkTokenValidation.Fail("LINK_TOKEN_INVALID", "token payload decode failed");
        }

        JsonDocument parsed;
        try
        {
            parsed = JsonDocument.Parse(json);
        }
        catch
        {
            return EvidenceLinkTokenValidation.Fail("LINK_TOKEN_INVALID", "token payload parse failed");
        }

        using (parsed)
        {
            var root = parsed.RootElement;
            var tenant = root.TryGetProperty("tenant_id", out var t) ? t.GetString() : null;
            var instruction = root.TryGetProperty("instruction_id", out var i) ? i.GetString() : null;
            var program = root.TryGetProperty("program_id", out var p) ? p.GetString() : null;
            var submitter = root.TryGetProperty("submitter_class", out var s) ? s.GetString() : null;
            var submitterMsisdn = root.TryGetProperty("submitter_msisdn", out var sm) ? sm.GetString() : null;
            var expectedLat = root.TryGetProperty("expected_latitude", out var lat) && lat.ValueKind != JsonValueKind.Null ? lat.GetDecimal() : (decimal?)null;
            var expectedLon = root.TryGetProperty("expected_longitude", out var lon) && lon.ValueKind != JsonValueKind.Null ? lon.GetDecimal() : (decimal?)null;
            var maxDistance = root.TryGetProperty("max_distance_meters", out var md) && md.ValueKind != JsonValueKind.Null ? md.GetDecimal() : (decimal?)null;
            var exp = root.TryGetProperty("exp", out var e) && e.TryGetInt64(out var expSec) ? expSec : 0;

            if (string.IsNullOrWhiteSpace(tenant) || string.IsNullOrWhiteSpace(instruction) || string.IsNullOrWhiteSpace(program) || string.IsNullOrWhiteSpace(submitter) || string.IsNullOrWhiteSpace(submitterMsisdn) || exp <= 0)
            {
                return EvidenceLinkTokenValidation.Fail("LINK_TOKEN_INVALID", "required claims missing");
            }

            if (now.ToUnixTimeSeconds() > exp)
            {
                return EvidenceLinkTokenValidation.Fail("LINK_TOKEN_EXPIRED", "secure link expired");
            }

            return EvidenceLinkTokenValidation.Ok(tenant!, instruction!, program!, submitter!, submitterMsisdn!, expectedLat, expectedLon, maxDistance, exp);
        }
    }

    private static string ComputeSignature(string payloadB64, string signingKey)
    {
        var key = Encoding.UTF8.GetBytes(signingKey);
        using var hmac = new HMACSHA256(key);
        var sig = hmac.ComputeHash(Encoding.UTF8.GetBytes(payloadB64));
        return ToBase64Url(sig);
    }

    private static bool SecureEquals(string a, string b)
    {
        var aa = SHA256.HashData(Encoding.UTF8.GetBytes(a ?? string.Empty));
        var bb = SHA256.HashData(Encoding.UTF8.GetBytes(b ?? string.Empty));
        return CryptographicOperations.FixedTimeEquals(aa, bb);
    }

    private static string ToBase64Url(byte[] bytes)
        => Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');

    private static byte[] FromBase64Url(string value)
    {
        var normalized = value.Replace('-', '+').Replace('_', '/');
        switch (normalized.Length % 4)
        {
            case 2: normalized += "=="; break;
            case 3: normalized += "="; break;
            case 0: break;
            default: throw new InvalidOperationException("invalid base64url length");
        }
        return Convert.FromBase64String(normalized);
    }
}

readonly record struct EvidenceLinkTokenValidation(
    bool Success,
    string? TenantId,
    string? InstructionId,
    string? ProgramId,
    string? SubmitterClass,
    string? SubmitterMsisdn,
    decimal? ExpectedLatitude,
    decimal? ExpectedLongitude,
    decimal? MaxDistanceMeters,
    long ExpiresAtUnix,
    string? ErrorCode,
    string ErrorMessage)
{
    public static EvidenceLinkTokenValidation Ok(
        string tenantId,
        string instructionId,
        string programId,
        string submitterClass,
        string submitterMsisdn,
        decimal? expectedLatitude,
        decimal? expectedLongitude,
        decimal? maxDistanceMeters,
        long expiresAtUnix)
        => new(true, tenantId, instructionId, programId, submitterClass, submitterMsisdn, expectedLatitude, expectedLongitude, maxDistanceMeters, expiresAtUnix, null, string.Empty);

    public static EvidenceLinkTokenValidation Fail(string errorCode, string errorMessage)
        => new(false, null, null, null, null, null, null, null, null, 0, errorCode, errorMessage);
}

static class EvidenceLinkSmsDispatchLog
{
    private static readonly string PathValue = Environment.GetEnvironmentVariable("EVIDENCE_LINK_SMS_DISPATCH_FILE")
        ?? "/tmp/symphony_evidence_link_sms_dispatch.ndjson";

    public static async Task AppendAsync(object payload, CancellationToken cancellationToken)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(PathValue) ?? "/tmp");
        await TamperEvidentChain.AppendJsonAsync(PathValue, "evidence_event_sms_dispatch", payload, cancellationToken);
    }
}

static class EvidenceLinkSubmissionLog
{
    private static readonly string PathValue = Environment.GetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE")
        ?? "/tmp/symphony_evidence_link_submissions.ndjson";
    private static readonly SemaphoreSlim _appendLock = new(1, 1);

    public static async Task AppendAsync(object payload, CancellationToken cancellationToken)
    {
        await _appendLock.WaitAsync(cancellationToken);
        try
        {
            var sequenceNumber = ReadAll().Count;

            // Serialize the payload to JSON, parse it, and inject sequence_number
            var payloadJson = JsonSerializer.Serialize(payload);
            using var doc = JsonDocument.Parse(payloadJson);
            var root = doc.RootElement;

            // Build a new object with sequence_number + all original properties
            var properties = new Dictionary<string, object?> { ["sequence_number"] = sequenceNumber };
            foreach (var prop in root.EnumerateObject())
            {
                properties[prop.Name] = prop.Value.ValueKind switch
                {
                    JsonValueKind.String => prop.Value.GetString(),
                    JsonValueKind.Number => prop.Value.TryGetInt32(out var i) ? (object)i :
                                           prop.Value.TryGetInt64(out var l) ? l :
                                           prop.Value.GetDecimal(),
                    JsonValueKind.True => true,
                    JsonValueKind.False => false,
                    JsonValueKind.Null => null,
                    _ => prop.Value.Clone()
                };
            }

            Directory.CreateDirectory(Path.GetDirectoryName(PathValue) ?? "/tmp");
            await TamperEvidentChain.AppendJsonAsync(PathValue, "evidence_event_submission", properties, cancellationToken);
        }
        finally
        {
            _appendLock.Release();
        }
    }

    public static IReadOnlyList<JsonElement> ReadAll()
        => NdjsonReadModel.Read(PathValue);
}

static class DemoExceptionLog
{
    private static readonly string PathValue = Environment.GetEnvironmentVariable("DEMO_EXCEPTION_LOG_FILE")
        ?? "/tmp/symphony_demo_exception_log.ndjson";

    public static async Task AppendAsync(object payload, CancellationToken cancellationToken)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(PathValue) ?? "/tmp");
        await TamperEvidentChain.AppendJsonAsync(PathValue, "evidence_event_exception", payload, cancellationToken);
    }

    public static IReadOnlyList<JsonElement> ReadAll()
        => NdjsonReadModel.Read(PathValue);
}

static class NdjsonReadModel
{
    public static IReadOnlyList<JsonElement> Read(string path)
    {
        if (!File.Exists(path))
        {
            return Array.Empty<JsonElement>();
        }

        var list = new List<JsonElement>();
        foreach (var line in File.ReadLines(path))
        {
            if (string.IsNullOrWhiteSpace(line))
            {
                continue;
            }

            try
            {
                using var doc = JsonDocument.Parse(line);
                list.Add(doc.RootElement.Clone());
            }
            catch
            {
                // Ignore malformed lines in demo-local append logs.
            }
        }

        return list;
    }
}

static class GeoMath
{
    public static decimal HaversineMeters(decimal lat1, decimal lon1, decimal lat2, decimal lon2)
    {
        const double EarthRadius = 6371000d;
        var dLat = ToRad((double)(lat2 - lat1));
        var dLon = ToRad((double)(lon2 - lon1));
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
                + Math.Cos(ToRad((double)lat1)) * Math.Cos(ToRad((double)lat2))
                * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return (decimal)(EarthRadius * c);
    }

    private static double ToRad(double degrees) => degrees * Math.PI / 180d;
}
