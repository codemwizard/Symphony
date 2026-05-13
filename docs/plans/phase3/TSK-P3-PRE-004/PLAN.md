# TSK-P3-PRE-004 PLAN — Adapt meta.yml Template for Phase 3

Task: TSK-P3-PRE-004
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-PRE-004.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---
## Objective

Adapt meta.yml Template for Phase 3. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p3_pre_004.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_pre_004_template_adaptation.json` | CREATE | Output artifact |
| `tasks/TSK-P3-PRE-004/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-PRE-004/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_pre_004_w01] Add wave field to the meta.yml template with comment documenting valid values.
- [ID tsk_p3_pre_004_w02] Update default must_read entries to include Phase 3 constitutional documents: PHASE3_CAPABILITY_BOUNDARY.md, PHASE3_INVARIANT_REGISTER.md.
- [ID tsk_p3_pre_004_w03] Update path mapping comments to include phase: 3 -> docs/plans/phase3/<TASK_ID>/PLAN.md.
- [ID tsk_p3_pre_004_w04] Add docs/operations/TASK_ID_NOMENCLATURE.md to must_read for all Phase 3 tasks.
- [ID tsk_p3_pre_004_w05] Verify template remains backward compatible — existing Phase 0-2 tasks must not break.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_tsk_p3_pre_004.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p3_pre_004.sh > evidence/phase3/tsk_p3_pre_004_template_adaptation.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_tsk_p3_pre_004.sh

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
