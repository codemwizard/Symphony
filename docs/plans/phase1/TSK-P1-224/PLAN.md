# TSK-P1-224 PLAN — Build a report-only task verification runner and gate result contract so that Wave 1 has one orchestrated execution path

This plan builds the report-only runner skeleton and shared gate result contract that later Wave 1 gates will use.

Task: TSK-P1-224
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-223
failure_signature: PHASE1.RLS_WAVE1.TSK-P1-224.RUNNER_FRAGMENTATION
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create one report-only verification runner and one gate result contract for Wave 1. Done means later gates are added to one ordered execution path, malformed gate output is rejected early, and the runner emits a stable structured envelope without yet claiming CI authority or deep semantic coverage.

---

## Architectural Context

This task sits between the loader and specialized gates because the runner is the execution spine for the first wave. If the runner and result contract are weak, later gates fragment into ad-hoc invocations and proof-boundary enforcement becomes inconsistent. This task prevents execution-path drift, malformed gate propagation, and premature coupling to deeper semantics.

---

## Pre-conditions

- [ ] TSK-P1-223 is completed and its evidence validates.
- [ ] The loader primitive is available for reuse.
- [ ] No specialized gate task has started implementation.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/task_verification_runner.py` | CREATE | Provide one report-only verification entry point for Wave 1 |
| `scripts/audit/task_gate_result.py` | CREATE | Define the shared gate-result schema and validation behavior |
| `scripts/audit/verify_tsk_p1_224.sh` | CREATE | Verify dry-run runner execution and malformed gate-result rejection |
| `evidence/phase1/tsk_p1_224_runner_contract.json` | CREATE | Persist runner/gate-contract verification evidence |
| `tasks/TSK-P1-224/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Define the runner and result contract boundary
**What:** Record exactly what belongs in the report-only runner and what belongs in later gates.
**How:** List the ordered gate-execution flow and required gate-result fields in `EXEC_LOG.md` before coding.
**Done when:** The runner contract is explicit and excludes CI authority or deep semantic gate logic.

### Step 2: Implement the report-only runner and result contract
**What:** Create the runner skeleton and result-shape enforcement.
**How:** Implement `scripts/audit/task_verification_runner.py` and `scripts/audit/task_gate_result.py` so dry-run gate execution flows through one structured path.
**Done when:** Dry-run execution works and malformed gate results are rejected.

### Step 3: Write the negative test BEFORE marking acceptance criteria done
**What:** Implement `TSK-P1-224-N1` in the task-specific verifier.
**How:** Make `scripts/audit/verify_tsk_p1_224.sh` exercise an incomplete gate result and require non-zero failure.
**Done when:** The malformed gate case fails closed while the valid dry-run path passes.

### Step 4: Emit evidence
**What:** Run the runner verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_224.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-224 --evidence evidence/phase1/tsk_p1_224_runner_contract.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records runner-entrypoint and gate-result contract details.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_224.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-224 --evidence evidence/phase1/tsk_p1_224_runner_contract.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
