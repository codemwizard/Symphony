# TSK-P3-GOV-004 PLAN — Repair DB task-pack generator and handoff scope for baseline, ADR, migration-head, and runtime-index closure

Task: TSK-P3-GOV-004
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-GOV-004.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any migration or regulated file without prior approval metadata.
- Approval artifacts MUST be created BEFORE editing regulated surfaces.
- Stage A: Before editing (approvals/YYYY-MM-DD/BRANCH-<branch>.md and .approval.json)
- Stage B: After PR opening (approvals/YYYY-MM-DD/PR-<number>.md and .approval.json)
- Conformance check: `bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=<branch>`

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---
## Objective

Repair DB task-pack generator and handoff scope for baseline, ADR, migration-head, and runtime-index closure. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

- [ ] `docs/operations/TASK_ID_NOMENCLATURE.md` reviewed for task-family and wave rules.
- [ ] `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` reviewed for scope boundaries.
- [ ] `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` reviewed for invariant references.


---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/agent/generate_task_pack.py` | MODIFY | Repair emitted DB task-pack scope surfaces |
| `docs/operations/TASK_CREATION_PROCESS.md` | MODIFY | Record canonical DB task-pack scope requirements |
| `docs/operations/AI_AGENT_PHASE_PLANNING_TO_TASK_HANDOFF_GUIDE.md` | MODIFY | Record DB handoff scope requirements |
| `docs/tasks/PHASE3_TASKS.md` | MODIFY | Register the follow-up governance repair task |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Reconcile completed status in Phase 3 machine registry |
| `docs/PHASE3/PHASE3_TASK_DAG.md` | MODIFY | Reconcile completed status in human DAG truth |
| `docs/PHASE3/phase3_task_dag.yml` | MODIFY | Reconcile completed status in machine DAG truth |
| `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` | MODIFY | Reconcile completed status in master plan truth |
| `scripts/agent/verify_tsk_p3_gov_004_db_task_scope_generator.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_gov_004_db_task_scope_generator.json` | CREATE | Output artifact |
| `tasks/TSK-P3-GOV-004/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-GOV-004/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_gov_004_work_01] Update the DB-task generation path so generated task packs include the canonical rebaseline closure surfaces required by the Phase 3 DB implementation plans, including schema migration head, stable baseline pointers, dated baseline outputs, ADR-0010 governance logging, and the correct human runtime task index when applicable.
- [ID tsk_p3_gov_004_work_02] Update the documented planning-to-task handoff rules so DB task packs distinguish between implementation deliverables and mandatory governance/runtime-index closure surfaces without relying on post-generation manual repair.
- [ID tsk_p3_gov_004_work_03] Add a deterministic verifier that generates a representative DB task pack in a temporary sandbox and proves the emitted scope includes the canonical DB baseline, migration-head, ADR, and runtime-index surfaces required for resumed implementation.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_gov_004_db_task_scope_generator.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_gov_004_db_task_scope_generator.sh > evidence/phase3/tsk_p3_gov_004_db_task_scope_generator.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_gov_004_db_task_scope_generator.sh

# 2. Evidence validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-GOV-004 --evidence evidence/phase3/tsk_p3_gov_004_db_task_scope_generator.json

# 3. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P3-GOV-004
```
