using System.Text.Json;
using Npgsql;

static class StorageModePolicy
{
    private static readonly HashSet<string> AllowedModes = new(StringComparer.OrdinalIgnoreCase)
    {
        "file",
        "db",
        "db_psql",
        "db_npgsql"
    };

    public static bool IsDatabaseMode(string storageMode) =>
        string.Equals(storageMode, "db", StringComparison.OrdinalIgnoreCase) ||
        string.Equals(storageMode, "db_psql", StringComparison.OrdinalIgnoreCase) ||
        string.Equals(storageMode, "db_npgsql", StringComparison.OrdinalIgnoreCase);

    public static void ValidateOrThrow(string storageMode)
    {
        if (!AllowedModes.Contains(storageMode))
        {
            throw new InvalidOperationException($"Unsupported INGRESS_STORAGE_MODE '{storageMode}'. Allowed: file, db, db_psql, db_npgsql.");
        }

        if (!string.Equals(storageMode, "file", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var environment = (Environment.GetEnvironmentVariable("ENVIRONMENT") ?? "local").Trim().ToLowerInvariant();
        if (environment is "staging" or "pilot" or "prod")
        {
            throw new InvalidOperationException($"INGRESS_STORAGE_MODE=file is blocked in ENVIRONMENT={environment}.");
        }
    }
}

static class DbDataSourceFactory
{
    public static NpgsqlDataSource Create(ILogger logger)
    {
        var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
        if (string.IsNullOrWhiteSpace(databaseUrl))
        {
            throw new InvalidOperationException("DATABASE_URL is required for db/db_psql/db_npgsql storage modes.");
        }

        logger.LogInformation("Initializing pooled PostgreSQL datasource for ingress/evidence path.");
        var normalized = NormalizeConnectionString(databaseUrl);
        var builder = new NpgsqlDataSourceBuilder(normalized);
        return builder.Build();
    }

    private static string NormalizeConnectionString(string raw)
    {
        if (!raw.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase)
            && !raw.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase))
        {
            return raw;
        }

        var uri = new Uri(raw);
        var builder = new NpgsqlConnectionStringBuilder
        {
            Host = uri.Host,
            Port = uri.Port > 0 ? uri.Port : 5432,
            Database = uri.AbsolutePath.Trim('/'),
        };

        if (!string.IsNullOrWhiteSpace(uri.UserInfo))
        {
            var userParts = uri.UserInfo.Split(':', 2);
            if (userParts.Length > 0)
            {
                builder.Username = Uri.UnescapeDataString(userParts[0]);
            }

            if (userParts.Length > 1)
            {
                builder.Password = Uri.UnescapeDataString(userParts[1]);
            }
        }

        var query = uri.Query.TrimStart('?');
        if (!string.IsNullOrWhiteSpace(query))
        {
            foreach (var segment in query.Split('&', StringSplitOptions.RemoveEmptyEntries))
            {
                var kv = segment.Split('=', 2);
                if (kv.Length != 2)
                {
                    continue;
                }

                var key = Uri.UnescapeDataString(kv[0]);
                var value = Uri.UnescapeDataString(kv[1]);
                if (string.Equals(key, "sslmode", StringComparison.OrdinalIgnoreCase))
                {
                    builder.SslMode = Enum.TryParse<SslMode>(value, true, out var sslMode)
                        ? sslMode
                        : builder.SslMode;
                }
            }
        }

        return builder.ToString();
    }
}

static class DbValueParsers
{
    public static Guid ParseRequiredUuid(string? raw, string fieldName)
    {
        if (string.IsNullOrWhiteSpace(raw) || !Guid.TryParse(raw, out var parsed))
        {
            throw new InvalidOperationException($"{fieldName} must be a valid UUID.");
        }

        return parsed;
    }

    public static object ParseOptionalUuid(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return DBNull.Value;
        }

        if (Guid.TryParse(raw, out var parsed))
        {
            return parsed;
        }

        throw new InvalidOperationException("correlation_id must be a valid UUID when provided.");
    }

    public static string? EmptyToNull(string value) => string.IsNullOrWhiteSpace(value) ? null : value;
    public static string EmptyToUnknown(string value) => string.IsNullOrWhiteSpace(value) ? "UNKNOWN" : value;
}

record SelfTestCase(string Name, string Status, string Detail);

static class ProjectionMeta
{
    public const string Version = "phase1-cqrs-v1";

    public static string AsOfUtc() => DateTimeOffset.UtcNow.ToString("O");
}

static class ProjectionFiles
{
    public static string InstructionStatusPath() =>
        Environment.GetEnvironmentVariable("INSTRUCTION_STATUS_PROJECTION_FILE")
        ?? "/tmp/symphony_instruction_status_projection.ndjson";

    public static string EvidenceBundlePath() =>
        Environment.GetEnvironmentVariable("EVIDENCE_BUNDLE_PROJECTION_FILE")
        ?? "/tmp/symphony_evidence_bundle_projection.ndjson";

    public static string IncidentCasePath() =>
        Environment.GetEnvironmentVariable("INCIDENT_CASE_PROJECTION_FILE")
        ?? "/tmp/symphony_incident_case_projection.ndjson";

    public static async Task UpsertByKeyAsync(string path, string keyField, string keyValue, object payload, CancellationToken cancellationToken)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path) ?? "/tmp");
        var lines = File.Exists(path)
            ? (await File.ReadAllLinesAsync(path, cancellationToken)).ToList()
            : new List<string>();

        var serialized = JsonSerializer.Serialize(payload);
        var replaced = false;
        for (var i = 0; i < lines.Count; i++)
        {
            var line = lines[i];
            if (string.IsNullOrWhiteSpace(line))
            {
                continue;
            }

            using var doc = JsonDocument.Parse(line);
            if (!doc.RootElement.TryGetProperty(keyField, out var keyProp))
            {
                continue;
            }

            if (!string.Equals(keyProp.GetString(), keyValue, StringComparison.Ordinal))
            {
                continue;
            }

            lines[i] = serialized;
            replaced = true;
            break;
        }

        if (!replaced)
        {
            lines.Add(serialized);
        }

        await File.WriteAllTextAsync(path, string.Join(Environment.NewLine, lines) + Environment.NewLine, cancellationToken);
    }
}
