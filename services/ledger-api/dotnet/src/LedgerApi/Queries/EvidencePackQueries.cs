using System.Text.Json;
using Npgsql;

record EvidenceLookupResult(bool Found, EvidencePack? Pack)
{
    public static EvidenceLookupResult Hit(EvidencePack pack) => new(true, pack);
    public static EvidenceLookupResult Miss() => new(false, null);
}

interface IEvidencePackStore
{
    Task<EvidenceLookupResult> FindAsync(string instructionId, string tenantId, CancellationToken cancellationToken);
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

sealed class FileEvidencePackStore(ILogger logger, string? path = null) : IEvidencePackStore
{
    private readonly string _path = path ?? ProjectionFiles.EvidenceBundlePath();

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

                var pack = JsonSerializer.Deserialize<EvidencePack>(line);
                if (pack is null)
                {
                    continue;
                }

                if (!string.Equals(pack.instruction_id, instructionId, StringComparison.Ordinal))
                {
                    continue;
                }

                if (!string.Equals(pack.tenant_id, tenantId, StringComparison.Ordinal))
                {
                    return EvidenceLookupResult.Miss();
                }

                return EvidenceLookupResult.Hit(pack);
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to read evidence pack projection from file store.");
            return EvidenceLookupResult.Miss();
        }

        return EvidenceLookupResult.Miss();
    }
}

sealed class NpgsqlEvidencePackStore(ILogger logger, NpgsqlDataSource dataSource) : IEvidencePackStore
{
    public async Task<EvidenceLookupResult> FindAsync(string instructionId, string tenantId, CancellationToken cancellationToken)
    {
        const string sql = @"
SELECT projection_payload::text
FROM public.evidence_bundle_projection
WHERE instruction_id = @instruction_id
  AND tenant_id = @tenant_id
LIMIT 1;";

        try
        {
            await using var conn = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = sql;
            cmd.Parameters.AddWithValue("instruction_id", instructionId);
            cmd.Parameters.AddWithValue("tenant_id", DbValueParsers.ParseRequiredUuid(tenantId, "tenant_id"));
            var payload = await cmd.ExecuteScalarAsync(cancellationToken);
            if (payload is null)
            {
                return EvidenceLookupResult.Miss();
            }

            var json = payload.ToString();
            if (string.IsNullOrWhiteSpace(json))
            {
                return EvidenceLookupResult.Miss();
            }

            return EvidenceLookupResult.Hit(JsonSerializer.Deserialize<EvidencePack>(json)!);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Npgsql evidence pack projection query failed.");
            return EvidenceLookupResult.Miss();
        }
    }
}
