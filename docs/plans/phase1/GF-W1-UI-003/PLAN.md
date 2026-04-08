# GF-W1-UI-003 PLAN — Programme Health tab: KPI row and disbursement status card

Task: GF-W1-UI-003
Owner: SUPERVISOR
Depends on: GF-W1-UI-002
failure_signature: PHASE1.GREEN_FINANCE.GF-W1-UI-003.KPI_ROW_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Add four KPI cards and a Disbursement Status card to the Programme Health tab, wired to the reveal API endpoint. When done, KPI numbers update from real API data and the disbursement card dynamically switches between red (NOT AUTHORIZED) and green (AUTHORIZED).

---

## Pre-conditions

- [ ] GF-W1-UI-002 is status=completed (three-tab layout exists)
- [ ] This PLAN.md has been reviewed and approved

---

## Must Read (MANDATORY — read in full before any code changes)

1. `.kiro/steering/ui-canonical-design.md` — CSS tokens, financial meaning rules
2. `.kiro/steering/pwrm0001-domain-rules.md` — Programme identity, proof types
3. `.kiro/steering/symphony-platform-conventions.md` — Runtime profile, API patterns
4. `.kiro/specs/symphony-ui-canonical/requirements.md` — Requirements 1.2, 1.3, 1.4
5. `.kiro/specs/symphony-ui-canonical/design.md` — KPI row wireframe, disbursement logic
6. `.kiro/specs/symphony-ui-canonical/tasks.md` — Task 3 verbatim instructions

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add KPI cards and disbursement card |
| `tasks/GF-W1-UI-003/meta.yml` | MODIFY | Update status |
| `evidence/phase1/gf_w1_ui_003.json` | CREATE | Evidence |

---

## Stop Conditions

- **If KPI values are hardcoded** → STOP
- **If disbursement card does not change colour** → STOP
- **If any node in the proof graph is orphaned** → STOP

---

## Implementation Steps

### Step 1: KPI cards
**What:** `[ID gf_w1_ui_003_work_01]` Four KPI cards in Programme Health div.
**How:** Create cards with labels "Evidence Submissions", "Exceptions", "Complete", "Completeness Rate". Large number + small label pattern.
**Done when:** All four labels present in HTML.

### Step 2: Disbursement card
**What:** `[ID gf_w1_ui_003_work_02]` Full-width Disbursement Status card with dynamic styling.
**How:** `rate < 1.0` or `total_collections == 0` → red, text "NOT AUTHORIZED — Incomplete MRV (N%)". `rate == 1.0` and `total_collections > 0` → green, "AUTHORIZED".
**Done when:** Both text patterns exist in HTML.

### Step 3: Wire to API
**What:** `[ID gf_w1_ui_003_work_03]` Wire to reveal endpoint and fit in top 40% viewport.
**How:** Extend `initDashboard()` to fetch and populate cards.
**Done when:** API URL referenced in JS code.

### Step 4: Emit evidence
```bash
# [ID gf_w1_ui_003_work_01] [ID gf_w1_ui_003_work_02] [ID gf_w1_ui_003_work_03]
test -f src/supervisory-dashboard/index.html \
  && grep -q "Evidence Submissions" src/supervisory-dashboard/index.html \
  && grep -q "NOT AUTHORIZED" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "reveal" \
  > evidence/phase1/gf_w1_ui_003.json || exit 1
```

---

## Verification

```bash
# [ID gf_w1_ui_003_work_01] [ID gf_w1_ui_003_work_02] [ID gf_w1_ui_003_work_03]
test -f src/supervisory-dashboard/index.html \
  && grep -q "Evidence Submissions" src/supervisory-dashboard/index.html \
  && grep -q "Completeness Rate" src/supervisory-dashboard/index.html \
  && grep -q "NOT AUTHORIZED" src/supervisory-dashboard/index.html \
  && grep -q "AUTHORIZED" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "reveal" \
  > evidence/phase1/gf_w1_ui_003.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/gf_w1_ui_003.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes, command_outputs, execution_trace

---

## Rollback

1. Revert: `git checkout HEAD -- src/supervisory-dashboard/index.html`
2. Update status back to `planned`

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| KPI values hardcoded | FAIL | Code review for API wiring |
| Disbursement doesn't switch | CRITICAL_FAIL | Manual browser test |
