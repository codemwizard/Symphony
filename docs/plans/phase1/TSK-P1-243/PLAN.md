# TSK-P1-243 PLAN — Establish the canonical guarded execution core in scripts/audit so downstream runtime-integrity tasks share one fail-closed entrypoint

This plan creates the next narrow child task under the TSK-P1-241 runtime-integrity graph by defining the guarded execution core contract only.

Task: TSK-P1-243
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-242
failure_signature: PHASE1.RUNTIME_INTEGRITY.TSK-P1-243.GUARDED_EXECUTION_CORE
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Establish one canonical fail-closed execution entrypoint at
`scripts/audit/runtime_guarded_execution_core.sh` so downstream runtime-integrity
tasks share a stable contract. Done means the execution core has a narrow CLI and
bootstrap contract, a task-specific verifier proves that the real script enforces
that contract, and the emitted evidence remains bounded to execution-core claims
instead of drifting into repository integrity or evidence finalization guarantees.

---

## Architectural Context

TSK-P1-242 resolved the host-path decision into the already-owned
`scripts/audit/**` surface, which means the next honest step is defining the
canonical execution-core entrypoint before any broader integrity logic starts.
This task exists to prevent the runtime-integrity line from splitting execution
contract design across multiple downstream tasks or silently mixing it with
repository/filesystem integrity, evidence semantics, or adversarial coverage.

---

## Pre-conditions

- [x] TSK-P1-242 exists as the host-path authority task and names `scripts/audit/**` as the authorized surface.
- [x] `AGENTS.md` has been reviewed for the `SECURITY_GUARDIAN` audit-surface authority.
- [x] The parent runtime-integrity graph still places repository/filesystem integrity, evidence finalization, and adversarial coverage downstream of this task.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/runtime_guarded_execution_core.sh` | CREATE | Define the canonical guarded execution entrypoint inside the authorized audit surface |
| `scripts/audit/verify_tsk_p1_243.sh` | CREATE | Prove the execution core contract through real executable inspection |
| `evidence/phase1/tsk_p1_243_guarded_execution_core.json` | CREATE | Emit bounded proof for the guarded execution core contract |
| `tasks/TSK-P1-243/meta.yml` | CREATE | Create the guarded execution core child task contract |
| `docs/plans/phase1/TSK-P1-243/PLAN.md` | CREATE | Define the execution-core scope, stop conditions, and verifier obligations |
| `docs/plans/phase1/TSK-P1-243/EXEC_LOG.md` | CREATE | Start the append-only execution log for the child task |
| `docs/tasks/PHASE1_GOVERNANCE_TASKS.md` | MODIFY | Register the new child task in the Phase-1 governance index |

---

## Stop Conditions

- **If the task begins implementing repository/filesystem integrity rules** -> STOP
- **If the task begins implementing evidence-finalization semantics** -> STOP
- **If the task adds adversarial test coverage instead of the execution-core contract** -> STOP
- **If the verifier cannot inspect real executable state** -> STOP
- **If the evidence claims more than the execution-core contract can prove** -> STOP

---

## Implementation Steps

### Step 1: Define the canonical execution-core interface
**What:** `[ID tsk_p1_243_work_item_01]` Create one canonical execution entrypoint at `scripts/audit/runtime_guarded_execution_core.sh`.
**How:** Implement a shell script in the authorized audit surface whose public interface is limited to `--mode repo-guard`, `--mode contract-check`, optional `--repo-root <path>`, and optional `--evidence <path>`.
**Done when:** The repo contains one execution-core script and no alternate ad hoc entrypoint is needed for downstream runtime-integrity work.

### Step 2: Enforce fail-closed bootstrap and confinement
**What:** `[ID tsk_p1_243_work_item_02]` Make the execution core reject unsupported modes and unauthorized repo roots.
**How:** Use hard-fail shell posture, deterministic argument parsing, repo-root normalization, and confinement checks so unknown modes and invalid roots exit non-zero before any downstream logic runs.
**Done when:** The script fails closed for unsupported modes, missing roots, and roots outside the working tree.

### Step 3: Add the task-specific verifier
**What:** `[ID tsk_p1_243_work_item_03]` Create `scripts/audit/verify_tsk_p1_243.sh`.
**How:** Inspect the real execution-core script for executable presence, supported modes, strict failure posture, and confinement behavior rather than validating documentation text.
**Done when:** The verifier proves the contract against the actual script and emits the declared evidence artifact.

### Step 4: Emit bounded execution-core evidence
**What:** `[ID tsk_p1_243_work_item_04]` Write `evidence/phase1/tsk_p1_243_guarded_execution_core.json`.
**How:** Emit structured evidence including the entrypoint path, supported modes, confinement result, strict-failure posture result, and an explicit scope boundary statement.
**Done when:** The evidence file exists and proves only the guarded execution core contract.

---

## Verification

```bash
# [ID tsk_p1_243_work_item_01] [ID tsk_p1_243_work_item_02]
# [ID tsk_p1_243_work_item_03] [ID tsk_p1_243_work_item_04]
bash -lc 'test -x scripts/audit/verify_tsk_p1_243.sh && \
bash scripts/audit/verify_tsk_p1_243.sh > \
evidence/phase1/tsk_p1_243_guarded_execution_core.json || exit 1'

# [ID tsk_p1_243_work_item_04]
bash -lc 'test -f evidence/phase1/tsk_p1_243_guarded_execution_core.json && \
python3 scripts/audit/validate_evidence.py --task TSK-P1-243 --evidence \
evidence/phase1/tsk_p1_243_guarded_execution_core.json || exit 1'

# [ID tsk_p1_243_work_item_01] [ID tsk_p1_243_work_item_02]
# [ID tsk_p1_243_work_item_03] [ID tsk_p1_243_work_item_04]
bash -lc 'test -x scripts/dev/pre_ci.sh && RUN_PHASE1_GATES=1 \
bash scripts/dev/pre_ci.sh || exit 1'
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_243_guarded_execution_core.json`

Required fields:
- `task_id`
- `git_sha`
- `timestamp_utc`
- `status`
- `checks`
- `observed_paths`
- `observed_hashes`
- `command_outputs`
- `execution_trace`
- `entrypoint_path`
- `supported_modes`
- `repo_root_confinement`
- `strict_failure_posture`
- `scope_boundary`

This evidence is bounded to proving the guarded execution core contract exists and
is constrained correctly. It does not prove repository/filesystem integrity
enforcement, evidence-finalization behavior, or adversarial coverage.

---

## Rollback

If this task must be reverted:
1. Remove the `TSK-P1-243` task pack files and Phase-1 governance index entry.
2. Remove the guarded execution core script and its task-specific verifier.
3. Remove the execution-core evidence artifact.
4. Reopen the runtime-integrity line at the host-path authority checkpoint until a different execution-core task is defined.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Guarded execution core is not rooted in the authorized audit surface | FAIL | Require the script path to live under `scripts/audit/**` and verify it mechanically |
| Execution entrypoint lacks fail-closed bootstrap or confinement checks | FAIL | Reject the task unless the verifier proves unsupported modes and invalid roots fail closed |
| Verifier inspects documentation text instead of executable contract state | FAIL | Require the task-specific verifier to inspect the real script and emitted evidence |
| Evidence overclaims repository integrity or evidence-finalization guarantees | FAIL | Bound the evidence fields and scope statement to execution-core facts only |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
