namespace Symphony.LedgerApi.Infrastructure;

/// <summary>
/// Holds resolved runtime secrets.
/// All in-scope hardened secrets are resolved ONCE at startup via the configured
/// <see cref="ISecretProvider"/> and cached for the process lifetime.
///
/// This avoids async cascading in every endpoint handler and ensures fail-closed
/// behavior at startup: if any required secret is missing, the app does not start.
/// </summary>
public sealed class RuntimeSecrets
{
    public string IngressApiKey { get; }
    public string AdminApiKey { get; }
    public string OperatorSessionKey { get; }
    public string DemoInstructionSigningKey { get; }
    public string EvidenceSigningKey { get; }
    public string EvidenceSigningKeyId { get; }

    private RuntimeSecrets(
        string ingressApiKey,
        string adminApiKey,
        string operatorSessionKey,
        string demoInstructionSigningKey,
        string evidenceSigningKey,
        string evidenceSigningKeyId)
    {
        IngressApiKey = ingressApiKey;
        AdminApiKey = adminApiKey;
        OperatorSessionKey = operatorSessionKey;
        DemoInstructionSigningKey = demoInstructionSigningKey;
        EvidenceSigningKey = evidenceSigningKey;
        EvidenceSigningKeyId = evidenceSigningKeyId;
    }

    /// <summary>
    /// Resolve all in-scope secrets from the given provider.
    /// For the hardened profile (OpenBao), this will throw if any required secret
    /// cannot be resolved — the app will not start.
    /// For the dev profile (env), this will read from process environment.
    /// </summary>
    public static async Task<RuntimeSecrets> ResolveAsync(ISecretProvider provider, CancellationToken cancellationToken = default)
    {
        var ingressApiKey = await provider.GetSecretAsync("INGRESS_API_KEY", cancellationToken);
        var adminApiKey = await provider.GetSecretAsync("ADMIN_API_KEY", cancellationToken);
        var operatorSessionKey = await provider.GetSecretAsync("OPERATOR_SESSION_KEY", cancellationToken);
        var demoInstructionSigningKey = await provider.GetSecretAsync("DEMO_INSTRUCTION_SIGNING_KEY", cancellationToken);
        var evidenceSigningKey = await provider.GetSecretAsync("EVIDENCE_SIGNING_KEY", cancellationToken);
        var evidenceSigningKeyId = await provider.GetSecretAsync("EVIDENCE_SIGNING_KEY_ID", cancellationToken);

        return new RuntimeSecrets(
            ingressApiKey,
            adminApiKey,
            operatorSessionKey,
            demoInstructionSigningKey,
            evidenceSigningKey,
            evidenceSigningKeyId);
    }
}
