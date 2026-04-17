# TSK-P2-CCG-001-00 PLAN — core contract gate

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

Task: TSK-P2-CCG-001-00
Owner: INVARIANTS_CURATOR
Depends on: TSK-P2-SEC-001-01, TSK-P2-SEC-002-01, TSK-P2-SEC-003-01, TSK-P2-SEC-004-01
failure_signature: PRE-PHASE2.CCG.CCG-001.FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective
core contract gate. This task ensures that the core contract gate is properly enforced and that INV-159/160/161/166 are promoted to implemented status. This task eliminates the risk of unverified contract gates being promoted without proper testing.

---

## Architectural Context
This task depends on TSK-P2-SEC-001-01, TSK-P2-SEC-002-01, TSK-P2-SEC-003-01, TSK-P2-SEC-004-01 and cannot start until all security invariant promotions are complete. This guards against the anti-pattern of promoting contract gates without verified security invariants. The task provides the actual implementation and verification of the core contract gate.

---

## Pre-conditions
- [ ] TSK-P2-SEC-001-01 and TSK-P2-SEC-002-01 and TSK-P2-SEC-003-01 and TSK-P2-SEC-004-01 are status=completed and evidence validates
- [ ] docs/operations/AI_AGENT_OPERATION_MANUAL.md has been read
- [ ] docs/operations/TASK_CREATION_PROCESS.md has been read
- [ ] docs/plans/phase2/ATOMIC_TASK_BREAKDOWN_PLAN.md has been read
- [ ] This PLAN.md has been reviewed and approved

---

## Files to Change
| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p2_ccg_CCG_001.sh` | CREATE/MODIFY | Verifier script for core contract gate |
| `docs/invariants/INVARIANTS_MANIFEST.yml` | MODIFY | Promote INV-159/160/161/166 to implemented |
| `tasks/TSK-P2-CCG-001-00/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions
- **If verifier script fails against the target implementation** -> STOP
- **If invariants cannot be promoted to implemented** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state** -> STOP

---

## Implementation Steps

### Step 1: Create verifier script
**What:** `[ID tsk_p2_ccg_001_00_work_item_01]` Create verifier script for core contract gate.
**How:** Create scripts/audit/verify_tsk_p2_ccg_CCG_001.sh with gate verification logic.
**Done when:** Verifier script exists and is executable.

### Step 2: Run verifier to confirm gate enforcement
**What:** `[ID tsk_p2_ccg_001_00_work_item_02]` Run verifier to confirm core contract gate is properly enforced.
**How:** Execute bash scripts/audit/verify_tsk_p2_ccg_CCG_001.sh
**Done when:** Verifier exits with code 0.

### Step 3: Promote invariants to implemented
**What:** `[ID tsk_p2_ccg_001_00_work_item_03]` Promote INV-159/160/161/166 to implemented status in INVARIANTS_MANIFEST.yml.
**How:** Update docs/invariants/INVARIANTS_MANIFEST.yml to set status: implemented for INV-159/160/161/166.
**Done when:** INVARIANTS_MANIFEST.yml shows all invariants as implemented.

---

## Verification

```bash
test -x scripts/audit/verify_tsk_p2_ccg_001_00.sh || exit 1

bash scripts/audit/verify_tsk_p2_ccg_001_00.sh || exit 1

for inv in INV-159 160 161 166; do
  grep -A5 "$inv" docs/invariants/INVARIANTS_MANIFEST.yml | grep "status: implemented" || exit 1
done
```

---

## Evidence Contract
File: `evidence/phase2/tsk_p2_ccg_001_00.json`

Required fields:
- `task_id`: "TSK-P2-CCG-001-00"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects
- `invariants_promoted`: "INV-159/160/161/166"
- `verifier_script`: "scripts/audit/verify_tsk_p2_ccg_CCG_001.sh"

---

## Rollback
If this task must be reverted:
1. Revert invariants status back to their previous state in INVARIANTS_MANIFEST.yml
2. Update status back to 'planned' in meta.yml
3. File exception in docs/security/EXCEPTION_REGISTER.yml with rationale and expiry.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Verifier script fails | FAIL | Verification checks exit code |
| Invariants cannot be promoted | BLOCKED | Manual review required |
| Anti-pattern: Promoting invariants without verification | FAIL_REVIEW | This plan requires verifier to pass before promotion |
