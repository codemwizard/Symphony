# TSK-P3-ACT-004 PLAN — Reconcile the legality layer and dependent Phase 3 planning posture

Task: TSK-P3-ACT-004
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-ACT-004.PROOF_FAIL
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

Reconcile the legality layer and dependent Phase 3 planning posture. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md` | MODIFY | Reconcile constitutional legality posture for active Phase 3 |
| `docs/PHASE3/README.md` | MODIFY | Remove stale planning-only posture |
| `docs/PHASE3/PHASE3_SOURCE_PACK.md` | MODIFY | Remove stale envelope-conflict blocker language |
| `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` | MODIFY | Reconcile master-plan posture with active envelope |
| `docs/PHASE3/PHASE3_OPENING_ACT.md` | MODIFY | Update historical conflict-resolution section to current activation state |
| `scripts/agent/verify_tsk_p3_act_004.sh` | CREATE | Verifier for this task |
| `docs/tasks/PHASE3_ACTIVATION_TASKS.md` | MODIFY | Register the activation task in the current task index |
| `evidence/phase3/tsk_p3_act_004_legality_alignment.json` | CREATE | Output artifact |
| `tasks/TSK-P3-ACT-004/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-ACT-004/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If the legality matrix still states that Phase 3 is constitutionally unopened or legally required to be absent** -> STOP
- **If dependent Phase 3 planning docs still describe a planning-only or unresolved-envelope posture** -> STOP
- **If the task expands doctrine or broader runtime claims instead of reconciling posture** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If evidence is statically faked instead of derived** -> STOP

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_act_004_work_01] Update docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md so it no longer encodes pre-opening legality for absent Phase 3 artifacts and instead reflects the active Phase 3 activation posture.
- [ID tsk_p3_act_004_work_02] Reconcile dependent Phase 3 planning posture documents, including docs/PHASE3/README.md, docs/PHASE3/PHASE3_SOURCE_PACK.md, docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md, and docs/PHASE3/PHASE3_OPENING_ACT.md, so they no longer describe a planning-only or unresolved-envelope posture.
- [ID tsk_p3_act_004_work_03] Create scripts/agent/verify_tsk_p3_act_004.sh to validate legality-layer and planning-posture alignment against the active envelope and opening artifacts, emit evidence/phase3/tsk_p3_act_004_legality_alignment.json, and register TSK-P3-ACT-004 in docs/tasks/PHASE3_ACTIVATION_TASKS.md.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_act_004.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_act_004.sh
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_act_004.sh

# 2. Evidence validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-ACT-004 --evidence evidence/phase3/tsk_p3_act_004_legality_alignment.json

# 3. Approval metadata validation
PRE_CI_CONTEXT=1 bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=chore-phase3-planning-followup

# 4. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P3-ACT-004

# 5. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
