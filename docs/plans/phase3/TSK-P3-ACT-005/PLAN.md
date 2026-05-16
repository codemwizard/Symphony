# TSK-P3-ACT-005 PLAN — Normalize existing Phase 3 plans and evidence for opened-phase use

Task: TSK-P3-ACT-005
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-ACT-005.PROOF_FAIL
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

Normalize existing Phase 3 plans and evidence for opened-phase use. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/operations/PHASE_EXECUTION_ENVELOPE.md` | MODIFY | Mark activation sequence complete and open Phase 3 runtime task creation |
| `docs/PHASE3/README.md` | MODIFY | Update top-level Phase 3 posture after activation completion |
| `docs/PHASE3/PHASE3_SOURCE_PACK.md` | MODIFY | Remove activation-incomplete blocker language |
| `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` | MODIFY | Update master-plan caveat for post-activation posture |
| `docs/PHASE3/PHASE3_OPENING_ACT.md` | MODIFY | Record that the activation sequence completed successfully |
| `docs/plans/phase3/phase3_artifact_classification_manifest.json` | CREATE | Machine-readable artifact classification rules |
| `docs/plans/phase3/PHASE3_OPENED_PHASE_ARTIFACT_CLASSIFICATION.md` | CREATE | Human-readable artifact normalization summary |
| `scripts/agent/verify_tsk_p3_act_005.sh` | CREATE | Verifier for this task |
| `docs/tasks/PHASE3_ACTIVATION_TASKS.md` | MODIFY | Register the activation task in the current task index |
| `evidence/phase3/tsk_p3_act_005_artifact_normalization.json` | CREATE | Output artifact |
| `tasks/TSK-P3-ACT-005/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-ACT-005/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If any current docs/plans/phase3/** or evidence/phase3/** artifact remains unclassified** -> STOP
- **If any pre-opening cleanup, PRE, GOV, or legacy runtime-adjacent artifact is silently classified as admissible opened-phase proof** -> STOP
- **If the task mutates historical artifacts instead of classifying them** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If evidence is statically faked instead of derived** -> STOP

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_act_005_work_01] Create a machine-readable classification manifest for existing docs/plans/phase3/** and evidence/phase3/** artifacts that assigns each artifact to one of: admissible_opened_phase_activation, historical_planning_only, or regenerate_required.
- [ID tsk_p3_act_005_work_02] Create a human-readable Phase 3 artifact classification summary that explains the classification rules and the handling of activation, remediation, cleanup, pre-entry, and legacy runtime-adjacent artifacts.
- [ID tsk_p3_act_005_work_03] Create scripts/agent/verify_tsk_p3_act_005.sh to verify every current Phase 3 plan/evidence artifact is classified, that only the activation evidence set is marked admissible for opened-phase use, emit evidence/phase3/tsk_p3_act_005_artifact_normalization.json, and register TSK-P3-ACT-005 in docs/tasks/PHASE3_ACTIVATION_TASKS.md.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_act_005.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_act_005.sh
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_act_005.sh

# 2. Evidence validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-ACT-005 --evidence evidence/phase3/tsk_p3_act_005_artifact_normalization.json

# 3. Approval metadata validation
PRE_CI_CONTEXT=1 bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=chore-phase3-planning-followup

# 4. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P3-ACT-005

# 5. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
