using System.IO;
using Xunit;

public class CqrsProjectionTests
{
    private static string RepoRoot => Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../../../../"));

    [Fact]
    public void Projection_BoundaryHandlers_AreNotDefinedInProgram()
    {
        var program = File.ReadAllText(Path.Combine(RepoRoot, "services/ledger-api/dotnet/src/LedgerApi/Program.cs"));
        Assert.DoesNotContain("static class IngressHandler", program);
        Assert.DoesNotContain("static class EvidencePackHandler", program);
        Assert.DoesNotContain("static class RegulatoryReportHandler", program);
        Assert.DoesNotContain("static class ApiAuthorization", program);
    }

    [Fact]
    public void Projection_Directories_Exist()
    {
        foreach (var rel in new[] { "Commands", "Queries", "ReadModels", "Infrastructure", "Security" })
        {
            Assert.True(Directory.Exists(Path.Combine(RepoRoot, "services/ledger-api/dotnet/src/LedgerApi", rel)));
        }
    }

    [Fact]
    public void Projection_FreshnessFields_ArePresent()
    {
        var queries = File.ReadAllText(Path.Combine(RepoRoot, "services/ledger-api/dotnet/src/LedgerApi/Queries/RegulatoryReports.cs"));
        var readModels = File.ReadAllText(Path.Combine(RepoRoot, "services/ledger-api/dotnet/src/LedgerApi/ReadModels/ProjectionReadModels.cs"));
        Assert.Contains("projection_version", queries);
        Assert.Contains("as_of_utc", queries);
        Assert.Contains("ProgramMemberSummaryProjection", readModels);
        Assert.Contains("EscrowSummaryProjection", readModels);
    }

    [Fact]
    public void QueryProjection_UsesProjectionTablesOnly()
    {
        var evidence = File.ReadAllText(Path.Combine(RepoRoot, "services/ledger-api/dotnet/src/LedgerApi/Queries/EvidencePackQueries.cs"));
        var reports = File.ReadAllText(Path.Combine(RepoRoot, "services/ledger-api/dotnet/src/LedgerApi/Queries/RegulatoryReports.cs"));
        Assert.Contains("evidence_bundle_projection", evidence);
        Assert.Contains("instruction_status_projection", reports);
        Assert.DoesNotContain("ingress_attestations", evidence);
        Assert.DoesNotContain("payment_outbox_pending", evidence);
        Assert.DoesNotContain("regulatory_incidents", reports);
        Assert.DoesNotContain("incident_events", reports);
    }
}
