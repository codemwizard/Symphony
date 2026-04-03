# PWRM-001 Implementation Tasks

## Task 1 — Add WASTE_COLLECTOR to submitter class allowlist
**File:** `Commands/EvidenceLinkHandlers.cs`

Add `ValidSubmitterClasses` HashSet to `EvidenceLinkIssueHandler`.
After the whitespace check on `submitter_class`, add allowlist check:
```csharp
private static readonly HashSet<string> ValidSubmitterClasses =
    new(StringComparer.Ordinal)
    { "VENDOR", "FIELD_OFFICER", "BORROWER", "SUPPLIER", "WASTE_COLLECTOR" };

// In HandleAsync, after null check:
if (!ValidSubmitterClasses.Contains(request.submitter_class.Trim()))
{
    return new HandlerResult(StatusCodes.Status400BadRequest, new
    {
        error_code = "INVALID_SUBMITTER_CLASS",
        errors = new[] { $"submitter_class '{request.submitter_class}' is not valid" }
    });
}
```

- [ ] Add `ValidSubmitterClasses` HashSet
- [ ] Add allowlist check returning 400 + `INVALID_SUBMITTER_CLASS`
- [ ] Confirm all existing self-tests still pass (SUPPLIER, FIELD_OFFICER, BORROWER, VENDOR all in set)

## Task 2 — Add supplier_type to SupplierRegistryUpsertRequest and in-memory store
**File:** `Commands/CommandContracts.cs`
```csharp
record SupplierRegistryUpsertRequest(
    string tenant_id,
    string supplier_id,
    string supplier_name,
    string payout_target,
    decimal? registered_latitude,
    decimal? registered_longitude,
    bool active,
    string? supplier_type = null   // NEW — "WORKER" for waste pickers
);
```

Ensure the in-memory `SupplierRegistry` (wherever it is stored) retains and
exposes the `supplier_type` field on retrieval.

- [ ] Add `string? supplier_type` to `SupplierRegistryUpsertRequest`
- [ ] Store `supplier_type` in the registry entry
- [ ] Expose `supplier_type` on registry lookup result

## Task 3 — Create Pwrm0001ArtifactTypes.cs
**File:** `Commands/Pwrm0001ArtifactTypes.cs` (new file)
```csharp
static class Pwrm0001ArtifactTypes
{
    public const string WEIGHBRIDGE_RECORD   = "WEIGHBRIDGE_RECORD";
    public const string COLLECTION_PHOTO     = "COLLECTION_PHOTO";
    public const string QUALITY_AUDIT_RECORD = "QUALITY_AUDIT_RECORD";
    public const string TRANSFER_MANIFEST    = "TRANSFER_MANIFEST";

    public static readonly IReadOnlyDictionary<string, string> ProofTypeDisplayLabels =
        new Dictionary<string, string>(StringComparer.Ordinal)
        {
            [WEIGHBRIDGE_RECORD]   = "Weighbridge Collection Record",
            [COLLECTION_PHOTO]     = "Field Collection Photo",
            [QUALITY_AUDIT_RECORD] = "Quality Audit Record",
            [TRANSFER_MANIFEST]    = "Offtake Transfer Manifest",
        };

    public static bool IsPwrm0001ArtifactType(string? value) =>
        value is not null && ProofTypeDisplayLabels.ContainsKey(value);
}
```

- [ ] Create file with four constants
- [ ] Add `ProofTypeDisplayLabels` dictionary (single source of truth)
- [ ] Add `IsPwrm0001ArtifactType` helper

## Task 4 — Seed Chunga workers in Program.cs with supplier_type = "WORKER" (never null)
**File:** `Program.cs`

