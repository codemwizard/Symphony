# GF-W1-UI-008 PLAN — Create canonical recipient landing page

Task: GF-W1-UI-008
Owner: SUPERVISOR
Depends on: GF-W1-UI-001
failure_signature: PHASE1.GREEN_FINANCE.GF-W1-UI-008.RECIPIENT_LANDING_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create `src/recipient-landing/index.html` as the canonical worker submission page with a
4-step flow: token validation, GPS capture, weighbridge form, and receipt. Enforces GPS
privacy via resolveNeighbourhoodLabel — raw coordinates never appear in any DOM element.

---

## Pre-conditions

- [ ] GF-W1-UI-001 is status=completed (CSS baseline established)
- [ ] This PLAN.md has been reviewed and approved

---

## Must Read (MANDATORY — read in full before any code changes)

1. `.kiro/steering/ui-canonical-design.md` — CSS tokens, resolveNeighbourhoodLabel function
2. `.kiro/steering/pwrm0001-domain-rules.md` — GPS rules, payload shape, collector roles
3. `.kiro/steering/symphony-platform-conventions.md` — Runtime profile, API patterns
4. `.kiro/specs/symphony-ui-canonical/requirements.md` — Requirements 4.1–4.5
5. `.kiro/specs/symphony-ui-canonical/design.md` — 4-step flow wireframe
6. `.kiro/specs/symphony-ui-canonical/tasks.md` — Task 8 verbatim instructions
7. `docs/operations/AGENTIC_SDLC_PILOT_POLICY.md` — Pilot containment

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/recipient-landing/index.html` | CREATE | Canonical recipient landing page |
| `tasks/GF-W1-UI-008/meta.yml` | MODIFY | Update status to completed |
| `evidence/phase1/gf_w1_ui_008.json` | CREATE | Evidence artifact |

---

## Stop Conditions

- **If raw GPS coordinates rendered in DOM** → STOP (CRITICAL_FAIL, stop immediately)
- **If resolveNeighbourhoodLabel function not defined in this file** → STOP (CRITICAL_FAIL)
- **If Net weight field is editable (must be readonly)** → STOP
- **If missing `// display only — backend recomputes` comment on net weight** → STOP
- **If any node in the proof graph is orphaned** → STOP

---

## Implementation Steps

### Step 1: Create file with resolveNeighbourhoodLabel
**What:** `[ID gf_w1_ui_008_work_01]` Create src/recipient-landing/index.html with resolveNeighbourhoodLabel.
**How:** Define the function matching the steering file specification.
**Done when:** File exists with resolveNeighbourhoodLabel function definition.

### Step 2: Token validation (Step 1 of flow)
**What:** `[ID gf_w1_ui_008_work_02]` Read token from window.location.hash, call context endpoint.
**How:** GET /api/public/evidence-links/context with x-evidence-link-token header. Show role chip, zone via resolveNeighbourhoodLabel, TTL countdown. Error: red card. "Continue to GPS Capture →" button.
**Done when:** evidence-links/context endpoint referenced.

### Step 3: GPS capture (Step 2 of flow)
**What:** `[ID gf_w1_ui_008_work_03]` GPS capture with neighbourhood label only.
**How:** navigator.geolocation.getCurrentPosition(). Show neighbourhood label (never raw coordinates). Haversine distance ≤ 250m: green. > 250m: amber. "Continue to Form →".
**Done when:** resolveNeighbourhoodLabel called after GPS capture. No raw coordinates in any element.

### Step 4: Weighbridge form (Step 3 of flow)
**What:** `[ID gf_w1_ui_008_work_04]` WASTE_COLLECTOR form with readonly net weight.
**How:** Plastic Type select. Gross/Tare weight inputs. Net Weight: readonly, `(gross - tare).toFixed(2)` with comment `// display only — backend recomputes from gross-tare`. Photo upload. Submit: upload then POST /v1/evidence-links/submit.
**Done when:** "display only" comment present. readonly attribute on net weight. Submit endpoint referenced.

### Step 5: Receipt (Step 4 of flow)
**What:** `[ID gf_w1_ui_008_work_05]` Green receipt card with instruction details.
**How:** instruction_id (monospace), sequence_number, submitted_at_utc. Text: "Your evidence has been recorded and sealed."
**Done when:** "recorded and sealed" text present.

### Step 6: Emit evidence
```bash
# [ID gf_w1_ui_008_work_01] [ID gf_w1_ui_008_work_02] [ID gf_w1_ui_008_work_03]
# [ID gf_w1_ui_008_work_04] [ID gf_w1_ui_008_work_05]
test -f src/recipient-landing/index.html \
  && grep -q "resolveNeighbourhoodLabel" src/recipient-landing/index.html \
  && grep -q "display only" src/recipient-landing/index.html \
  && grep -q "readonly" src/recipient-landing/index.html \
  && grep -q "evidence-links/submit" src/recipient-landing/index.html \
  && cat src/recipient-landing/index.html | grep "recorded and sealed" \
  > evidence/phase1/gf_w1_ui_008.json || exit 1

# [ID gf_w1_ui_008_work_02] [ID gf_w1_ui_008_work_03]
test -z "$(grep -E 'textContent.*latitude|innerHTML.*longitude' src/recipient-landing/index.html)" \
  || exit 1
```

---

## Verification

```bash
# [ID gf_w1_ui_008_work_01] [ID gf_w1_ui_008_work_02] [ID gf_w1_ui_008_work_03]
# [ID gf_w1_ui_008_work_04] [ID gf_w1_ui_008_work_05]
test -f src/recipient-landing/index.html \
  && grep -q "resolveNeighbourhoodLabel" src/recipient-landing/index.html \
  && grep -q "display only" src/recipient-landing/index.html \
  && grep -q "readonly" src/recipient-landing/index.html \
  && grep -q "evidence-links/submit" src/recipient-landing/index.html \
  && cat src/recipient-landing/index.html | grep "recorded and sealed" \
  > evidence/phase1/gf_w1_ui_008.json || exit 1

# [ID gf_w1_ui_008_work_02] [ID gf_w1_ui_008_work_03]
test -z "$(grep -E 'textContent.*latitude|innerHTML.*longitude' src/recipient-landing/index.html)" \
  || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/gf_w1_ui_008.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes, command_outputs, execution_trace, gps_coordinate_check_passed

---

## Rollback

1. Delete: `rm src/recipient-landing/index.html`
2. Update status back to `planned`

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Raw GPS in DOM | CRITICAL_FAIL | Negative grep test |
| resolveNeighbourhoodLabel missing | CRITICAL_FAIL | Positive grep test |
| Net weight editable | FAIL | grep for readonly |
| "display only" comment missing | FAIL | grep for "display only" |
