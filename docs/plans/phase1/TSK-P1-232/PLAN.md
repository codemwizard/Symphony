# TSK-P1-232 PLAN — Implement a report-only proof-integrity gate so declared verification, acceptance criteria, evidence, and proof guarantees must align

This plan builds the Pack B proof-integrity gate that validates declared proof-chain alignment without performing semantic runtime analysis.

Task: TSK-P1-232
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-224, TSK-P1-225, TSK-P1-227, TSK-P1-230, TSK-P1-231
failure_signature: PHASE1.RLS_WAVE2.TSK-P1-232.PROOF_THEATER
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create a report-only proof-integrity gate that forces alignment between declared acceptance criteria, verifier declarations, evidence declarations, and proof guarantees while remaining strictly contract-level. Done means decorative proof is surfaced, orphan evidence is surfaced, overclaimed guarantees are surfaced, and the gate does not turn into semantic runtime analysis.

---

## Architectural Context

After authoring and scope alignment are visible, the next anti-drift failure is proof theater: contracts that look formal but prove little or nothing. This task closes that gap while explicitly refusing to become a semantic or runtime truth engine, because that would reintroduce hallucination risk inside the verifier layer itself.

---

## Pre-conditions

- [ ] TSK-P1-224 and TSK-P1-225 are completed and their evidence validates.
- [ ] TSK-P1-227, TSK-P1-230, and TSK-P1-231 are completed and their evidence validates.
- [ ] No dependency-truth implementation has started.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/task_proof_integrity_gate.py` | CREATE | Validate proof-chain contract alignment |
| `scripts/audit/verify_tsk_p1_232.sh` | CREATE | Verify decorative-verifier, orphan-evidence, and overclaimed-proof behavior |
| `evidence/phase1/tsk_p1_232_proof_integrity.json` | CREATE | Persist proof-integrity verification evidence |
| `tasks/TSK-P1-232/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Define the proof-integrity boundary
**What:** Record which proof relationships are in scope and which semantic/runtime claims are explicitly out of scope.
**How:** Capture hard scope constraints, proof-chain mapping rules, and upstream gate-consumption rules in `EXEC_LOG.md` before coding.
**Done when:** The gate boundary is explicit and contract-bounded.

### Step 2: Implement the report-only proof-integrity gate
**What:** Create the gate and shared-envelope emission path.
**How:** Implement `scripts/audit/task_proof_integrity_gate.py` so declared acceptance, verification, evidence, and proof guarantees are checked for alignment without semantic execution analysis.
**Done when:** Decorative proof and overclaimed proof become visible while the gate stays contract-bound.

### Step 3: Write the negative tests BEFORE claiming acceptance
**What:** Implement `TSK-P1-232-N1` through `TSK-P1-232-N3` in the task-specific verifier.
**How:** Make `scripts/audit/verify_tsk_p1_232.sh` exercise decorative-verifier, orphan-evidence, and overclaimed-proof fixtures.
**Done when:** Each proof-theater pattern is surfaced deterministically without runtime-analysis theater.

### Step 4: Emit evidence
**What:** Run the verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_232.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-232 --evidence evidence/phase1/tsk_p1_232_proof_integrity.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records proof-chain requirements, hard scope constraints, and fixture behavior.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_232.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-232 --evidence evidence/phase1/tsk_p1_232_proof_integrity.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
