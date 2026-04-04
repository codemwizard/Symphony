# PWRM-001: Worker Registry, Onboarding, and Scoped Token Issuance

## Background
Waste pickers at Chunga Dumpsite receive GPS-locked evidence tokens.
Workers live in the supplier registry with `supplier_type = "WORKER"` (never null).
GPS is locked at issuance and immutable thereafter.

## US-1: Submitter class validation

**As** an API consumer,  
**I want** `WASTE_COLLECTOR` accepted as a `submitter_class`,  
**so that** waste picker tokens can be issued.

**Acceptance criteria:**
- WHEN `submitter_class` is `WASTE_COLLECTOR` → 200.
- WHEN `submitter_class` is not in `{VENDOR, FIELD_OFFICER, BORROWER, SUPPLIER, WASTE_COLLECTOR}` → 400 `INVALID_SUBMITTER_CLASS`.
- The check is an explicit HashSet comparison (not regex or prefix).

## US-2: Worker seeding at startup — supplier_type never null

**As** the pilot demo operator,  
**I want** two Chunga workers pre-seeded with `supplier_type = "WORKER"`,  
**so that** no manual provisioning is needed and null-type lookups cannot occur.

**Acceptance criteria:**
- ON startup, two registry entries exist with `supplier_type = "WORKER"` (exact string, not null).
- `supplier_id` = `CreateStableGuid("worker-chunga-001")` and `CreateStableGuid("worker-chunga-002")`.
- Both entries: `registered_latitude = -15.4167`, `registered_longitude = 28.2833`.
- Payout targets: `MMO:+260971100001`, `MMO:+260971100002`.
- Both on allowlist for `PGM-ZAMBIA-GRN-001`.
- GET policy for worker-chunga-001 → `decision = "ALLOW"` with no manual steps.

## US-3: worker_id issues GPS-locked token — null supplier_type rejected (FIX F13 + F15)

**As** the pilot demo operator,  
**I want** `worker_id` to auto-fill GPS from the registry,  
**so that** GPS is always server-authoritative and non-WORKER registry entries are rejected.

**Acceptance criteria:**
- WHEN `POST /pilot-demo/api/evidence-links/issue` includes `worker_id` + `submitter_class = "WASTE_COLLECTOR"`:
  - Worker not found → 404 `WORKER_NOT_FOUND`.
  - `supplier_type == null` → 400 `INVALID_SUPPLIER_TYPE`. *(null is not legacy-compatible here)*
  - `supplier_type` is non-null and not `"WORKER"` → 400 `INVALID_SUPPLIER_TYPE`.
  - `supplier_type == "WORKER"` → proceed.
- Server sets `expected_latitude`, `expected_longitude` from registry; `max_distance_meters = 250.0`.
- ANY `expected_latitude`/`expected_longitude` in the caller's request body are silently discarded.
- Token embeds the registry GPS; caller-provided GPS is NEVER embedded.
- `worker_id` is NOT accepted on `/v1/evidence-links/issue`.

## US-4: GPS is immutable after issuance (FIX F13)

**As** the evidence integrity system,  
**I want** GPS coordinates to be fixed at token issuance time,  
**so that** submit-time validation is deterministic regardless of registry changes.

**Acceptance criteria:**
- WHEN a token is validated at submit time, GPS is read from the token's embedded fields, NOT re-queried from the worker registry.
- WHEN a worker's registered coordinates change after a token is issued, the existing token still validates against its embedded coordinates.
- The submit handler performs no worker registry lookup.

## US-5: Recipient landing page displays worker context

**As** a waste picker,  
**I want** the landing page to identify my role and zone clearly,  
**so that** I know what to do.

**Acceptance criteria:**
- Token `submitter_class = "WASTE_COLLECTOR"` → label `"Waste Collector"` (not enum string).
- Zone label = `resolveNeighbourhoodLabel(lat, lon)` from hardcoded lookup → `"Chunga Dumpsite, Lusaka"`.
- Displays: `"Identity Check: Your phone number must match the one registered for this link"`.
- Raw latitude/longitude values are NEVER visible in the DOM.

## US-6: Self-test — 8 cases, fully isolated

**Acceptance criteria:**
- `dotnet run --self-test-worker-onboarding` exits 0, all 8 cases PASS.
- Runner deletes its own NDJSON files before starting.
- Runner uses namespaced IDs; does not rely on Program.cs startup seeding.
- Runner does NOT use `Task.WhenAll` on sequential appends.