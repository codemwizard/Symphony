# TSK-P2-SEC-002-01 PLAN — Fix verifier scope and promote INV-131

<!--
  PLAN.md RULES
  ─────────────
  1. This file must exist BEFORE status = 'in-progress' in meta.yml.
  2. Every section marked REQUIRED must be filled before any code is written.
  3. The EXEC_LOG.md is the append-only record of what actually happened.
     Do not retroactively edit this PLAN.md to match the log.
  4. failure_signature must match the format used in verify_remediation_trace.sh.
  5. PROOF GRAPH INTEGRITY: Every work item, acceptance criterion, and verification command MUST be explicitly mapped using tracking IDs (e.g., `[ID <task_id>_work_item_01]`).
-->

Task: TSK-P2-SEC-002-01
Owner: SECURITY_GUARDIAN
Depends on: TSK-P2-SEC-002-00
failure_signature: PRE-PHASE2.SEC.INV131-IMPL.FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective
Fix the verifier scope for INV-131 and promote the invariant to implemented status. This task involves live service test to verify the invariant is properly enforced. This task eliminates the risk of unverified security invariants being promoted without proper testing.

---

## Architectural Context
This task depends on TSK-P2-SEC-002-00 (PLAN creation) and cannot start until the plan is verified. This guards against the anti-pattern of implementing without a verified plan. The task provides the actual implementation and verification of the security invariant.

---

## Pre-conditions
- [ ] TSK-P2-SEC-002-00 is status=completed and evidence validates
- [ ] docs/operations/AI_AGENT_OPERATION_MANUAL.md has been read
- [ ] docs/operations/TASK_CREATION_PROCESS.md has been read
- [ ] docs/plans/phase2/ATOMIC_TASK_BREAKDOWN_PLAN.md has been read
- [ ] This PLAN.md has been reviewed and approved

---

## Files to Change
| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p2_sec_SEC_002.sh` | CREATE/MODIFY | Verifier script for INV-131 |
| `docs/invariants/INVARIANTS_MANIFEST.yml` | MODIFY | Promote INV-131 to implemented |
| `tasks/TSK-P2-SEC-002-01/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions
- **If verifier script fails against the target implementation** -> STOP
- **If INV-131 cannot be promoted to implemented** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state** -> STOP

---

## Implementation Steps

### Step 1: Create or update verifier script
**What:** `[ID tsk_p2_sec_002_01_work_item_01]` Create or update the verifier script for INV-131.
**How:** Create scripts/audit/verify_tsk_p2_sec_SEC_002.sh with live service test logic.
**Done when:** Verifier script exists and is executable.

### Step 2: Run verifier to confirm invariant enforcement
**What:** `[ID tsk_p2_sec_002_01_work_item_02]` Run verifier to confirm INV-131 is properly enforced.
**How:** Execute bash scripts/audit/verify_tsk_p2_sec_SEC_002.sh
**Done when:** Verifier exits with code 0.

### Step 3: Promote invariant to implemented
**What:** `[ID tsk_p2_sec_002_01_work_item_03]` Promote INV-131 to implemented status in INVARIANTS_MANIFEST.yml.
**How:** Update docs/invariants/INVARIANTS_MANIFEST.yml to set status: implemented for INV-131.
**Done when:** INVARIANTS_MANIFEST.yml shows INV-131 as implemented.

---

## Verification

```bash
# [ID tsk_p2_sec_002_01_work_item_01]
test -x scripts/audit/verify_tsk_p2_sec_SEC_002.sh || exit 1

# [ID tsk_p2_sec_002_01_work_item_02]
bash scripts/audit/verify_tsk_p2_sec_SEC_002.sh || exit 1

# [ID tsk_p2_sec_002_01_work_item_03]
grep -A5 "INV-131" docs/invariants/INVARIANTS_MANIFEST.yml | grep "status: implemented" || exit 1
```

---

## Evidence Contract
File: `evidence/phase2/tsk_p2_sec_002_01.json`

Required fields:
- `task_id`: "TSK-P2-SEC-002-01"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects
- `invariant_id`: "INV-131"
- `invariant_status`: "implemented"
- `verifier_script`: "scripts/audit/verify_tsk_p2_sec_SEC_002.sh"

---

## Rollback
If this task must be reverted:
1. Revert INV-131 status back to its previous state in INVARIANTS_MANIFEST.yml
2. Update status back to 'planned' in meta.yml
3. File exception in docs/security/EXCEPTION_REGISTER.yml with rationale and expiry.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Verifier script fails | FAIL | Verification checks exit code |
| Invariant cannot be promoted | BLOCKED | Manual review required |
| Anti-pattern: Promoting invariant without verification | FAIL_REVIEW | This plan requires verifier to pass before promotion |
