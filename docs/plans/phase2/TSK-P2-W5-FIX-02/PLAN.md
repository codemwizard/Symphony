# TSK-P2-W5-FIX-02 PLAN — Add entity_type to state_rules for per-domain rule scoping

<!--
  PLAN.md RULES
  ─────────────
  1. This file must exist BEFORE status = 'in-progress' in meta.yml.
  2. Every section marked REQUIRED must be filled before any code is written.
  3. The EXEC_LOG.md is the append-only record of what actually happened.
  4. failure_signature must match the format used in verify_remediation_trace.sh.
  5. PROOF GRAPH INTEGRITY: Every work item, acceptance criterion, and verification
     command MUST be explicitly mapped using tracking IDs.
-->

Task: TSK-P2-W5-FIX-02
Owner: DB_FOUNDATION
Depends on: TSK-P2-W5-FIX-01
failure_signature: P2.W5-FIX.ENTITY-TYPE-MISSING.RUNTIME_CRASH
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

The `state_rules` table (migration 0135) lacks an `entity_type` column, but the
`enforce_transition_state_rules()` trigger (migration 0139, lines 14 and 24) queries
`WHERE entity_type = NEW.entity_type`. This causes a raw PostgreSQL runtime crash on
every INSERT to `state_transitions`. After this task closes: (a) `state_rules` has
`entity_type TEXT NOT NULL`, (b) the unique constraint includes `entity_type`, and
(c) the trigger resolves correctly with per-domain rule scoping — proven by a
two-domain isolation test in `evidence/phase2/tsk_p2_w5_fix_02.json`.

---

## Architectural Context

This is the second task in the Wave 5 stabilization chain. It depends on FIX-01 because
both tasks fix runtime crashes, and FIX-01's column fix must be applied first so that
the state machine has at least one functioning trigger before this task is tested.

**Design decision (Option A — approved by architect):** Add `entity_type` to `state_rules`
rather than removing the predicate from the trigger. Rationale:
- Wave 6 `derive_data_authority()` requires entity_type scoping
- Removing the predicate creates cross-domain rule leakage
- Replay determinism depends on domain-isolated rule resolution

Anti-patterns guarded against:
- **Removing predicate (Option B):** Destroys domain isolation, makes replay non-deterministic
- **Nullable entity_type:** Allows orphaned rules that bypass domain scoping
- **Editing migration 0135:** Forward-only mandate

---

## Pre-conditions

- [ ] TSK-P2-W5-FIX-01 is status=completed with passing evidence.
- [ ] Current branch is NOT `main`.
- [ ] `DATABASE_URL` is set to a live PostgreSQL instance with migration 0145 applied.
- [ ] MIGRATION_HEAD is currently `0145`.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0146_add_entity_type_to_state_rules.sql` | CREATE | Add entity_type column, update unique constraint |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Update from 0145 to 0146 |
| `scripts/db/verify_tsk_p2_w5_fix_02.sh` | CREATE | Behavioral verification with two-domain isolation test |
| `evidence/phase2/tsk_p2_w5_fix_02.json` | CREATE | Evidence artifact produced by verifier |
| `docs/plans/phase2/TSK-P2-W5-FIX-02/EXEC_LOG.md` | MODIFY | Append execution history |
| `tasks/TSK-P2-W5-FIX-02/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions

- **If entity_type is created as nullable** → STOP (destroys domain isolation guarantee)
- **If the unique constraint does not include entity_type** → STOP (allows duplicate rules)
- **If verifier does not execute two-domain isolation test** → STOP
- **If entity_type predicate is removed from trigger** → STOP (Option B explicitly rejected)
- **If existing rows exist and no deterministic backfill strategy** → STOP

---

## Implementation Steps

### Step 1: Reproduce the Bug
**What:** `[ID w5_fix_02_work_01]` Execute a live INSERT into `state_transitions` and capture the raw PostgreSQL error from the `state_rules` lookup.
**How:** After FIX-01 is applied, the `enforce_transition_authority` trigger will pass, but `enforce_transition_state_rules` will crash on the `state_rules` query.
**Done when:** EXEC_LOG.md contains exact error text `column "entity_type" does not exist`.

### Step 2: Write the Migration
**What:** `[ID w5_fix_02_work_02]` Create `schema/migrations/0146_add_entity_type_to_state_rules.sql`.
**How:** The migration must:
1. Check if existing rows exist — if so, require a deterministic backfill or abort:
   ```sql
   DO $$
   DECLARE row_count INTEGER;
   BEGIN
       SELECT COUNT(*) INTO row_count FROM state_rules;
       IF row_count > 0 THEN
           RAISE EXCEPTION 'PRECONDITION: % existing rows in state_rules require explicit backfill before adding NOT NULL entity_type', row_count;
       END IF;
   END $$;
   ```
2. Add column: `ALTER TABLE state_rules ADD COLUMN IF NOT EXISTS entity_type TEXT NOT NULL DEFAULT '__UNSET__';`
   (DEFAULT is for DDL only — the precondition ensures no rows use it)
