# TSK-P1-230 PLAN — Implement a report-only task-pack authoring gate so hollow or incomplete task contracts fail readiness truthfully

This plan builds the first Pack B authoring gate and its report-only to soft-block transition model.

Task: TSK-P1-230
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-227, TSK-P1-228, TSK-P1-229, TSK-P1-224
failure_signature: PHASE1.RLS_WAVE2.TSK-P1-230.AUTHORING_THEATER
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create a report-only authoring gate that surfaces hollow or incomplete task contracts through the shared gate result contract and establishes a concrete path from report-only to soft-block. Done means the gate checks hardened authoring truthfulness, emits one consistent envelope, and aggregates repeated weak signals instead of leaving them as isolated lint.

---

## Architectural Context

Template, process, and parity hardening only matter if the repo can actually inspect newly created task packs for hollow contracts before implementation begins. This task is the first Pack B gate, so it also becomes the first place where enforcement transition, drift-density escalation, and gate-boundary discipline have to be made real.

---

## Pre-conditions

- [ ] TSK-P1-227 through TSK-P1-229 are completed and their evidence validates.
- [ ] TSK-P1-224 is completed and the shared runner/result contract is stable enough for reuse.
- [ ] No later Pack B gate has started implementation.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/task_authoring_gate.py` | CREATE | Enforce hardened authoring truthfulness in report-only mode |
| `scripts/audit/verify_tsk_p1_230.sh` | CREATE | Verify hollow, escalation, and valid fixture behavior |
| `evidence/phase1/tsk_p1_230_authoring_gate.json` | CREATE | Persist authoring-gate verification evidence |
| `tasks/TSK-P1-230/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Define the authoring-gate boundary and transition model
**What:** Record the authoring checks owned by this gate and the checks it must not duplicate from parity or scope gates.
**How:** Capture detection scope, shared-result fields, promotion criteria, rollback conditions, and drift-density rules in `EXEC_LOG.md` before coding.
**Done when:** The gate boundary and transition model are explicit.

### Step 2: Implement the report-only authoring gate
**What:** Create the gate and shared-envelope emission path.
**How:** Implement `scripts/audit/task_authoring_gate.py` so hardened required sections, doc resolution, placeholder verification prose, evidence-contract completeness, and parity findings are surfaced through the shared gate result contract.
**Done when:** Hollow contracts fail truthfully in report-only mode.

### Step 3: Write the negative tests BEFORE claiming acceptance
**What:** Implement `TSK-P1-230-N1` and `TSK-P1-230-N2` in the task-specific verifier.
**How:** Make `scripts/audit/verify_tsk_p1_230.sh` exercise a hollow fixture and a repeated-warning fixture that proves drift-density escalation is real.
**Done when:** Hollow contracts and aggregated warning patterns are both surfaced deterministically.

### Step 4: Emit evidence
**What:** Run the verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_230.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-230 --evidence evidence/phase1/tsk_p1_230_authoring_gate.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records contract fields, transition data, and escalation behavior.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_230.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-230 --evidence evidence/phase1/tsk_p1_230_authoring_gate.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
