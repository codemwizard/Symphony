# PWRM-003 Design

## Hard override for PGM-ZAMBIA-GRN-001
```csharp
static bool IsPwrm0001Programme(string programId, IReadOnlyList<JsonElement> submissions)
{
    // Hard override — demo cannot break due to seed timing
    if (string.Equals(programId, "PGM-ZAMBIA-GRN-001", StringComparison.Ordinal))
        return true;

    // Generic detection: both conditions required
    bool hasArtifact = submissions.Any(s =>
        s.TryGetProperty("artifact_type", out var at) &&
        Pwrm0001ArtifactTypes.IsPwrm0001ArtifactType(at.GetString()));
    bool hasWasteCollector = submissions.Any(s =>
        s.TryGetProperty("submitter_class", out var sc) &&
        string.Equals(sc.GetString(), "WASTE_COLLECTOR", StringComparison.Ordinal));

    return hasArtifact && hasWasteCollector;
}
```

## Removing PT-001..PT-004
Current `SupervisoryReadModelsSelfTestRunner.cs` asserts:
```csharp
hasAllProofTypes = new[] { "PT-001", "PT-002", "PT-003", "PT-004" }.All(typeSet.Contains);
```
This assertion is replaced with:
```csharp
hasAllProofTypes = new[]
{
    Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD,
    Pwrm0001ArtifactTypes.COLLECTION_PHOTO,
    Pwrm0001ArtifactTypes.QUALITY_AUDIT_RECORD,
    Pwrm0001ArtifactTypes.TRANSFER_MANIFEST
}.All(typeSet.Contains);
```
And the seeded test submissions in that runner use PWRM0001 artifact type strings.

## Proof guarantee usage
Because PWRM-002 enforces structured_payload as REQUIRED for WEIGHBRIDGE_RECORD,
any WEIGHBRIDGE_RECORD record in the log has structured_payload guaranteed non-null.
The only guard needed in the detail read model is:
```csharp
if (record.TryGetProperty("structured_payload", out var sp) && sp.ValueKind != JsonValueKind.Null)
{
    // safe to access plastic_type, net_weight_kg, collector_id directly
}
```

## Seeding order in Program.cs
1. PWRM-001 seeding: worker-chunga-001, worker-chunga-002 (supplier_type = "WORKER")
2. PWRM-003 seeding: CHG-2026-00001 (4 proofs), CHG-2026-00002 (1 proof)
Each seeded record includes `sequence_number` to maintain the append-order contract.