In the pilot-demo startup seeding block:
```csharp
var workerChunga001Id = CreateStableGuid("worker-chunga-001").ToString();
var workerChunga002Id = CreateStableGuid("worker-chunga-002").ToString();
const string PgmZambiaGrn  = "PGM-ZAMBIA-GRN-001";
const string DemoTenantId  = "11111111-1111-1111-1111-111111111111";

await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    DemoTenantId, workerChunga001Id, "Chunga Worker 001",
    "MMO:+260971100001", -15.4167m, 28.2833m, true,
    supplier_type: "WORKER"));   // explicit — never null

await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    DemoTenantId, workerChunga002Id, "Chunga Worker 002",
    "MMO:+260971100002", -15.4167m, 28.2833m, true,
    supplier_type: "WORKER"));   // explicit — never null

await ProgramSupplierAllowlistUpsertHandler.HandleAsync(
    new ProgramSupplierAllowlistUpsertRequest(DemoTenantId, PgmZambiaGrn, workerChunga001Id, true));
await ProgramSupplierAllowlistUpsertHandler.HandleAsync(
    new ProgramSupplierAllowlistUpsertRequest(DemoTenantId, PgmZambiaGrn, workerChunga002Id, true));
```

- [ ] Seed both workers with `supplier_type = "WORKER"` explicitly
- [ ] Both workers on `PGM-ZAMBIA-GRN-001` allowlist

## Task 5 — Add /pilot-demo/api/evidence-links/issue proxy route
**File:** `Program.cs`

Define `PilotDemoEvidenceLinkIssueRequest`:
```csharp
record PilotDemoEvidenceLinkIssueRequest(
    string? worker_id,         // PWRM-specific; null = not a worker request
    string tenant_id,
    string instruction_id,
    string program_id,
    string submitter_class,
    string submitter_msisdn,
    int? expires_in_seconds
    // NOTE: expected_latitude, expected_longitude, max_distance_meters are NOT
    // accepted from client when worker_id is set — they come from registry only
);
```

Route logic:
```csharp
app.MapPost("/pilot-demo/api/evidence-links/issue", async (
    PilotDemoEvidenceLinkIssueRequest req, HttpContext ctx, CancellationToken ct) =>
{
    if (!TryValidatePilotDemoOperatorCookie(ctx, null, out var ec, out var errs))
        return Results.Json(new { error_code = ec, errors = errs }, statusCode: 401);

    decimal? lat = null, lon = null, maxDist = null;

    if (req.worker_id is not null)
    {
        var entry = SupplierRegistry.TryGet(req.worker_id);
        if (entry is null)
            return Results.Json(new { error_code = "WORKER_NOT_FOUND" }, statusCode: 404);

        // FIX F15: null is rejected — only explicit "WORKER" is accepted
        if (entry.SupplierType != "WORKER")
            return Results.Json(new { error_code = "INVALID_SUPPLIER_TYPE" }, statusCode: 400);

        // FIX F13: registry GPS injected; caller GPS discarded entirely
        lat = entry.RegisteredLatitude;
        lon = entry.RegisteredLongitude;
        maxDist = 250.0m;
    }

    var issueReq = new EvidenceLinkIssueRequest(
        req.tenant_id, req.instruction_id, req.program_id,
        req.submitter_class, req.submitter_msisdn,
        lat, lon, maxDist, req.expires_in_seconds);

    var result = await EvidenceLinkIssueHandler.HandleAsync(issueReq, logger, ct);
    return Results.Json(result.Body, statusCode: result.StatusCode);
});
```

- [ ] Define `PilotDemoEvidenceLinkIssueRequest` (no GPS fields from client)
- [ ] Add route with operator cookie gate
- [ ] Implement null check on supplier_type (null → rejected)
- [ ] Inject registry GPS; discard any client GPS
- [ ] Confirm generic `/v1/evidence-links/issue` does NOT accept `worker_id`

## Task 6 — Update recipient landing page for WASTE_COLLECTOR
**File:** `src/recipient-landing/index.html`

When decoded token `submitter_class === "WASTE_COLLECTOR"`:
```javascript
function resolveNeighbourhoodLabel(lat, lon) {
  if (lat >= -15.43 && lat <= -15.40 && lon >= 28.26 && lon <= 28.30)
    return "Chunga Dumpsite, Lusaka";
  return "Lusaka";
}
// Display: "Waste Collector" | "Collection Zone: Chunga Dumpsite, Lusaka"
// Display: "Identity Check: Your phone number must match..."
// NEVER display raw lat/lon in DOM
```

- [ ] Add WASTE_COLLECTOR detection branch
- [ ] Implement `resolveNeighbourhoodLabel` hardcoded lookup
- [ ] Show role label, zone label, identity check message
- [ ] Assert no raw coordinates render

