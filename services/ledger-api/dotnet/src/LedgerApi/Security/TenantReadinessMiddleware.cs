using System.Text.Json;
using Microsoft.AspNetCore.Http;

/// <summary>
/// Global middleware that enforces the "System Readiness First" principle:
/// tenant readiness (503) is checked BEFORE any authentication (401/403).
///
/// This ensures that when no tenants are configured, the system returns
/// 503 TENANT_ALLOWLIST_UNCONFIGURED rather than misleading 403 errors.
///
/// Excluded paths (always pass through):
///   - /health, /healthz, /readyz  (probes)
///   - POST /v1/admin/tenants      (bootstrap: create first tenant)
///   - /pilot-demo/pilot/*         (UI page serving)
///   - /pilot-demo/api/session/*   (session management)
///   - Static assets (css, js)
/// </summary>
sealed class TenantReadinessMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ITenantReadinessProbe _probe;

    public TenantReadinessMiddleware(RequestDelegate next, ITenantReadinessProbe probe)
    {
        _next = next;
        _probe = probe;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Fast path: if tenant system is ready, skip all checks
        if (_probe.IsReady)
        {
            await _next(context);
            return;
        }

        var path = context.Request.Path.Value ?? string.Empty;
        var method = context.Request.Method;

        // Excluded paths — always pass through even when not ready
        if (IsExcludedPath(path, method))
        {
            await _next(context);
            return;
        }

        // System is not ready and this is a tenant-scoped request → 503
        context.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new
        {
            error_code = "TENANT_ALLOWLIST_UNCONFIGURED",
            errors = new[] { "tenant allowlist not configured" }
        });
    }

    private static bool IsExcludedPath(string path, string method)
    {
        // Health probes
        if (path.Equals("/health", StringComparison.OrdinalIgnoreCase) ||
            path.Equals("/healthz", StringComparison.OrdinalIgnoreCase) ||
            path.Equals("/readyz", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        // Bootstrap endpoint: creating the first tenant must work even when unconfigured
        if (path.Equals("/v1/admin/tenants", StringComparison.OrdinalIgnoreCase) &&
            method.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        // Pilot-demo UI pages and static assets (served as HTML, not API calls)
        if (path.StartsWith("/pilot-demo/pilot/", StringComparison.OrdinalIgnoreCase) ||
            path.Equals("/pilot-demo/pilot", StringComparison.OrdinalIgnoreCase) ||
            path.Equals("/pilot-demo/supervisory", StringComparison.OrdinalIgnoreCase) ||
            path.Equals("/pilot-demo/supervisory-legacy", StringComparison.OrdinalIgnoreCase) ||
            path.Equals("/pilot-demo/evidence-link", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        // Pilot-demo session management (needed to establish context before API calls)
        if (path.StartsWith("/pilot-demo/api/session/", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        return false;
    }
}
