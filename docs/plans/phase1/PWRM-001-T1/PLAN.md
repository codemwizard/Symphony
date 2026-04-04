# PWRM-001-T1 PLAN — Add WASTE_COLLECTOR to submitter class allowlist

Task: PWRM-001-T1
Owner: IMPLEMENTER
Depends on: none (root task)
failure_signature: phase1.pwrm001.t1.allowlist_missing
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Add a HashSet-based allowlist to EvidenceLinkIssueHandler that accepts exactly five submitter
classes — VENDOR, FIELD_OFFICER, BORROWER, SUPPLIER, WASTE_COLLECTOR — and rejects any other
value with 400 INVALID_SUBMITTER_CLASS. Done when the self-test runner exits 0 with WASTE_COLLECTOR
accepted and UNKNOWN_CLASS rejected, and all existing passing classes remain unaffected.

---

## Architectural Context

This task is the root of the PWRM-001 dependency chain. The allowlist guard must exist on the
generic route before the pilot-demo proxy route (T5) is added, because the proxy delegates to
the generic handler after GPS injection. The anti-pattern being closed is unconstrained string
acceptance of submitter_class — which would allow any caller-invented class to generate signed
tokens.

---

## Design Reference (from .kiro/specs/pwrm-001-worker-onboarding/design.md)

### Submitter class allowlist

```csharp
private static readonly HashSet<string> ValidSubmitterClasses =
    new(StringComparer.Ordinal)
    { "VENDOR", "FIELD_OFFICER", "BORROWER", "SUPPLIER", "WASTE_COLLECTOR" };
```

In HandleAsync, after the null/whitespace check on submitter_class, add:

```csharp
if (!ValidSubmitterClasses.Contains(request.submitter_class.Trim()))
{
    return new HandlerResult(StatusCodes.Status400BadRequest, new
    {
        error_code = "INVALID_SUBMITTER_CLASS",
        errors = new[] { $"submitter_class '{request.submitter_class}' is not valid" }
    });
}
```

### FIX F15: null supplier_type rejected in pilot-demo worker flow

The pilot-demo proxy does NOT treat supplier_type = null as legacy-compatible. Any registry entry
that is not explicitly supplier_type = "WORKER" (including null) is rejected with 400
INVALID_SUPPLIER_TYPE.

### FIX F13: GPS locked at issuance, immutable

The pilot-demo proxy injects GPS from the worker registry into the issue request. The token carries
this GPS. The submit handler reads GPS from the token only. No re-query of the worker registry
occurs at submit time.

Sequence:
```
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
```

### FIX F11: structured_payload required

Even though structured_payload enforcement is primarily in the submit handler (PWRM-002), the
recipient landing page form for WASTE_COLLECTOR MUST always supply structured_payload. The UI has
no "skip payload" path for WASTE_COLLECTOR.

### Neighbourhood label — hardcoded, no geocoding API

```javascript
function resolveNeighbourhoodLabel(lat, lon) {
  if (lat >= -15.43 && lat <= -15.40 && lon >= 28.26 && lon <= 28.30)
    return "Chunga Dumpsite, Lusaka";
  return "Lusaka";
}
```

Raw coordinate values are never rendered.

### New files introduced by PWRM-001

- `Commands/Pwrm0001ArtifactTypes.cs` — constants + ProofTypeDisplayLabels (needed by PWRM-002)
- `Demo/WorkerOnboardingSelfTestRunner.cs`

### SupplierRegistryUpsertRequest extension

CommandContracts.cs gains `string? supplier_type = null` on the record. SupplierRegistry
(in-memory store) stores this field. All PWRM workers are seeded with explicit
`supplier_type = "WORKER"`.

---

## Requirements Reference (from .kiro/specs/pwrm-001-worker-onboarding/requirements.md)

### Background

Waste pickers at Chunga Dumpsite receive GPS-locked evidence tokens. Workers live in the supplier
registry with `supplier_type = "WORKER"` (never null). GPS is locked at issuance and immutable
thereafter.

### US-1: Submitter class validation

**As** an API consumer,
**I want** WASTE_COLLECTOR accepted as a submitter_class,
**so that** waste picker tokens can be issued.

Acceptance criteria:
- WHEN submitter_class is WASTE_COLLECTOR → 200.
- WHEN submitter_class is not in {VENDOR, FIELD_OFFICER, BORROWER, SUPPLIER, WASTE_COLLECTOR} → 400 INVALID_SUBMITTER_CLASS.
- The check is an explicit HashSet comparison (not regex or prefix).

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

**As** the pilot demo operator,
**I want** worker_id to auto-fill GPS from the registry,
**so that** GPS is always server-authoritative and non-WORKER registry entries are rejected.

Acceptance criteria:
- WHEN POST /pilot-demo/api/evidence-links/issue includes worker_id + submitter_class = "WASTE_COLLECTOR":
  - Worker not found → 404 WORKER_NOT_FOUND.
  - supplier_type == null → 400 INVALID_SUPPLIER_TYPE. (null is not legacy-compatible here)
  - supplier_type is non-null and not "WORKER" → 400 INVALID_SUPPLIER_TYPE.
  - supplier_type == "WORKER" → proceed.
- Server sets expected_latitude, expected_longitude from registry; max_distance_meters = 250.0.
- ANY expected_latitude/expected_longitude in the caller's request body are silently discarded.
- Token embeds the registry GPS; caller-provided GPS is NEVER embedded.
- worker_id is NOT accepted on /v1/evidence-links/issue.

