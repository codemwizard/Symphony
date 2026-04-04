# PWRM-001-T4 PLAN — Seed Chunga workers in Program.cs with supplier_type = "WORKER" and program allowlist

Task: PWRM-001-T4
Owner: IMPLEMENTER
Depends on: PWRM-001-T2
failure_signature: phase1.pwrm001.t4.worker_seeding_missing
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Add two Chunga waste picker workers to the pilot-demo startup seeding block in Program.cs with
explicit `supplier_type: "WORKER"` (never null), GPS at Chunga Dumpsite (-15.4167, 28.2833), and
both workers on the PGM-ZAMBIA-GRN-001 allowlist. Done when GET policy for worker-chunga-001
returns decision = "ALLOW" with no manual steps, and both registry entries have SupplierType ==
"WORKER" on lookup.

---

## Architectural Context

Without pre-seeded workers the pilot-demo proxy (T5) always returns 404 WORKER_NOT_FOUND, making
the WASTE_COLLECTOR flow completely non-functional in the demo. The seeding must use CreateStableGuid
for idempotency across restarts, and supplier_type must be explicitly passed (not relying on the
null default) because the T5 proxy rejects null as FIX F15 requires. The self-test runner (T7)
uses a different tenant and namespaced IDs specifically to avoid any collision with this seeding.

---

## Design Reference (from .kiro/specs/pwrm-001-worker-onboarding/design.md)

### FIX F15: null supplier_type rejected in pilot-demo worker flow

The pilot-demo proxy does NOT treat supplier_type = null as legacy-compatible. Any registry entry
that is not explicitly supplier_type = "WORKER" (including null) is rejected with 400
INVALID_SUPPLIER_TYPE. Rationale: this eliminates the ambiguity class entirely. All seeded workers
have supplier_type = "WORKER". If null somehow appears, it means the entry was not properly seeded
— which is a data problem, not a legacy compatibility case.

### FIX F13: GPS locked at issuance, immutable

GPS is locked at issuance from the registry. The submit handler reads GPS from the token only.

### Worker seeding (from design.md)

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

---

## Requirements Reference (from .kiro/specs/pwrm-001-worker-onboarding/requirements.md)

### US-2: Worker seeding at startup — supplier_type never null

**As** the pilot demo operator,
**I want** two Chunga workers pre-seeded with supplier_type = "WORKER",
**so that** no manual provisioning is needed and null-type lookups cannot occur.

Acceptance criteria:
- ON startup, two registry entries exist with supplier_type = "WORKER" (exact string, not null).
- supplier_id = CreateStableGuid("worker-chunga-001") and CreateStableGuid("worker-chunga-002").
- Both entries: registered_latitude = -15.4167, registered_longitude = 28.2833.
- Payout targets: MMO:+260971100001, MMO:+260971100002.
- Both on allowlist for PGM-ZAMBIA-GRN-001.
- GET policy for worker-chunga-001 → decision = "ALLOW" with no manual steps.

### US-3: worker_id issues GPS-locked token — null supplier_type rejected (FIX F13 + F15)

Acceptance criteria:
- supplier_type == null → 400 INVALID_SUPPLIER_TYPE (null is not legacy-compatible).
- supplier_type == "WORKER" → proceed.

### US-6: Self-test — 8 cases, fully isolated

- Runner uses namespaced IDs; does not rely on Program.cs startup seeding.

---

## Pre-conditions

- [ ] PWRM-001-T2 is status=completed (supplier_type field exists on request record).
- [ ] This PLAN.md has been reviewed before any code is written.
- [ ] services/ledger-api solution builds cleanly.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `services/ledger-api/Program.cs` | MODIFY | Add worker seeding block to pilot-demo startup |
| `tasks/PWRM-001-T4/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions

- **If supplier_type is not passed as an explicit named argument "WORKER"** → STOP
- **If CreateStableGuid is not used for both worker IDs** → STOP
- **If either worker is not added to PGM-ZAMBIA-GRN-001 allowlist** → STOP
- **If evidence is static or self-declared instead of derived** → STOP

---

## Implementation Steps

### Step 1: Declare constants and stable IDs

**What:** `[ID pwrm001_t4_work_item_01]` Declare workerChunga001Id, workerChunga002Id, PgmZambiaGrn,
DemoTenantId in the seeding block.
**How:** Use `CreateStableGuid("worker-chunga-001").ToString()` and equivalent for worker 002.
Declare PgmZambiaGrn = "PGM-ZAMBIA-GRN-001" and DemoTenantId = "11111111-1111-1111-1111-111111111111"
as constants.
**Done when:** Both IDs are deterministic and reproducible across restarts.

### Step 2: Seed both workers with explicit supplier_type = "WORKER"

**What:** `[ID pwrm001_t4_work_item_02]` Call SupplierRegistryUpsertHandler.HandleAsync for both
workers with all required fields.
**How:** Use the exact call pattern from design.md. Pass `supplier_type: "WORKER"` as a named
argument on both calls. GPS: -15.4167m, 28.2833m. Sequential await, not Task.WhenAll.
**Done when:** Both entries exist in the registry with SupplierType == "WORKER" on TryGet.

### Step 3: Add both workers to PGM-ZAMBIA-GRN-001 allowlist

**What:** `[ID pwrm001_t4_work_item_03]` Call ProgramSupplierAllowlistUpsertHandler.HandleAsync
for both workers.
**How:** One await call per worker, sequential. DemoTenantId, PgmZambiaGrn, worker ID, active = true.
**Done when:** GET policy for worker-chunga-001 returns decision = "ALLOW".

### Step 4: Emit evidence

**What:** `[ID pwrm001_t4_work_item_03]` Run self-test and capture evidence.
**How:**
```bash
dotnet run --self-test-worker-onboarding || exit 1
```
**Done when:** evidence/phase1/pwrm_worker_onboarding.json exists and contains status = "PASS".

---

## Verification

```bash
# [ID pwrm001_t4_work_item_01] [ID pwrm001_t4_work_item_02] [ID pwrm001_t4_work_item_03]
dotnet run --self-test-worker-onboarding || exit 1

python3 scripts/audit/validate_evidence.py --task PWRM-001-T4 --evidence evidence/phase1/pwrm_worker_onboarding.json || exit 1

RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/pwrm_worker_onboarding.json`

Required fields:
- `task_id`: "PWRM-001-T4"
- `git_sha`: commit sha at time of evidence emission
- `timestamp_utc`: ISO 8601
- `status`: "PASS"
- `checks`: array of check objects
- `workers_seeded_count`: 2
- `supplier_type_explicit_confirmed`: true
- `allowlist_seeded_confirmed`: true

---

## Rollback

If this task must be reverted:
1. Remove the worker seeding block from Program.cs.
2. Restore status to 'ready' in meta.yml.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| supplier_type omitted from upsert call (left as default null) | CRITICAL_FAIL — T5 proxy rejects all workers | Always pass as explicit named argument |
| Random GUIDs used instead of CreateStableGuid | FAIL — non-idempotent across restarts | Use CreateStableGuid for both worker IDs |
| Workers not added to allowlist | FAIL — GET policy returns DENY | Sequential await for both allowlist calls |
