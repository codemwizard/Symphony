# PWRM-001-T6 PLAN — Update recipient landing page for WASTE_COLLECTOR tokens

Task: PWRM-001-T6
Owner: IMPLEMENTER
Depends on: none (standalone, client-side only)
failure_signature: phase1.pwrm001.t6.landing_page_no_worker_branch
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Add a WASTE_COLLECTOR detection branch in `src/recipient-landing/index.html` that displays role
label "Waste Collector", zone label via resolveNeighbourhoodLabel hardcoded lookup (Chunga bounds),
and the identity check message. Done when the DOM contains the correct labels and confirms zero
instances of raw lat/lon decimal values being rendered anywhere in the page.

---

## Architectural Context

The landing page currently has no branch for WASTE_COLLECTOR tokens. Without this change, waste
pickers see a generic or broken UI. The no-raw-coordinates rule is a privacy requirement — GPS
coordinates embedded in the token must be used for zone label resolution only, never displayed
directly. The hardcoded bounds approach is intentional: no geocoding API is in scope for the pilot.

---

## Design Reference (from .kiro/specs/pwrm-001-worker-onboarding/design.md)

### Neighbourhood label — hardcoded, no geocoding API

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

### FIX F11: structured_payload required

The recipient landing page form for WASTE_COLLECTOR MUST always supply structured_payload.
The UI has no "skip payload" path for WASTE_COLLECTOR.

### FIX F13: GPS locked at issuance, immutable

GPS coordinates come from the token. They are used for zone label resolution only.

---

## Requirements Reference (from .kiro/specs/pwrm-001-worker-onboarding/requirements.md)

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

- dotnet run --self-test-worker-onboarding exits 0, all 8 cases PASS.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed before any code is written.
- [ ] index.html is buildable/servable in the local environment.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/recipient-landing/index.html` | MODIFY | Add WASTE_COLLECTOR branch, resolveNeighbourhoodLabel, zone and identity labels |
| `tasks/PWRM-001-T6/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions

- **If raw lat/lon decimal values appear anywhere in the DOM (text, data-*, hidden inputs)** → STOP
- **If resolveNeighbourhoodLabel makes any network request** → STOP
- **If role label uses the enum string "WASTE_COLLECTOR" instead of "Waste Collector"** → STOP
- **If evidence is static or self-declared instead of derived** → STOP

---

## Implementation Steps

### Step 1: Add WASTE_COLLECTOR detection branch

**What:** `[ID pwrm001_t6_work_item_01]` In the token decode/display logic, add a branch for
submitter_class === "WASTE_COLLECTOR".
**How:** Find the section where token fields control UI state. Add an `else if` or equivalent
branch that sets the role label to the string "Waste Collector".
**Done when:** When rendered with a WASTE_COLLECTOR token, the page shows "Waste Collector" as
the role label.

### Step 2: Implement resolveNeighbourhoodLabel

**What:** `[ID pwrm001_t6_work_item_02]` Add the hardcoded bounds lookup function.
**How:** Implement exactly as specified in design.md. No network calls. No external library.
**Done when:** resolveNeighbourhoodLabel(-15.4167, 28.2833) returns "Chunga Dumpsite, Lusaka";
resolveNeighbourhoodLabel(0, 0) returns "Lusaka".

### Step 3: Display zone label and identity check message; assert no raw coordinates

**What:** `[ID pwrm001_t6_work_item_03]` Display zone label and identity message. Confirm no
raw coordinate strings are assigned to any DOM property.
**How:** Use resolveNeighbourhoodLabel output for the zone label. Add identity check text.
Audit the WASTE_COLLECTOR branch to confirm lat/lon variables are never assigned to innerHTML,
textContent, value, or data-* attributes.
**Done when:** Zone label displays correctly; DOM audit finds zero instances of "-15.4167" or
"28.2833" or any other raw decimal coordinate.

### Step 4: Emit evidence

**What:** `[ID pwrm001_t6_work_item_03]` Run self-test and capture evidence.
**How:**
```bash
dotnet run --self-test-worker-onboarding || exit 1
```
**Done when:** evidence/phase1/pwrm_worker_onboarding.json exists and contains status = "PASS".

---

## Verification

```bash
# [ID pwrm001_t6_work_item_01] [ID pwrm001_t6_work_item_02] [ID pwrm001_t6_work_item_03]
dotnet run --self-test-worker-onboarding || exit 1

python3 scripts/audit/validate_evidence.py --task PWRM-001-T6 --evidence evidence/phase1/pwrm_worker_onboarding.json || exit 1

RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/pwrm_worker_onboarding.json`

Required fields:
- `task_id`: "PWRM-001-T6"
- `git_sha`: commit sha at time of evidence emission
- `timestamp_utc`: ISO 8601
- `status`: "PASS"
- `checks`: array of check objects
- `waste_collector_branch_added`: true
- `raw_coordinates_not_in_dom_confirmed`: true
- `neighbourhood_label_hardcoded_confirmed`: true

---

## Rollback

If this task must be reverted:
1. Remove the WASTE_COLLECTOR branch from index.html.
2. Remove resolveNeighbourhoodLabel function.
3. Restore status to 'ready' in meta.yml.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Raw lat/lon rendered in DOM | CRITICAL_FAIL — privacy violation | Audit every DOM assignment in WASTE_COLLECTOR branch before committing |
| resolveNeighbourhoodLabel makes network request | FAIL — offline/latency risk | Pure function with no fetch/XHR; test with network disabled |
| Role label displays "WASTE_COLLECTOR" enum string | FAIL | Use "Waste Collector" (human-readable) as the display string |
