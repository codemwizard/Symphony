# TSK-P1-227 PLAN — Harden the canonical task template so all future task packs must declare anti-drift boundaries and proof limits

This plan hardens the canonical task meta template so anti-drift boundary fields become part of the default task contract rather than planning-only guidance.

Task: TSK-P1-227
Owner: SUPERVISOR
Depends on: TSK-P1-222
failure_signature: PHASE1.RLS_WAVE2.TSK-P1-227.TEMPLATE_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Harden the canonical task template so newly authored task packs must declare anti-drift boundaries and proof limits. Done means the shared template requires the hardened structural contract shape, fixture tasks that omit it fail the strict validation flow, and authors no longer need to reconstruct these fields from separate planning artifacts.

---

## Architectural Context

Wave 1 produced strong exemplar task packs, but exemplars are not enforcement. If the shared template remains permissive, future task authors can omit anti-drift boundaries while still claiming to follow the process. This task prevents structural drift at the authoring source by moving the anti-drift contract into the canonical template.

---

## Pre-conditions

- [ ] TSK-P1-222 is completed and its evidence validates.
- [ ] The current task template has been inspected for compatibility constraints.
- [ ] No later Wave 2 task pack implementation has started.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `tasks/_template/meta.yml` | MODIFY | Require hardened anti-drift boundary fields for future task packs |
| `scripts/audit/verify_tsk_p1_227.sh` | CREATE | Verify fixture rejection and template hardening behavior |
| `evidence/phase1/tsk_p1_227_template_hardening.json` | CREATE | Persist template-hardening verification evidence |
| `tasks/TSK-P1-227/meta.yml` | MODIFY | Update task state and actual verification record at completion |

---

## Implementation Steps

### Step 1: Define the hardened template boundary
**What:** Record which anti-drift sections must become required in the canonical template.
**How:** Capture the exact required structural fields and anti-pattern guidance in `EXEC_LOG.md` before editing the template.
**Done when:** The template hardening scope is explicit and does not overclaim semantic enforcement.

### Step 2: Harden the canonical template
**What:** Update `tasks/_template/meta.yml` to require the anti-drift contract shape.
**How:** Add or strengthen the template sections for anti-drift boundaries, proof guarantees, and proof limitations while keeping strict validation compatibility in view.
**Done when:** The template makes the hardened structural contract the default authoring shape.

### Step 3: Write the negative test BEFORE claiming acceptance
**What:** Implement `TSK-P1-227-N1` in the task-specific verifier.
**How:** Create a fixture task missing the hardened sections and require strict validation failure in `scripts/audit/verify_tsk_p1_227.sh`.
**Done when:** Omission of the hardened anti-drift sections fails closed.

### Step 4: Emit evidence
**What:** Run the verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_227.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-227 --evidence evidence/phase1/tsk_p1_227_template_hardening.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records required template fields and rejected fixture behavior.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_227.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-227 --evidence evidence/phase1/tsk_p1_227_template_hardening.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
