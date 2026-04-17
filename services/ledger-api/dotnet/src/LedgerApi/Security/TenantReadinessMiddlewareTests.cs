using System.Text.Json;
using Microsoft.AspNetCore.Http;

/// <summary>
/// Unit tests for TenantReadinessMiddleware and ITenantReadinessProbe implementations.
/// TSK-P1-TEN-RDY: Validates the 503-before-403 invariant and probe behavior.
/// </summary>
static class TenantReadinessMiddlewareTests
{
    public static async Task<(int Passed, int Failed, List<string> Failures)> RunAllAsync()
    {
        int passed = 0;
        int failed = 0;
        var failures = new List<string>();

        async Task RunTest(string name, Func<Task<bool>> test)
        {
            try
            {
                if (await test())
                {
                    passed++;
                }
                else
                {
                    failed++;
                    failures.Add($"FAIL: {name}");
                }
            }
            catch (Exception ex)
            {
                failed++;
                failures.Add($"FAIL: {name} — {ex.GetType().Name}: {ex.Message}");
            }
        }

        // Probe tests
        await RunTest("EnvVar_EmptyEnv_NotReady", Test_EnvVar_EmptyEnv_NotReady);
        await RunTest("EnvVar_PopulatedEnv_Ready", Test_EnvVar_PopulatedEnv_Ready);
        await RunTest("EnvVar_MarkReady_NoOp", Test_EnvVar_MarkReady_NoOp);

        // Middleware routing tests
        await RunTest("Middleware_NotReady_V1Path_Returns503", Test_Middleware_NotReady_V1Path_Returns503);
        await RunTest("Middleware_NotReady_HealthPath_Passthrough", Test_Middleware_NotReady_HealthPath_Passthrough);
        await RunTest("Middleware_NotReady_HealthzPath_Passthrough", Test_Middleware_NotReady_HealthzPath_Passthrough);
        await RunTest("Middleware_NotReady_ReadyzPath_Passthrough", Test_Middleware_NotReady_ReadyzPath_Passthrough);
        await RunTest("Middleware_NotReady_BootstrapEndpoint_Passthrough", Test_Middleware_NotReady_BootstrapEndpoint_Passthrough);
        await RunTest("Middleware_NotReady_PilotUiPath_Passthrough", Test_Middleware_NotReady_PilotUiPath_Passthrough);
        await RunTest("Middleware_NotReady_SessionPath_Passthrough", Test_Middleware_NotReady_SessionPath_Passthrough);
        await RunTest("Middleware_Ready_V1Path_Passthrough", Test_Middleware_Ready_V1Path_Passthrough);
        await RunTest("Middleware_503Body_HasCorrectErrorCode", Test_Middleware_503Body_HasCorrectErrorCode);

        return (passed, failed, failures);
    }

    // ── Probe Tests ───────────────────────────────────────────────────

    private static Task<bool> Test_EnvVar_EmptyEnv_NotReady()
    {
        var original = Environment.GetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS");
        try
        {
            Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", "");
            var probe = new EnvVarTenantReadinessProbe();
            return Task.FromResult(!probe.IsReady);
        }
        finally
        {
            Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", original);
        }
    }

    private static Task<bool> Test_EnvVar_PopulatedEnv_Ready()
    {
        var original = Environment.GetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS");
        try
        {
            Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", "tenant-a,tenant-b");
            var probe = new EnvVarTenantReadinessProbe();
            return Task.FromResult(probe.IsReady);
        }
        finally
        {
            Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", original);
        }
    }

    private static Task<bool> Test_EnvVar_MarkReady_NoOp()
    {
        var original = Environment.GetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS");
        try
        {
            Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", "");
            var probe = new EnvVarTenantReadinessProbe();
            probe.MarkReady(); // Should be a no-op
            // Still not ready because env var is empty
            return Task.FromResult(!probe.IsReady);
        }
        finally
        {
            Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", original);
        }
    }

    // ── Middleware Routing Tests ───────────────────────────────────────

