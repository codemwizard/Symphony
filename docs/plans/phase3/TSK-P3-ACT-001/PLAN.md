# TSK-P3-ACT-001 PLAN — Build the missing Phase 3 lifecycle artifact set

Task: TSK-P3-ACT-001
Owner: SECURITY_GUARDIAN
failure_signature: PHASE3.STRICT.TSK-P3-ACT-001.PROOF_FAIL
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

Build the missing Phase 3 lifecycle artifact set. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/PHASE3/PHASE3_CONTRACT.md` | CREATE | Human-readable Phase 3 contract |
| `docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md` | CREATE | Phase-specific SDLC policy guard |
| `scripts/audit/verify_phase3_contract.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_act_001_lifecycle_artifacts.json` | CREATE | Output artifact |
| `docs/tasks/PHASE3_ACTIVATION_TASKS.md` | MODIFY | Register the activation task in the current phase task index |
| `tasks/TSK-P3-ACT-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-ACT-001/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If the contract, policy, and verifier disagree on phase identity, verifier path, gate flag, or evidence namespace** -> STOP
- **If any artifact claims that the root execution envelope has already been updated** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_act_001_work_01] Create docs/PHASE3/PHASE3_CONTRACT.md as the human-readable Phase 3 contract aligned to docs/PHASE3/phase3_contract.yml and the activation sequence.
- [ID tsk_p3_act_001_work_02] Create docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md defining the Phase 3 SDLC policy, evidence namespace, gate flag, and authority chain without overstating completion.
- [ID tsk_p3_act_001_work_03] Create scripts/audit/verify_phase3_contract.sh to validate the required Phase 3 artifact set and emit evidence/phase3/tsk_p3_act_001_lifecycle_artifacts.json deterministically.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_phase3_contract.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_phase3_contract.sh
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_phase3_contract.sh

# 1b. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-ACT-001 --evidence evidence/phase3/tsk_p3_act_001_lifecycle_artifacts.json

# 1c. Approval metadata validation
PRE_CI_CONTEXT=1 bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=chore-phase3-planning-followup

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
