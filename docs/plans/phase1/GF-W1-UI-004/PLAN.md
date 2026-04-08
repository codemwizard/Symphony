# GF-W1-UI-004 PLAN — Programme Health tab: Activity table with financial columns

Task: GF-W1-UI-004
Owner: SUPERVISOR
Depends on: GF-W1-UI-003
failure_signature: PHASE1.GREEN_FINANCE.GF-W1-UI-004.ACTIVITY_TABLE_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Add the activity table below the KPI rows in the Programme Health tab. The table shows
instruction-level data with financial columns (Net Weight, tCO₂ est.) and status chips.
It fills remaining viewport height using flex:1 and overflow-y:auto. Row click opens
the instruction drawer (Task 5). The tCO₂ column uses the canonical constant 0.00048.

---

## Pre-conditions

- [ ] GF-W1-UI-003 is status=completed (KPI cards and disbursement card exist)
- [ ] This PLAN.md has been reviewed and approved

---

## Must Read (MANDATORY — read in full before any code changes)

1. `.kiro/steering/ui-canonical-design.md` — CSS tokens, financial constants
2. `.kiro/steering/pwrm0001-domain-rules.md` — Programme identity, proof types, tCO₂ constant
3. `.kiro/steering/symphony-platform-conventions.md` — Runtime profile, API patterns
4. `.kiro/specs/symphony-ui-canonical/requirements.md` — Requirements 1.5, 1.6
5. `.kiro/specs/symphony-ui-canonical/design.md` — Activity table wireframe
6. `.kiro/specs/symphony-ui-canonical/tasks.md` — Task 4 verbatim instructions

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add activity table with financial columns |
| `tasks/GF-W1-UI-004/meta.yml` | MODIFY | Update status to completed |
| `evidence/phase1/gf_w1_ui_004.json` | CREATE | Evidence artifact |

---

## Stop Conditions

- **If tCO₂ computed with wrong constant (must be 0.00048)** → STOP (CRITICAL_FAIL)
- **If table has no overflow-y:auto** → STOP
- **If row click does not trigger drawer open** → STOP
- **If any node in the proof graph is orphaned** → STOP

---

## Implementation Steps

### Step 1: Create activity table
**What:** `[ID gf_w1_ui_004_work_01]` Add table below KPI rows filling remaining viewport height.
**How:** Create table with flex:1, overflow-y:auto. Columns: Instruction ID | Proof Type | Status | Net Weight | tCO₂ est. | Time.
**Done when:** Table element exists with all 6 columns and overflow-y:auto.

### Step 2: Status chips and financial columns
**What:** `[ID gf_w1_ui_004_work_02]` Implement status chips and financial column logic.
**How:** Status chip: green=PRESENT, amber=PENDING, red=MISSING. Net Weight: `net_weight_kg + " kg"` if WEIGHBRIDGE_RECORD, else "—". tCO₂: `(net_weight_kg * 0.00048).toFixed(4)` if weight present, else "—". Time: `observed_at_utc` formatted as HH:mm local.
**Done when:** 0.00048 constant appears in JS code, status chip colours reference canonical tokens.

### Step 3: Row click handler
**What:** `[ID gf_w1_ui_004_work_03]` Wire row click to instruction detail endpoint.
**How:** Row click calls `GET /pilot-demo/api/instructions/{instructionId}/detail` and opens the drawer (Task 5).
**Done when:** Click handler references the instruction detail endpoint.

### Step 4: Emit evidence
```bash
# [ID gf_w1_ui_004_work_01] [ID gf_w1_ui_004_work_02] [ID gf_w1_ui_004_work_03]
test -f src/supervisory-dashboard/index.html \
  && grep -q "0.00048" src/supervisory-dashboard/index.html \
  && grep -q "overflow-y" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "instructions.*detail" \
  > evidence/phase1/gf_w1_ui_004.json || exit 1
```

---

## Verification

```bash
# [ID gf_w1_ui_004_work_01] [ID gf_w1_ui_004_work_02] [ID gf_w1_ui_004_work_03]
test -f src/supervisory-dashboard/index.html \
  && grep -q "0.00048" src/supervisory-dashboard/index.html \
  && grep -q "overflow-y" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "instructions.*detail" \
  > evidence/phase1/gf_w1_ui_004.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/gf_w1_ui_004.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes, command_outputs, execution_trace

---

## Rollback

1. Revert: `git checkout HEAD -- src/supervisory-dashboard/index.html`
2. Update status back to `planned`

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| tCO₂ constant wrong | CRITICAL_FAIL | grep for 0.00048 |
| Table overflows viewport | FAIL | grep for overflow-y:auto |
| Row click broken | FAIL | grep for endpoint pattern |
