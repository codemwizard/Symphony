# TSK-P1-245 PLAN — Finalize guarded execution evidence emission so runtime-integrity proof artifacts are deterministic, bounded, and machine-validated

This plan creates the evidence-finalization child task under the runtime-integrity
graph without expanding into adversarial coverage.

Task: TSK-P1-245
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-243
failure_signature: PHASE1.RUNTIME_INTEGRITY.TSK-P1-245.EVIDENCE_FINALIZATION
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Finalize the guarded execution evidence-emission contract. Done means
`scripts/audit/runtime_guarded_execution_core.sh` emits a deterministic proof
artifact only when explicitly asked, the emitted payload contains strong fields
bound to real execution outputs, a task-specific verifier proves the finalization
behavior against the real execution path, and the evidence remains bounded to
proof-emission semantics rather than adversarial completeness.

---

## Architectural Context

TSK-P1-243 defines the execution core and TSK-P1-244 fixes the repository and
filesystem boundaries around it, but the runtime-integrity line still needs one
separate task to define how proof artifacts are actually finalized. This task
must remain distinct from adversarial coverage so the proof payload and validator
contract stabilize before corruption-focused tests start exercising them.

---

## Pre-conditions

- [x] TSK-P1-243 exists as the guarded execution-core contract task.
- [x] TSK-P1-244 exists as the repository/filesystem integrity task or is at least defined as the path-boundary layer.
- [x] The runtime-integrity graph still reserves adversarial coverage for TSK-P1-246.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/runtime_guarded_execution_core.sh` | MODIFY | Finalize the evidence-emission contract on the guarded execution path |
| `scripts/audit/verify_tsk_p1_245.sh` | CREATE | Verify evidence-finalization behavior through the real execution path |
| `evidence/phase1/tsk_p1_245_evidence_finalization.json` | CREATE | Emit bounded proof for guarded-runtime evidence finalization |
| `tasks/TSK-P1-245/meta.yml` | CREATE | Create the evidence-finalization child task contract |
| `docs/plans/phase1/TSK-P1-245/PLAN.md` | CREATE | Define the narrow evidence-finalization scope and verifier obligations |
| `docs/plans/phase1/TSK-P1-245/EXEC_LOG.md` | CREATE | Start the append-only execution log for the child task |
| `docs/tasks/PHASE1_GOVERNANCE_TASKS.md` | MODIFY | Register the new child task in the Phase-1 governance index |

---

## Stop Conditions

- **If the task begins modifying repository/filesystem boundary rules** -> STOP
- **If the task begins adding adversarial or corruption-focused test coverage** -> STOP
- **If the guarded path emits final proof without explicit evidence targeting** -> STOP
- **If the verifier cannot prove strong evidence fields are bound to real execution outputs** -> STOP
- **If the evidence claims adversarial completeness or final runtime integrity beyond proof emission** -> STOP

---

## Implementation Steps

### Step 1: Finalize explicit evidence targeting
**What:** `[ID tsk_p1_245_work_item_01]` Extend the guarded execution core so proof emission occurs only through an explicit evidence target.
**How:** Modify `scripts/audit/runtime_guarded_execution_core.sh` so final proof output is gated behind an explicit evidence path and is not silently produced on unrelated execution branches.
**Done when:** The execution core emits a proof artifact only when explicitly instructed to do so.

### Step 2: Finalize the proof payload contract
**What:** `[ID tsk_p1_245_work_item_02]` Define the bounded evidence payload fields for guarded runtime proof emission.
**How:** Ensure the emitted payload contains strong evidence fields, stable metadata, proof-binding results, and a scope statement tied to real execution outputs.
**Done when:** The evidence payload is structurally complete and bounded to proof-emission semantics.

### Step 3: Add the task-specific verifier
**What:** `[ID tsk_p1_245_work_item_03]` Create `scripts/audit/verify_tsk_p1_245.sh`.
**How:** Exercise the real evidence-emission path, reject incomplete or static payloads, and confirm a valid final proof artifact passes.
**Done when:** The verifier proves the evidence-finalization contract against the executable behavior and emits the declared evidence artifact.

### Step 4: Emit bounded evidence-finalization proof
**What:** `[ID tsk_p1_245_work_item_04]` Write `evidence/phase1/tsk_p1_245_evidence_finalization.json`.
**How:** Emit structured evidence including the finalized evidence path, contract-field list, proof-binding result, and a scope statement leaving adversarial coverage downstream.
**Done when:** The evidence file exists and proves only guarded evidence-finalization behavior.

---

## Verification

```bash
# [ID tsk_p1_245_work_item_01] [ID tsk_p1_245_work_item_02]
# [ID tsk_p1_245_work_item_03] [ID tsk_p1_245_work_item_04]
bash -lc 'test -x scripts/audit/verify_tsk_p1_245.sh && \
bash scripts/audit/verify_tsk_p1_245.sh > \
evidence/phase1/tsk_p1_245_evidence_finalization.json || exit 1'

# [ID tsk_p1_245_work_item_04]
bash -lc 'test -f evidence/phase1/tsk_p1_245_evidence_finalization.json && \
python3 scripts/audit/validate_evidence.py --task TSK-P1-245 --evidence \
evidence/phase1/tsk_p1_245_evidence_finalization.json || exit 1'

# [ID tsk_p1_245_work_item_01] [ID tsk_p1_245_work_item_02]
# [ID tsk_p1_245_work_item_03] [ID tsk_p1_245_work_item_04]
bash -lc 'test -x scripts/dev/pre_ci.sh && RUN_PHASE1_GATES=1 \
bash scripts/dev/pre_ci.sh || exit 1'
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_245_evidence_finalization.json`

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
- `finalized_evidence_path`
- `evidence_contract_fields`
- `proof_binding_result`
- `scope_boundary`

This evidence is bounded to proving deterministic guarded-runtime proof emission.
It does not prove adversarial or corruption-focused coverage.

---

## Rollback

If this task must be reverted:
1. Remove the `TSK-P1-245` task pack files and Phase-1 governance index entry.
2. Remove the evidence-finalization changes from the execution core.
3. Remove the task-specific verifier and finalization evidence artifact.
4. Reopen the runtime-integrity line at the execution-core or path-boundary checkpoint until a different evidence-finalization task is defined.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Guarded execution evidence finalization accepts incomplete or self-declared proof payloads | FAIL | Require strong evidence fields and verifier-backed rejection of incomplete payloads |
| Execution core silently emits final proof without explicit evidence targeting | FAIL | Gate proof output behind an explicit evidence path and verify the negative case |
| Verifier accepts evidence not derived from real execution outputs | FAIL | Exercise the real execution path and reject static or self-declared payloads |
| Evidence overclaims adversarial completeness or final runtime integrity beyond proof emission | FAIL | Bound the evidence contract to deterministic proof-emission semantics only |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
