using Npgsql;

/// <summary>
/// Abstracts the tenant readiness check so that production (env-var) and
/// pilot-demo (DB-backed) profiles can use different resolution strategies
/// without coupling production code to pilot-demo internals.
/// </summary>
interface ITenantReadinessProbe
{
    /// <summary>
    /// Returns true when at least one tenant is configured and the system
    /// is ready to serve tenant-scoped requests.
    /// </summary>
    bool IsReady { get; }

    /// <summary>
    /// Signal that the system has become ready (e.g. after seeding the first tenant).
    /// No-op for probes that derive readiness from static config.
    /// </summary>
    void MarkReady();

    /// <summary>
    /// Re-evaluate readiness from its source (env var, database, etc.).
    /// </summary>
    Task RefreshAsync(CancellationToken cancellationToken);
}

/// <summary>
/// Production/staging probe: readiness is derived from the SYMPHONY_KNOWN_TENANTS
/// environment variable. If the env var is set and non-empty, the system is ready.
/// This probe has no dependency on pilot-demo or any database table.
/// </summary>
sealed class EnvVarTenantReadinessProbe : ITenantReadinessProbe
{
    private volatile bool _isReady;

    public bool IsReady => _isReady;

    public EnvVarTenantReadinessProbe()
    {
        _isReady = EvaluateEnvVar();
    }

    public void MarkReady()
    {
        // For env-var probe, MarkReady is a no-op.
        // Readiness is determined entirely by the env var at startup.
    }

    public Task RefreshAsync(CancellationToken cancellationToken)
    {
        _isReady = EvaluateEnvVar();
        return Task.CompletedTask;
    }

    private static bool EvaluateEnvVar()
    {
        var rawAllowlist = (Environment.GetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS") ?? string.Empty).Trim();
        return !string.IsNullOrWhiteSpace(rawAllowlist);
    }
}

/// <summary>
/// Pilot-demo probe: readiness is derived from the tenant_registry database table.
/// The system is ready when at least one ACTIVE tenant exists.
/// This implementation is only instantiated when runtimeProfile == "pilot-demo".
/// Production code paths NEVER use this class.
/// </summary>
sealed class DatabaseTenantReadinessProbe : ITenantReadinessProbe
{
    private readonly ILogger _logger;
    private readonly NpgsqlDataSource _dataSource;
    private volatile bool _isReady;

    public bool IsReady => _isReady;

    public DatabaseTenantReadinessProbe(ILogger logger, NpgsqlDataSource dataSource)
    {
        _logger = logger;
        _dataSource = dataSource;
    }

    public void MarkReady()
    {
        _isReady = true;
        _logger.LogInformation("Tenant readiness probe: marked ready (tenant seeded).");
    }

    public async Task RefreshAsync(CancellationToken cancellationToken)
    {
        try
        {
            await using var conn = await _dataSource.OpenConnectionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            // Bypass RLS for this system-level probe
            cmd.CommandText = "SELECT set_config('app.bypass_rls', 'on', true)";
            await cmd.ExecuteScalarAsync(cancellationToken);

            cmd.CommandText = @"
SELECT EXISTS(
  SELECT 1 FROM public.tenant_registry
  WHERE status = 'ACTIVE'
  LIMIT 1
);";
            var result = await cmd.ExecuteScalarAsync(cancellationToken);
            _isReady = result is true;
            _logger.LogInformation("Tenant readiness probe refreshed from database: IsReady={IsReady}", _isReady);
        }
        catch (Exception ex)
        {
            // If the table doesn't exist yet (e.g. migrations haven't run),
            // we are definitively not ready.
            _logger.LogWarning(ex, "Tenant readiness probe: database check failed, marking not ready.");
            _isReady = false;
        }
    }
}
