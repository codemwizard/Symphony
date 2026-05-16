# TSK-P3-CLEAN-004 PLAN — Reconcile Phase 3 opening posture with active execution envelope

Task: TSK-P3-CLEAN-004
Owner: ARCHITECT
Depends on: none
Blocked by: TSK-P3-CLEAN-001
failure_signature: PHASE3.STRICT.TSK-P3-CLEAN-004.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
surface_specific_plan: docs/PHASE3/implementation_plans/TSK-P3-CAP-000_governance_cleanup.md
doctrine_gap_status: ESCALATE-DOCTRINE

---

## Objective

Reconcile the conflict between docs/PHASE3/PHASE3_OPENING_ACT.md and the active
execution envelope (PHASE_EXECUTION_ENVELOPE.md). The conflict must be explicitly
resolved, deferred, or escalated. The root execution envelope remains the
controlling authority. No unauthorized Phase 3 executable status may be claimed.

---

## Pre-conditions

- [ ] TSK-P3-CLEAN-001 blocked_by gate is cleared.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/PHASE3/PHASE3_OPENING_ACT.md` | MODIFY | Add conflict-resolution section |
| `scripts/audit/verify_tsk_p3_clean_004.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_clean_004.json` | CREATE | Output artifact |
| `tasks/TSK-P3-CLEAN-004/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-CLEAN-004/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If the task attempts to update the root envelope without human authority** -> STOP
- **If the task claims Phase 3 executable status** -> STOP
- **If the conflict resolution is not explicitly recorded** -> STOP

---

## Implementation Steps

### Step 1: Document conflict
**What:** [ID tsk_p3_clean_004_work_01] Document the conflict between PHASE3_OPENING_ACT.md and PHASE_EXECUTION_ENVELOPE.md.
**Done when:** Conflict is explicitly described.

### Step 2: Record resolution
**What:** [ID tsk_p3_clean_004_work_02] Resolve, defer, or escalate with governance decision.
**Done when:** Outcome is recorded as RESOLVED, DEFERRED, or ESCALATED.

### Step 3: Confirm envelope authority
**What:** [ID tsk_p3_clean_004_work_03] Confirm root envelope remains controlling authority.
**Done when:** No executable-status claim is present.

### Step 4: Emit evidence
```bash
bash scripts/audit/verify_tsk_p3_clean_004.sh > evidence/phase3/tsk_p3_clean_004.json
```

---

## Verification

```bash
bash scripts/audit/verify_tsk_p3_clean_004.sh
bash scripts/dev/pre_ci.sh
```

---

## Evidence Contract

File: `evidence/phase3/tsk_p3_clean_004.json`

Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes
