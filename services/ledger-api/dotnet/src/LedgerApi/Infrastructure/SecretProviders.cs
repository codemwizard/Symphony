using System.Net.Http.Json;
using System.Text.Json;

namespace Symphony.LedgerApi.Infrastructure;

/// <summary>
/// Abstracts runtime secret resolution.
/// The hardened profile MUST use <see cref="OpenBaoSecretProvider"/>.
/// The <see cref="EnvironmentSecretProvider"/> is ONLY for developer/test/CI profiles.
/// </summary>
public interface ISecretProvider
{
    /// <summary>
    /// Resolve a secret by its logical key name.
    /// Hardened implementations MUST throw if the key is in-scope but cannot be resolved.
    /// </summary>
    Task<string> GetSecretAsync(string keyName, CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns true if the provider is healthy and can resolve secrets.
    /// Used by /readyz to fail-closed when the secret backend is unreachable.
    /// </summary>
    Task<bool> IsHealthyAsync(CancellationToken cancellationToken = default);
}

/// <summary>
/// Developer/test/CI-only secret provider that reads from process environment.
/// MUST NOT be used for the hardened (pilot-demo, production) runtime profile.
/// </summary>
public sealed class EnvironmentSecretProvider : ISecretProvider
{
    public Task<string> GetSecretAsync(string keyName, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Environment.GetEnvironmentVariable(keyName) ?? string.Empty);
    }

    public Task<bool> IsHealthyAsync(CancellationToken cancellationToken = default)
        => Task.FromResult(true);
}

/// <summary>
/// Path contract for mapping logical secret key names to OpenBao KV paths.
/// This is the single place that defines the real secret schema.
/// The bootstrap script (<c>openbao_bootstrap.sh</c>) seeds the dev instance;
/// production OpenBao must be seeded with secrets at these same logical paths.
///
/// Bootstrap dependency note: The AppRole <c>role_id</c> and <c>secret_id</c>
/// are deployment-time bootstrap credentials. They are read from environment
/// variables or files at startup. This is an acceptable bootstrap dependency
/// for Wave 1, but is NOT the app's long-term secret source — the secrets
/// themselves are resolved from OpenBao, not from environment.
/// </summary>
public static class OpenBaoPathContract
{
    /// <summary>
    /// The set of secret keys that MUST be resolved from OpenBao in the hardened profile.
    /// Any request for a key in this set that cannot be resolved is a fatal error.
    /// </summary>
    public static readonly HashSet<string> HardenedSecretKeys = new(StringComparer.Ordinal)
    {
        "INGRESS_API_KEY",
        "ADMIN_API_KEY",
        "DEMO_INSTRUCTION_SIGNING_KEY",
        "EVIDENCE_SIGNING_KEY"
    };

    /// <summary>
    /// Maps each in-scope secret key to its OpenBao KV v2 path and property name.
    /// The path prefix is relative to the KV mount (e.g., if mounted at <c>kv</c>,
    /// the full API path would be <c>/v1/kv/data/{Path}</c>).
    /// </summary>
    public static readonly Dictionary<string, (string Path, string Property)> KeyMapping = new(StringComparer.Ordinal)
    {
        // API authentication secrets
        { "INGRESS_API_KEY",              ("symphony/secrets/api", "ingress_api_key") },
        { "ADMIN_API_KEY",                ("symphony/secrets/api", "admin_api_key") },

        // Signing key material
        { "DEMO_INSTRUCTION_SIGNING_KEY", ("symphony/secrets/signing", "demo_instruction_signing_key") },
        { "EVIDENCE_SIGNING_KEY",         ("symphony/secrets/signing", "evidence_signing_key") },

        // Operator session signing (cookie material) — same key domain as admin
        { "EVIDENCE_SIGNING_KEY_ID",      ("symphony/secrets/signing", "evidence_signing_key_id") },
    };
}

/// <summary>
/// OpenBao-backed secret provider using AppRole authentication.
/// Resolves secrets via the OpenBao KV v2 HTTP API.
///
/// Fail-closed behavior:
/// - If an in-scope hardened secret cannot be fetched, GetSecretAsync throws.
/// - If OpenBao is unreachable, IsHealthyAsync returns false (causes /readyz to fail).
/// - Non-mapped keys are rejected with an explicit error, never silently delegated to env.
///
/// AppRole bootstrap credentials (<c>BAO_ROLE_ID</c>, <c>BAO_SECRET_ID</c>) are
/// read once at construction time. This is a deployment concern, not a runtime secret.
/// </summary>
public sealed class OpenBaoSecretProvider : ISecretProvider, IDisposable
{
    private readonly HttpClient _httpClient;
    private readonly string _kvMount;
    private readonly string _roleId;
    private readonly string _secretId;
    private string? _token;
    private DateTimeOffset _tokenExpiry;
    private readonly SemaphoreSlim _authLock = new(1, 1);

