# GF-W1-UI-006 PLAN — Monitoring Report tab: full financial report display

Task: GF-W1-UI-006
Owner: SUPERVISOR
Depends on: GF-W1-UI-002
failure_signature: PHASE1.GREEN_FINANCE.GF-W1-UI-006.MONITORING_REPORT_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Implement the Monitoring Report tab with disbursement banner, additionality row, plastic
totals table, tCO₂/credits row, benefit-sharing three-way split, ZGFT alignment chips,
and Generate Report button. This is the primary financial transparency view. All financial
values must carry the "(indicative)" qualifier. Constants must match the steering file.

---

## Pre-conditions

- [ ] GF-W1-UI-002 is status=completed (three-tab layout exists)
- [ ] This PLAN.md has been reviewed and approved

---

## Must Read (MANDATORY — read in full before any code changes)

1. `.kiro/steering/ui-canonical-design.md` — CSS tokens, financial constants
2. `.kiro/steering/pwrm0001-domain-rules.md` — Programme identity, benefit-sharing rules
3. `.kiro/steering/symphony-platform-conventions.md` — Runtime profile, API patterns
4. `.kiro/specs/symphony-ui-canonical/requirements.md` — Requirements 2.1–2.5
5. `.kiro/specs/symphony-ui-canonical/design.md` — Monitoring report wireframe
6. `.kiro/specs/symphony-ui-canonical/tasks.md` — Task 6 verbatim instructions

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add monitoring report tab content |
| `tasks/GF-W1-UI-006/meta.yml` | MODIFY | Update status to completed |
| `evidence/phase1/gf_w1_ui_006.json` | CREATE | Evidence artifact |

---

## Stop Conditions

- **If financial values displayed without (indicative) qualifier** → STOP
- **If additionality row missing or baseline not explicitly shown** → STOP
- **If benefit-sharing block missing or percentages don't sum to 100%** → STOP
- **If tCO₂ constant is not 0.00048** → STOP (CRITICAL_FAIL)
- **If PRICE_PER_TCO2_ZMW is not 150.0** → STOP (CRITICAL_FAIL)
- **If any node in the proof graph is orphaned** → STOP

---

## Implementation Steps

### Step 1: Disbursement banner
**What:** `[ID gf_w1_ui_006_work_01]` Section 1 (~20%): Disbursement status banner.
**How:** Same red/green logic as Task 3 but from monitoring report API.
**Done when:** Banner shows red/green based on completeness.

### Step 2: Additionality, totals, and carbon
**What:** `[ID gf_w1_ui_006_work_02]` Section 2 (~50%): Additionality row, plastic totals table, tCO₂/credits row.
**How:** (a) "Baseline: 0 kg | Actual: N kg | Additionality: +N kg ● GREEN". Always shown. (b) PET, HDPE, LDPE, PP, PS, OTHER, TOTAL with kg values. (c) "Estimated tCO₂: X | Estimated Credits: X credits (1 credit = 1 tCO₂, indicative)".
**Done when:** "Baseline" and "Additionality" text patterns present. All plastic types listed.

### Step 3: Benefit sharing and ZGFT
**What:** `[ID gf_w1_ui_006_work_03]` Section 3 (~30%): Benefit sharing, ZGFT chips, Generate Report button.
**How:** "Project Developer (50%): ZMW X", "Community (30%): ZMW X", "National Fund (20%): ZMW X". Three ZGFT chips (green): "Pollution Prevention ✓", "Circular Economy ✓", "DNSH Declared ✓". Generate Report button with amber spinner.
**Done when:** "Project Developer" and percentage text present.

### Step 4: Wire to API
**What:** `[ID gf_w1_ui_006_work_04]` Wire to monitoring report endpoint with canonical constants.
**How:** Call `GET /pilot-demo/api/monitoring-report/{programId}`. Use TCO2_PER_KG = 0.00048, PRICE_PER_TCO2_ZMW = 150.0, BENEFIT_SHARE = {0.50, 0.30, 0.20}.
**Done when:** Constants 0.00048, 150.0 present. monitoring-report endpoint referenced.

### Step 5: Emit evidence
```bash
# [ID gf_w1_ui_006_work_01] [ID gf_w1_ui_006_work_02]
# [ID gf_w1_ui_006_work_03] [ID gf_w1_ui_006_work_04]
test -f src/supervisory-dashboard/index.html \
  && grep -q "Baseline" src/supervisory-dashboard/index.html \
  && grep -q "Additionality" src/supervisory-dashboard/index.html \
  && grep -q "Project Developer" src/supervisory-dashboard/index.html \
  && grep -q "indicative" src/supervisory-dashboard/index.html \
  && grep -q "0.00048" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "monitoring-report" \
  > evidence/phase1/gf_w1_ui_006.json || exit 1

# [ID gf_w1_ui_006_work_03]
test -f src/supervisory-dashboard/index.html \
  && grep -q "50%" src/supervisory-dashboard/index.html \
  && grep -q "30%" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "20%" \
  || exit 1
```

---

## Verification

```bash
# [ID gf_w1_ui_006_work_01] [ID gf_w1_ui_006_work_02]
# [ID gf_w1_ui_006_work_03] [ID gf_w1_ui_006_work_04]
test -f src/supervisory-dashboard/index.html \
  && grep -q "Baseline" src/supervisory-dashboard/index.html \
  && grep -q "Additionality" src/supervisory-dashboard/index.html \
  && grep -q "Project Developer" src/supervisory-dashboard/index.html \
  && grep -q "indicative" src/supervisory-dashboard/index.html \
  && grep -q "0.00048" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "monitoring-report" \
  > evidence/phase1/gf_w1_ui_006.json || exit 1

# [ID gf_w1_ui_006_work_03]
test -f src/supervisory-dashboard/index.html \
  && grep -q "50%" src/supervisory-dashboard/index.html \
  && grep -q "30%" src/supervisory-dashboard/index.html \
  && cat src/supervisory-dashboard/index.html | grep "20%" \
  || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/gf_w1_ui_006.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes, command_outputs, execution_trace, additionality_row_verified, benefit_sharing_verified

---

## Rollback

1. Revert: `git checkout HEAD -- src/supervisory-dashboard/index.html`
2. Update status back to `planned`

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Financial values unqualified | FAIL | grep for "indicative" |
| Additionality row missing | FAIL | grep for "Baseline" |
| Benefit-sharing wrong | FAIL | grep for 50%/30%/20% |
| Constants wrong | CRITICAL_FAIL | grep for 0.00048, 150.0 |
