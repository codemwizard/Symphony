# TSK-P3-PRE-001 PLAN — Reconcile Phase 2 Constitutional Status

Task: TSK-P3-PRE-001
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-PRE-001.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any migration or regulated file without prior approval metadata.
- Approval artifacts MUST be created BEFORE editing regulated surfaces.
- Stage A: Before editing (approvals/YYYY-MM-DD/BRANCH-<branch>.md and .approval.json)
- Stage B: After PR opening (approvals/YYYY-MM-DD/PR-<number>.md and .approval.json)
- Conformance check: `bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=<branch>`

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---
## Objective

Reconcile Phase 2 Constitutional Status. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p3_pre_001.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_pre_001_status_reconciliation.json` | CREATE | Output artifact |
| `tasks/TSK-P3-PRE-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-PRE-001/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_pre_001_w01] Read PHASE_CAPABILITY_LEGALITY_MATRIX.md §3.3 and identify all references to FORMALLY UNOPENED for Phase 2.
- [ID tsk_p3_pre_001_w02] Update §3.3 constitutional posture from FORMALLY UNOPENED to CLOSED with citation to approvals/2026-05-10/PHASE2_CLOSEOUT_APPROVAL.json and approvals/2026-05-03/PHASE2-RATIFICATION.md.
- [ID tsk_p3_pre_001_w03] Update PROHIB-05 (line 651-656) to reflect Phase 2 is now closed, not unopened.
- [ID tsk_p3_pre_001_w04] Update §3.4 (Phase 3 entry condition) to confirm Phase 2 closeout dependency is now satisfied.
- [ID tsk_p3_pre_001_w05] Verify no other section of the document contains stale Phase 2 status references.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_tsk_p3_pre_001.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p3_pre_001.sh > evidence/phase3/tsk_p3_pre_001_status_reconciliation.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_tsk_p3_pre_001.sh

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
