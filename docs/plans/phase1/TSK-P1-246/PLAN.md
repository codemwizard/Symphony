# TSK-P1-246 PLAN — Add the adversarial verifier suite for guarded runtime integrity so corrupted execution, path, and proof scenarios fail closed

This plan creates the adversarial verifier child task under the runtime-integrity
graph and limits scope to corruption-focused verification coverage.

Task: TSK-P1-246
Owner: QA_VERIFIER
Depends on: TSK-P1-244, TSK-P1-245
failure_signature: PHASE1.RUNTIME_INTEGRITY.TSK-P1-246.ADVERSARIAL_VERIFIER_SUITE
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Add the adversarial verifier suite for the guarded runtime path. Done means the
repo contains one hostile-input suite that exercises corrupted repo-root,
path-traversal, unauthorized-write, and malformed-proof scenarios against the
real guarded runtime path, a task-specific verifier fails closed if any hostile
case is accepted, and the emitted evidence stays bounded to hostile-case
rejection coverage.

---

## Architectural Context

TSK-P1-244 and TSK-P1-245 define the path-boundary and evidence-finalization
contracts, but neither task proves those contracts hold up under deliberately
hostile inputs. This final required child task exists to add that corruption-
focused verification layer without re-opening the implementation surfaces already
owned by the earlier children.

---

## Pre-conditions

- [x] TSK-P1-244 exists as the repository/filesystem integrity child task.
- [x] TSK-P1-245 exists as the evidence-finalization child task.
- [x] The guarded runtime line has distinct upstream contracts for path boundaries and proof emission.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/tests/test_tsk_p1_246_guarded_runtime_adversarial.sh` | CREATE | Exercise hostile runtime-integrity scenarios against the real guarded runtime path |
| `scripts/audit/verify_tsk_p1_246.sh` | CREATE | Run the adversarial suite and fail closed when any hostile case is accepted |
| `evidence/phase1/tsk_p1_246_adversarial_verifier_suite.json` | CREATE | Emit bounded evidence for hostile-case rejection coverage |
| `tasks/TSK-P1-246/meta.yml` | CREATE | Create the adversarial verifier child task contract |
| `docs/plans/phase1/TSK-P1-246/PLAN.md` | CREATE | Define the narrow adversarial verification scope and obligations |
| `docs/plans/phase1/TSK-P1-246/EXEC_LOG.md` | CREATE | Start the append-only execution log for the child task |
| `docs/tasks/PHASE1_GOVERNANCE_TASKS.md` | MODIFY | Register the new child task in the Phase-1 governance index |

---

## Stop Conditions

- **If the task begins modifying the execution-core implementation instead of testing it** -> STOP
- **If the task begins redefining repository/filesystem boundary rules or evidence-finalization semantics** -> STOP
- **If the verifier suite does not exercise real hostile inputs against the guarded runtime path** -> STOP
- **If the suite allows any hostile case to pass without failing closed** -> STOP
- **If the evidence claims broader runtime integrity than the hostile scenarios actually covered** -> STOP

---

## Implementation Steps

### Step 1: Create the hostile-input suite
**What:** `[ID tsk_p1_246_work_item_01]` Add `scripts/audit/tests/test_tsk_p1_246_guarded_runtime_adversarial.sh`.
**How:** Exercise hostile repo-root, path-traversal, unauthorized-write, and malformed-proof scenarios against the real guarded runtime path.
**Done when:** The suite covers the declared hostile cases without reimplementing the guarded runtime contracts.

### Step 2: Add the task-specific verifier
**What:** `[ID tsk_p1_246_work_item_02]` Create `scripts/audit/verify_tsk_p1_246.sh`.
**How:** Run the adversarial suite, capture hostile-case results, and fail closed if any corrupted scenario is accepted.
**Done when:** The verifier emits the declared evidence artifact only when every hostile case is rejected.

### Step 3: Prove cross-contract hostile coverage
**What:** `[ID tsk_p1_246_work_item_03]` Demonstrate hostile coverage across both path-boundary and proof-emission contracts.
**How:** Structure the suite so hostile cases map back to the TSK-P1-244 and TSK-P1-245 guarantees while keeping those implementation layers upstream.
**Done when:** The coverage scope is explicit and bounded to adversarial verification.

### Step 4: Emit bounded adversarial evidence
**What:** `[ID tsk_p1_246_work_item_04]` Write `evidence/phase1/tsk_p1_246_adversarial_verifier_suite.json`.
**How:** Emit structured evidence including hostile-case inventory, rejected-case results, coverage scope, and a bounded scope statement.
**Done when:** The evidence file exists and proves hostile-case rejection coverage only.

---

## Verification

```bash
# [ID tsk_p1_246_work_item_01] [ID tsk_p1_246_work_item_02]
# [ID tsk_p1_246_work_item_03] [ID tsk_p1_246_work_item_04]
bash -lc 'test -x scripts/audit/verify_tsk_p1_246.sh && \
bash scripts/audit/verify_tsk_p1_246.sh > \
evidence/phase1/tsk_p1_246_adversarial_verifier_suite.json || exit 1'

# [ID tsk_p1_246_work_item_04]
bash -lc 'test -f evidence/phase1/tsk_p1_246_adversarial_verifier_suite.json && \
python3 scripts/audit/validate_evidence.py --task TSK-P1-246 --evidence \
evidence/phase1/tsk_p1_246_adversarial_verifier_suite.json || exit 1'

# [ID tsk_p1_246_work_item_01] [ID tsk_p1_246_work_item_02]
# [ID tsk_p1_246_work_item_03] [ID tsk_p1_246_work_item_04]
bash -lc 'test -x scripts/dev/pre_ci.sh && RUN_PHASE1_GATES=1 \
bash scripts/dev/pre_ci.sh || exit 1'
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_246_adversarial_verifier_suite.json`

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
- `hostile_cases`
- `rejected_case_results`
- `coverage_scope`
- `scope_boundary`

This evidence is bounded to hostile-case rejection coverage against the guarded
runtime path. It does not prove broader runtime integrity beyond the exercised
suite.

---

## Rollback

If this task must be reverted:
1. Remove the `TSK-P1-246` task pack files and Phase-1 governance index entry.
2. Remove the adversarial test suite and task-specific verifier.
3. Remove the adversarial verifier evidence artifact.
4. Reopen the runtime-integrity line at the hostile-coverage checkpoint until a different adversarial suite is defined.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Adversarial suite allows hostile runtime-integrity scenarios to pass without failing closed | FAIL | Require the verifier to exit non-zero on any accepted hostile case |
| Verifier suite reimplements upstream contracts instead of exercising the real guarded runtime path | FAIL | Limit the suite to hostile-input execution against the upstream contract surfaces |
| Evidence overclaims broader runtime integrity than the hostile scenarios actually covered | FAIL | Bound the evidence contract to rejected hostile-case results only |
| Evidence file missing | FAIL | Require emitted evidence and validate it mechanically |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
