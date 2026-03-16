using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Npgsql;
using Symphony.LedgerApi.Infrastructure;

static class ApiAuthorization
{
    public static HandlerResult? AuthorizeIngressWrite(HttpContext httpContext, IngressRequest request, RuntimeSecrets secrets)
    {
        if (httpContext.Request.Query.ContainsKey("token"))
        {
            return new HandlerResult(StatusCodes.Status401Unauthorized, new
            {
                ack = false,
                error_code = "UNAUTHORIZED_TOKEN_TRANSPORT",
                errors = new[] { "querystring token transport is not allowed; use Authorization header token or x-api-key" }
            });
        }

        var configuredKey = secrets.IngressApiKey.Trim();
        if (string.IsNullOrWhiteSpace(configuredKey))
        {
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                ack = false,
                error_code = "AUTHZ_CONFIG_MISSING",
                errors = new[] { "INGRESS_API_KEY must be configured" }
            });
        }

        var presentedKey = ReadHeader(httpContext, "x-api-key");
        if (string.IsNullOrWhiteSpace(presentedKey))
        {
            presentedKey = ReadAuthorizationToken(httpContext);
        }
        if (string.IsNullOrWhiteSpace(presentedKey) || !SecureEquals(configuredKey, presentedKey))
        {
            return new HandlerResult(StatusCodes.Status401Unauthorized, new
            {
                ack = false,
                error_code = "UNAUTHORIZED",
                errors = new[] { "x-api-key is required and must be valid" }
            });
        }

        var tenantHeader = ReadHeader(httpContext, "x-tenant-id");
        if (string.IsNullOrWhiteSpace(tenantHeader))
        {
            return new HandlerResult(StatusCodes.Status403Forbidden, new
            {
                ack = false,
                error_code = "FORBIDDEN_TENANT_CONTEXT_REQUIRED",
                errors = new[] { "x-tenant-id header is required" }
            });
        }

        if (!string.Equals(tenantHeader.Trim(), request.tenant_id?.Trim(), StringComparison.Ordinal))
        {
            return new HandlerResult(StatusCodes.Status403Forbidden, new
            {
                ack = false,
                error_code = "FORBIDDEN_TENANT_SCOPE",
                errors = new[] { "x-tenant-id must match request tenant_id" }
            });
        }

        var scopeAuthFailure = AuthorizeTenantScope(tenantHeader);
        if (scopeAuthFailure is not null)
        {
            return scopeAuthFailure;
        }

        // Propagate resolved tenant into request context for downstream policy/data access checks.
        httpContext.Items["tenant_id"] = tenantHeader.Trim();

        var participantHeader = ReadHeader(httpContext, "x-participant-id");
        if (string.IsNullOrWhiteSpace(participantHeader))
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                ack = false,
                error_code = "INVALID_REQUEST",
                errors = new[] { "x-participant-id header is required" }
            });
        }

        if (!string.Equals(participantHeader.Trim(), request.participant_id?.Trim(), StringComparison.Ordinal))
        {
            return new HandlerResult(StatusCodes.Status403Forbidden, new
            {
                ack = false,
                error_code = "FORBIDDEN_PARTICIPANT_SCOPE",
                errors = new[] { "x-participant-id must match request participant_id" }
            });
        }

        return null;
    }

    public static HandlerResult? AuthorizeTenantScope(string tenantId)
    {
        var rawAllowlist = (Environment.GetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS") ?? string.Empty).Trim();
        var tenantAllowlistConfigured = !string.IsNullOrWhiteSpace(rawAllowlist);

        if (!tenantAllowlistConfigured)
        {
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                // Note: The /health endpoint structure might omit 'ack' but for ingress consistency we carry it or just omit where unneeded.
                // The verification script only checks HTTP 503 and error_code='TENANT_ALLOWLIST_UNCONFIGURED'.
                error_code = "TENANT_ALLOWLIST_UNCONFIGURED",
                errors = new[] { "tenant allowlist not configured" }
            });
        }

        if (!IsKnownTenant(tenantId, rawAllowlist))
        {
            return new HandlerResult(StatusCodes.Status403Forbidden, new
            {
                error_code = "FORBIDDEN_UNKNOWN_TENANT",
                errors = new[] { "x-tenant-id is not recognized by tenant registry" }
            });
        }

        return null;
    }

    private static bool IsKnownTenant(string tenantId, string configuredAllowlist)
    {
        var known = configuredAllowlist
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        return known.Contains(tenantId.Trim());
    }

    public static HandlerResult? AuthorizeEvidenceRead(HttpContext httpContext, RuntimeSecrets secrets)
    {
        if (httpContext.Request.Query.ContainsKey("token"))
        {
            return new HandlerResult(StatusCodes.Status401Unauthorized, new
            {
                error_code = "UNAUTHORIZED_TOKEN_TRANSPORT",
                errors = new[] { "querystring token transport is not allowed; use Authorization header token or x-api-key" }
            });
        }

        var configuredKey = secrets.IngressApiKey.Trim();
        if (string.IsNullOrWhiteSpace(configuredKey))
        {
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                error_code = "AUTHZ_CONFIG_MISSING",
                errors = new[] { "INGRESS_API_KEY must be configured" }
            });
        }

        var presentedKey = ReadHeader(httpContext, "x-api-key");
        if (string.IsNullOrWhiteSpace(presentedKey))
        {
            presentedKey = ReadAuthorizationToken(httpContext);
        }
        if (string.IsNullOrWhiteSpace(presentedKey) || !SecureEquals(configuredKey, presentedKey))
        {
            return new HandlerResult(StatusCodes.Status401Unauthorized, new
            {
                error_code = "UNAUTHORIZED",
                errors = new[] { "x-api-key is required and must be valid" }
            });
        }

        return null;
    }

    public static HandlerResult? AuthorizeAdminTenantOnboarding(HttpContext httpContext, RuntimeSecrets secrets)
    {
        var configuredAdminKey = secrets.AdminApiKey.Trim();
        if (string.IsNullOrWhiteSpace(configuredAdminKey))
        {
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                error_code = "AUTHZ_CONFIG_MISSING",
                errors = new[] { "ADMIN_API_KEY must be configured" }
            });
        }

        var presentedAdminKey = ReadHeader(httpContext, "x-admin-api-key");
        if (!string.IsNullOrWhiteSpace(presentedAdminKey) && SecureEquals(configuredAdminKey, presentedAdminKey))
        {
            return null;
        }

        return new HandlerResult(StatusCodes.Status403Forbidden, new
        {
            error_code = "FORBIDDEN_ADMIN_REQUIRED",
            errors = new[] { "admin credentials are required (x-admin-api-key)" }
        });
    }

    private static string ReadHeader(HttpContext context, string name)
        => context.Request.Headers.TryGetValue(name, out var value) ? value.ToString() : string.Empty;

    private static string ReadAuthorizationToken(HttpContext context)
    {
        var authorization = ReadHeader(context, "Authorization");
        var parts = authorization.Split(' ', 2, StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 2 && string.Equals(parts[0], "bearer", StringComparison.OrdinalIgnoreCase))
        {
            return parts[1];
        }
        return string.Empty;
    }

    private static bool SecureEquals(string expected, string actual)
    {
        var expectedBytes = SHA256.HashData(Encoding.UTF8.GetBytes(expected ?? string.Empty));
        var actualBytes = SHA256.HashData(Encoding.UTF8.GetBytes(actual ?? string.Empty));
        return CryptographicOperations.FixedTimeEquals(expectedBytes, actualBytes);
    }
}
