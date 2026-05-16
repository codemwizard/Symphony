# TSK-P3-ACT-002 PLAN — Create the formal Phase 3 opening approval artifact set

Task: TSK-P3-ACT-002
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-ACT-002.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---
## Objective

Create the formal Phase 3 opening approval artifact set. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `approvals/2026-05-16/PHASE3-OPENING.md` | CREATE | Formal human opening approval record |
| `approvals/2026-05-16/PHASE3-OPENING.approval.json` | CREATE | Machine-readable opening approval sidecar |
| `scripts/agent/verify_tsk_p3_act_002.sh` | CREATE | Verifier for this task |
| `docs/tasks/PHASE3_ACTIVATION_TASKS.md` | MODIFY | Register activation task in the current task index |
| `evidence/phase3/tsk_p3_act_002_opening_approval.json` | CREATE | Output artifact |
| `tasks/TSK-P3-ACT-002/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-ACT-002/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If the opening artifact set claims that Phase 3 runtime implementation is complete** -> STOP
- **If the opening markdown and approval sidecar diverge on approval status or scope** -> STOP
- **If required regulated reconciliation surfaces are missing from the approval scope** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If evidence is statically faked instead of derived from the verifier** -> STOP

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_act_002_work_01] Create approvals/2026-05-16/PHASE3-OPENING.md documenting human approval to open Phase 3 and the exact regulated and non-regulated activation scope.
- [ID tsk_p3_act_002_work_02] Create approvals/2026-05-16/PHASE3-OPENING.approval.json conforming to the approval sidecar schema and linking the opening record to the activation surfaces.
- [ID tsk_p3_act_002_work_03] Create scripts/agent/verify_tsk_p3_act_002.sh to validate the opening markdown and sidecar for required fields, scope references, and no overclaim of runtime completion, then emit evidence/phase3/tsk_p3_act_002_opening_approval.json.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_act_002.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_act_002.sh
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_act_002.sh

# 2. Evidence validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-ACT-002 --evidence evidence/phase3/tsk_p3_act_002_opening_approval.json

# 3. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P3-ACT-002

# 4. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
