# TSK-P2-W5-FIX-06 PLAN — Change state_current FK to ON DELETE RESTRICT

Task: TSK-P2-W5-FIX-06
Owner: DB_FOUNDATION
Depends on: TSK-P2-W5-FIX-05
failure_signature: P2.W5-FIX.DELETE-CASCADE.APPEND_ONLY_VIOLATION
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Migration 0138 (line 14-15) created `fk_last_transition` on `state_current.last_transition_id`
with `ON DELETE CASCADE`. This means deleting a `state_transitions` row silently cascade-
deletes the current state — violating the append-only guarantee. After this task, the FK
uses `ON DELETE RESTRICT`, and the evidence proves DELETE rejection.

---

## Pre-conditions

- [ ] TSK-P2-W5-FIX-05 status=completed. MIGRATION_HEAD = 0149.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0150_fix_state_current_fk_restrict.sql` | CREATE | Drop CASCADE FK, add RESTRICT FK |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Update to 0150 |
| `scripts/db/verify_tsk_p2_w5_fix_06.sh` | CREATE | DELETE rejection test |
| `evidence/phase2/tsk_p2_w5_fix_06.json` | CREATE | Evidence |
| Governance files | MODIFY | Steps 9-13 |

---

## Implementation Steps

### Step 1: Verify CASCADE
**What:** `[ID w5_fix_06_work_01]` Confirm confdeltype='c' in pg_constraint.
```sql
SELECT confdeltype FROM pg_constraint WHERE conname = 'fk_last_transition';
-- Expected: 'c' (CASCADE)
```

### Step 2: Write Migration
**What:** `[ID w5_fix_06_work_02]`
```sql
ALTER TABLE state_current DROP CONSTRAINT fk_last_transition;
ALTER TABLE state_current ADD CONSTRAINT fk_last_transition
    FOREIGN KEY (last_transition_id)
    REFERENCES state_transitions(transition_id) ON DELETE RESTRICT;
```

### Step 3-8: MIGRATION_HEAD, verification, governance, baseline, evidence, EXEC_LOG.

---

## Verification

```bash
psql "$DATABASE_URL" -tAc "SELECT confdeltype FROM pg_constraint WHERE conname = 'fk_last_transition'" | grep -q 'r' || exit 1
bash scripts/db/verify_tsk_p2_w5_fix_06.sh || exit 1
test -f evidence/phase2/tsk_p2_w5_fix_06.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_06.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, fk_delete_policy_verified, negative_test_results

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| CASCADE remains | Silent audit loss | Verifier checks confdeltype |
| DELETE not tested | False PASS | N1 DELETE rejection test |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata exists
