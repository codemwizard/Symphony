# TSK-P1-234 PLAN — Define the canonical verify-task entrypoint so task verification has one sanctioned execution shell

This plan defines the canonical `verify-task` entrypoint that future authority checks will treat as the sanctioned task-verification shell.

Task: TSK-P1-234
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-224
failure_signature: PHASE1.RLS_WAVE2.TSK-P1-234.ENTRYPOINT_AMBIGUITY
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Define a single canonical `verify-task` entrypoint for task verification. Done means humans and wrapper scripts have one sanctioned execution shell, later authority checks can judge canonical versus non-canonical invocation, and this task does not blur into bypass detection.

---

## Architectural Context

The runner spine exists, but a runner without one explicit sanctioned entrypoint still invites partial invocation and manual assembly. This task closes that ergonomics and authority gap by naming the shell-level contract before non-canonical path detection is added.

---

## Pre-conditions

- [ ] TSK-P1-224 is completed and its evidence validates.
- [ ] The current runner invocation contract has been reviewed.
- [ ] No non-canonical execution classification work has started.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_task.sh` | CREATE | Provide the sanctioned shell-level verification entrypoint |
| `scripts/audit/verify_tsk_p1_234.sh` | CREATE | Verify sanctioned entrypoint behavior |
| `evidence/phase1/tsk_p1_234_verify_task_entrypoint.json` | CREATE | Persist entrypoint verification evidence |
| `tasks/TSK-P1-234/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Define the sanctioned entrypoint contract
**What:** Record the exact shell-level invocation contract and what remains out of scope for this task.
**How:** Capture the canonical invocation path and exclusions in `EXEC_LOG.md` before coding.
**Done when:** Entrypoint definition is explicit and bounded.

### Step 2: Implement the canonical entrypoint
**What:** Create the sanctioned `verify-task` shell entrypoint.
**How:** Implement `scripts/audit/verify_task.sh` so it runs the sanctioned verification flow and produces a stable invocation contract.
**Done when:** Humans and wrappers have one explicit verification shell.

### Step 3: Write the negative test BEFORE claiming acceptance
**What:** Implement `TSK-P1-234-N1` in the task-specific verifier.
**How:** Make `scripts/audit/verify_tsk_p1_234.sh` contrast a bypass path with the sanctioned shell path without taking on full bypass-detection authority.
**Done when:** The sanctioned shell path is mechanically distinguishable.

### Step 4: Emit evidence
**What:** Run the verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_234.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-234 --evidence evidence/phase1/tsk_p1_234_verify_task_entrypoint.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records the sanctioned entrypoint contract.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_234.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-234 --evidence evidence/phase1/tsk_p1_234_verify_task_entrypoint.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
