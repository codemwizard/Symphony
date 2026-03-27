# TSK-P1-226 PLAN — Implement proof-blocker detection and hard stop so that Wave 1 cannot fake progress when verification is not honest

This plan adds proof-blocker detection and hard-stop behavior to the Wave 1 verification spine.

Task: TSK-P1-226
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-224, TSK-P1-225
failure_signature: PHASE1.RLS_WAVE1.TSK-P1-226.PROOF_BLOCKED
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Implement the proof-blocker gate so Wave 1 stops when proof prerequisites are missing instead of continuing with plausible-looking output. Done means blocked paths emit `PROOF_BLOCKED`, downstream execution halts, the unblocked path still runs, and the task-specific verifier emits evidence describing both cases.

---

## Architectural Context

This task comes after the report-only runner and contract gate because stop behavior only matters once there is a shared execution path and a first gate already enforcing basic contract integrity. If proof-blocker handling is left advisory, later gates can produce fake progress and misleading evidence. This task prevents optimistic continuation, false confidence loops, and silent evidence pollution when proof is unavailable.

---

## Pre-conditions

- [ ] TSK-P1-224 is completed and its evidence validates.
- [ ] TSK-P1-225 is completed and its evidence validates.
- [ ] The shared runner path is available for blocked/unblocked test cases.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/task_proof_blocker_gate.py` | CREATE | Implement proof-blocker classification and stop behavior |
| `scripts/audit/verify_tsk_p1_226.sh` | CREATE | Verify blocked and unblocked proof-path behavior |
| `evidence/phase1/tsk_p1_226_proof_blocker.json` | CREATE | Persist proof-blocker verification evidence |
| `tasks/TSK-P1-226/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Define proof-blocker classes and stop boundary
**What:** Record which conditions count as proof blockers in Wave 1.
**How:** List the blocked prerequisites and explicit stop behavior in `EXEC_LOG.md` before coding.
**Done when:** The blocker classification boundary is explicit and does not drift into blocker repair.

### Step 2: Implement proof-blocker detection
**What:** Create the proof-blocker gate and runner stop behavior.
**How:** Implement `scripts/audit/task_proof_blocker_gate.py` so blocked paths emit `PROOF_BLOCKED` and halt downstream execution.
**Done when:** The runner stops the blocked path and still allows the unblocked report-only path to proceed.

### Step 3: Write the negative test BEFORE marking acceptance criteria done
**What:** Implement `TSK-P1-226-N1` in the task-specific verifier.
**How:** Make `scripts/audit/verify_tsk_p1_226.sh` simulate a missing proof prerequisite and require the runner to halt with `PROOF_BLOCKED`.
**Done when:** The blocked case fails closed and the unblocked case passes.

### Step 4: Emit evidence
**What:** Run the proof-blocker verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_226.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-226 --evidence evidence/phase1/tsk_p1_226_proof_blocker.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records both blocked and unblocked outcomes.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_226.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-226 --evidence evidence/phase1/tsk_p1_226_proof_blocker.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
