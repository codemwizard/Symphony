using System.Text.Json;

static class Pwrm0001MonitoringReportHandler
{
    public static async Task<HandlerResult> HandleAsync(
        string programId, string rootDir, CancellationToken ct)
    {
        var allRecords = EvidenceLinkSubmissionLog.ReadAll();
        var programRecs = allRecords
            .Where(r => string.Equals(GetStr(r, "program_id"), programId, StringComparison.Ordinal))
            .ToList();
        var exceptions = DemoExceptionLog.ReadAll()
            .Where(r => string.Equals(GetStr(r, "program_id"), programId, StringComparison.Ordinal))
            .ToList();

        // Plastic totals — all seven keys, TOTAL in same pass
        var plasticTotals = new Dictionary<string, decimal>
        {
            ["PET"] = 0m,
            ["HDPE"] = 0m,
            ["LDPE"] = 0m,
            ["PP"] = 0m,
            ["PS"] = 0m,
            ["OTHER"] = 0m,
            ["TOTAL"] = 0m
        };

        // Group all records by instruction_id
        var allProofTypes = new HashSet<string>(Pwrm0001ArtifactTypes.ProofTypeDisplayLabels.Keys);
        var byInstruction = programRecs
            .GroupBy(r => GetStr(r, "instruction_id") ?? "")
            .Where(g => !string.IsNullOrEmpty(g.Key))
            .ToList();

        int totalCollections = 0, completeCollections = 0;
        var collectorIds = new HashSet<string>(StringComparer.Ordinal);

        foreach (var group in byInstruction)
        {
            // Check completeness: all four proof types present in any submission
            var typesInGroup = group
                .Select(r => GetStr(r, "artifact_type") ?? "")
                .ToHashSet(StringComparer.Ordinal);
            bool isComplete = allProofTypes.IsSubsetOf(typesInGroup);

            // Find the WEIGHBRIDGE_RECORD winner (highest sequence_number)
            var weighbridgeRecs = group
                .Where(r => string.Equals(GetStr(r, "artifact_type"),
                    Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD, StringComparison.Ordinal))
                .ToList();

            if (weighbridgeRecs.Count > 0)
            {
                totalCollections++;
                if (isComplete) completeCollections++;

                var winner = weighbridgeRecs
                    .OrderByDescending(r =>
                        r.TryGetProperty("sequence_number", out var sq) ? sq.GetInt32() : -1)
                    .First();

                if (winner.TryGetProperty("structured_payload", out var sp)
                    && sp.ValueKind != JsonValueKind.Null)
                {
                    var pt = sp.GetProperty("plastic_type").GetString() ?? "OTHER";
                    var net = sp.GetProperty("net_weight_kg").GetDecimal();  // backend-computed

                    if (plasticTotals.ContainsKey(pt)) plasticTotals[pt] += net;
                    else plasticTotals["OTHER"] += net;
                    plasticTotals["TOTAL"] += net;  // same pass

                    var cid = sp.TryGetProperty("collector_id", out var c) ? c.GetString() : null;
                    if (!string.IsNullOrEmpty(cid)) collectorIds.Add(cid!);
                }
            }
        }

        var incompleteCollections = totalCollections - completeCollections;
        var exceptionCount = exceptions
            .Select(r => GetStr(r, "instruction_id") ?? "")
            .Where(id => !string.IsNullOrEmpty(id))
            .Distinct(StringComparer.Ordinal)
            .Count();

        var rate = totalCollections == 0 ? 1.0m
            : (decimal)completeCollections / (decimal)totalCollections;

        var report = new
        {
            program_id = programId,
            generated_at_utc = DateTimeOffset.UtcNow.ToString("O"),
            total_collections = totalCollections,
            complete_collections = completeCollections,
            incomplete_collections = incompleteCollections,
            worker_count = collectorIds.Count,
            proof_completeness_rate = rate,
            exception_count = exceptionCount,
            plastic_totals_kg = plasticTotals,
            zgft_waste_sector_alignment = new
            {
                pollution_prevention = true,
                circular_economy = true,
                do_no_significant_harm_declared = true
            }
        };

        // Write unconditionally — even on empty result
        var reportPath = Path.Combine(rootDir, "evidence", "phase1",
            "pwrm0001_monitoring_report.json");
        Directory.CreateDirectory(Path.GetDirectoryName(reportPath)!);
        await File.WriteAllTextAsync(reportPath,
            JsonSerializer.Serialize(report, new JsonSerializerOptions { WriteIndented = true })
            + Environment.NewLine, ct);

        return new HandlerResult(StatusCodes.Status200OK, report);
    }

    private static string? GetStr(JsonElement el, string key) =>
        el.TryGetProperty(key, out var v) ? v.GetString() : null;
}
