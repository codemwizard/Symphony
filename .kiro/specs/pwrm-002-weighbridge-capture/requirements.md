# PWRM-002: Weighbridge Evidence Capture with Validated Structured Payload

## Background
Every WEIGHBRIDGE_RECORD must carry a validated structured_payload. This is
REQUIRED (not optional) for the pilot. Backend recomputes net_weight_kg from
gross and tare — client-submitted net is only a sanity check. Sequence numbers
make append-order explicit and testable.

## US-1: structured_payload is REQUIRED for WEIGHBRIDGE_RECORD (FIX F11)

**Acceptance criteria:**
- WHEN `artifact_type = "WEIGHBRIDGE_RECORD"` AND `structured_payload` is null/absent → 400 `INVALID_REQUEST`, message: `"structured_payload is required for WEIGHBRIDGE_RECORD"`.
- This check fires AFTER GPS validation (GPS is the outermost gate).
- All other artifact types: structured_payload is ignored entirely.

## US-2: Backend recomputes net_weight_kg — client value is sanity-check only (FIX F14)

**Acceptance criteria:**
- WHEN `structured_payload` is present and `artifact_type = "WEIGHBRIDGE_RECORD"`:
  - Backend computes `backend_net = gross_weight_kg - tare_weight_kg` using `decimal` arithmetic.
  - IF `Math.Abs(submitted_net - backend_net) > 0.01m` → 400 `INVALID_WEIGHBRIDGE_PAYLOAD`, violation: `"net_weight_kg does not match gross minus tare within 0.01 tolerance"`.
  - The value stored in the log as `net_weight_kg` is ALWAYS `backend_net`, NOT `submitted_net`.
- All weight fields MUST be JSON numbers (not strings). String `"12.4"` → violation.
- `plastic_type` must be one of: `PET`, `HDPE`, `LDPE`, `PP`, `PS`, `OTHER`.
- `gross_weight_kg > 0`, `tare_weight_kg >= 0`, `backend_net > 0`.
- `collector_id` is a non-empty string.
- `violations` is always a non-null array.

**Canonical locked payload shape:**
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
`net_weight_kg` = 12.4 passes the tolerance check (12.5 - 0.1 = 12.4, diff = 0.0).
Backend stores 12.4 (= backend_net).

## US-3: GPS validation runs before payload validation

**Acceptance criteria:**
- WHEN submitted GPS is outside 250m Chunga zone → 422 `GPS_MATCH_FAILED` regardless of payload.
- GPS validation order: token check → tenant/MSISDN check → artifact presence → **GPS** → payload required → payload validate.

## US-4: sequence_number written with every submission (FIX F12)

**Acceptance criteria:**
- Every submission log record includes `sequence_number` (int) = `ReadAll().Count` before append.
- Append is serialised via `SemaphoreSlim(1,1)` on `EvidenceLinkSubmissionLog`.
- "Latest wins" for duplicate `instruction_id` = highest `sequence_number`.
- Read models rely on `sequence_number` only, never on timestamps.

## US-5: Weighbridge form in recipient UI — net weight is display-only

**Acceptance criteria:**
- WHEN `submitter_class = "WASTE_COLLECTOR"`: show weighbridge form.
- Net Weight field is `readonly`. Value is `(parseFloat(gross) - parseFloat(tare)).toFixed(2)`.
- **Note:** the displayed net is for user orientation only. Backend recomputes it.
- Submitted JSON uses `parseFloat` for all numeric fields (not raw string values).
- `collector_id` is pre-filled from token `worker_id`, readonly.

## US-6: Self-test — 7 cases, fully isolated

**Acceptance criteria:**
- `dotnet run --self-test-weighbridge-capture` exits 0, 7 cases PASS.
- Runner deletes its own NDJSON files at start.
- Runner uses namespaced IDs.
- Case specifically tests backend net recomputation (not client value).