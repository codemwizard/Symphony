# PWRM-001-T3 PLAN — Create Pwrm0001ArtifactTypes.cs with artifact type constants and display labels

Task: PWRM-001-T3
Owner: IMPLEMENTER
Depends on: none (root task, standalone)
failure_signature: phase1.pwrm001.t3.artifact_types_missing
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create `services/ledger-api/Commands/Pwrm0001ArtifactTypes.cs` as a static class containing
exactly four artifact type constants, a ProofTypeDisplayLabels IReadOnlyDictionary, and an
IsPwrm0001ArtifactType helper. Done when the file compiles, IsPwrm0001ArtifactType returns true
for all four valid constants (case-sensitive) and false for null or unknown values, and the
evidence file records the outcome.

---

## Architectural Context

Artifact type string literals for the PWRM domain are the validation source of truth for PWRM-002.
Defining them in multiple places creates split-source risk. This file must be in place before
PWRM-002 implements artifact type validation. It is a standalone file with no handler logic.

---

## Design Reference (from .kiro/specs/pwrm-001-worker-onboarding/design.md)

### New files introduced by PWRM-001

- `Commands/Pwrm0001ArtifactTypes.cs` — constants + ProofTypeDisplayLabels (needed by PWRM-002)

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

### FIX F15: null supplier_type rejected in pilot-demo worker flow

The pilot-demo proxy does NOT treat supplier_type = null as legacy-compatible. Any registry entry
that is not explicitly supplier_type = "WORKER" (including null) is rejected with 400
INVALID_SUPPLIER_TYPE.

### FIX F13: GPS locked at issuance, immutable

GPS is injected from the worker registry at issuance. The submit handler reads GPS from the token
only. No re-query of the worker registry occurs at submit time.

### Neighbourhood label — hardcoded, no geocoding API

```javascript
function resolveNeighbourhoodLabel(lat, lon) {
  if (lat >= -15.43 && lat <= -15.40 && lon >= 28.26 && lon <= 28.30)
    return "Chunga Dumpsite, Lusaka";
  return "Lusaka";
}
```

---

## Requirements Reference (from .kiro/specs/pwrm-001-worker-onboarding/requirements.md)

### Background

Waste pickers at Chunga Dumpsite receive GPS-locked evidence tokens. Workers live in the supplier
registry with `supplier_type = "WORKER"` (never null). GPS is locked at issuance and immutable
thereafter.

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
| `services/ledger-api/Commands/Pwrm0001ArtifactTypes.cs` | CREATE | Single source of truth for PWRM artifact type constants |
| `tasks/PWRM-001-T3/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions

- **If IsPwrm0001ArtifactType uses OrdinalIgnoreCase or any case-insensitive comparison** → STOP
- **If fewer or more than four constants are defined** → STOP
- **If the file imports handler types or request/response contracts** → STOP
- **If evidence is static or self-declared instead of derived** → STOP

---

## Implementation Steps

### Step 1: Create Pwrm0001ArtifactTypes.cs

**What:** `[ID pwrm001_t3_work_item_01]` Create the file with four public const string fields.
**How:** Create new file at `services/ledger-api/Commands/Pwrm0001ArtifactTypes.cs`. Copy the
static class definition exactly as specified in design.md.
**Done when:** File exists; `dotnet build` passes; constants are accessible.

### Step 2: Add ProofTypeDisplayLabels

**What:** `[ID pwrm001_t3_work_item_02]` Add the IReadOnlyDictionary with StringComparer.Ordinal.
**How:** Add the dictionary field mapping each constant to its display label as specified. Use
`new Dictionary<string, string>(StringComparer.Ordinal)`.
**Done when:** ProofTypeDisplayLabels[WEIGHBRIDGE_RECORD] == "Weighbridge Collection Record".

### Step 3: Add IsPwrm0001ArtifactType helper

**What:** `[ID pwrm001_t3_work_item_03]` Add the static bool helper method.
**How:** Implement as `value is not null && ProofTypeDisplayLabels.ContainsKey(value)`.
**Done when:** Returns true for all four constants; false for null; false for "weighbridge_record"
(lowercase); false for "UNKNOWN".

### Step 4: Emit evidence

**What:** `[ID pwrm001_t3_work_item_03]` Run self-test and capture evidence.
**How:**
```bash
dotnet build services/ledger-api || exit 1
dotnet run --self-test-worker-onboarding || exit 1
```
**Done when:** evidence/phase1/pwrm_worker_onboarding.json exists and contains status = "PASS".

---

## Verification

```bash
# [ID pwrm001_t3_work_item_01] [ID pwrm001_t3_work_item_02] [ID pwrm001_t3_work_item_03]
dotnet build services/ledger-api || exit 1
dotnet run --self-test-worker-onboarding || exit 1

python3 scripts/audit/validate_evidence.py --task PWRM-001-T3 --evidence evidence/phase1/pwrm_worker_onboarding.json || exit 1

RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/pwrm_worker_onboarding.json`

Required fields:
- `task_id`: "PWRM-001-T3"
- `git_sha`: commit sha at time of evidence emission
- `timestamp_utc`: ISO 8601
- `status`: "PASS"
- `checks`: array of check objects
- `artifact_type_constants_count`: 4
- `is_pwrm_helper_case_sensitive_confirmed`: true

---

## Rollback

If this task must be reverted:
1. Delete `services/ledger-api/Commands/Pwrm0001ArtifactTypes.cs`.
2. Restore status to 'ready' in meta.yml.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| IsPwrm0001ArtifactType uses OrdinalIgnoreCase | CRITICAL_FAIL | Use ContainsKey on Ordinal dictionary; do not override comparer |
| Fewer than four constants | FAIL — PWRM-002 validation silently rejects valid types | Count constants before marking done |
| File imports handler types | FAIL_REVIEW | Keep file as pure constants; no using references to handler namespaces |