## Task 7 — Create WorkerOnboardingSelfTestRunner.cs (8 cases, fully isolated)
**File:** `Demo/WorkerOnboardingSelfTestRunner.cs`
**Registration:** `["--self-test-worker-onboarding"]` in `DemoSelfTestEntryPoint.SelfTests`

Runner setup:
```csharp
// Namespaced IDs — cannot collide with Program.cs seeding or other runners
var runnerSuffix = "pwrm001-selftest";
var tenantId     = "22222222-2222-2222-2222-222222222222";  // different from demo tenant
var programId    = $"PGM-SELFTEST-{runnerSuffix}";
var worker001Id  = CreateStableGuid($"worker-chunga-001-{runnerSuffix}").ToString();
var worker002Id  = CreateStableGuid($"worker-chunga-002-{runnerSuffix}").ToString();

// Isolated NDJSON paths
var submissionsPath = $"/tmp/pwrm001_selftest_submissions.ndjson";
var smsLogPath      = $"/tmp/pwrm001_selftest_sms.ndjson";
File.Delete(submissionsPath);
File.Delete(smsLogPath);
Environment.SetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE", submissionsPath);
Environment.SetEnvironmentVariable("EVIDENCE_LINK_SMS_DISPATCH_FILE", smsLogPath);
Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", tenantId);
Environment.SetEnvironmentVariable("DEMO_EVIDENCE_LINK_SIGNING_KEY", "pwrm001-selftest-key");

// Seed workers with explicit supplier_type = "WORKER" (not null)
await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    tenantId, worker001Id, "Test Worker 001", "MMO:+260971100001",
    -15.4167m, 28.2833m, true, supplier_type: "WORKER"));
await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    tenantId, worker002Id, "Test Worker 002", "MMO:+260971100002",
    -15.4167m, 28.2833m, true, supplier_type: "WORKER"));

// Seed a SUPPLIER entry (supplier_type explicitly not "WORKER", for test case 6)
var supplierFakeId = CreateStableGuid($"supplier-fake-{runnerSuffix}").ToString();
await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    tenantId, supplierFakeId, "Fake Supplier", "MMO:+260971199999",
    null, null, true, supplier_type: "SUPPLIER"));

// Seed a NULL-type entry (for test case 7: null → rejected)
var nullTypeId = CreateStableGuid($"supplier-null-type-{runnerSuffix}").ToString();
await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    tenantId, nullTypeId, "Null Type Entry", "MMO:+260971188888",
    null, null, true, supplier_type: null));

await ProgramSupplierAllowlistUpsertHandler.HandleAsync(
    new ProgramSupplierAllowlistUpsertRequest(tenantId, programId, worker001Id, true));
```

8 test cases:

| # | Input | Expected |
|---|-------|----------|
| 1 | `submitter_class = "WASTE_COLLECTOR"` on generic route | 200 |
| 2 | `submitter_class = "UNKNOWN_CLASS"` | 400 `INVALID_SUBMITTER_CLASS` |
| 3 | GET policy for worker001Id | `decision = "ALLOW"` |
| 4 | Pilot-demo issue with `worker_id = worker001Id` + WASTE_COLLECTOR | 200; token has lat=-15.4167, lon=28.2833 |
| 5 | Pilot-demo issue with `worker_id = worker001Id` + caller provides wrong GPS | 200; token has REGISTRY GPS not caller GPS |
| 6 | Pilot-demo issue with `worker_id = supplierFakeId` (supplier_type = "SUPPLIER") | 400 `INVALID_SUPPLIER_TYPE` |
| 7 | Pilot-demo issue with `worker_id = nullTypeId` (supplier_type = null) | 400 `INVALID_SUPPLIER_TYPE` |
| 8 | Pilot-demo issue with `worker_id = "nonexistent-guid"` | 404 `WORKER_NOT_FOUND` |

- [ ] Create runner with all 8 cases
- [ ] Register `--self-test-worker-onboarding` in `DemoSelfTestEntryPoint`
- [ ] Case 5 confirms caller GPS is discarded (F13)
- [ ] Case 7 confirms null supplier_type is rejected (F15)
- [ ] Write evidence to `evidence/phase1/pwrm_worker_onboarding.json`
- [ ] All appends use sequential `await`, no `Task.WhenAll`