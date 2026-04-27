# TSK-P2-W5-FIX-05 PLAN — Rename triggers for deterministic execution order

Task: TSK-P2-W5-FIX-05
Owner: DB_FOUNDATION
Depends on: TSK-P2-W5-FIX-04
failure_signature: P2.W5-FIX.TRIGGER-ORDER.NON_DETERMINISTIC
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

PostgreSQL fires same-event triggers in alphabetical order by name. Current trigger names
(`trg_enforce_*`, `trg_deny_*`, `trg_06_*`) fire in an order that does not match the
intended logical sequence. After this task, all BEFORE INSERT triggers use `bi_XX_` prefix
and the AFTER INSERT trigger uses `ai_01_`, guaranteeing deterministic execution order.

Current triggers on state_transitions (from migrations 0137-0144):
- BEFORE INSERT/UPDATE: `trg_enforce_state_transition_authority` (0137)
- BEFORE INSERT/UPDATE: `trg_upgrade_authority_on_execution_binding` (0137)
- BEFORE INSERT/UPDATE: `trg_enforce_transition_state_rules` (0139)
- BEFORE INSERT/UPDATE: `trg_enforce_transition_authority` (0140)
- BEFORE INSERT/UPDATE: `trg_enforce_transition_signature` (0141)
- BEFORE INSERT/UPDATE: `trg_enforce_execution_binding` (0142)
- BEFORE UPDATE/DELETE: `trg_deny_state_transitions_mutation` (0143)
- AFTER INSERT: `trg_06_update_current` (0144)

Target naming (BEFORE INSERT only, ordered by logical sequence):
1. `bi_01_enforce_transition_authority` — validate policy authority
2. `bi_02_enforce_execution_binding` — validate execution exists
3. `bi_03_enforce_transition_state_rules` — validate state rules
4. `bi_04_enforce_transition_signature` — validate signature
5. `bi_05_enforce_state_transition_authority` — validate data_authority transitions
6. `bi_06_upgrade_authority_on_execution_binding` — auto-upgrade authority
7. `bd_01_deny_state_transitions_mutation` — BEFORE DELETE/UPDATE deny
8. `ai_01_update_current_state` — AFTER INSERT update state_current

---

## Pre-conditions

- [ ] TSK-P2-W5-FIX-04 status=completed. MIGRATION_HEAD = 0148.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0149_rename_triggers_deterministic_order.sql` | CREATE | DROP + CREATE all triggers with prefixed names |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Update to 0149 |
| `scripts/db/verify_tsk_p2_w5_fix_05.sh` | CREATE | Verify trigger order |
| `evidence/phase2/tsk_p2_w5_fix_05.json` | CREATE | Evidence |
| Governance files | MODIFY | Steps 9-13 |

---

## Stop Conditions

- **Non-padded prefix (bi_1_ instead of bi_01_)** → STOP
- **Old trigger names still exist** → STOP
- **Function bodies changed** → STOP (trigger rename only, no function changes)

---

## Implementation Steps

### Step 1: Audit Current Order
**What:** `[ID w5_fix_05_work_01]` Record current alphabetical trigger order.
```sql
SELECT tgname, tgtype FROM pg_trigger
WHERE tgrelid = 'state_transitions'::regclass AND NOT tgisinternal
ORDER BY tgname;
```

### Step 2: Write Migration
**What:** `[ID w5_fix_05_work_02]` For each trigger: DROP TRIGGER old_name, CREATE TRIGGER new_name with same function and event.

### Step 3-8: MIGRATION_HEAD, verification, governance, baseline, evidence, EXEC_LOG.

---

## Verification

```bash
psql "$DATABASE_URL" -tAc "SELECT tgname FROM pg_trigger WHERE tgrelid = 'state_transitions'::regclass AND NOT tgisinternal ORDER BY tgname" | head -1 | grep -q 'ai_01\|bi_01' || exit 1
bash scripts/db/verify_tsk_p2_w5_fix_05.sh || exit 1
test -f evidence/phase2/tsk_p2_w5_fix_05.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_05.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, trigger_order_before, trigger_order_after, old_triggers_removed

---

## Rollback

1. Reverse rename migration (restore original trigger names)

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Old trigger names remain | Duplicate triggers fire | N1 negative test: old names absent |
| Wrong logical order | State machine behavior changes | Test INSERT lifecycle in FIX-13 |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata exists
