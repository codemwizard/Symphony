# TSK-P1-231 PLAN — Implement a report-only scope ceiling and objective-work-touches alignment gate so fake narrowness is surfaced before implementation begins

This plan builds the Pack B scope/alignment gate that detects both obvious breadth and hidden conceptual expansion.

Task: TSK-P1-231
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-227, TSK-P1-224, TSK-P1-229, TSK-P1-230
failure_signature: PHASE1.RLS_WAVE2.TSK-P1-231.FAKE_NARROWNESS
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create a report-only scope ceiling and objective-work-touches alignment gate that catches both oversized task packs and fake narrowness. Done means the gate emits alignment scoring and confidence through the shared result contract, honors heuristic limits on authority, and proves it can detect both obvious breadth and hidden conceptual drift.

---

## Architectural Context

Once authoring truthfulness exists, tasks can still drift by staying structurally valid while conceptually expanding. This task closes that gap by combining coarse scope checks with objective-work-touches alignment, while explicitly limiting heuristic authority through confidence-bounded escalation.

---

## Pre-conditions

- [ ] TSK-P1-227, TSK-P1-229, and TSK-P1-230 are completed and their evidence validates.
- [ ] TSK-P1-224 is completed and its shared result contract is available for reuse.
- [ ] No proof-integrity implementation has started.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/task_scope_gate.py` | CREATE | Detect scope ceiling violations and alignment drift |
| `scripts/audit/verify_tsk_p1_231.sh` | CREATE | Verify oversized, fake-narrowness, and valid fixture behavior |
| `evidence/phase1/tsk_p1_231_scope_alignment.json` | CREATE | Persist scope/alignment verification evidence |
| `tasks/TSK-P1-231/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Define the alignment boundary and heuristic limits
**What:** Record which scope signals are authoritative, which are heuristic, and how confidence limits escalation.
**How:** Capture alignment score semantics, severity thresholds, and gate-boundary exclusions in `EXEC_LOG.md` before coding.
**Done when:** The scope gate’s authority limits are explicit.

### Step 2: Implement the report-only scope/alignment gate
**What:** Create the gate and shared-envelope emission path.
**How:** Implement `scripts/audit/task_scope_gate.py` so touches breadth, verifier-family breadth, mixed surfaces, and objective-work-touches misalignment are surfaced through the shared gate result contract.
**Done when:** Obvious oversized tasks and fake narrowness both become visible.

### Step 3: Write the negative tests BEFORE claiming acceptance
**What:** Implement `TSK-P1-231-N1` and `TSK-P1-231-N2` in the task-specific verifier.
**How:** Make `scripts/audit/verify_tsk_p1_231.sh` exercise an oversized fixture and a structurally narrow but conceptually expanded fixture.
**Done when:** Both breadth drift and hidden drift are surfaced with confidence-bounded output.

### Step 4: Emit evidence
**What:** Run the verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_231.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-231 --evidence evidence/phase1/tsk_p1_231_scope_alignment.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records alignment scores, confidence, and severity behavior.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_231.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-231 --evidence evidence/phase1/tsk_p1_231_scope_alignment.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
