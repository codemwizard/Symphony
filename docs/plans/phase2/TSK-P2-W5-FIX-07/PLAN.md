# TSK-P2-W5-FIX-07 PLAN — Add NOT NULL to state_current.current_state

Task: TSK-P2-W5-FIX-07
Owner: DB_FOUNDATION
Depends on: TSK-P2-W5-FIX-06
failure_signature: P2.W5-FIX.NULLABLE-STATE.CONSTRAINT_GAP
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Migration 0138 (line 10) created `current_state VARCHAR NOT NULL` — so this column
actually already has a NOT NULL constraint. This task must **verify** this is true in the
live DB and close the gap analysis finding with evidence. If the constraint is confirmed
present, the migration becomes a no-op verification-only task.

> **IMPORTANT:** Re-reading migration 0138 shows `current_state VARCHAR NOT NULL` on line
> 10. The gap analysis flagged this based on an earlier audit. This task will verify
> the constraint exists and produce evidence — if already correct, it produces a PASS
> evidence with `constraint_already_present: true`.

---

## Pre-conditions

- [ ] TSK-P2-W5-FIX-06 status=completed. MIGRATION_HEAD = 0150.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0151_verify_not_null_state_current.sql` | CREATE | Verification-only migration (assert NOT NULL exists, no-op if correct) |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Update to 0151 |
| `scripts/db/verify_tsk_p2_w5_fix_07.sh` | CREATE | Verify NOT NULL + rejection test |
| `evidence/phase2/tsk_p2_w5_fix_07.json` | CREATE | Evidence |
| Governance files | MODIFY | Steps 9-13 |

---

## Implementation Steps

### Step 1: Verify Current State
**What:** `[ID w5_fix_07_work_01]` Check is_nullable for current_state.
```sql
SELECT is_nullable FROM information_schema.columns
WHERE table_name = 'state_current' AND column_name = 'current_state';
-- Expected: 'NO' (already NOT NULL per migration 0138)
```

### Step 2: Write Migration
**What:** `[ID w5_fix_07_work_02]` Verification-only migration:
```sql
-- Assert NOT NULL constraint exists. If not, add it.
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'state_current'
               AND column_name = 'current_state'
               AND is_nullable = 'YES') THEN
        ALTER TABLE state_current ALTER COLUMN current_state SET NOT NULL;
    END IF;
END $$;
```

### Step 3-7: MIGRATION_HEAD, verification, governance, baseline, EXEC_LOG.

---

## Verification

```bash
psql "$DATABASE_URL" -tAc "SELECT is_nullable FROM information_schema.columns WHERE table_name = 'state_current' AND column_name = 'current_state'" | grep -q 'NO' || exit 1
bash scripts/db/verify_tsk_p2_w5_fix_07.sh || exit 1
test -f evidence/phase2/tsk_p2_w5_fix_07.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_07.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, not_null_verified, constraint_already_present, negative_test_results

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Gap was phantom (already NOT NULL) | No-op task | Evidence records constraint_already_present=true |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata exists