    private static async Task<bool> Test_Middleware_NotReady_V1Path_Returns503()
    {
        var probe = new TestProbe(isReady: false);
        var (statusCode, _) = await InvokeMiddleware(probe, "GET", "/v1/evidence-packs/test-123");
        return statusCode == 503;
    }

    private static async Task<bool> Test_Middleware_NotReady_HealthPath_Passthrough()
    {
        var probe = new TestProbe(isReady: false);
        var (statusCode, _) = await InvokeMiddleware(probe, "GET", "/health");
        return statusCode == 200; // passthrough to terminal handler
    }

    private static async Task<bool> Test_Middleware_NotReady_HealthzPath_Passthrough()
    {
        var probe = new TestProbe(isReady: false);
        var (statusCode, _) = await InvokeMiddleware(probe, "GET", "/healthz");
        return statusCode == 200;
    }

    private static async Task<bool> Test_Middleware_NotReady_ReadyzPath_Passthrough()
    {
        var probe = new TestProbe(isReady: false);
        var (statusCode, _) = await InvokeMiddleware(probe, "GET", "/readyz");
        return statusCode == 200;
    }

    private static async Task<bool> Test_Middleware_NotReady_BootstrapEndpoint_Passthrough()
    {
        var probe = new TestProbe(isReady: false);
        var (statusCode, _) = await InvokeMiddleware(probe, "POST", "/v1/admin/tenants");
        return statusCode == 200; // passthrough — bootstrap allowed
    }

    private static async Task<bool> Test_Middleware_NotReady_PilotUiPath_Passthrough()
    {
        var probe = new TestProbe(isReady: false);
        var (statusCode, _) = await InvokeMiddleware(probe, "GET", "/pilot-demo/pilot/overview");
        return statusCode == 200;
    }

    private static async Task<bool> Test_Middleware_NotReady_SessionPath_Passthrough()
    {
        var probe = new TestProbe(isReady: false);
        var (statusCode, _) = await InvokeMiddleware(probe, "POST", "/pilot-demo/api/session/switch");
        return statusCode == 200;
    }

    private static async Task<bool> Test_Middleware_Ready_V1Path_Passthrough()
    {
        var probe = new TestProbe(isReady: true);
        var (statusCode, _) = await InvokeMiddleware(probe, "GET", "/v1/evidence-packs/test-123");
        return statusCode == 200; // passthrough when ready
    }

    private static async Task<bool> Test_Middleware_503Body_HasCorrectErrorCode()
    {
        var probe = new TestProbe(isReady: false);
        var (statusCode, body) = await InvokeMiddleware(probe, "GET", "/v1/evidence-packs/test-123");
        if (statusCode != 503) return false;

        using var doc = JsonDocument.Parse(body);
        var errorCode = doc.RootElement.GetProperty("error_code").GetString();
        return errorCode == "TENANT_ALLOWLIST_UNCONFIGURED";
    }

    // ── Test Infrastructure ──────────────────────────────────────────

    private sealed class TestProbe : ITenantReadinessProbe
    {
        public bool IsReady { get; private set; }

        public TestProbe(bool isReady)
        {
            IsReady = isReady;
        }

        public void MarkReady() => IsReady = true;
        public Task RefreshAsync(CancellationToken ct) => Task.CompletedTask;
    }

    private static async Task<(int StatusCode, string Body)> InvokeMiddleware(
        ITenantReadinessProbe probe, string method, string path)
    {
        var context = new DefaultHttpContext();
        context.Request.Method = method;
        context.Request.Path = path;
        context.Response.Body = new MemoryStream();

        RequestDelegate terminal = ctx =>
        {
            ctx.Response.StatusCode = 200;
            return Task.CompletedTask;
        };

        var middleware = new TenantReadinessMiddleware(terminal, probe);
        await middleware.InvokeAsync(context);

        context.Response.Body.Seek(0, SeekOrigin.Begin);
        var body = await new StreamReader(context.Response.Body).ReadToEndAsync();
        return (context.Response.StatusCode, body);
    }
}
