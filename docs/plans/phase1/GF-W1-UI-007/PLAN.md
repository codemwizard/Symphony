# GF-W1-UI-007 PLAN — Onboarding Console tab: migrate to canonical CSS tokens

Task: GF-W1-UI-007
Owner: SUPERVISOR
Depends on: GF-W1-UI-002
failure_signature: PHASE1.GREEN_FINANCE.GF-W1-UI-007.CSS_MIGRATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Migrate the existing Onboarding Console tab from inline colours and non-canonical CSS
variables to the canonical token system established in GF-W1-UI-001. No JavaScript or
API call changes — CSS-only migration.

---

## Pre-conditions

- [ ] GF-W1-UI-002 is status=completed (three-tab layout exists)
- [ ] This PLAN.md has been reviewed and approved

---

## Must Read (MANDATORY — read in full before any code changes)

1. `.kiro/steering/ui-canonical-design.md` — CSS tokens (source of truth)
2. `.kiro/steering/pwrm0001-domain-rules.md` — Programme identity
3. `.kiro/steering/symphony-platform-conventions.md` — Runtime profile
4. `.kiro/specs/symphony-ui-canonical/requirements.md` — Requirement 3.1
5. `.kiro/specs/symphony-ui-canonical/design.md` — Token mapping
6. `.kiro/specs/symphony-ui-canonical/tasks.md` — Task 7 verbatim instructions

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Replace inline colours with CSS tokens |
| `tasks/GF-W1-UI-007/meta.yml` | MODIFY | Update status to completed |
| `evidence/phase1/gf_w1_ui_007.json` | CREATE | Evidence artifact |

---

## Stop Conditions

- **If any JavaScript changes in Onboarding Console section** → STOP
- **If any inline style= with colour values remains** → STOP
- **If any node in the proof graph is orphaned** → STOP

---

## Implementation Steps

### Step 1: Replace inline colours
**What:** `[ID gf_w1_ui_007_work_01]` Replace inline colours and non-canonical vars with canonical tokens.
**How:** Find all `style="color:..."`, `style="background:..."` in the Onboarding Console section. Replace with references to CSS token variables from :root.
**Done when:** No inline colour values remain in Onboarding Console section.

### Step 2: Table containers
**What:** `[ID gf_w1_ui_007_work_02]` Ensure table containers use overflow-y:auto and content fits 100vh.
**How:** Add overflow-y:auto to table containers. All chips use token colours.
**Done when:** overflow-y present, var(--) references in Onboarding Console.

### Step 3: Emit evidence
```bash
# [ID gf_w1_ui_007_work_01] [ID gf_w1_ui_007_work_02]
test -f src/supervisory-dashboard/index.html \
  && grep -q "Onboarding Console" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "overflow-y" \
  > evidence/phase1/gf_w1_ui_007.json || exit 1
```

---

## Verification

```bash
# [ID gf_w1_ui_007_work_01] [ID gf_w1_ui_007_work_02]
test -f src/supervisory-dashboard/index.html \
  && grep -q "Onboarding Console" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "overflow-y" \
  > evidence/phase1/gf_w1_ui_007.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/gf_w1_ui_007.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes, command_outputs, execution_trace

---

## Rollback

1. Revert: `git checkout HEAD -- src/supervisory-dashboard/index.html`
2. Update status back to `planned`

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Inline colours remain | FAIL | Grep for style= with colour values |
| JS logic changed | FAIL | Diff check for JS changes |
| Content overflows viewport | FAIL | grep for overflow-y |
