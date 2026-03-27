# TSK-P1-228 PLAN — Harden the task creation process so anti-drift authoring rules become canonical repo policy

This plan updates the canonical task-creation process so anti-drift authoring discipline becomes repo policy rather than planning memory.

Task: TSK-P1-228
Owner: SUPERVISOR
Depends on: TSK-P1-227
failure_signature: PHASE1.RLS_WAVE2.TSK-P1-228.PROCESS_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Harden the task-creation process so anti-drift authoring rules become canonical repo policy. Done means the process document explicitly requires truthful anti-drift boundaries, honest proof language, and parity discipline, and a task-specific verifier can prove those rules are present.

---

## Architectural Context

A hardened template is necessary but insufficient if the canonical creation process still leaves critical authoring rules optional or implicit. This task closes that gap by making the task-creation workflow itself the authoritative source for anti-drift authoring discipline.

---

## Pre-conditions

- [ ] TSK-P1-227 is completed and its evidence validates.
- [ ] The current task-creation process document has been reviewed for insertion points.
- [ ] Later Wave 2 authoring/runtime gates have not started implementation.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/operations/TASK_CREATION_PROCESS.md` | MODIFY | Codify anti-drift authoring rules as canonical process policy |
| `scripts/audit/verify_tsk_p1_228.sh` | CREATE | Verify the required anti-drift process rules are present |
| `evidence/phase1/tsk_p1_228_process_hardening.json` | CREATE | Persist process-hardening verification evidence |
| `tasks/TSK-P1-228/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Enumerate the process rules that must become canonical
**What:** Record the anti-drift authoring rules that currently exist only in planning artifacts or review comments.
**How:** Capture the required process rules in `EXEC_LOG.md` before editing the process document.
**Done when:** The process-hardening scope is explicit and avoids runtime-gate spillover.

### Step 2: Harden the task-creation process
**What:** Amend `docs/operations/TASK_CREATION_PROCESS.md` with the required anti-drift rules.
**How:** Add one-primary-objective discipline, truthful proof-language requirements, parity expectations, and anti-placeholder requirements in the canonical process flow.
**Done when:** The process document can serve as the authoritative anti-drift authoring reference for future task creation.

### Step 3: Write the negative test BEFORE claiming acceptance
**What:** Implement `TSK-P1-228-N1` in the task-specific verifier.
**How:** Exercise a fixture excerpt missing key anti-drift rules and require rejection in `scripts/audit/verify_tsk_p1_228.sh`.
**Done when:** Process-policy gaps fail closed instead of remaining socially tolerated.

### Step 4: Emit evidence
**What:** Run the verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_228.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-228 --evidence evidence/phase1/tsk_p1_228_process_hardening.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records the required process rules.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_228.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-228 --evidence evidence/phase1/tsk_p1_228_process_hardening.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
