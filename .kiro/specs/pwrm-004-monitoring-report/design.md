# PWRM-004 Design

## FIX F16: Full self-test isolation — namespaced IDs + fresh registry state
The runner uses distinct tenant ID, program ID, and worker IDs not used by
any other runner. It seeds its own workers before creating submissions.

Because `SupplierRegistry` is in-memory and shared across runners (if run in
the same process), the runner uses `worker_id` values with a `-selftest-004`
suffix that cannot collide with Program.cs workers or other runners.

## Exception log — explicitly seeded
```csharp
await DemoExceptionLog.AppendAsync(new {
    tenant_id    = tenantId,
    program_id   = programId,
    instruction_id = "CHG-SELFTEST-004-001",
    error_code   = "SIM_SWAP_FLAG",
    recorded_at_utc = DateTimeOffset.UtcNow.ToString("O")
}, ct);
```
This mirrors the pattern in `SupervisoryReadModelsSelfTestRunner.cs` exactly.

## Latest-wins via sequence_number
```csharp
var byInstruction = weighbridgeRecords
    .GroupBy(s => GetString(s, "instruction_id") ?? "")
    .Where(g => !string.IsNullOrEmpty(g.Key));

foreach (var group in byInstruction)
{
    // Latest wins = highest sequence_number (not timestamp)
    var winner = group
        .OrderByDescending(s =>
            s.TryGetProperty("sequence_number", out var sq) ? sq.GetInt32() : -1)
        .First();

    var sp = winner.GetProperty("structured_payload");
    var plasticType = sp.GetProperty("plastic_type").GetString() ?? "OTHER";
    var net = sp.GetProperty("net_weight_kg").GetDecimal();  // backend-computed value

    if (plasticTotals.ContainsKey(plasticType)) plasticTotals[plasticType] += net;
    else plasticTotals["OTHER"] += net;
    plasticTotals["TOTAL"] += net;  // same pass
    ...
}
```

## TOTAL accumulated in same pass (no post-aggregation sum)
`plasticTotals["TOTAL"]` is incremented in the same loop iteration as per-type.
This eliminates floating-point divergence from separate summation.

## Proof-completeness detection
An instruction is complete if ALL four artifact types appear in its submissions
(any submission for that instruction_id, not just WEIGHBRIDGE_RECORD):
```csharp
var allProofTypes = new HashSet<string>(Pwrm0001ArtifactTypes.ProofTypeDisplayLabels.Keys);
var completeCount = instructionGroups
    .Count(g => allProofTypes.IsSubsetOf(
        g.Select(s => GetString(s, "artifact_type") ?? "").ToHashSet()));
```

## Report written unconditionally
```csharp
var reportPath = Path.Combine(rootDir, "evidence", "phase1", "pwrm0001_monitoring_report.json");
Directory.CreateDirectory(Path.GetDirectoryName(reportPath)!);
await File.WriteAllTextAsync(reportPath, JsonSerializer.Serialize(report, ...) + "\n", ct);
// THEN return 200
```
This runs even when `totalCollections == 0`.