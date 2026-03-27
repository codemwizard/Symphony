# TSK-P1-233 PLAN — Implement a report-only dependency truth validator so downstream tasks cannot proceed on socially assumed upstream completion

This plan builds the report-only dependency-truth gate that validates upstream proof and required outputs before downstream work is treated as ready.

Task: TSK-P1-233
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-232
failure_signature: PHASE1.RLS_WAVE2.TSK-P1-233.DEPENDENCY_THEATER
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create a report-only dependency truth validator that checks whether upstream dependencies are actually proven and whether required outputs exist before downstream readiness is assumed. Done means socially assumed dependency completion is surfaced through the shared gate result contract and valid dependency chains pass cleanly.

---

## Architectural Context

Once individual task-pack proof-integrity exists, the next anti-drift seam is the handoff between tasks. This task prevents downstream work from trusting dependency declarations socially by forcing dependency completion, evidence validity, and expected outputs into one explicit report-only dependency-truth check.

---

## Pre-conditions

- [ ] TSK-P1-232 is completed and its evidence validates.
- [ ] Upstream Pack B result-envelope semantics are available for reuse.
- [ ] No execution-authority work has started.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/task_dependency_truth_gate.py` | CREATE | Validate dependency proof and required outputs |
| `scripts/audit/verify_tsk_p1_233.sh` | CREATE | Verify invalid and valid dependency-chain behavior |
| `evidence/phase1/tsk_p1_233_dependency_truth.json` | CREATE | Persist dependency-truth verification evidence |
| `tasks/TSK-P1-233/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Define the dependency-truth boundary
**What:** Record what constitutes proven dependency completion and which dependency claims remain out of scope.
**How:** Capture proof-artifact requirements, output requirements, and gate-boundary exclusions in `EXEC_LOG.md` before coding.
**Done when:** The dependency-truth scope is explicit and bounded.

### Step 2: Implement the report-only dependency-truth gate
**What:** Create the gate and shared-envelope emission path.
**How:** Implement `scripts/audit/task_dependency_truth_gate.py` so unproven dependencies, missing outputs, and reimplementation patterns are surfaced through the shared gate result contract.
**Done when:** Socially assumed dependency completion becomes visible.

### Step 3: Write the negative tests BEFORE claiming acceptance
**What:** Implement `TSK-P1-233-N1` and `TSK-P1-233-N2` in the task-specific verifier.
**How:** Make `scripts/audit/verify_tsk_p1_233.sh` exercise dependency-complete-but-unproven and missing-output fixtures.
**Done when:** Invalid dependency chains fail truthfully in report-only mode.

### Step 4: Emit evidence
**What:** Run the verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_233.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-233 --evidence evidence/phase1/tsk_p1_233_dependency_truth.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records invalid and valid dependency-chain results.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_233.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-233 --evidence evidence/phase1/tsk_p1_233_dependency_truth.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