    /// <param name="httpClient">Externally managed HttpClient (prefer IHttpClientFactory).</param>
    /// <param name="baoAddr">OpenBao base address, e.g. http://127.0.0.1:8200</param>
    /// <param name="roleId">AppRole role_id for authentication.</param>
    /// <param name="secretId">AppRole secret_id for authentication.</param>
    /// <param name="kvMount">KV v2 mount path. Defaults to "kv".</param>
    public OpenBaoSecretProvider(HttpClient httpClient, string baoAddr, string roleId, string secretId, string kvMount = "kv")
    {
        if (string.IsNullOrWhiteSpace(roleId))
            throw new InvalidOperationException("BAO_ROLE_ID is required for OpenBao secret provider. Cannot start in hardened mode without AppRole credentials.");
        if (string.IsNullOrWhiteSpace(secretId))
            throw new InvalidOperationException("BAO_SECRET_ID is required for OpenBao secret provider. Cannot start in hardened mode without AppRole credentials.");

        _httpClient = httpClient;
        _httpClient.BaseAddress = new Uri(baoAddr);
        _roleId = roleId;
        _secretId = secretId;
        _kvMount = kvMount;
    }

    private async Task EnsureTokenAsync(CancellationToken cancellationToken)
    {
        if (_token is not null && DateTimeOffset.UtcNow < _tokenExpiry)
            return;

        await _authLock.WaitAsync(cancellationToken);
        try
        {
            // Double-check after acquiring lock
            if (_token is not null && DateTimeOffset.UtcNow < _tokenExpiry)
                return;

            var payload = new { role_id = _roleId, secret_id = _secretId };
            var response = await _httpClient.PostAsJsonAsync("/v1/auth/approle/login", payload, cancellationToken);
            response.EnsureSuccessStatusCode();

            using var doc = await response.Content.ReadFromJsonAsync<JsonDocument>(cancellationToken: cancellationToken);
            if (doc is null)
                throw new InvalidOperationException("OpenBao AppRole login returned a null response body.");

            var authNode = doc.RootElement.GetProperty("auth");
            _token = authNode.GetProperty("client_token").GetString()
                ?? throw new InvalidOperationException("OpenBao AppRole login did not return a client_token.");
            var leaseDuration = authNode.GetProperty("lease_duration").GetInt32();

            // Renew 60 seconds before expiry to avoid edge-case failures
            _tokenExpiry = DateTimeOffset.UtcNow.AddSeconds(Math.Max(leaseDuration - 60, 10));
        }
        finally
        {
            _authLock.Release();
        }
    }

    public async Task<string> GetSecretAsync(string keyName, CancellationToken cancellationToken = default)
    {
        if (!OpenBaoPathContract.KeyMapping.TryGetValue(keyName, out var mapping))
        {
            throw new InvalidOperationException(
                $"Secret key '{keyName}' is not mapped in the OpenBao path contract. " +
                "Only in-scope secrets may be resolved through the hardened provider. " +
                "If this key should be in scope, add it to OpenBaoPathContract.KeyMapping.");
        }

        await EnsureTokenAsync(cancellationToken);

        var requestUri = $"/v1/{_kvMount}/data/{mapping.Path}";
        var request = new HttpRequestMessage(HttpMethod.Get, requestUri);
        request.Headers.Add("X-Vault-Token", _token);

        var response = await _httpClient.SendAsync(request, cancellationToken);

        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            if (OpenBaoPathContract.HardenedSecretKeys.Contains(keyName))
            {
                throw new InvalidOperationException(
                    $"Required hardened secret '{keyName}' not found at OpenBao path '{mapping.Path}'. " +
                    "The hardened profile cannot start without this secret. " +
                    "Ensure the secret is seeded in OpenBao before starting the application.");
            }
            return string.Empty;
        }

        response.EnsureSuccessStatusCode();

        using var doc = await response.Content.ReadFromJsonAsync<JsonDocument>(cancellationToken: cancellationToken);
        if (doc is null)
        {
            throw new InvalidOperationException(
                $"OpenBao returned null body when reading secret '{keyName}' from path '{mapping.Path}'.");
        }

        var dataNode = doc.RootElement.GetProperty("data").GetProperty("data");
        if (dataNode.TryGetProperty(mapping.Property, out var prop))
        {
            var value = prop.GetString() ?? string.Empty;
            if (string.IsNullOrWhiteSpace(value) && OpenBaoPathContract.HardenedSecretKeys.Contains(keyName))
            {
                throw new InvalidOperationException(
                    $"Required hardened secret '{keyName}' exists at OpenBao path '{mapping.Path}' " +
                    $"but property '{mapping.Property}' is empty. Cannot proceed in hardened mode.");
            }
            return value;
        }

        if (OpenBaoPathContract.HardenedSecretKeys.Contains(keyName))
        {
            throw new InvalidOperationException(
                $"Required hardened secret '{keyName}' exists at OpenBao path '{mapping.Path}' " +
                $"but property '{mapping.Property}' was not found in the KV data.");
        }

        return string.Empty;
    }

    public async Task<bool> IsHealthyAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("/v1/sys/health", cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }

    public void Dispose()
    {
        _authLock.Dispose();
        // Note: HttpClient is NOT disposed here because it is externally managed
        // (injected via IHttpClientFactory or DI). Disposing it here would break
        // shared HttpClient pools.
        GC.SuppressFinalize(this);
    }
}
