# TSK-P1-235 PLAN — Detect and classify non-canonical verification execution so bypass outputs are treated as non-authoritative

This plan builds the execution-authority gate that classifies bypass verification output as non-authoritative.

Task: TSK-P1-235
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-234
failure_signature: PHASE1.RLS_WAVE2.TSK-P1-235.BYPASS_AUTHORITY
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create a report-only execution-authority gate that detects and classifies non-canonical verification execution. Done means direct gate invocation and partial runner bypass are surfaced as non-authoritative through the shared gate result contract, while sanctioned `verify-task` flows remain distinct.

---

## Architectural Context

A canonical entrypoint is necessary, but it is not enough if bypass outputs can still be treated socially or mechanically as truth. This task closes that authority gap by classifying bypass execution explicitly so structured output alone is no longer mistaken for canonical proof.

---

## Pre-conditions

- [ ] TSK-P1-234 is completed and its evidence validates.
- [ ] The sanctioned `verify-task` contract is available for reuse.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/task_execution_authority_gate.py` | CREATE | Detect and classify non-canonical verification execution |
| `scripts/audit/verify_tsk_p1_235.sh` | CREATE | Verify canonical and bypass execution behavior |
| `evidence/phase1/tsk_p1_235_execution_authority.json` | CREATE | Persist execution-authority verification evidence |
| `tasks/TSK-P1-235/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Define the execution-authority boundary
**What:** Record which execution paths count as canonical and which are explicitly non-authoritative.
**How:** Capture canonical versus bypass execution classes in `EXEC_LOG.md` before coding.
**Done when:** The authority classification boundary is explicit.

### Step 2: Implement the execution-authority gate
**What:** Create the report-only authority-classification gate.
**How:** Implement `scripts/audit/task_execution_authority_gate.py` so direct gate invocation, partial runner bypass, and missing authority markers are surfaced through the shared gate result contract.
**Done when:** Bypass outputs can no longer masquerade as canonical verification truth.

### Step 3: Write the negative tests BEFORE claiming acceptance
**What:** Implement `TSK-P1-235-N1` and `TSK-P1-235-N2` in the task-specific verifier.
**How:** Make `scripts/audit/verify_tsk_p1_235.sh` exercise direct invocation and partial bypass fixtures alongside the canonical flow.
**Done when:** Non-canonical execution is distinguished deterministically.

### Step 4: Emit evidence
**What:** Run the verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_235.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-235 --evidence evidence/phase1/tsk_p1_235_execution_authority.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records direct invocation, partial bypass, and canonical flow results.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_235.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-235 --evidence evidence/phase1/tsk_p1_235_execution_authority.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