### US-4: GPS is immutable after issuance (FIX F13)

**As** the evidence integrity system,
**I want** GPS coordinates to be fixed at token issuance time,
**so that** submit-time validation is deterministic regardless of registry changes.

Acceptance criteria:
- WHEN a token is validated at submit time, GPS is read from the token's embedded fields, NOT
  re-queried from the worker registry.
- WHEN a worker's registered coordinates change after a token is issued, the existing token still
  validates against its embedded coordinates.
- The submit handler performs no worker registry lookup.

### US-5: Recipient landing page displays worker context

**As** a waste picker,
**I want** the landing page to identify my role and zone clearly,
**so that** I know what to do.

Acceptance criteria:
- Token submitter_class = "WASTE_COLLECTOR" → label "Waste Collector" (not enum string).
- Zone label = resolveNeighbourhoodLabel(lat, lon) from hardcoded lookup → "Chunga Dumpsite, Lusaka".
- Displays: "Identity Check: Your phone number must match the one registered for this link".
- Raw latitude/longitude values are NEVER visible in the DOM.

### US-6: Self-test — 8 cases, fully isolated

Acceptance criteria:
- dotnet run --self-test-worker-onboarding exits 0, all 8 cases PASS.
- Runner deletes its own NDJSON files before starting.
- Runner uses namespaced IDs; does not rely on Program.cs startup seeding.
- Runner does NOT use Task.WhenAll on sequential appends.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed before any code is written.
- [ ] services/ledger-api solution builds cleanly on the current branch.
- [ ] The existing self-test suite passes before this change is applied.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `services/ledger-api/Commands/EvidenceLinkHandlers.cs` | MODIFY | Add ValidSubmitterClasses HashSet and allowlist check |
| `tasks/PWRM-001-T1/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions

- **If ValidSubmitterClasses uses StringComparer other than Ordinal** → STOP
- **If any existing passing submitter_class is removed from the set** → STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** → STOP
- **If evidence is static or self-declared instead of derived** → STOP

---

## Implementation Steps

### Step 1: Add ValidSubmitterClasses HashSet

**What:** `[ID pwrm001_t1_work_item_01]` Add the static readonly HashSet field to EvidenceLinkIssueHandler.
**How:** Insert the field declaration before HandleAsync. Use `new(StringComparer.Ordinal)` with
the five exact class strings as listed in design.md.
**Done when:** File compiles; the field is visible in the class scope.

```csharp
private static readonly HashSet<string> ValidSubmitterClasses =
    new(StringComparer.Ordinal)
    { "VENDOR", "FIELD_OFFICER", "BORROWER", "SUPPLIER", "WASTE_COLLECTOR" };
```

### Step 2: Add allowlist check in HandleAsync

**What:** `[ID pwrm001_t1_work_item_02]` Insert the allowlist guard after the null/whitespace check.
**How:** After the existing whitespace rejection, add the Contains check returning 400 with
error_code = "INVALID_SUBMITTER_CLASS".
**Done when:** A call with submitter_class = "UNKNOWN_CLASS" returns 400; a call with
submitter_class = "WASTE_COLLECTOR" proceeds past the guard.

### Step 3: Confirm existing self-tests still pass

**What:** `[ID pwrm001_t1_work_item_03]` Run existing self-tests and confirm no regression.
**How:** `dotnet run --self-test` (or equivalent existing runner invocation).
**Done when:** All previously passing cases still pass; no new failures.

### Step 4: Emit evidence

**What:** `[ID pwrm001_t1_work_item_03]` Run worker onboarding self-test and capture evidence.
**How:**
```bash
dotnet run --self-test-worker-onboarding > evidence/phase1/pwrm_worker_onboarding.json || exit 1
```
**Done when:** evidence/phase1/pwrm_worker_onboarding.json exists and contains status = "PASS".

---

## Verification

```bash
# [ID pwrm001_t1_work_item_01] [ID pwrm001_t1_work_item_02] [ID pwrm001_t1_work_item_03]
dotnet run --self-test-worker-onboarding || exit 1

# [ID pwrm001_t1_work_item_03]
python3 scripts/audit/validate_evidence.py --task PWRM-001-T1 --evidence evidence/phase1/pwrm_worker_onboarding.json || exit 1

# Full local gate
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/pwrm_worker_onboarding.json`

Required fields:
- `task_id`: "PWRM-001-T1"
- `git_sha`: commit sha at time of evidence emission
- `timestamp_utc`: ISO 8601
- `status`: "PASS"
- `checks`: array of check objects
- `allowlist_classes_confirmed`: true
- `invalid_class_rejection_confirmed`: true

---

## Rollback

If this task must be reverted:
1. Remove the ValidSubmitterClasses HashSet and the allowlist check from EvidenceLinkHandlers.cs.
2. Restore status to 'ready' in meta.yml.
3. File exception in docs/security/EXCEPTION_REGISTER.yml with rationale and expiry.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| WASTE_COLLECTOR omitted from HashSet | FAIL — tokens cannot be issued | Double-check the five entries before committing |
| StringComparer.OrdinalIgnoreCase used instead of Ordinal | CRITICAL_FAIL | Use exactly `new(StringComparer.Ordinal)` |
| Allowlist check placed after GPS injection | CRITICAL_FAIL | Guard must be first check after whitespace validation |
| Existing classes removed causing regression | FAIL | Run existing self-tests before marking done |
