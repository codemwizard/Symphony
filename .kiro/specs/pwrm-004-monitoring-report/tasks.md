# PWRM-004 Implementation Tasks

## Task 1 — Create Pwrm0001MonitoringReportHandler.cs
**File:** `ReadModels/Pwrm0001MonitoringReportHandler.cs` (new file)
```csharp
static class Pwrm0001MonitoringReportHandler
{
    public static async Task<HandlerResult> HandleAsync(
        string programId, string rootDir, CancellationToken ct)
    {
        var allRecords   = EvidenceLinkSubmissionLog.ReadAll();
        var programRecs  = allRecords
            .Where(r => string.Equals(GetStr(r, "program_id"), programId, StringComparison.Ordinal))
            .ToList();
        var exceptions   = DemoExceptionLog.ReadAll()
            .Where(r => string.Equals(GetStr(r, "program_id"), programId, StringComparison.Ordinal))
            .ToList();

        // Plastic totals — all seven keys, TOTAL in same pass
        var plasticTotals = new Dictionary<string, decimal>
        {
            ["PET"]="0"m, ["HDPE"]=0m, ["LDPE"]=0m,
            ["PP"]=0m, ["PS"]=0m, ["OTHER"]=0m, ["TOTAL"]=0m
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
                    var pt  = sp.GetProperty("plastic_type").GetString() ?? "OTHER";
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
```

- [x] Create handler with full aggregation logic
- [x] `plasticTotals["TOTAL"]` incremented in same loop as per-type
- [x] `net_weight_kg` read from `structured_payload` (backend-computed decimal)
- [x] Latest wins = `OrderByDescending` on `sequence_number`
- [x] proof_completeness_rate uses `decimal` division with zero guard
- [x] Report written to evidence file unconditionally before return
- [x] exception_count from DemoExceptionLog filtered by program_id

## Task 2 — Wire the route and add artifacts allowlist entry
**File:** `Program.cs`
```csharp
app.MapGet("/pilot-demo/api/monitoring-report/{programId}", async (
    string programId, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    if (!string.Equals(runtimeProfile, "pilot-demo", StringComparison.OrdinalIgnoreCase))
        return Results.NotFound();

    if (!TryValidatePilotDemoOperatorCookie(httpContext, null, out var errorCode, out var errors))
        return Results.Json(new { error_code = errorCode, errors },
            statusCode: StatusCodes.Status401Unauthorized);

    var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
    var result  = await Pwrm0001MonitoringReportHandler.HandleAsync(
        programId, rootDir, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
});
```

In the `GET /pilot-demo/artifacts/{fileName}` route, add `"pwrm0001_monitoring_report.json"`
to the filename allowlist alongside `"reporting_pack_sample.json"`.

- [x] Add monitoring report route with operator cookie gate
- [x] pilot-demo profile guard (NotFound otherwise)
- [x] Add artifact filename to allowlist

## Task 3 — Add "Generate PWRM0001 Monitoring Report" button to dashboard
**File:** `src/supervisory-dashboard/index.html`
```javascript
async function generateMonitoringReport() {
  const programId = window.symphonyContext?.programId ?? 'PGM-ZAMBIA-GRN-001';
  try {
    const res  = await fetch(`/pilot-demo/api/monitoring-report/${programId}`);
    const data = await res.json();
    if (!res.ok) { showError(data.error_code ?? 'REPORT_FAILED'); return; }

    // Trigger download
    const blob = new Blob([JSON.stringify(data, null, 2)], {type:'application/json'});
    const a = Object.assign(document.createElement('a'), {
      href: URL.createObjectURL(blob),
      download: 'pwrm0001_monitoring_report.json'
    });
    a.click();

    // Display summary in cards
    document.getElementById('total-collections-val').textContent =
      data.total_collections ?? 0;
    document.getElementById('total-weight-val').textContent =
      (data.plastic_totals_kg?.TOTAL ?? 0).toFixed(2);
    document.getElementById('report-summary').style.display = 'block';
  } catch (e) { showError('NETWORK_ERROR'); }
}
```

