# TSK-P1-239 PLAN — Template Hardening & Anti-Drift Restructuring

Task: TSK-P1-239
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-222
failure_signature: PHASE1.GOVERNANCE.TSK-P1-239.TEMPLATE_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Eradicate subjective fluff from future task creation by mutating the canonical `PLAN_TEMPLATE.md`. Introduce mathematical rigidity to the template through Explicit Stop Conditions, Verifier Design boundaries, and ID-based tracking requirements. The `PLAN_TEMPLATE.md` will become a cryptographically enforcable blueprint modeled directly after the successful `TSK-P1-240` execution.

---

## Architectural Context

Standard markdown templates degrade rapidly under generative UI systems because agents fill headers with subjective words like "ensure" or "validate." This task enforces structural rigidity down to the literal task template, explicitly bridging the gap before `TSK-P1-240` deployed the python meta-verifier. 

---

## Pre-conditions

- [x] TSK-P1-222 is status=completed.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/contracts/templates/PLAN_TEMPLATE.md` | MODIFY | Inject TSK-P1-240 stop conditions and ID tracking |
| `tasks/TSK-P1-239/meta.yml` | MODIFY | Update status to completed |
| `evidence/phase1/tsk_p1_239_template_hardening.json` | CREATE | Output artifact |

---

## Stop Conditions

- **If the template doesn't explicitly restrict verification stubs to || exit 1** -> STOP
- **If the template lacks mathematical ID graph connection rules** -> STOP

---

## Implementation Steps

### Step 1: Formalize PLAN_TEMPLATE.md Strict Mode
**What:** `[ID tsk_p1_239_work_item_01]` Overwrite `docs/contracts/templates/PLAN_TEMPLATE.md`.
**How:** Directly copy `TSK-P1-240` stop conditions and add explicit tracking ID guidelines (`[ID <task_slug>_...]`) into every step and verifier example.
**Done when:** The template actively forces ID tagging loops and prevents hallucinated artifacts.

### Step 2: Write Verification Logic
**What:** `[ID tsk_p1_239_work_item_02]` Ensure the new template compiles.
**How:** Verify that grep asserts the presence of the critical stop conditions in the template file.
**Done when:** Grep returns 0.

### Step 3: Emit evidence
**What:** `[ID tsk_p1_239_work_item_03]` Run verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_239.sh > evidence/phase1/tsk_p1_239_template_hardening.json || exit 1
```
**Done when:** Verification executes natively through failure paths and the explicit JSON schema is written to disk.

---

## Verification

```bash
# [ID tsk_p1_239_work_item_01] [ID tsk_p1_239_work_item_02] [ID tsk_p1_239_work_item_03]
test -f docs/contracts/templates/PLAN_TEMPLATE.md && cat docs/contracts/templates/PLAN_TEMPLATE.md | grep "Stop Conditions" > /dev/null || exit 1

# [ID tsk_p1_239_work_item_03]
cat <<EOF > evidence/phase1/tsk_p1_239_template_hardening.json
{
  "task_id": "TSK-P1-239",
  "status": "PASS",
  "checks": ["P1"]
}
EOF
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_239_template_hardening.json`

Required fields:
- `task_id`
- `status`
- `checks`

---

## Rollback

If this task must be reverted:
1. Revert `docs/contracts/templates/PLAN_TEMPLATE.md` to its original 120-line draft.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Rejecting docs-only tasks due to strictness | FRICTION | Allow DOCS_ONLY to bypass graph gates where applicable (handled in logic later). |
