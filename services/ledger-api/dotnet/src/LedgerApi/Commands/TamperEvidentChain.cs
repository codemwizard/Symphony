using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Collections.Concurrent;

sealed record ChainRecord(
    string domain,
    string current_hash,
    string? previous_hash,
    string payload_hash,
    string generated_at_utc,
    string commit_boundary
);

sealed record ChainVerificationResult(
    bool Pass,
    string? ErrorCode,
    string? Message
)
{
    public static ChainVerificationResult Ok() => new(true, null, null);
    public static ChainVerificationResult Fail(string errorCode, string message) => new(false, errorCode, message);
}

static class TamperEvidentChain
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        WriteIndented = true
    };
    private static readonly ConcurrentDictionary<string, SemaphoreSlim> FileLocks = new(StringComparer.Ordinal);

    public static bool Enabled =>
        !string.Equals(Environment.GetEnvironmentVariable("SYMPHONY_CHAIN_POPULATION"), "0", StringComparison.Ordinal);

    public static async Task AppendJsonAsync(string path, string domain, object payload, CancellationToken cancellationToken)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path) ?? "/tmp");
        var fileLock = FileLocks.GetOrAdd(path, _ => new SemaphoreSlim(1, 1));
        await fileLock.WaitAsync(cancellationToken);
        try
        {
            var envelope = await BuildEnvelopeAsync(path, domain, payload, cancellationToken);
            await File.AppendAllTextAsync(path, JsonSerializer.Serialize(envelope) + Environment.NewLine, cancellationToken);
        }
        finally
        {
            fileLock.Release();
        }
    }

    public static async Task WriteJsonAsync(string path, string domain, object payload, CancellationToken cancellationToken)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path) ?? "/tmp");
        var fileLock = FileLocks.GetOrAdd(path, _ => new SemaphoreSlim(1, 1));
        await fileLock.WaitAsync(cancellationToken);
        try
        {
            var envelope = await BuildEnvelopeAsync(path, domain, payload, cancellationToken);
            await File.WriteAllTextAsync(path, JsonSerializer.Serialize(envelope, SerializerOptions) + Environment.NewLine, cancellationToken);
        }
        finally
        {
            fileLock.Release();
        }
    }

    public static ChainVerificationResult VerifyJsonFile(string path, string expectedDomain)
    {
        if (!File.Exists(path))
        {
            return ChainVerificationResult.Fail("FILE_MISSING", $"Missing file: {path}");
        }

        try
        {
            var node = JsonNode.Parse(File.ReadAllText(path)) as JsonObject;
            if (node is null)
            {
                return ChainVerificationResult.Fail("JSON_INVALID", "JSON object required");
            }

            return VerifyNode(node, expectedDomain, null);
        }
        catch (Exception ex)
        {
            return ChainVerificationResult.Fail("JSON_INVALID", ex.Message);
        }
    }

    public static ChainVerificationResult VerifyNdjsonFile(string path, string expectedDomain)
    {
        if (!File.Exists(path))
        {
            return ChainVerificationResult.Fail("FILE_MISSING", $"Missing file: {path}");
        }

        string? previousHash = null;
        foreach (var line in File.ReadLines(path))
        {
            if (string.IsNullOrWhiteSpace(line))
            {
                continue;
            }

            JsonObject? node;
            try
            {
                node = JsonNode.Parse(line) as JsonObject;
            }
            catch (Exception ex)
            {
                return ChainVerificationResult.Fail("JSON_INVALID", ex.Message);
            }

            if (node is null)
            {
                return ChainVerificationResult.Fail("JSON_INVALID", "NDJSON object required");
            }

            var currentHash = node["chain_record"]?["current_hash"]?.GetValue<string>();
            var result = VerifyNode(node, expectedDomain, previousHash);
            if (!result.Pass)
            {
                return result;
            }

            previousHash = currentHash;
        }

        return ChainVerificationResult.Ok();
    }

    private static async Task<JsonObject> BuildEnvelopeAsync(string path, string domain, object payload, CancellationToken cancellationToken)
    {
        var envelope = JsonNode.Parse(JsonSerializer.Serialize(payload))?.AsObject()
            ?? throw new InvalidOperationException("Unable to serialize payload envelope");

        if (!Enabled)
        {
            return envelope;
        }

        var canonicalPayload = JsonSerializer.Serialize(envelope);
        var payloadHash = ComputeHash(canonicalPayload);
        var previousHash = await ReadLastHashAsync(path, cancellationToken);
        var currentHash = ComputeHash($"{domain}\n{previousHash ?? string.Empty}\n{payloadHash}");
        var chainRecord = new ChainRecord(
            domain: domain,
            current_hash: currentHash,
            previous_hash: previousHash,
            payload_hash: payloadHash,
            generated_at_utc: DateTimeOffset.UtcNow.ToString("O"),
            commit_boundary: "single_write_envelope");

        envelope["chain_record"] = JsonSerializer.SerializeToNode(chainRecord);
        return envelope;
    }

    private static async Task<string?> ReadLastHashAsync(string path, CancellationToken cancellationToken)
    {
        if (!File.Exists(path))
        {
            return null;
        }

        var lines = await File.ReadAllLinesAsync(path, cancellationToken);
        for (var i = lines.Length - 1; i >= 0; i--)
        {
            if (string.IsNullOrWhiteSpace(lines[i]))
            {
                continue;
            }

            try
            {
                var node = JsonNode.Parse(lines[i]) as JsonObject;
                var currentHash = node?["chain_record"]?["current_hash"]?.GetValue<string>();
                if (!string.IsNullOrWhiteSpace(currentHash))
                {
                    return currentHash;
                }
            }
            catch
            {
                return null;
            }
        }

        return null;
    }

    private static ChainVerificationResult VerifyNode(JsonObject node, string expectedDomain, string? expectedPreviousHash)
    {
        var chainNode = node["chain_record"] as JsonObject;
        if (chainNode is null)
        {
            return ChainVerificationResult.Fail("CHAIN_RECORD_MISSING", "chain_record is required");
        }

        var domain = chainNode["domain"]?.GetValue<string>();
        var currentHash = chainNode["current_hash"]?.GetValue<string>();
        var previousHash = chainNode["previous_hash"]?.GetValue<string>();
        var payloadHash = chainNode["payload_hash"]?.GetValue<string>();
        var commitBoundary = chainNode["commit_boundary"]?.GetValue<string>();
        if (!string.Equals(domain, expectedDomain, StringComparison.Ordinal))
        {
            return ChainVerificationResult.Fail("CHAIN_DOMAIN_INVALID", $"expected {expectedDomain}, got {domain ?? "<null>"}");
        }

        if (string.IsNullOrWhiteSpace(currentHash) || string.IsNullOrWhiteSpace(payloadHash))
        {
            return ChainVerificationResult.Fail("CHAIN_FIELDS_MISSING", "current_hash and payload_hash are required");
        }

        if (!string.Equals(commitBoundary, "single_write_envelope", StringComparison.Ordinal))
        {
            return ChainVerificationResult.Fail("CHAIN_BOUNDARY_INVALID", "commit_boundary must be single_write_envelope");
        }

        if (expectedPreviousHash != previousHash)
        {
            return ChainVerificationResult.Fail("CHAIN_PREVIOUS_HASH_INVALID", "previous_hash does not match the prior record");
        }

        var payloadNode = node.DeepClone() as JsonObject ?? new JsonObject();
        payloadNode.Remove("chain_record");
        var canonicalPayload = JsonSerializer.Serialize(payloadNode);
        var actualPayloadHash = ComputeHash(canonicalPayload);
        if (!string.Equals(actualPayloadHash, payloadHash, StringComparison.Ordinal))
        {
            return ChainVerificationResult.Fail("CHAIN_PAYLOAD_HASH_INVALID", "payload hash mismatch");
        }

        var actualCurrentHash = ComputeHash($"{expectedDomain}\n{previousHash ?? string.Empty}\n{payloadHash}");
        if (!string.Equals(actualCurrentHash, currentHash, StringComparison.Ordinal))
        {
            return ChainVerificationResult.Fail("CHAIN_CURRENT_HASH_INVALID", "current hash mismatch");
        }

        return ChainVerificationResult.Ok();
    }

    private static string ComputeHash(string value)
        => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value))).ToLowerInvariant();
}
