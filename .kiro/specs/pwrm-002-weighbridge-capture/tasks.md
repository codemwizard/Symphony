# PWRM-002 Implementation Tasks

## Task 1 — Add structured_payload to EvidenceLinkSubmitRequest
**File:** `Commands/CommandContracts.cs`
```csharp
record EvidenceLinkSubmitRequest(
    string artifact_type,
    string artifact_ref,
    decimal? latitude,
    decimal? longitude,
    JsonElement? structured_payload = null
);
```

- [x] Add `JsonElement? structured_payload = null` to the record
- [x] Confirm existing tests compile (additive change)

## Task 2 — Add SemaphoreSlim to EvidenceLinkSubmissionLog (FIX F12)
**File:** `Commands/EvidenceLinkHandlers.cs`

Add `private static readonly SemaphoreSlim _appendLock = new(1, 1);`
Wrap the AppendAsync body:
```csharp
public static async Task AppendAsync(object payload, CancellationToken ct)
{
    await _appendLock.WaitAsync(ct);
    try
    {
        var seq = ReadAll().Count;
        // build final object including sequence_number = seq
        // then call TamperEvidentChain.AppendJsonAsync
    }
    finally { _appendLock.Release(); }
}
```
All PWRM appends automatically receive sequence_number. Existing tests are
unaffected (they don't assert on sequence_number yet).

- [x] Add `_appendLock` SemaphoreSlim
- [x] Wrap AppendAsync to compute + inject sequence_number inside lock
- [x] Confirm GeoCaptureSelfTestRunner and EvidenceLinkSelfTestRunner still pass

## Task 3 — Create Pwrm0001WeighbridgePayloadValidator with backend net recomputation (FIX F14)
**File:** `Commands/Pwrm0001ArtifactTypes.cs` (add to file from PWRM-001)
```csharp
static class Pwrm0001WeighbridgePayloadValidator
{
    private static readonly HashSet<string> ValidPlasticTypes =
        new(StringComparer.Ordinal) { "PET","HDPE","LDPE","PP","PS","OTHER" };

    // Returns violations array + the backend-computed net weight
    public static (string[] violations, decimal backendNet) Validate(JsonElement payload)
    {
        var violations = new List<string>();
        decimal gross = 0m, tare = 0m, submittedNet = 0m;
        decimal backendNet = 0m;

        // plastic_type
        if (!payload.TryGetProperty("plastic_type", out var ptEl) || ptEl.ValueKind != JsonValueKind.String)
            violations.Add("plastic_type is required and must be a string");
        else if (!ValidPlasticTypes.Contains(ptEl.GetString()!))
            violations.Add($"plastic_type '{ptEl.GetString()}' is not valid; must be PET HDPE LDPE PP PS OTHER");

        // gross_weight_kg — must be JSON number (decimal)
        if (!payload.TryGetProperty("gross_weight_kg", out var gEl) || gEl.ValueKind != JsonValueKind.Number)
            violations.Add("gross_weight_kg must be a JSON number");
        else { gross = gEl.GetDecimal(); if (gross <= 0m) violations.Add("gross_weight_kg must be > 0"); }

        // tare_weight_kg — must be JSON number (decimal)
        if (!payload.TryGetProperty("tare_weight_kg", out var tEl) || tEl.ValueKind != JsonValueKind.Number)
            violations.Add("tare_weight_kg must be a JSON number");
        else { tare = tEl.GetDecimal(); if (tare < 0m) violations.Add("tare_weight_kg must be >= 0"); }

        // net_weight_kg — present and is a number; used for sanity check only
        if (!payload.TryGetProperty("net_weight_kg", out var nEl) || nEl.ValueKind != JsonValueKind.Number)
            violations.Add("net_weight_kg must be a JSON number");
        else submittedNet = nEl.GetDecimal();

        // backend recomputes net; tolerance check
        backendNet = gross - tare;
        if (violations.Count == 0 && Math.Abs(submittedNet - backendNet) > 0.01m)
            violations.Add($"net_weight_kg {submittedNet} does not match gross {gross} minus tare {tare} within 0.01 tolerance");

        // collector_id
        if (!payload.TryGetProperty("collector_id", out var cidEl)
            || cidEl.ValueKind != JsonValueKind.String
            || string.IsNullOrWhiteSpace(cidEl.GetString()))
            violations.Add("collector_id is required and must be a non-empty string");

        return (violations.ToArray(), backendNet);
    }
}
```

- [x] Add validator class to `Pwrm0001ArtifactTypes.cs`
- [x] Return `(violations, backendNet)` tuple
- [x] All weight parsing uses `decimal` (GetDecimal)
- [x] `ValueKind != JsonValueKind.Number` check on all weight fields
- [x] Tolerance uses `0.01m` (decimal literal, not double)

## Task 4 — Update EvidenceLinkSubmitHandler with payload gating + backend net storage (FIX F11 + F14)
**File:** `Commands/EvidenceLinkHandlers.cs`

After the GPS check block and before the duplicate-check, add:
```csharp
// FIX F11: WEIGHBRIDGE_RECORD requires structured_payload (pilot policy, no exceptions)
decimal? storedNetWeight = null;
if (string.Equals(request.artifact_type.Trim(), Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD, StringComparison.Ordinal))
{
    if (request.structured_payload is null ||
        request.structured_payload.Value.ValueKind == JsonValueKind.Null)
    {
        return new HandlerResult(StatusCodes.Status400BadRequest, new
        {
            error_code = "INVALID_REQUEST",
            errors = new[] { "structured_payload is required for WEIGHBRIDGE_RECORD" }
        });
    }

    // FIX F14: backend recomputes net; violations include tolerance check
    var (violations, backendNet) = Pwrm0001WeighbridgePayloadValidator.Validate(
        request.structured_payload.Value);

    if (violations.Length > 0)
    {
        return new HandlerResult(StatusCodes.Status400BadRequest, new
        {
            error_code = "INVALID_WEIGHBRIDGE_PAYLOAD",
            violations   // non-null, non-empty
        });
    }
    storedNetWeight = backendNet;  // backend value, not client value
}
```

In the AppendAsync call, include:
- `structured_payload = request.structured_payload` (raw JsonElement, not stringified)
- When `storedNetWeight` is set, override `net_weight_kg` in the stored payload with `storedNetWeight`

Sequence_number is injected automatically by the updated `AppendAsync` (Task 2).

- [x] Add WEIGHBRIDGE_RECORD required-payload gate (returns 400 if null)
- [x] Call validator; propagate violations on failure
- [x] Store `backendNet` as `net_weight_kg` in the log (not client value)
- [x] Store `structured_payload` as raw JsonElement (not double-stringified)
- [x] GPS check still runs before this block

## Task 5 — Update recipient landing page weighbridge form (FIX F14)
**File:** `src/recipient-landing/index.html`

Show weighbridge form when `submitter_class === "WASTE_COLLECTOR"`:
- Plastic Type: `<select>` — PET, HDPE, LDPE, PP, PS, OTHER
- Gross Weight kg: `<input type="number" step="0.01" min="0.01">`
- Tare Weight kg: `<input type="number" step="0.01" min="0">`
- Net Weight kg: `<input type="number" readonly>` — display only, updated on gross/tare change
- Collector ID: `<input type="text" readonly>` — pre-filled from token `worker_id`

Net weight display:
```javascript
function updateNetWeight() {
  const g = parseFloat(grossInput.value) || 0;
  const t = parseFloat(tareInput.value)  || 0;
  netInput.value = (g - t).toFixed(2);
}
grossInput.addEventListener('input', updateNetWeight);
tareInput.addEventListener('input', updateNetWeight);
```

Submit body:
```javascript
const body = {
  artifact_type: "WEIGHBRIDGE_RECORD",
  artifact_ref: uploadedPhotoRef,
  latitude: geoLat,
  longitude: geoLon,
  structured_payload: {
    plastic_type: plasticTypeSelect.value,
    gross_weight_kg: parseFloat(grossInput.value),  // MUST be parseFloat
    tare_weight_kg:  parseFloat(tareInput.value),   // MUST be parseFloat
    net_weight_kg:   parseFloat(netInput.value),    // sanity check; backend recomputes
    collector_id:    collectorIdInput.value
  }
};
```

Comment in code: `// net_weight_kg is for display/sanity only — backend recomputes from gross-tare`

- [x] Build form with 5 fields
- [x] Net weight computed via parseFloat (not parseInt)
- [x] net_weight_kg field is readonly
- [x] All numerics submitted as parseFloat (JSON numbers not strings)
- [x] Code comment explaining backend recomputation

## Task 6 — Create WeighbridgeCaptureSelfTestRunner.cs (7 cases)
**File:** `Demo/WeighbridgeCaptureSelfTestRunner.cs`
**Registration:** `["--self-test-weighbridge-capture"]` in `DemoSelfTestEntryPoint.SelfTests`

Runner uses:
- `tenantId = "33333333-3333-3333-3333-333333333333"`
- `programId = "PGM-SELFTEST-PWRM002"`
- Isolated NDJSON paths, deleted at start
- Worker seeded with `supplier_type = "WORKER"`, lat=-15.4167, lon=28.2833

7 test cases:

| # | Input | Expected |
|---|-------|----------|
| 1 | WEIGHBRIDGE_RECORD + valid payload (gross=12.5, tare=0.1, net=12.4, PET) | 202; log record has net_weight_kg=12.4 (backend computed) |
| 2 | WEIGHBRIDGE_RECORD + invalid plastic_type "GLASS" | 400 `INVALID_WEIGHBRIDGE_PAYLOAD`, violations non-empty |
| 3 | WEIGHBRIDGE_RECORD + net mismatch (gross=10, tare=1, submitted_net=5; diff=4.0 > 0.01) | 400 `INVALID_WEIGHBRIDGE_PAYLOAD` |
| 4 | WEIGHBRIDGE_RECORD + net submitted as string "12.4" (not number) | 400 `INVALID_WEIGHBRIDGE_PAYLOAD` (F14 type check) |
| 5 | WEIGHBRIDGE_RECORD + null structured_payload | 400 `INVALID_REQUEST` (F11) |
| 6 | GPS 14km outside zone (GPS check fires before payload) | 422 `GPS_MATCH_FAILED` even with valid payload |
| 7 | Two WEIGHBRIDGE_RECORD submissions same instruction_id; second has higher seq | ReadAll has 2 records; second has sequence_number > first; winner = second |

Case 4 specifically tests the F14 type-check (string value → violation).
Case 6 verifies GPS is checked before payload (F11 ordering).
Case 7 verifies sequence_number is monotonically increasing.

- [x] Create `WeighbridgeCaptureSelfTestRunner.cs` with 7 cases
- [x] Register `--self-test-weighbridge-capture`
- [x] Case 1: assert stored `net_weight_kg` equals backend-computed value
- [x] Case 4: submit net as JSON string; expect violation (F14)
- [x] Case 6: assert GPS error, not payload error
- [x] Case 7: assert two records, second has higher sequence_number
- [x] Write evidence to `evidence/phase1/pwrm_weighbridge_capture.json`