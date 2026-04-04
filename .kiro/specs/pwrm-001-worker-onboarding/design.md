# PWRM-001 Design

## FIX F15: null supplier_type rejected in pilot-demo worker flow
The pilot-demo proxy does NOT treat `supplier_type = null` as legacy-compatible.
Any registry entry that is not explicitly `supplier_type = "WORKER"` (including null)
is rejected with 400 `INVALID_SUPPLIER_TYPE`.

Rationale: this eliminates the ambiguity class entirely. All seeded workers have
`supplier_type = "WORKER"`. If null somehow appears, it means the entry was not
properly seeded — which is a data problem, not a legacy compatibility case.

Lookup logic in the proxy route:
```csharp
var entry = SupplierRegistry.TryGet(workerId);
if (entry is null)
    return 404 WORKER_NOT_FOUND;
if (entry.SupplierType != "WORKER")   // null, "SUPPLIER", anything else → rejected
    return 400 INVALID_SUPPLIER_TYPE;
// proceed — GPS injection
```

## FIX F13: GPS locked at issuance, immutable
The pilot-demo proxy injects GPS from the worker registry into the issue request.
The token carries this GPS. The submit handler reads GPS from the token only.
No re-query of the worker registry occurs at submit time.

Sequence:
POST /pilot-demo/api/evidence-links/issue { worker_id, submitter_class }
│
▼
Proxy: look up worker registry by worker_id
→ check supplier_type == "WORKER" (not null, not other)
→ discard any caller-provided GPS
→ inject registry GPS + max_distance=250
│
▼
EvidenceLinkIssueHandler.HandleAsync(enriched request)
→ token created with embedded GPS
│
▼
POST /api/public/evidence-links/submit { artifact_type, artifact_ref, latitude, longitude }
│
▼
EvidenceLinkSubmitHandler: validate submitted GPS against TOKEN-EMBEDDED GPS only
(no worker registry access here)

## FIX F11: structured_payload required — enforcement at proxy too
Even though structured_payload enforcement is primarily in the submit handler
(PWRM-002), the recipient landing page form for WASTE_COLLECTOR MUST always
supply structured_payload. The UI has no "skip payload" path for WASTE_COLLECTOR.

## Submitter class allowlist
```csharp
private static readonly HashSet<string> ValidSubmitterClasses =
    new(StringComparer.Ordinal)
    { "VENDOR", "FIELD_OFFICER", "BORROWER", "SUPPLIER", "WASTE_COLLECTOR" };
```

## Neighbourhood label — hardcoded, no geocoding API
```javascript
function resolveNeighbourhoodLabel(lat, lon) {
  if (lat >= -15.43 && lat <= -15.40 && lon >= 28.26 && lon <= 28.30)
    return "Chunga Dumpsite, Lusaka";
  return "Lusaka";
}
```
Raw coordinate values are never rendered.

## New files
- `Commands/Pwrm0001ArtifactTypes.cs` — constants + ProofTypeDisplayLabels (needed by PWRM-002)
- `Demo/WorkerOnboardingSelfTestRunner.cs`

## SupplierRegistryUpsertRequest extension
`CommandContracts.cs` gains `string? supplier_type = null` on the record.
`SupplierRegistry` (in-memory store) stores this field.
All PWRM workers are seeded with explicit `supplier_type = "WORKER"`.