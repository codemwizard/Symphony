# PWRM0001 Domain Rules

## Programme identity
- Programme ID: `PGM-ZAMBIA-GRN-001`
- Site: Chunga Dumpsite, Lusaka, Zambia
- Coordinates: latitude -15.4167, longitude 28.2833
- Zone radius: 250 metres

## Worker identity — single canonical field: worker_id
The ONLY canonical field name for waste picker identity is `worker_id`.
- Registry storage: `supplier_id` column; `supplier_type = "WORKER"` (required, never null)
- `worker_id` appears in: issue request, token payload, UI display, `collector_id` in structured_payload
- `collector_id` in structured_payload MUST equal the `worker_id` of the submitting worker
- The field name `supplier_id` does NOT appear in any PWRM-specific UI or API contract

## Worker stable GUIDs
worker-chunga-001 → CreateStableGuid("worker-chunga-001")
worker-chunga-002 → CreateStableGuid("worker-chunga-002")

Payout targets: `MMO:+260971100001`, `MMO:+260971100002`
Both registered at: lat -15.4167, lon 28.2833

## supplier_type enforcement at pilot-demo proxy (FIX F15)
For `POST /pilot-demo/api/evidence-links/issue` with `worker_id`:
| supplier_type value | Result |
|---|---|
| `"WORKER"` | Accepted |
| `null` | **REJECTED** → 400 INVALID_SUPPLIER_TYPE |
| any other string | **REJECTED** → 400 INVALID_SUPPLIER_TYPE |

`null` is NOT legacy-compatible in the pilot-demo worker flow.

## GPS rule — immutable after issuance (FIX F13)
1. At issue time: worker registry GPS is embedded in the token
2. Client-provided GPS in the issue request body is silently discarded
3. At submit time: client GPS is validated against token-embedded coordinates ONLY
4. Worker registry is NOT queried again at submit time
5. Token GPS is immutable — it cannot be updated after issuance

## net_weight_kg — backend-authoritative (FIX F14)
The backend computes `net_weight_kg = gross_weight_kg - tare_weight_kg` using
`decimal` arithmetic. The client-submitted `net_weight_kg` is used only as a
sanity check (tolerance 0.01m). The backend-computed value is what is stored
in the log. Never trust browser arithmetic as the stored value.

## structured_payload — REQUIRED for WEIGHBRIDGE_RECORD (FIX F11)
For `artifact_type = "WEIGHBRIDGE_RECORD"`, `structured_payload` is REQUIRED.
Absent or null → 400 `INVALID_REQUEST`. No exceptions. No legacy-compatibility.
All read models may unconditionally assume structured_payload is non-null on
any WEIGHBRIDGE_RECORD in the log.

## Canonical payload shape (locked)
```json
{
  "artifact_type": "WEIGHBRIDGE_RECORD",
  "structured_payload": {
    "plastic_type": "PET",
    "gross_weight_kg": 12.5,
    "tare_weight_kg": 0.1,
    "net_weight_kg": 12.4,
    "collector_id": "worker-chunga-001"
  }
}
```
Note: `net_weight_kg` in this shape is the CLIENT-SUBMITTED value used for
sanity-check only. The stored value is always `gross - tare` computed by backend.

## Valid plastic types
`PET`, `HDPE`, `LDPE`, `PP`, `PS`, `OTHER`

## PWRM0001 programme detection
Primary: `program_id == "PGM-ZAMBIA-GRN-001"` → ALWAYS PWRM0001 (hard override)
Secondary: BOTH artifact_type in PWRM0001 constants AND submitter_class = "WASTE_COLLECTOR"

## Neighbourhood label — hardcoded lookup (no geocoding)
```javascript
function resolveNeighbourhoodLabel(lat, lon) {
  if (lat >= -15.43 && lat <= -15.40 && lon >= 28.26 && lon <= 28.30)
    return "Chunga Dumpsite, Lusaka";
  return "Lusaka";
}
```
Raw coordinates are NEVER displayed in the UI.

## Sequence number — write ordering guarantee
Every submission log record includes `sequence_number` (int) = count of records
before the append. Append is protected by `SemaphoreSlim(1,1)`. "Latest wins" =
highest sequence_number. No timestamp-based sort is ever used.

## Proof types
| Constant | Display label |
|---|---|
| `WEIGHBRIDGE_RECORD` | Weighbridge Collection Record |
| `COLLECTION_PHOTO` | Field Collection Photo |
| `QUALITY_AUDIT_RECORD` | Quality Audit Record |
| `TRANSFER_MANIFEST` | Offtake Transfer Manifest |

## Weight arithmetic
All weights: `decimal` (not `double`). TOTAL accumulated in same pass as per-type.
`proof_completeness_rate` computed as `decimal` division with zero guard → 1.0.

## Demo instructions
| ID | Worker | Status | Proof types present |
|---|---|---|---|
| `CHG-2026-00001` | worker-chunga-001 | SETTLED | All four |
| `CHG-2026-00002` | worker-chunga-002 | HOLD | WEIGHBRIDGE_RECORD only |