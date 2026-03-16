using Symphony.LedgerApi.Infrastructure;
using Xunit;

namespace LedgerApi.Tests;

/// <summary>
/// Unit tests for TSK-P1-215: ISecretProvider / RuntimeSecrets / OpenBaoSecretProvider
///
/// Tests validate:
/// - EnvironmentSecretProvider reads from process env (success + missing path)
/// - OpenBaoSecretProvider rejects empty AppRole credentials (fail-closed)
/// - OpenBaoSecretProvider throws for unmapped keys (no env fallback)
/// - OpenBaoPathContract has all in-scope hardened keys with non-empty paths
/// - RuntimeSecrets resolves all keys through the provider (success path)
/// - RuntimeSecrets propagates provider failures (fail-closed path)
/// </summary>
public class SecretProviderTests
{
    // ────────── EnvironmentSecretProvider ──────────

    [Fact]
    public async Task EnvironmentSecretProvider_ReturnsEnvValue_WhenSet()
    {
        var uniqueKey = $"TEST_SECRET_{Guid.NewGuid():N}";
        Environment.SetEnvironmentVariable(uniqueKey, "test-value-215");
        try
        {
            var provider = new EnvironmentSecretProvider();
            var result = await provider.GetSecretAsync(uniqueKey);
            Assert.Equal("test-value-215", result);
        }
        finally
        {
            Environment.SetEnvironmentVariable(uniqueKey, null);
        }
    }

    [Fact]
    public async Task EnvironmentSecretProvider_ReturnsEmpty_WhenNotSet()
    {
        var provider = new EnvironmentSecretProvider();
        var result = await provider.GetSecretAsync("DEFINITELY_NOT_SET_KEY_215");
        Assert.Equal(string.Empty, result);
    }

    [Fact]
    public async Task EnvironmentSecretProvider_IsHealthy_Always()
    {
        var provider = new EnvironmentSecretProvider();
        Assert.True(await provider.IsHealthyAsync());
    }

    // ────────── OpenBaoSecretProvider: Constructor Validation ──────────

    [Fact]
    public void OpenBaoSecretProvider_ThrowsOnEmptyRoleId()
    {
        var ex = Assert.Throws<InvalidOperationException>(() =>
            new OpenBaoSecretProvider(new HttpClient(), "http://127.0.0.1:8200", "", "some-secret-id"));
        Assert.Contains("BAO_ROLE_ID", ex.Message);
    }

    [Fact]
    public void OpenBaoSecretProvider_ThrowsOnEmptySecretId()
    {
        var ex = Assert.Throws<InvalidOperationException>(() =>
            new OpenBaoSecretProvider(new HttpClient(), "http://127.0.0.1:8200", "some-role-id", ""));
        Assert.Contains("BAO_SECRET_ID", ex.Message);
    }

    [Fact]
    public void OpenBaoSecretProvider_ThrowsOnWhitespaceRoleId()
    {
        var ex = Assert.Throws<InvalidOperationException>(() =>
            new OpenBaoSecretProvider(new HttpClient(), "http://127.0.0.1:8200", "   ", "secret-id"));
        Assert.Contains("BAO_ROLE_ID", ex.Message);
    }

    // ────────── OpenBaoSecretProvider: Key Mapping Enforcement ──────────

    [Fact]
    public async Task OpenBaoSecretProvider_ThrowsOnUnmappedKey()
    {
        using var provider = new OpenBaoSecretProvider(
            new HttpClient(), "http://127.0.0.1:8200", "role-id", "secret-id");

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(
            () => provider.GetSecretAsync("SOME_RANDOM_UNMAPPED_KEY"));
        Assert.Contains("not mapped in the OpenBao path contract", ex.Message);
    }

    // ────────── OpenBaoPathContract ──────────

    [Theory]
    [InlineData("INGRESS_API_KEY")]
    [InlineData("ADMIN_API_KEY")]
    [InlineData("DEMO_INSTRUCTION_SIGNING_KEY")]
    [InlineData("EVIDENCE_SIGNING_KEY")]
    public void PathContract_ContainsRequiredHardenedKey(string keyName)
    {
        Assert.True(OpenBaoPathContract.KeyMapping.ContainsKey(keyName),
            $"KeyMapping must contain '{keyName}'");
    }

    [Theory]
    [InlineData("INGRESS_API_KEY")]
    [InlineData("ADMIN_API_KEY")]
    [InlineData("DEMO_INSTRUCTION_SIGNING_KEY")]
    [InlineData("EVIDENCE_SIGNING_KEY")]
    public void PathContract_HardenedSetContainsRequiredKeys(string keyName)
    {
        Assert.Contains(keyName, OpenBaoPathContract.HardenedSecretKeys);
    }

    [Fact]
    public void PathContract_EachMappingHasNonEmptyPathAndProperty()
    {
        foreach (var (key, mapping) in OpenBaoPathContract.KeyMapping)
        {
            Assert.False(string.IsNullOrWhiteSpace(mapping.Path),
                $"KeyMapping[{key}].Path must not be empty");
            Assert.False(string.IsNullOrWhiteSpace(mapping.Property),
                $"KeyMapping[{key}].Property must not be empty");
        }
    }

    // ────────── RuntimeSecrets: Success Path ──────────

    [Fact]
    public async Task RuntimeSecrets_ResolvesAllKeys_FromEnvironment()
    {
        var keys = new Dictionary<string, string>
        {
            { "INGRESS_API_KEY", "ingress-test-val" },
            { "ADMIN_API_KEY", "admin-test-val" },
            { "DEMO_INSTRUCTION_SIGNING_KEY", "demo-sign-val" },
            { "EVIDENCE_SIGNING_KEY", "evidence-sign-val" },
            { "EVIDENCE_SIGNING_KEY_ID", "key-id-val" }
        };

        foreach (var (k, v) in keys)
            Environment.SetEnvironmentVariable(k, v);

        try
        {
            var secrets = await RuntimeSecrets.ResolveAsync(new EnvironmentSecretProvider());

            Assert.Equal("ingress-test-val", secrets.IngressApiKey);
            Assert.Equal("admin-test-val", secrets.AdminApiKey);
            Assert.Equal("demo-sign-val", secrets.DemoInstructionSigningKey);
            Assert.Equal("evidence-sign-val", secrets.EvidenceSigningKey);
            Assert.Equal("key-id-val", secrets.EvidenceSigningKeyId);
        }
        finally
        {
            foreach (var k in keys.Keys)
                Environment.SetEnvironmentVariable(k, null);
        }
    }

    // ────────── RuntimeSecrets: Failure Path (fail-closed) ──────────

    [Fact]
    public async Task RuntimeSecrets_PropagatesProviderException()
    {
        var flakyProvider = new ThrowingSecretProvider("INGRESS_API_KEY");

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => RuntimeSecrets.ResolveAsync(flakyProvider));
    }

    // ────────── Helpers ──────────

    private sealed class ThrowingSecretProvider : ISecretProvider
    {
        private readonly string _failOnKey;

        public ThrowingSecretProvider(string failOnKey)
        {
            _failOnKey = failOnKey;
        }

        public Task<string> GetSecretAsync(string keyName, CancellationToken cancellationToken = default)
        {
            if (keyName == _failOnKey)
                throw new InvalidOperationException($"Simulated OpenBao failure for '{keyName}'");
            return Task.FromResult("dummy-value");
        }

        public Task<bool> IsHealthyAsync(CancellationToken cancellationToken = default)
            => Task.FromResult(false);
    }
}
