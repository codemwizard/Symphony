# GF-W1-UI-005 PLAN — Instruction detail drawer with GPS, sequence, registry status, and weighbridge data

Task: GF-W1-UI-005
Owner: SUPERVISOR
Depends on: GF-W1-UI-004
failure_signature: PHASE1.GREEN_FINANCE.GF-W1-UI-005.DRAWER_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Add a slide-in drawer that shows full instruction detail when an activity table row is
clicked. The drawer displays instruction ID, worker ID, sequence number, registry status,
duplicate check, GPS neighbourhood label (never raw coordinates), evidence completeness
per proof type, and weighbridge data with tCO₂ and credits. GPS privacy is critical —
raw coordinates must never appear in any DOM element.

---

## Pre-conditions

- [ ] GF-W1-UI-004 is status=completed (activity table with row click handler exists)
- [ ] This PLAN.md has been reviewed and approved

---

## Must Read (MANDATORY — read in full before any code changes)

1. `.kiro/steering/ui-canonical-design.md` — CSS tokens, resolveNeighbourhoodLabel function
2. `.kiro/steering/pwrm0001-domain-rules.md` — GPS rules, proof types, payload shape
3. `.kiro/steering/symphony-platform-conventions.md` — Runtime profile
4. `.kiro/specs/symphony-ui-canonical/requirements.md` — Requirement 1.7 (GPS privacy)
5. `.kiro/specs/symphony-ui-canonical/design.md` — Drawer wireframe
6. `.kiro/specs/symphony-ui-canonical/tasks.md` — Task 5 verbatim instructions
7. `docs/operations/AGENTIC_SDLC_PILOT_POLICY.md` — Pilot containment

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add instruction detail drawer |
| `tasks/GF-W1-UI-005/meta.yml` | MODIFY | Update status to completed |
| `evidence/phase1/gf_w1_ui_005.json` | CREATE | Evidence artifact |

---

## Stop Conditions

- **If raw GPS coordinates rendered in DOM at any step** → STOP (CRITICAL_FAIL, stop immediately)
- **If resolveNeighbourhoodLabel function not used** → STOP (CRITICAL_FAIL)
- **If registry status value other than 'NOT ISSUED' for pilot** → STOP
- **If any node in the proof graph is orphaned** → STOP

---

## Implementation Steps

### Step 1: Drawer structure
**What:** `[ID gf_w1_ui_005_work_01]` Add drawer div with slide-in animation.
**How:** position: fixed; right: 0; width: 38%; height: 100%; transform: translateX(100%). On active: translateX(0). Close button (×) top-right.
**Done when:** Drawer div exists with translateX transform.

### Step 2: Instruction metadata
**What:** `[ID gf_w1_ui_005_work_02]` Display instruction ID, worker ID, sequence, registry status, duplicate check.
**How:** Instruction ID: monospace, truncated to 12 chars + "…". Registry Status: "NOT ISSUED" (amber chip). Duplicate Check: "PASS" (green chip).
**Done when:** "NOT ISSUED" and "PASS" text present in drawer.

### Step 3: GPS neighbourhood label
**What:** `[ID gf_w1_ui_005_work_03]` Display GPS as neighbourhood label only, never raw coordinates.
**How:** Call `resolveNeighbourhoodLabel(lat, lon)` → show label. Compute Haversine distance from (-15.4167, 28.2833). Show "Xm from boundary" with green chip ≤ 250m, red chip > 250m.
**Done when:** resolveNeighbourhoodLabel call exists in drawer code. No raw coordinate DOM insertion.

### Step 4: Evidence completeness
**What:** `[ID gf_w1_ui_005_work_04]` Four PWRM0001 proof type rows with status chips.
**How:** WEIGHBRIDGE_RECORD, COLLECTION_PHOTO, QUALITY_AUDIT_RECORD, TRANSFER_MANIFEST — green PRESENT / red MISSING chip per row.
**Done when:** WEIGHBRIDGE_RECORD text present.

### Step 5: Weighbridge data
**What:** `[ID gf_w1_ui_005_work_05]` If WEIGHBRIDGE_RECORD has data: show plastic_type, net_weight_kg, tCO₂ estimate, credits.
**How:** tCO₂: `(net * 0.00048).toFixed(6)`. Credits estimate equal to tCO₂.
**Done when:** 0.00048 constant and WEIGHBRIDGE_RECORD text present.

### Step 6: Emit evidence
```bash
# [ID gf_w1_ui_005_work_01] [ID gf_w1_ui_005_work_02] [ID gf_w1_ui_005_work_03]
# [ID gf_w1_ui_005_work_04] [ID gf_w1_ui_005_work_05]
test -f src/supervisory-dashboard/index.html \
  && grep -q "resolveNeighbourhoodLabel" src/supervisory-dashboard/index.html \
  && grep -q "NOT ISSUED" src/supervisory-dashboard/index.html \
  && grep -q "translateX" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "WEIGHBRIDGE_RECORD" \
  > evidence/phase1/gf_w1_ui_005.json || exit 1

# [ID gf_w1_ui_005_work_03] — negative test: no raw coordinates
test -z "$(grep -E 'textContent.*latitude|innerHTML.*longitude' src/supervisory-dashboard/index.html)" \
  || exit 1
```

---

## Verification

```bash
# [ID gf_w1_ui_005_work_01] [ID gf_w1_ui_005_work_02] [ID gf_w1_ui_005_work_03]
# [ID gf_w1_ui_005_work_04] [ID gf_w1_ui_005_work_05]
test -f src/supervisory-dashboard/index.html \
  && grep -q "resolveNeighbourhoodLabel" src/supervisory-dashboard/index.html \
  && grep -q "NOT ISSUED" src/supervisory-dashboard/index.html \
  && grep -q "translateX" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "WEIGHBRIDGE_RECORD" \
  > evidence/phase1/gf_w1_ui_005.json || exit 1

# [ID gf_w1_ui_005_work_03]
test -z "$(grep -E 'textContent.*latitude|innerHTML.*longitude' src/supervisory-dashboard/index.html)" \
  || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/gf_w1_ui_005.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes, command_outputs, execution_trace, gps_coordinate_check_passed

---

## Rollback

1. Revert: `git checkout HEAD -- src/supervisory-dashboard/index.html`
2. Update status back to `planned`

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Raw GPS coordinates in DOM | CRITICAL_FAIL | Negative grep test |
| resolveNeighbourhoodLabel missing | CRITICAL_FAIL | Positive grep test |
| Drawer doesn't slide | FAIL | grep for translateX |
| Evidence completeness rows missing | FAIL | grep for WEIGHBRIDGE_RECORD |
