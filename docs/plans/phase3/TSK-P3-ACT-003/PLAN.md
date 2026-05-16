# TSK-P3-ACT-003 PLAN — Rewrite the root execution envelope for active Phase 3 status

Task: TSK-P3-ACT-003
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-ACT-003.PROOF_FAIL
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

Rewrite the root execution envelope for active Phase 3 status. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/operations/PHASE_EXECUTION_ENVELOPE.md` | MODIFY | Rewrite the root execution contract for active Phase 3 status |
| `scripts/agent/verify_tsk_p3_act_003.sh` | CREATE | Verifier for this task |
| `docs/tasks/PHASE3_ACTIVATION_TASKS.md` | MODIFY | Register the activation task in the current task index |
| `evidence/phase3/tsk_p3_act_003_envelope_alignment.json` | CREATE | Output artifact |
| `tasks/TSK-P3-ACT-003/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-ACT-003/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata does not cover the envelope rewrite before the first regulated edit** -> STOP
- **If the rewrite opens non-Phase-3 execution surfaces implicitly** -> STOP
- **If the envelope still states that Phase 2 is the only legal execution surface** -> STOP
- **If the rewrite overclaims full Phase 3 runtime completion instead of activation status** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If evidence is statically faked instead of derived** -> STOP

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_act_003_work_01] Rewrite docs/operations/PHASE_EXECUTION_ENVELOPE.md so it names Phase 3 as the active lifecycle phase, aligns allowed and forbidden capabilities to the opened Phase 3 state, and removes unopened-phase treatment of evidence/phase3/**.
- [ID tsk_p3_act_003_work_02] Create scripts/agent/verify_tsk_p3_act_003.sh to validate that the envelope aligns with Phase 3 lifecycle artifacts, opening approval artifacts, and the active execution surface claims, then emit evidence/phase3/tsk_p3_act_003_envelope_alignment.json.
- [ID tsk_p3_act_003_work_03] Register TSK-P3-ACT-003 in docs/tasks/PHASE3_ACTIVATION_TASKS.md and update the task pack status, plan, and execution log after the verifier and readiness checks pass.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_act_003.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_act_003.sh
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_act_003.sh

# 2. Evidence validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-ACT-003 --evidence evidence/phase3/tsk_p3_act_003_envelope_alignment.json

# 3. Approval metadata validation
PRE_CI_CONTEXT=1 bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=chore-phase3-planning-followup

# 4. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P3-ACT-003

# 5. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