3. Remove default after column creation: `ALTER TABLE state_rules ALTER COLUMN entity_type DROP DEFAULT;`
4. Drop old unique constraint and create new one including entity_type
5. Use idempotency guards (IF NOT EXISTS, DO blocks)

**Done when:** `\d state_rules` shows `entity_type` as `text not null` and the unique constraint includes it.

### Step 3: Update MIGRATION_HEAD
**What:** `[ID w5_fix_02_work_03]` Update MIGRATION_HEAD to 0146.
**How:** `echo 0146 > schema/migrations/MIGRATION_HEAD`
**Done when:** `cat schema/migrations/MIGRATION_HEAD` returns `0146`.

### Step 4: Write the Verification Script
**What:** `[ID w5_fix_02_work_04]` Create `scripts/db/verify_tsk_p2_w5_fix_02.sh` with two-domain isolation test.
**How:** The script must:
1. Verify column exists and is NOT NULL
2. Verify unique constraint includes entity_type
3. Seed rule: `entity_type='asset', from_state='PENDING', to_state='APPROVED'`
4. P1: INSERT `state_transitions` for `entity_type='asset'` PENDING→APPROVED → must pass rule check
5. N2: INSERT `state_transitions` for `entity_type='kyc'` PENDING→APPROVED → must fail with 'no rule defined'
6. All tests in transaction with ROLLBACK
7. Write evidence JSON

**Done when:** Script exits 0 with isolation proof in evidence.

### Step 5: Run Verification
**What:** `[ID w5_fix_02_work_05]` Execute verifier and produce evidence.
**How:** `bash scripts/db/verify_tsk_p2_w5_fix_02.sh`
**Done when:** Evidence JSON exists at declared path with all required fields.

### Step 6: Update EXEC_LOG.md
**What:** `[ID w5_fix_02_work_06]` Append remediation trace markers.
**How:** Update EXEC_LOG.md with verification_commands_run and final_status.
**Done when:** All 5 remediation trace markers present.

---

## Verification

```bash
# [ID w5_fix_02_work_02] Column exists and is NOT NULL
psql "$DATABASE_URL" -tAc "SELECT column_name FROM information_schema.columns WHERE table_name = 'state_rules' AND column_name = 'entity_type'" | grep -q 'entity_type' || exit 1
psql "$DATABASE_URL" -tAc "SELECT is_nullable FROM information_schema.columns WHERE table_name = 'state_rules' AND column_name = 'entity_type'" | grep -q 'NO' || exit 1

# [ID w5_fix_02_work_03] MIGRATION_HEAD updated
test "$(cat schema/migrations/MIGRATION_HEAD)" = '0146' || exit 1

# [ID w5_fix_02_work_04] [ID w5_fix_02_work_05] Full behavioral verification
bash scripts/db/verify_tsk_p2_w5_fix_02.sh || exit 1

# [ID w5_fix_02_work_05] Evidence exists
test -f evidence/phase2/tsk_p2_w5_fix_02.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_02.json`

Required fields:
- `task_id`: "TSK-P2-W5-FIX-02"
- `git_sha`: commit sha at time of evidence emission
- `timestamp_utc`: ISO 8601
- `status`: "PASS"
- `checks`: array of check objects
- `entity_type_column_verified`: boolean
- `unique_constraint_verified`: boolean
- `negative_test_results`: object with N1 (pre-fix crash proof) and N2 (two-domain isolation)
- `positive_test_results`: object with P1 (valid domain INSERT passes)
- `two_domain_isolation_proof`: object with domain_a_result, domain_b_result

---

## Rollback

If this task must be reverted:
1. Create migration that drops entity_type column and restores original unique constraint
2. Update MIGRATION_HEAD
3. Update task status back to 'ready' in meta.yml
4. File exception in docs/security/EXCEPTION_REGISTER.yml

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| entity_type created as nullable | Orphaned rules bypass domain scoping | NOT NULL constraint + precondition check |
| Existing rows without entity_type | Migration fails or corrupts data | Precondition abort if rows exist |
| Cross-domain rule leakage | Invalid transitions accepted silently | N2 two-domain isolation test |
| Old unique constraint remains | Duplicate rules per domain | Migration explicitly drops old constraint |
| Anti-pattern: Option B (remove predicate) | Replay non-determinism, Wave 6 incompatible | Stop condition in meta.yml |

---

## Anti-Drift Cheating Limits

After this task completes, the following attack surfaces remain open:
- **search_path injection**: Function lacks SECURITY DEFINER (FIX-04)
- **No SQLSTATE codes**: Rejection uses generic P0001 (FIX-08)
- **Trigger ordering**: Alphabetical firing (FIX-05)
- **Rule seeding**: No production rules exist — rules must be seeded per entity type

---

## Approval (for regulated surfaces)

- [ ] Approval metadata artifact exists (Stage A: pre-push, branch-linked)
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
