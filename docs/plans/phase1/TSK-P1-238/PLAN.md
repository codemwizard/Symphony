# TSK-P1-238 PLAN — Repair execution-order authority drift so anti-hallucination task metadata, registry, and pickup guidance agree

This plan repairs the governance-layer order authority for `TSK-P1-222` through `TSK-P1-235` so future agents can determine the next valid task from repository state alone.

Task: TSK-P1-238
Owner: SUPERVISOR
Depends on: none
failure_signature: PHASE1.RLS_ORDERING.TSK-P1-238.AUTHORITY_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Repair execution-order authority drift between anti-hallucination task metadata, the governance index, and the pickup guide. Done means the actual `depends_on` graph no longer contradicts the documented canonical sequence, the downstream backlog in the pickup guide is deduplicated and unambiguous, and the primary Phase 1 task index points readers to the pickup authority artifact.

---

## Architectural Context

The anti-hallucination chain now has strong task packs, but a future agent can still follow the repo mechanically and start some tasks earlier than the documented order because `depends_on` and handoff guidance do not fully agree. This task exists to close that governance seam before later agents resume implementation work from the newly created pack set.

---

## Pre-conditions

- [ ] The standards-review report has been read and accepted as the basis for remediation.
- [ ] `TSK-P1-222` through `TSK-P1-235` remain in planned state and no implementation has started from the misaligned pickup model.
- [ ] `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md` and `docs/tasks/PHASE1_GOVERNANCE_TASKS.md` are readable.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `tasks/TSK-P1-227/meta.yml` | MODIFY | Align or explicitly clarify the Pack A start conditions with the canonical sequence |
| `tasks/TSK-P1-234/meta.yml` | MODIFY | Align or explicitly clarify the verify-task entrypoint task’s position in the canonical pickup model |
| `tasks/TSK-P1-235/meta.yml` | MODIFY | Keep execution-authority classification consistent with the repaired ordering model if needed |
| `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md` | MODIFY | Deduplicate downstream backlog items and make pickup authority mechanically clear |
| `docs/tasks/PHASE1_GOVERNANCE_TASKS.md` | MODIFY | Point the primary governance index to the pickup-guide artifact |
| `scripts/audit/verify_tsk_p1_238.sh` | CREATE | Fail closed when metadata order, handoff order, or index discoverability drift again |
| `evidence/phase1/tsk_p1_238_order_authority.json` | CREATE | Persist order-authority remediation evidence |
| `tasks/TSK-P1-238/meta.yml` | MODIFY | Update task state and verification record at completion |

---

## Implementation Steps

### Step 1: Reconcile the intended sequence with the actual dependency graph
**What:** Determine whether the chain should be fully linear or explicitly branch after shared prerequisites.
**How:** Compare `depends_on` in `TSK-P1-227`, `TSK-P1-234`, and `TSK-P1-235` with the pickup guide and record the intended authority model in `EXEC_LOG.md` before editing.
**Done when:** There is one explicit repository authority for when those tasks may start.

### Step 2: Repair metadata and handoff guidance together
**What:** Update the task metadata and pickup guide in one pass.
**How:** Change `depends_on` and ordering language together so the execution-order artifact no longer makes stronger claims than the metadata, and deduplicate downstream backlog items so each future work item has one meaning.
**Done when:** The metadata graph and pickup guide agree on the anti-hallucination chain and downstream backlog.

### Step 3: Restore discoverability from the main governance index
**What:** Make the pickup guide visible from the primary task registry.
**How:** Add a concise note or subsection in `docs/tasks/PHASE1_GOVERNANCE_TASKS.md` that directs future agents to `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md` for canonical anti-hallucination sequencing.
**Done when:** An agent starting at the main task index can discover the pickup-order artifact without chat history.

### Step 4: Write the negative tests BEFORE claiming acceptance
**What:** Implement `TSK-P1-238-N1` and `TSK-P1-238-N2` in the task-specific verifier.
**How:** Make `scripts/audit/verify_tsk_p1_238.sh` fail if metadata order and pickup order diverge, if the index reference is missing, or if duplicate downstream backlog aliases remain.
**Done when:** Governance-order drift is detected mechanically rather than socially.

### Step 5: Emit evidence
**What:** Run the verifier and validate evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_238.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-238 --evidence evidence/phase1/tsk_p1_238_order_authority.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
**Done when:** All commands exit 0 and the evidence file records corrected dependency edges, index-reference status, and backlog deduplication status.

---

## Verification

```bash
bash scripts/audit/verify_tsk_p1_238.sh
python3 scripts/audit/validate_evidence.py --task TSK-P1-238 --evidence evidence/phase1/tsk_p1_238_order_authority.json
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```
