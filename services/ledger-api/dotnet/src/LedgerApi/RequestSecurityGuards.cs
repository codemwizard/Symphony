using System.Buffers;
using Microsoft.AspNetCore.Http;

public static class RequestSecurityGuards
{
    public const string ForceAttestationFailHeader = "x-symphony-force-attestation-fail";

    public static string BuildRateLimitPartitionKey(HttpContext context)
    {
        var tenant = ReadHeader(context.Request, "x-tenant-id");
        var clientIp = context.Connection.RemoteIpAddress?.ToString();
        if (string.IsNullOrWhiteSpace(clientIp))
        {
            clientIp = ReadForwardedFor(context.Request);
        }

        var normalizedTenant = string.IsNullOrWhiteSpace(tenant) ? "no-tenant" : tenant.Trim().ToLowerInvariant();
        var normalizedIp = string.IsNullOrWhiteSpace(clientIp) ? "unknown-ip" : clientIp.Trim();
        return $"{normalizedTenant}|{normalizedIp}";
    }

    public static bool IsDevOrCi(string? profile)
    {
        if (string.IsNullOrWhiteSpace(profile))
        {
            return false;
        }

        var normalized = profile.Trim().ToLowerInvariant();
        return normalized is "development" or "dev" or "ci";
    }

    public static bool DevOnlyHeadersPresent(HttpRequest request)
    {
        return request.Headers.ContainsKey(ForceAttestationFailHeader);
    }

    public static async Task<bool> IsBodyTooLargeAsync(HttpRequest request, long maxBodyBytes, CancellationToken cancellationToken)
    {
        if (maxBodyBytes <= 0)
        {
            return false;
        }

        if (request.ContentLength is long contentLength)
        {
            return contentLength > maxBodyBytes;
        }

        if (!(HttpMethods.IsPost(request.Method) || HttpMethods.IsPut(request.Method) || HttpMethods.IsPatch(request.Method)))
        {
            return false;
        }

        request.EnableBuffering();

        long totalRead = 0;
        const int defaultChunkSize = 16 * 1024;
        var chunkSize = (int)Math.Min(defaultChunkSize, Math.Max(1024, maxBodyBytes + 1));
        var buffer = ArrayPool<byte>.Shared.Rent(chunkSize);

        try
        {
            while (true)
            {
                var read = await request.Body.ReadAsync(buffer.AsMemory(0, chunkSize), cancellationToken);
                if (read <= 0)
                {
                    break;
                }

                totalRead += read;
                if (totalRead > maxBodyBytes)
                {
                    return true;
                }
            }

            return false;
        }
        finally
        {
            request.Body.Position = 0;
            ArrayPool<byte>.Shared.Return(buffer);
        }
    }

    private static string ReadForwardedFor(HttpRequest request)
    {
        if (!request.Headers.TryGetValue("X-Forwarded-For", out var headerValue))
        {
            return string.Empty;
        }

        var raw = headerValue.ToString();
        if (string.IsNullOrWhiteSpace(raw))
        {
            return string.Empty;
        }

        var first = raw.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries).FirstOrDefault();
        return first ?? string.Empty;
    }

    private static string ReadHeader(HttpRequest request, string name)
    {
        return request.Headers.TryGetValue(name, out var value) ? value.ToString() : string.Empty;
    }
}
