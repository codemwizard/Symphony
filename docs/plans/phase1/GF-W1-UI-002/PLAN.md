# GF-W1-UI-002 PLAN — Add three-tab layout with Programme Health as default

Task: GF-W1-UI-002
Owner: SUPERVISOR
Depends on: GF-W1-UI-001
failure_signature: PHASE1.GREEN_FINANCE.GF-W1-UI-002.TAB_LAYOUT_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create the three-tab navigation structure in the supervisory dashboard. When done,
exactly three tabs exist ("Programme Health", "Monitoring Report", "Onboarding Console"),
Programme Health is active by default, and clicking a tab shows only that tab's content.

---

## Pre-conditions

- [ ] GF-W1-UI-001 is status=completed (CSS tokens established)
- [ ] This PLAN.md has been reviewed and approved

---

## Must Read (MANDATORY — read in full before any code changes)

1. `.kiro/steering/ui-canonical-design.md` — CSS tokens, tab layout rules
2. `.kiro/steering/pwrm0001-domain-rules.md` — Programme identity
3. `.kiro/steering/symphony-platform-conventions.md` — Runtime conventions
4. `.kiro/specs/symphony-ui-canonical/requirements.md` — Requirement 1.1
5. `.kiro/specs/symphony-ui-canonical/design.md` — Tab layout wireframe
6. `.kiro/specs/symphony-ui-canonical/tasks.md` — Task 2 verbatim instructions

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add three-tab navigation |
| `tasks/GF-W1-UI-002/meta.yml` | MODIFY | Update status to completed |
| `evidence/phase1/gf_w1_ui_002.json` | CREATE | Evidence artifact |

---

## Stop Conditions

- **If more or fewer than 3 tabs exist** → STOP
- **If tab labels don't match exactly** → STOP
- **If multiple content divs visible simultaneously** → STOP
- **If any node in the proof graph is orphaned** → STOP

---

## Implementation Steps

### Step 1: Create tab buttons
**What:** `[ID gf_w1_ui_002_work_01]` Create exactly three tab buttons.
**How:** Add three button/div elements with text "Programme Health", "Monitoring Report", "Onboarding Console". Tab bar uses `position: sticky`.
**Done when:** All three tab labels exist in the HTML.

### Step 2: Tab switching logic
**What:** `[ID gf_w1_ui_002_work_02]` Implement CSS class toggle to show/hide tab content.
**How:** Each tab click adds `active` class to target div and removes from others.
**Done when:** Clicking each tab shows only its content div.

### Step 3: Default active tab
**What:** `[ID gf_w1_ui_002_work_03]` Programme Health is active by default with 2px `var(--bright)` bottom border.
**How:** Set Programme Health tab as active in HTML and initial JS state.
**Done when:** Page load shows Programme Health tab as active.

### Step 4: Emit evidence
**What:** Run verifier and write evidence JSON.
```bash
# [ID gf_w1_ui_002_work_01] [ID gf_w1_ui_002_work_02] [ID gf_w1_ui_002_work_03]
test -f src/supervisory-dashboard/index.html \
  && grep -q "Programme Health" src/supervisory-dashboard/index.html \
  && grep -q "Monitoring Report" src/supervisory-dashboard/index.html \
  && grep -q "Onboarding Console" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "sticky" \
  > evidence/phase1/gf_w1_ui_002.json || exit 1
```

---

## Verification

```bash
# [ID gf_w1_ui_002_work_01] [ID gf_w1_ui_002_work_02] [ID gf_w1_ui_002_work_03]
test -f src/supervisory-dashboard/index.html \
  && grep -q "Programme Health" src/supervisory-dashboard/index.html \
  && grep -q "Monitoring Report" src/supervisory-dashboard/index.html \
  && grep -q "Onboarding Console" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "sticky" \
  > evidence/phase1/gf_w1_ui_002.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/gf_w1_ui_002.json`

Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes, command_outputs, execution_trace

---

## Rollback

1. Revert tab changes: `git checkout HEAD -- src/supervisory-dashboard/index.html`
2. Update status back to `planned` in meta.yml

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Tab labels wrong | FAIL | grep verification |
| Multiple tabs visible | CRITICAL_FAIL | Manual browser test |
| Default tab wrong | FAIL | grep for active class |
