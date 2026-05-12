# TSK-P3-GOV-003 PLAN — Implement task corpus archival gate to exclude completed tasks from active CI traversal

Task: TSK-P3-GOV-003
Owner: SECURITY_GUARDIAN
failure_signature: PHASE3.STRICT.TSK-P3-GOV-003.PROOF_FAIL
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

Implement task corpus archival gate to exclude completed tasks from active CI traversal. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_p3_task_archival_gate.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_gov_003_task_archival_gate.json` | CREATE | Output artifact |
| `tasks/TSK-P3-GOV-003/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-GOV-003/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_gov_003_work_item_01] Add archived: false field to the canonical task meta.yml template at Gove/tasks/_template/meta.yml with documentation that only tasks with status=completed and no current Phase 3 dependencies may be archived by human authorization.
- [ID tsk_p3_gov_003_work_item_02] Modify verify_task_meta_schema.sh Python inner script to skip tasks where archived: true after YAML loading, incrementing an archived_count counter reported in the evidence summary.
- [ID tsk_p3_gov_003_work_item_03] Modify verify_task_plans_present.sh Python inner script to skip tasks where archived: true after YAML loading, before the status check.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_p3_task_archival_gate.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_p3_task_archival_gate.sh > evidence/phase3/tsk_p3_gov_003_task_archival_gate.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_p3_task_archival_gate.sh

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
