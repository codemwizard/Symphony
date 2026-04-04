# PWRM-003 Implementation Tasks

## Task 1 — Replace PT-001..PT-004 entirely
**Files:** `ReadModels/SupervisoryRevealReadModelHandler.cs`, `Demo/SupervisoryReadModelsSelfTestRunner.cs`

In the reveal handler:
- Read `artifact_type` from each submission record
- `proof_type_id = artifact_type`
- `proof_type_display = ProofTypeDisplayLabels.TryGetValue(artifact_type, out var l) ? l : artifact_type`

In `SupervisoryReadModelsSelfTestRunner.cs`:
- Replace `new[] { "PT-001", "PT-002", "PT-003", "PT-004" }` with PWRM0001 constants
- Update the seed submissions to use artifact type strings matching PWRM0001 constants

Grep entire repo: `grep -r "PT-00[1234]"` — fix every hit.

- [x] Replace PT-001..PT-004 in handler with artifact_type lookup
- [x] Update SupervisoryReadModelsSelfTestRunner assertion
- [x] Update test data seeds in that runner to use PWRM0001 artifact types
- [x] Grep repo; confirm zero remaining PT-00N strings in source and responses

## Task 2 — Add IsPwrm0001Programme with hard override
**File:** `ReadModels/SupervisoryRevealReadModelHandler.cs`

Add function exactly as designed above (hard override first, then generic).

- [x] Add `IsPwrm0001Programme` with `PGM-ZAMBIA-GRN-001` hard override
- [x] Generic path requires BOTH conditions
- [x] Write unit assertion in self-test that hard override fires even with empty submissions

## Task 3 — Add weighbridge detail fields to instruction detail read model
**File:** Instruction detail read model handler
```csharp
if (record.TryGetProperty("structured_payload", out var sp)
    && sp.ValueKind != JsonValueKind.Null
    && string.Equals(artifactType, Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD, StringComparison.Ordinal))
{
    // PWRM-002 guarantee: these fields are present and valid
    proofRow["plastic_type"]  = sp.GetProperty("plastic_type").GetString();
    proofRow["net_weight_kg"] = sp.GetProperty("net_weight_kg").GetDecimal();
    proofRow["collector_id"]  = sp.GetProperty("collector_id").GetString();
}
```

- [x] Add structured_payload null guard
- [x] Add plastic_type, net_weight_kg, collector_id to WEIGHBRIDGE_RECORD rows
- [x] Assert these fields appear in the detail response for CHG-2026-00001

## Task 4 — Seed CHG-2026-00001 and CHG-2026-00002 in Program.cs
**File:** `Program.cs`

Seed after worker seeding block. Include `sequence_number` on every record.
Use `await` sequentially (no `Task.WhenAll`) to maintain monotonic sequence.

CHG-2026-00001 — 4 records (one per proof type):
```csharp
int seq = EvidenceLinkSubmissionLog.ReadAll().Count;
await EvidenceLinkSubmissionLog.AppendAsync(new {
    tenant_id = DemoTenantId, instruction_id = "CHG-2026-00001",
    program_id = PgmZambiaGrn, submitter_class = "WASTE_COLLECTOR",
    worker_id = workerChunga001Id,
    artifact_type = Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD,
    artifact_ref = "demo://weighbridge/chg-001",
    structured_payload = JsonSerializer.SerializeToElement(new {
        plastic_type = "PET", gross_weight_kg = 12.5m, tare_weight_kg = 0.1m,
        net_weight_kg = 12.4m,   // backend_net stored here
        collector_id = workerChunga001Id
    }),
    sequence_number = seq,
    submitted_at_utc = DateTimeOffset.UtcNow.ToString("O")
}, ct);
// seq+1, seq+2, seq+3 for COLLECTION_PHOTO, QUALITY_AUDIT_RECORD, TRANSFER_MANIFEST
```

CHG-2026-00002 — 1 record (WEIGHBRIDGE_RECORD only, no TRANSFER_MANIFEST):
```csharp
seq = EvidenceLinkSubmissionLog.ReadAll().Count;
await EvidenceLinkSubmissionLog.AppendAsync(new { ...worker-chunga-002...
    artifact_type = Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD, sequence_number = seq, ... }, ct);
// NO TRANSFER_MANIFEST record seeded for CHG-2026-00002
```

- [x] Seed 4 records for CHG-2026-00001 (sequential await, sequence_number each)
- [x] Seed 1 record for CHG-2026-00002 (WEIGHBRIDGE_RECORD only)
- [x] worker-chunga-001 on 00001, worker-chunga-002 on 00002 (not swapped)

## Task 5 — Update supervisory dashboard HTML
**File:** `src/supervisory-dashboard/index.html`

PWRM0001 detection client-side (mirror of server):
```javascript
const isPwrm0001 = (programId === 'PGM-ZAMBIA-GRN-001');
```

When `isPwrm0001`:
- Programme header: `"Chunga Dumpsite — PWRM0001 Plastic Collection"`
- Summary card label: `"Collection Programme (PWRM0001)"`

Proof type display label map (mirrors `ProofTypeDisplayLabels`):
```javascript
const PROOF_LABELS = {
  'WEIGHBRIDGE_RECORD':   'Weighbridge Collection Record',
  'COLLECTION_PHOTO':     'Field Collection Photo',
  'QUALITY_AUDIT_RECORD': 'Quality Audit Record',
  'TRANSFER_MANIFEST':    'Offtake Transfer Manifest'
};
function getProofLabel(type) { return PROOF_LABELS[type] ?? type; }
```

WEIGHBRIDGE_RECORD proof row extra fields (when structured_payload present):
```javascript
if (proof.plastic_type) {
  row.appendChild(badge(proof.plastic_type));
  row.appendChild(text(`${proof.net_weight_kg} kg`));
}
```

- [x] Add `isPwrm0001` detection (hard check on programme ID)
- [x] Update header and summary card label in PWRM0001 mode
- [x] Add `PROOF_LABELS` map and `getProofLabel` function
- [x] Add plastic type badge + net weight display for WEIGHBRIDGE_RECORD rows