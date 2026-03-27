# TSK-P1-225 PLAN — Implement a report-only contract gate so that Wave 1 can reject invalid task packs through one runner path

This plan adds the first real report-only gate for Wave 1 so task-pack invalidity is surfaced early through the shared runner.

Task: TSK-P1-225
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-224
failure_signature: PHASE1.RLS_WAVE1.TSK-P1-225.CONTRACT_GATE_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Implement the report-only contract gate that validates basic task-pack integrity through the shared runner. Done means malformed or incomplete task packs fail through structured gate output, valid packs pass through the same path, and the task-specific verifier writes evidence for both cases.

---

## Architectural Context

This task is the first specialized gate in the Wave 1 spine. It must come after the runner/result contract so contract failures are emitted through one shared path, and before proof-blocker logic so invalid task packs are rejected before runtime blocker analysis even matters. This task prevents malformed task contracts from reaching deeper logic and prevents unstructured failure output from becoming normal.

---

## Pre-conditions

- [ ] TSK-P1-224 is completed and its evidence validates.
- [ ] The report-only runner path is available.
- [ ] The repaired parent task pack is usable as a valid test case.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/task_contract_gate.py` | CREATE | Implement the first report-only task contract gate |
| `scripts/audit/verify_tsk_p1_225.sh` | CREATE | Verify pass/fail task-pack handling through the contract gate |
| `evidence/phase1/tsk_p1_225_contract_gate.json` | CREATE | Persist contract-gate verification evidence |
| `tasks/TSK-P1-225/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Define the contract-gate checks
**What:** Record which task-pack failures this gate catches in Wave 1.
**How:** List the exact required-field and touch-path checks in `EXEC_LOG.md` before writing code.
**Done when:** The gate boundary is explicit and does not absorb full undeclared-file enforcement.

### Step 2: Implement report-only contract validation
**What:** Create the contract gate.
**How:** Implement `scripts/audit/task_contract_gate.py` so it runs through the shared runner and emits structured pass/fail output.
**Done when:** Valid task packs pass and malformed task packs fail with structured output.

### Step 3: Write the negative test BEFORE marking acceptance criteria done
**What:** Implement `TSK-P1-225-N1` in the task-specific verifier.
**How:** Make `scripts/audit/verify_tsk_p1_225.sh` corrupt a required field or touch-path reference and require gate failure.
**Done when:** The invalid case fails closed and the valid case passes through the runner.

### Step 4: Emit evidence
**What:** Run the contract-gate verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_225.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-225 --evidence evidence/phase1/tsk_p1_225_contract_gate.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records both valid and invalid gate cases.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_225.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-225 --evidence evidence/phase1/tsk_p1_225_contract_gate.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
