# TSK-P1-223 PLAN — Build a task metadata loader primitive so that Wave 1 verification can read task contracts deterministically

This plan builds the deterministic task metadata loader primitive that all later Wave 1 verification gates will consume.

Task: TSK-P1-223
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-222
failure_signature: PHASE1.RLS_WAVE1.TSK-P1-223.LOADER_DETERMINISM
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Implement a deterministic loader for task `meta.yml` files on governed audit surfaces. Done means later Wave 1 gates can rely on one shared loader instead of ad-hoc parsing, malformed metadata fails closed, and the task-specific verifier emits evidence describing deterministic loader behavior.

---

## Architectural Context

This task exists before the runner and gates because those later tasks need a single contract reader. If parsing is duplicated or informal, later failures become difficult to classify and proof-boundary logic becomes inconsistent. This task prevents hidden parser drift, silent field omission, and premature loading of enforcement logic into a primitive component.

---

## Pre-conditions

- [ ] TSK-P1-222 is completed and its evidence validates.
- [ ] The repaired parent RLS task pack is readable.
- [ ] `scripts/audit/` remains the governed implementation surface for Wave 1 primitives.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/task_meta_loader.py` | CREATE | Provide deterministic task metadata loading for later Wave 1 gates |
| `scripts/audit/verify_tsk_p1_223.sh` | CREATE | Verify loader determinism and fail-closed malformed-input handling |
| `evidence/phase1/tsk_p1_223_task_meta_loader.json` | CREATE | Persist loader verification evidence |
| `tasks/TSK-P1-223/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Define the minimal loader contract
**What:** Identify the exact task fields Wave 1 needs from metadata loading.
**How:** Review the repaired parent task pack and write the intended loader output shape in `EXEC_LOG.md` before implementing the parser.
**Done when:** The loader contract is listed and excludes runner or CI behavior.

### Step 2: Implement deterministic loading
**What:** Create the loader primitive.
**How:** Implement `scripts/audit/task_meta_loader.py` to parse task metadata deterministically and fail explicitly on malformed shape.
**Done when:** Valid metadata loads identically across repeated runs and malformed metadata exits non-zero.

### Step 3: Write the negative test BEFORE marking acceptance criteria done
**What:** Implement `TSK-P1-223-N1` in the task-specific verifier.
**How:** Make `scripts/audit/verify_tsk_p1_223.sh` feed malformed metadata into the loader and require explicit failure.
**Done when:** The malformed case fails closed and the valid case passes deterministically.

### Step 4: Emit evidence
**What:** Run the loader verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_223.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-223 --evidence evidence/phase1/tsk_p1_223_task_meta_loader.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file contains the declared loader fields.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_223.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-223 --evidence evidence/phase1/tsk_p1_223_task_meta_loader.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
