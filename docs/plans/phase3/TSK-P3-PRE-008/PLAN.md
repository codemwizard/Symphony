# TSK-P3-PRE-008 PLAN — Populate Phase 3 Task Registry

Task: TSK-P3-PRE-008
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-PRE-008.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---
## Objective

Populate Phase 3 Task Registry. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p3_pre_008.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_pre_008_registry_population.json` | CREATE | Output artifact |
| `tasks/TSK-P3-PRE-008/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-PRE-008/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_pre_008_w01] Extract all task IDs from phase_3_constraint_legitimacy_engine_task_plan.md, applying nomenclature rules.
- [ID tsk_p3_pre_008_w02] Assign each task a task_type from the approved taxonomy.
- [ID tsk_p3_pre_008_w03] Assign each task a wave from the approved group registry.
- [ID tsk_p3_pre_008_w04] Assign each task a ci_tier from the CI tier model (mark all as proposed).
- [ID tsk_p3_pre_008_w05] Link VERIFY tasks to their IMPL parents via verifies field.
- [ID tsk_p3_pre_008_w06] Populate docs/PHASE3/phase3_task_registry.yml with all tasks, replacing the 3 example tasks with the verified inventory.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_tsk_p3_pre_008.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p3_pre_008.sh > evidence/phase3/tsk_p3_pre_008_registry_population.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_tsk_p3_pre_008.sh

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
