# PWRM-001-T2 PLAN — Add supplier_type to SupplierRegistryUpsertRequest and in-memory store

Task: PWRM-001-T2
Owner: IMPLEMENTER
Depends on: none (root task, parallel to T1)
failure_signature: phase1.pwrm001.t2.supplier_type_missing
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Extend SupplierRegistryUpsertRequest with an optional `string? supplier_type = null` field, store
the value in the in-memory SupplierRegistry, and expose it verbatim on TryGet. Done when a record
upserted with supplier_type = "WORKER" returns "WORKER" on lookup, and a record upserted with null
returns null (not any default). All existing call sites must compile unchanged.

---

## Architectural Context

The supplier_type field is the load-bearing discriminator for T5's proxy guard (FIX F15). If the
field is not stored and returned verbatim, the guard cannot distinguish null-type entries from
WORKER entries, silently allowing non-workers to receive GPS-locked tokens. This task must complete
before T4 (seeding), T5 (proxy), and T7 (self-test) can function correctly.

---

## Design Reference (from .kiro/specs/pwrm-001-worker-onboarding/design.md)

### FIX F15: null supplier_type rejected in pilot-demo worker flow

The pilot-demo proxy does NOT treat supplier_type = null as legacy-compatible. Any registry entry
that is not explicitly supplier_type = "WORKER" (including null) is rejected with 400
INVALID_SUPPLIER_TYPE.

Lookup logic in the proxy route:
```csharp
var entry = SupplierRegistry.TryGet(workerId);
if (entry is null)
    return 404 WORKER_NOT_FOUND;
if (entry.SupplierType != "WORKER")   // null, "SUPPLIER", anything else → rejected
    return 400 INVALID_SUPPLIER_TYPE;
// proceed — GPS injection
```

### FIX F13: GPS locked at issuance, immutable

The pilot-demo proxy injects GPS from the worker registry into the issue request. The token carries
this GPS. The submit handler reads GPS from the token only. No re-query of the worker registry
occurs at submit time.

### SupplierRegistryUpsertRequest extension

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

All PWRM workers are seeded with explicit `supplier_type = "WORKER"`. The parameter is optional
(default null) so existing call sites do not require changes.

### New files introduced by PWRM-001

- `Commands/Pwrm0001ArtifactTypes.cs` — constants + ProofTypeDisplayLabels (needed by PWRM-002)
- `Demo/WorkerOnboardingSelfTestRunner.cs`

---

## Requirements Reference (from .kiro/specs/pwrm-001-worker-onboarding/requirements.md)

### Background

Waste pickers at Chunga Dumpsite receive GPS-locked evidence tokens. Workers live in the supplier
registry with `supplier_type = "WORKER"` (never null). GPS is locked at issuance and immutable
thereafter.

### US-2: Worker seeding at startup — supplier_type never null

Acceptance criteria:
- ON startup, two registry entries exist with supplier_type = "WORKER" (exact string, not null).
- supplier_id = CreateStableGuid("worker-chunga-001") and CreateStableGuid("worker-chunga-002").
- Both entries: registered_latitude = -15.4167, registered_longitude = 28.2833.

### US-3: worker_id issues GPS-locked token — null supplier_type rejected (FIX F13 + F15)

Acceptance criteria:
- supplier_type == null → 400 INVALID_SUPPLIER_TYPE. (null is not legacy-compatible)
- supplier_type is non-null and not "WORKER" → 400 INVALID_SUPPLIER_TYPE.
- supplier_type == "WORKER" → proceed.

### US-6: Self-test — 8 cases, fully isolated

Acceptance criteria:
- dotnet run --self-test-worker-onboarding exits 0, all 8 cases PASS.
- Runner uses namespaced IDs; does not rely on Program.cs startup seeding.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed before any code is written.
- [ ] services/ledger-api solution builds cleanly on the current branch.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `services/ledger-api/Commands/CommandContracts.cs` | MODIFY | Add supplier_type optional parameter to record |
| `tasks/PWRM-001-T2/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions

- **If supplier_type parameter is not optional (breaks existing call sites)** → STOP
- **If null is coerced to any string value at storage time** → STOP
- **If SupplierType is not exposed as a readable property on the lookup result** → STOP
- **If evidence is static or self-declared instead of derived** → STOP

---

## Implementation Steps

### Step 1: Add supplier_type to SupplierRegistryUpsertRequest

**What:** `[ID pwrm001_t2_work_item_01]` Add `string? supplier_type = null` as the last parameter.
**How:** Edit the record declaration in CommandContracts.cs. Optional parameter with default null.
**Done when:** Solution compiles; all existing call sites continue to compile without changes.

```csharp
record SupplierRegistryUpsertRequest(
    string tenant_id,
    string supplier_id,
    string supplier_name,
    string payout_target,
    decimal? registered_latitude,
    decimal? registered_longitude,
    bool active,
    string? supplier_type = null
);
```

### Step 2: Store supplier_type in the registry entry

**What:** `[ID pwrm001_t2_work_item_02]` Update the in-memory SupplierRegistry upsert to store
the supplier_type field from the request. No coercion — null stays null.
**How:** Find the upsert logic in SupplierRegistry (or wherever the in-memory store is implemented)
and assign request.supplier_type to the stored entry field.
**Done when:** Upsert with supplier_type = "WORKER" stores "WORKER"; upsert with null stores null.

### Step 3: Expose SupplierType on the lookup result

**What:** `[ID pwrm001_t2_work_item_03]` Confirm the TryGet return type has a SupplierType property.
**How:** Add or verify the SupplierType property on the registry entry class/record. Return the
stored value verbatim.
**Done when:** TryGet for a "WORKER" entry returns SupplierType == "WORKER"; TryGet for a null
entry returns SupplierType == null.

### Step 4: Emit evidence

**What:** `[ID pwrm001_t2_work_item_03]` Run self-test and capture evidence.
**How:**
```bash
dotnet run --self-test-worker-onboarding || exit 1
```
**Done when:** evidence/phase1/pwrm_worker_onboarding.json exists and contains status = "PASS".

---

## Verification

```bash
# [ID pwrm001_t2_work_item_01] [ID pwrm001_t2_work_item_02] [ID pwrm001_t2_work_item_03]
dotnet run --self-test-worker-onboarding || exit 1

# [ID pwrm001_t2_work_item_03]
python3 scripts/audit/validate_evidence.py --task PWRM-001-T2 --evidence evidence/phase1/pwrm_worker_onboarding.json || exit 1

RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/pwrm_worker_onboarding.json`

Required fields:
- `task_id`: "PWRM-001-T2"
- `git_sha`: commit sha at time of evidence emission
- `timestamp_utc`: ISO 8601
- `status`: "PASS"
- `checks`: array of check objects
- `supplier_type_field_added`: true
- `null_type_preserved_on_lookup`: true

---

## Rollback

If this task must be reverted:
1. Remove supplier_type parameter from SupplierRegistryUpsertRequest.
2. Remove SupplierType field from the registry entry type.
3. Restore status to 'ready' in meta.yml.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| SupplierType not exposed on lookup result | CRITICAL_FAIL — T5 guard silently passes all | Verify TryGet return type has the property before marking done |
| null coerced to empty string at storage | CRITICAL_FAIL — T7 case 7 cannot detect null entries | Assert null-in/null-out in step 3 |
| Non-optional parameter breaks existing call sites | FAIL | Use `= null` default value |
