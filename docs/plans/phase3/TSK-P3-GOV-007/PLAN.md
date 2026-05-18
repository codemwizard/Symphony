# TSK-P3-GOV-007 PLAN — Normalize proof-before-completion lifecycle semantics for task verifiers

Task: TSK-P3-GOV-007
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-GOV-007.PROOF_FAIL
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

Normalize proof-before-completion lifecycle semantics for task verifiers. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

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
| `scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh` | MODIFY | Remove pre-proof dependency on completed status from representative verifier |
| `scripts/db/verify_p3_conflict_of_interest_enforcement.sh` | MODIFY | Remove pre-proof dependency on completed status from representative verifier |
| `scripts/db/verify_p3_spatial_legality_dnsh_gates.sh` | MODIFY | Remove pre-proof dependency on completed status from representative verifier |
| `scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh` | MODIFY | Remove pre-proof dependency on completed status from representative verifier |
| `scripts/agent/verify_tsk_p3_support_obs_001.sh` | MODIFY | Remove pre-proof dependency on completed status from representative verifier |
| `scripts/agent/verify_tsk_p3_support_perf_001.sh` | MODIFY | Remove pre-proof dependency on completed status from representative verifier |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register task in Phase 3 registry |
| `docs/tasks/PHASE3_TASKS.md` | MODIFY | Register task in the human Phase 3 task index |
| `scripts/agent/verify_tsk_p3_gov_007_proof_before_completion.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_gov_007_proof_before_completion.json` | CREATE | Output artifact |
| `tasks/TSK-P3-GOV-007/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-GOV-007/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_gov_007_w01] Remove the coupling that requires task-specific verifiers to observe meta.yml status completed before they can prove implementation, and define proof-before-completion as the canonical task closeout sequence.
- [ID tsk_p3_gov_007_w02] Update the task creation and implementation workflow docs so task-packed, resume-ready, proof-passed, and completed are mechanically distinct lifecycle states with no circular dependency between proof and status.
- [ID tsk_p3_gov_007_w03] Add a deterministic verifier that generates or inspects representative task packs and fails if verifier contracts still require completed status prior to proof emission.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_gov_007_proof_before_completion.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_gov_007_proof_before_completion.sh > evidence/phase3/tsk_p3_gov_007_proof_before_completion.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_gov_007_proof_before_completion.sh

# 2. Evidence validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-GOV-007 --evidence evidence/phase3/tsk_p3_gov_007_proof_before_completion.json

# 3. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P3-GOV-007
```
