# TSK-P1-229 PLAN — Implement a report-only parity verifier so task YAML and companion docs cannot silently diverge

This plan builds the report-only parity gate that aligns task YAML, companion docs, and index registration through one structured contract.

Task: TSK-P1-229
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-227, TSK-P1-228, TSK-P1-224
failure_signature: PHASE1.RLS_WAVE2.TSK-P1-229.PARITY_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create a report-only parity verifier that detects divergence between `meta.yml`, `PLAN.md`, `EXEC_LOG.md`, and index registration. Done means parity mismatches are surfaced deterministically through the shared gate result contract and aligned fixtures pass cleanly without ad hoc comparison output.

---

## Architectural Context

After template and process hardening, the next drift vector is divergence between machine-readable and human-readable task artifacts. This task prevents split-brain task contracts by turning parity into a first-class gate signal that later authoring and proof gates can consume.

---

## Pre-conditions

- [ ] TSK-P1-227 and TSK-P1-228 are completed and their evidence validates.
- [ ] TSK-P1-224 is completed and its shared result contract is available for reuse.
- [ ] No Pack B gate has started implementation.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/task_parity_gate.py` | CREATE | Compare YAML, plan/log docs, and index registration |
| `scripts/audit/verify_tsk_p1_229.sh` | CREATE | Verify mismatched and aligned parity behavior |
| `evidence/phase1/tsk_p1_229_task_parity.json` | CREATE | Persist parity verification evidence |
| `tasks/TSK-P1-229/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Define the parity boundary
**What:** Record exactly which task-pack contract sections must remain aligned.
**How:** Capture the compared fields and shared result-envelope requirements in `EXEC_LOG.md` before coding.
**Done when:** The parity scope is explicit and excludes unrelated semantic gate logic.

### Step 2: Implement the report-only parity gate
**What:** Create the parity gate and shared-envelope emission path.
**How:** Implement `scripts/audit/task_parity_gate.py` so mismatches across task YAML, plan/log docs, and index registration are emitted in the shared gate result contract.
**Done when:** Mismatch output is structured and aligned fixtures pass cleanly.

### Step 3: Write the negative test BEFORE claiming acceptance
**What:** Implement `TSK-P1-229-N1` in the task-specific verifier.
**How:** Make `scripts/audit/verify_tsk_p1_229.sh` exercise a fixture with mismatched verification/evidence declarations and require a structured mismatch result.
**Done when:** Parity drift fails visibly instead of surviving as silent divergence.

### Step 4: Emit evidence
**What:** Run the verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_229.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-229 --evidence evidence/phase1/tsk_p1_229_task_parity.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records shared contract fields and mismatch/aligned fixture results.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_229.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-229 --evidence evidence/phase1/tsk_p1_229_task_parity.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
