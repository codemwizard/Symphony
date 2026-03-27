# TSK-P1-244 PLAN — Implement repository and filesystem integrity guards on the execution core so guarded runtime work fails closed on path and write-boundary violations

This plan creates the repository/filesystem integrity child task under the
runtime-integrity graph without expanding into evidence finalization or
adversarial coverage.

Task: TSK-P1-244
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-243
failure_signature: PHASE1.RUNTIME_INTEGRITY.TSK-P1-244.REPO_FILESYSTEM_INTEGRITY
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Implement the repository/filesystem integrity layer on top of the guarded
execution core. Done means `scripts/audit/runtime_guarded_execution_core.sh`
enforces repository-root normalization, rejects path traversal and unauthorized
writes, a task-specific verifier proves those guarantees against the real
execution path, and the evidence remains bounded to path and write-boundary
integrity claims only.

---

## Architectural Context

TSK-P1-243 defines the canonical execution-core entrypoint, but that contract is
still incomplete until the runtime-integrity line proves what repository scope
and filesystem write boundaries the core may use. This task exists before
evidence finalization so the write-boundary semantics are fixed mechanically
before proof-output behavior becomes its own concern, and it stays separate from
adversarial coverage so the integrity contract can stabilize first.

---

## Pre-conditions

- [x] TSK-P1-243 exists as the guarded execution-core contract task.
- [x] The authorized host surface remains `scripts/audit/**`.
- [x] The runtime-integrity graph still places evidence finalization and adversarial coverage downstream of this task.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/runtime_guarded_execution_core.sh` | MODIFY | Add repository-root and filesystem-boundary guards to the execution core |
| `scripts/audit/verify_tsk_p1_244.sh` | CREATE | Verify repository/filesystem integrity behavior through the real execution path |
| `evidence/phase1/tsk_p1_244_repository_filesystem_integrity.json` | CREATE | Emit bounded integrity proof for repo-root and write-boundary enforcement |
| `tasks/TSK-P1-244/meta.yml` | CREATE | Create the repository/filesystem integrity child task contract |
| `docs/plans/phase1/TSK-P1-244/PLAN.md` | CREATE | Define the narrow integrity-layer scope and verifier obligations |
| `docs/plans/phase1/TSK-P1-244/EXEC_LOG.md` | CREATE | Start the append-only execution log for the child task |
| `docs/tasks/PHASE1_GOVERNANCE_TASKS.md` | MODIFY | Register the new child task in the Phase-1 governance index |

---

## Stop Conditions

- **If the task begins implementing evidence-finalization semantics** -> STOP
- **If the task begins adding adversarial or corruption test suites** -> STOP
- **If the task weakens the execution core by allowing out-of-repo roots or unauthorized writes** -> STOP
- **If the verifier cannot inspect real executable path and write-boundary behavior** -> STOP
- **If the evidence claims final proof semantics or adversarial completeness** -> STOP

---

## Implementation Steps

### Step 1: Guard repository-root normalization
**What:** `[ID tsk_p1_244_work_item_01]` Extend `repo-guard` so repository arguments normalize inside the working tree only.
**How:** Implement normalization and rejection rules in `scripts/audit/runtime_guarded_execution_core.sh` so out-of-repo roots and path traversal attempts fail closed.
**Done when:** The guarded execution path exits non-zero for roots that resolve outside the working tree.

### Step 2: Guard filesystem write boundaries
**What:** `[ID tsk_p1_244_work_item_02]` Restrict writes to explicit evidence targets or shell temp space.
**How:** Add output-path checks in the execution core so unauthorized repository writes are rejected before any file is created or modified.
**Done when:** The guarded path permits only declared evidence output or temp-space writes.

### Step 3: Add the task-specific verifier
**What:** `[ID tsk_p1_244_work_item_03]` Create `scripts/audit/verify_tsk_p1_244.sh`.
**How:** Exercise the real execution core with invalid roots, traversal attempts, and unauthorized output targets, then confirm a valid bounded path still succeeds.
**Done when:** The verifier proves repository/filesystem integrity behavior against the executable contract and emits the declared evidence artifact.

### Step 4: Emit bounded repository/filesystem evidence
**What:** `[ID tsk_p1_244_work_item_04]` Write `evidence/phase1/tsk_p1_244_repository_filesystem_integrity.json`.
**How:** Emit structured evidence including the guarded mode, repo-root guard result, filesystem write-boundary result, and a scope statement that leaves evidence finalization and adversarial coverage downstream.
**Done when:** The evidence file exists and proves only repository/filesystem integrity claims.

---

## Verification

```bash
# [ID tsk_p1_244_work_item_01] [ID tsk_p1_244_work_item_02]
# [ID tsk_p1_244_work_item_03] [ID tsk_p1_244_work_item_04]
bash -lc 'test -x scripts/audit/verify_tsk_p1_244.sh && \
bash scripts/audit/verify_tsk_p1_244.sh > \
evidence/phase1/tsk_p1_244_repository_filesystem_integrity.json || exit 1'

# [ID tsk_p1_244_work_item_04]
bash -lc 'test -f evidence/phase1/tsk_p1_244_repository_filesystem_integrity.json && \
python3 scripts/audit/validate_evidence.py --task TSK-P1-244 --evidence \
evidence/phase1/tsk_p1_244_repository_filesystem_integrity.json || exit 1'

# [ID tsk_p1_244_work_item_01] [ID tsk_p1_244_work_item_02]
# [ID tsk_p1_244_work_item_03] [ID tsk_p1_244_work_item_04]
bash -lc 'test -x scripts/dev/pre_ci.sh && RUN_PHASE1_GATES=1 \
bash scripts/dev/pre_ci.sh || exit 1'
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_244_repository_filesystem_integrity.json`

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
- `guarded_mode`
- `repo_root_guard_result`
- `filesystem_write_boundary`
- `scope_boundary`

This evidence is bounded to proving repository-root and filesystem-boundary
enforcement. It does not prove evidence-finalization semantics or adversarial
coverage.

---

## Rollback

If this task must be reverted:
1. Remove the `TSK-P1-244` task pack files and Phase-1 governance index entry.
2. Remove the repository/filesystem integrity changes from the execution core.
3. Remove the task-specific verifier and integrity evidence artifact.
4. Reopen the runtime-integrity line at the execution-core checkpoint until a different integrity-layer task is defined.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Repository/filesystem integrity guard allows path traversal or out-of-repo roots | FAIL | Normalize and mechanically verify repo-root and guarded path behavior |
| Execution core writes outside declared evidence or temp boundaries | FAIL | Require output-path checks and verifier-backed rejection of unauthorized writes |
| Verifier inspects text claims instead of executable filesystem behavior | FAIL | Exercise the real execution core against invalid and valid paths |
| Evidence overclaims final proof semantics or adversarial completeness | FAIL | Bound the evidence contract to repository/filesystem integrity results only |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