- [x] Add button in export controls section
- [x] Implement fetch + JSON file download
- [x] Display total_collections and TOTAL kg
- [x] Show error_code on failure and on network error

## Task 4 — Create Pwrm0001MonitoringReportSelfTestRunner.cs (8 cases, fully isolated)
**File:** `Demo/Pwrm0001MonitoringReportSelfTestRunner.cs`
**Registration:** `["--self-test-pwrm-monitoring-report"]` in `DemoSelfTestEntryPoint.SelfTests`

Runner isolation setup (FIX F16):
```csharp
var tenantId  = "44444444-4444-4444-4444-444444444444";
var programId = "PGM-SELFTEST-PWRM004";
var worker001 = CreateStableGuid("worker-chunga-001-selftest-004").ToString();
var worker002 = CreateStableGuid("worker-chunga-002-selftest-004").ToString();

var submissionsPath  = "/tmp/pwrm004_selftest_submissions.ndjson";
var exceptionLogPath = "/tmp/pwrm004_selftest_exceptions.ndjson";
File.Delete(submissionsPath);
File.Delete(exceptionLogPath);
Environment.SetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE", submissionsPath);
Environment.SetEnvironmentVariable("DEMO_EXCEPTION_LOG_FILE",        exceptionLogPath);
Environment.SetEnvironmentVariable("DEMO_EVIDENCE_LINK_SIGNING_KEY", "pwrm004-selftest-key");

// Seed workers with supplier_type = "WORKER"
await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    tenantId, worker001, "Test Worker 004-001", "MMO:+260971100001",
    -15.4167m, 28.2833m, true, supplier_type: "WORKER"));
await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    tenantId, worker002, "Test Worker 004-002", "MMO:+260971100002",
    -15.4167m, 28.2833m, true, supplier_type: "WORKER"));
await ProgramSupplierAllowlistUpsertHandler.HandleAsync(
    new ProgramSupplierAllowlistUpsertRequest(tenantId, programId, worker001, true));
await ProgramSupplierAllowlistUpsertHandler.HandleAsync(
    new ProgramSupplierAllowlistUpsertRequest(tenantId, programId, worker002, true));
```

All submissions seeded with sequential `await` (no `Task.WhenAll`) to preserve
monotonic sequence_number.

8 test cases:

| # | Setup | Expected |
|---|-------|----------|
| 1 | No submissions | total_collections=0, proof_completeness_rate=1.0 |
| 2 | Two WEIGHBRIDGE_RECORDs (PET 12.4kg + PET 8.1kg, different instruction_ids) | plastic_totals_kg.PET=20.5, TOTAL=20.5 |
| 3 | Two WEIGHBRIDGE_RECORDs SAME instruction_id (seq 0: PET 12.4kg, seq 1: HDPE 8.1kg) | total_collections=1; winner=seq 1; HDPE=8.1, PET=0, TOTAL=8.1 |
| 4 | One instruction: all four PWRM0001 proof types submitted | complete_collections=1 |
| 5 | One instruction: missing TRANSFER_MANIFEST | incomplete_collections=1 |
| 6 | One complete + one incomplete | proof_completeness_rate=0.5 |
| 7 | One exception log entry seeded for programId | exception_count=1 |
| 8 | zgft_waste_sector_alignment fields | all three booleans = true |

Case 3 tests latest-wins by sequence_number: seq 1 (HDPE 8.1) wins over seq 0 (PET 12.4).
Case 2 tests TOTAL accumulation in same pass (20.5 = 12.4 + 8.1 via decimal arithmetic).

- [x] Create runner with all 8 cases
- [x] Register `--self-test-pwrm-monitoring-report`
- [x] Case 3: seed two records same instruction_id; assert winner is seq 1
- [x] Case 2: assert TOTAL = 20.5 (decimal exact)
- [x] Case 7: explicitly seed `DemoExceptionLog.AppendAsync` (F10 explicit seeding)
- [x] All appends use sequential `await` (FIX F12 — no `Task.WhenAll`)
- [x] Write evidence to `evidence/phase1/pwrm_monitoring_report.json`
- [x] Runner fully isolated: different tenant, program, worker IDs from all other runners