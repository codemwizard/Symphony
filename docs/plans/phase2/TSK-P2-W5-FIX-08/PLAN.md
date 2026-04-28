# TSK-P2-W5-FIX-08 PLAN — Add SQLSTATE codes to trigger RAISE EXCEPTION statements

Task: TSK-P2-W5-FIX-08
Owner: DB_FOUNDATION
Depends on: TSK-P2-W5-FIX-07
failure_signature: P2.W5-FIX.SQLSTATE.GENERIC_P0001
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

All RAISE EXCEPTION statements in Wave 5 triggers use the default SQLSTATE P0001. The
application layer cannot distinguish authority violations from state rule violations from
hash collisions without parsing message text. After this task, each exception uses a
GF-prefixed SQLSTATE code in PostgreSQL's user-definable range.

Proposed code assignments:
- `GF001` — Authority violation (enforce_transition_authority)
- `GF002` — State rule violation: no rule defined (enforce_transition_state_rules)
- `GF003` — State rule violation: transition not allowed (enforce_transition_state_rules)
- `GF004` — Signature missing (enforce_transition_signature)
- `GF005` — Hash missing (enforce_transition_signature)
- `GF006` — Execution binding missing (enforce_execution_binding)
- `GF007` — Execution binding invalid (enforce_execution_binding)
- `GF008` — Append-only violation (deny_state_transitions_mutation)
- `GF009` — Policy decision missing (enforce_transition_authority)

---

## Pre-conditions

- [ ] TSK-P2-W5-FIX-07 status=completed. MIGRATION_HEAD = 0151.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0152_add_sqlstate_codes_to_triggers.sql` | CREATE | CREATE OR REPLACE all functions with USING ERRCODE |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Update to 0152 |
| `scripts/db/verify_tsk_p2_w5_fix_08.sh` | CREATE | Trigger each exception, verify SQLSTATE |
| `evidence/phase2/tsk_p2_w5_fix_08.json` | CREATE | Evidence |
| Governance files | MODIFY | Steps 9-13 |

---

## Implementation Steps

### Step 1: Audit RAISE Statements
**What:** `[ID w5_fix_08_work_01]` Extract all RAISE EXCEPTION from pg_proc prosrc. Record each with default P0001.

### Step 2: Write Migration
**What:** `[ID w5_fix_08_work_02]` CREATE OR REPLACE each function with RAISE EXCEPTION ... USING ERRCODE = 'GFxxx'. Function bodies unchanged except for adding USING ERRCODE.

### Step 3-7: Standard governance sequence.

---

## Verification

```bash
# Trigger an authority violation, capture SQLSTATE
psql "$DATABASE_URL" -c "DO \$\$ BEGIN ... END \$\$;" 2>&1 | grep -q 'GF001' || exit 1
bash scripts/db/verify_tsk_p2_w5_fix_08.sh || exit 1
test -f evidence/phase2/tsk_p2_w5_fix_08.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_08.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, sqlstate_codes_verified, negative_test_results

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| GF codes collide with PG reserved | Unexpected behavior | GF is user-definable range |
| Message text changed | Downstream breakage | Code review: only add USING ERRCODE |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata exists
