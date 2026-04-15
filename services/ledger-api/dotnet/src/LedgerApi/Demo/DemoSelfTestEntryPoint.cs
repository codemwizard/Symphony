using Microsoft.Extensions.Logging;

namespace Symphony.LedgerApi.Demo;

public static class DemoSelfTestEntryPoint
{
    private static readonly IReadOnlyDictionary<string, Func<ILogger, CancellationToken, Task<int>>> SelfTests =
        new Dictionary<string, Func<ILogger, CancellationToken, Task<int>>>(StringComparer.OrdinalIgnoreCase)
        {
            ["--self-test"] = (logger, ct) => global::IngressSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-evidence-pack"] = (logger, ct) => global::EvidencePackSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-case-pack"] = (logger, ct) => global::ExceptionCasePackSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-authz"] = (_, ct) => global::PilotAuthSelfTestRunner.RunAsync(ct),
            ["--self-test-batching-telemetry"] = (logger, ct) => global::BatchingTelemetrySelfTestRunner.RunAsync(logger, ct),
            ["--self-test-tenant-context"] = (_, ct) => global::TenantContextSelfTestRunner.RunAsync(ct),
            ["--self-test-tenant-onboarding-admin"] = (logger, ct) => global::TenantOnboardingAdminSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-canonical-message-model"] = (logger, ct) => global::CanonicalMessageModelSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-kyc-hash-bridge"] = (logger, ct) => global::KycHashBridgeSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-reg-daily-report"] = (logger, ct) => global::RegulatoryDailyReportSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-reg-incident-48h-report"] = (logger, ct) => global::RegulatoryIncident48hSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-evidence-link-issuance"] = (logger, ct) => EvidenceLinkSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-integrity-chain"] = (logger, ct) => IntegrityChainSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-geo-capture"] = (logger, ct) => GeoCaptureSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-msisdn-submitter-match"] = (logger, ct) => MsisdnSubmitterMatchSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-signed-egress"] = (logger, ct) => SignedInstructionEgressSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-supplier-policy"] = (logger, ct) => SupplierPolicySelfTestRunner.RunAsync(logger, ct),
            ["--self-test-supervisory-read-models"] = (logger, ct) => SupervisoryReadModelsSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-worker-onboarding"] = (logger, ct) => WorkerOnboardingSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-pwrm002-task4"] = (logger, ct) => Pwrm002Task4ValidationRunner.RunAsync(logger, ct),
            ["--self-test-weighbridge-capture"] = (logger, ct) => WeighbridgeCaptureSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-pwrm-monitoring-report"] = (logger, ct) => Pwrm0001MonitoringReportSelfTestRunner.RunAsync(logger, ct),
            ["--self-test-pilot-demo-seeding-bug"] = (logger, ct) => PilotDemoSeedingBugExplorationTest.RunAsync(logger, ct),
            ["--self-test-pilot-demo-seeding-preservation"] = (logger, ct) => PilotDemoSeedingPreservationTest.RunAsync(logger, ct)
        };

    public static async Task<int?> TryRunAsync(string[] args, string runtimeProfile, ILogger logger, CancellationToken cancellationToken)
    {
        var selected = args.FirstOrDefault(SelfTests.ContainsKey);
        if (selected is null)
        {
            return null;
        }

        if (!string.Equals(runtimeProfile, "pilot-demo", StringComparison.OrdinalIgnoreCase))
        {
            logger.LogError("Self-test flag {Flag} is not allowed in runtime profile '{Profile}'. Use profile 'pilot-demo'.", selected, runtimeProfile);
            return 64;
        }

        return await SelfTests[selected](logger, cancellationToken);
    }
}
