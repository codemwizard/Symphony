# TSK-P2-PREAUTH-003-REM-02 PLAN — Tighten determinism columns via migration 0132 (contract phase)

Task: TSK-P2-PREAUTH-003-REM-02
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-003-REM-01
failure_signature: PHASE2.PREAUTH.EXECUTION_RECORDS.DETERMINISM_CONSTRAINTS_MISSING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
remediation_casefile: docs/plans/remediation/REM-2026-04-20_execution-truth-anchor/PLAN.md

---

## Objective

Tighten the four determinism columns added by REM-01 plus the legacy nullable `interpretation_version_id` into a determinism-enforcing shape: five `SET NOT NULL` statements and one `UNIQUE(input_hash, interpretation_version_id, runtime_version)` constraint, gated behind an idempotent backfill precondition. Forward migration 0132. Three negative SQLSTATE tests (23502 x2, 23505 x1) prove the enforcement is real. No edit to 0118 or 0131.

---

## Architectural Context

This is the contract half of the INV-097 expand/contract pair. Enforcement cannot coexist with the column addition migration because an `ALTER TABLE ADD COLUMN t TEXT NOT NULL` against a non-empty table with no default would abort, and an `ADD COLUMN t TEXT NOT NULL DEFAULT ''` would silently paper over missing data with a meaningless sentinel. The two-migration split gives a deterministic backfill checkpoint. `UNIQUE(execution_id)` is deliberately NOT added here because `execution_id` is already the PK of `execution_records` (line 7 of migration 0118); the UNIQUE on the hash tuple is the *determinism* claim, not a row-identity claim.

---

## Pre-conditions

- [ ] `TSK-P2-PREAUTH-003-REM-01` is `status=completed` and its evidence validates.
- [ ] `schema/migrations/MIGRATION_HEAD` reads `0131`.
- [ ] `DATABASE_URL` points at a database with 0001-0131 applied.
- [ ] Precondition query `SELECT COUNT(*) FROM public.execution_records WHERE input_hash IS NULL OR output_hash IS NULL OR runtime_version IS NULL OR tenant_id IS NULL OR interpretation_version_id IS NULL` returns 0.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/db/backfill_execution_records_determinism.sql` | CREATE | Idempotent precondition + (if needed) backfill body |
| `schema/migrations/0132_execution_records_determinism_constraints.sql` | CREATE | SET NOT NULL x5 + UNIQUE |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | 0131 -> 0132 |
| `scripts/db/verify_execution_records_determinism_constraints.sh` | CREATE | Inspects pg_attribute + pg_constraint + drives negative tests |
| `scripts/db/tests/test_execution_records_determinism_constraints_negative.sh` | CREATE | N1-N3 SQLSTATE assertions |
| `evidence/phase2/tsk_p2_preauth_003_rem_02.json` | CREATE | Evidence emitted by the verifier |
| `tasks/TSK-P2-PREAUTH-003-REM-02/meta.yml` | MODIFY | Status progression |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-02/PLAN.md` | CREATE | This document |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-02/EXEC_LOG.md` | CREATE | Append-only record |

---

## Stop Conditions

- **Precondition NULL-row count > 0 on a second attempt** -> STOP, two-strike DRD lockout, open REM-02b.
- **UNIQUE placed on `execution_id`** -> STOP (redundant with PK, drops determinism claim).
- **SET NOT NULL runs before backfill precondition passes** -> STOP.
- **Any ALTER targets 0118 or 0131** -> STOP.
- **Verifier lacks `|| exit 1` on any check** -> STOP.
- **FK target is anything other than `interpretation_packs(interpretation_pack_id)`** -> STOP.

---

## Implementation Steps

### Step 1: Author backfill script

**What:** `[ID tsk_p2_preauth_003_rem_02_work_item_01]` Create `scripts/db/backfill_execution_records_determinism.sql`. The script is idempotent: it first runs the precondition assertion (`DO $$ BEGIN IF (SELECT COUNT(*) ...) > 0 THEN RAISE EXCEPTION 'GF059: execution_records determinism backfill precondition failed - NULL rows present' USING ERRCODE = 'GF059'; END IF; END $$;`). `GF059` is the next unused code in the GF05x range: `GF050`/`GF051` are append-only triggers on the statutory/exchange ledgers (migrations 0123/0124), `GF055` is the append-only trigger on `protected_areas` + `project_boundaries` (0126/0127), `GF056` and `GF058` are reserved by REM-03 for the execution_records append-only and temporal-binding triggers, `GF057` is the DNSH trigger in migration 0129, and `GF060` is the K13 taxonomy trigger in migration 0130. Using `GF059` keeps backfill-precondition failures distinguishable from every existing and reserved SQLSTATE. If the precondition passes, the script is a no-op on row data. If it fails twice, DRD lockout forks to REM-02b.

**Done when:** `test -f scripts/db/backfill_execution_records_determinism.sql && grep -q 'precondition' scripts/db/backfill_execution_records_determinism.sql` exits 0.

### Step 2: Author migration 0132

**What:** `[ID tsk_p2_preauth_003_rem_02_work_item_02]` Create `schema/migrations/0132_execution_records_determinism_constraints.sql`:

```sql
-- Migration 0132: execution_records determinism constraints (contract phase)
-- Task: TSK-P2-PREAUTH-003-REM-02
-- Casefile: REM-2026-04-20_execution-truth-anchor
--
-- Do NOT add top-level BEGIN/COMMIT. scripts/db/migrate.sh wraps every
-- migration file in its own transaction (see migrate.sh:158-166).

\i scripts/db/backfill_execution_records_determinism.sql

ALTER TABLE public.execution_records ALTER COLUMN input_hash              SET NOT NULL;
ALTER TABLE public.execution_records ALTER COLUMN output_hash             SET NOT NULL;
ALTER TABLE public.execution_records ALTER COLUMN runtime_version         SET NOT NULL;
ALTER TABLE public.execution_records ALTER COLUMN tenant_id               SET NOT NULL;
ALTER TABLE public.execution_records ALTER COLUMN interpretation_version_id SET NOT NULL;

ALTER TABLE public.execution_records
  ADD CONSTRAINT execution_records_determinism_unique
  UNIQUE (input_hash, interpretation_version_id, runtime_version);
```

Then advance `schema/migrations/MIGRATION_HEAD` to `0132`.

**Done when:** The migration file exists, contains `SET NOT NULL` five times, contains `execution_records_determinism_unique`, and MIGRATION_HEAD reads `0132`.

### Step 3: Write negative tests before the verifier

**What:** `[ID tsk_p2_preauth_003_rem_02_work_item_03]` Create `scripts/db/tests/test_execution_records_determinism_constraints_negative.sh` that drives three `psql` `INSERT` statements into a disposable transaction (each `BEGIN ... ROLLBACK`):

- N1: INSERT with `input_hash = NULL`, assert `SQLSTATE = 23502`.
- N2: INSERT with `interpretation_version_id = NULL`, assert `SQLSTATE = 23502`.
- N3: INSERT twice with identical `(input_hash, interpretation_version_id, runtime_version)`, assert the second raises `SQLSTATE = 23505`.

Each assertion is a `|| exit 1` line against `psql --set ON_ERROR_STOP=off -v ...`.

**Done when:** The three SQLSTATE assertions each exit 0 against a 0132-applied database.

### Step 4: Author the constraints verifier

**What:** `[ID tsk_p2_preauth_003_rem_02_work_item_03]` Create `scripts/db/verify_execution_records_determinism_constraints.sh`. The verifier must:

1. Require `DATABASE_URL`; `|| exit 1`.
2. Query `pg_attribute` joined with `pg_class` filtered on `relname='execution_records'` to confirm `attnotnull=true` for each of the five columns.
3. Query `pg_constraint` for `conname='execution_records_determinism_unique'` with `contype='u'` and confirm its `conkey` maps to the three determinism columns by ordinal position.
4. Drive the three negative tests via the helper from Step 3 and capture returned SQLSTATEs.
5. Compute SHA-256 of migration 0132 and the verifier script.
6. Emit `evidence/phase2/tsk_p2_preauth_003_rem_02.json` with `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`, `not_null_enforced` (bool), `unique_enforced` (bool), `fk_not_null_enforced` (bool), `backfill_null_count` (int), `negative_test_sqlstates` (array of three strings).
7. `|| exit 1` on any assertion failure.

**Done when:** The verifier exits 0 on a well-formed database and the evidence JSON contains the nine required proof fields.

### Step 5: Run and capture evidence

**What:** `[ID tsk_p2_preauth_003_rem_02_work_item_03]` Execute the verifier, confirm evidence JSON lands, confirm `pre_ci.sh` picks it up.

**Done when:** The commands in the Verification section all exit 0.

---

## Verification

```bash
# [ID tsk_p2_preauth_003_rem_02_work_item_03] Run the verifier and emit evidence.
test -x scripts/db/verify_execution_records_determinism_constraints.sh && bash scripts/db/verify_execution_records_determinism_constraints.sh > evidence/phase2/tsk_p2_preauth_003_rem_02.json || exit 1

# [ID tsk_p2_preauth_003_rem_02_work_item_01] Confirm backfill script exists and references the precondition guard.
test -f scripts/db/backfill_execution_records_determinism.sql && grep -q 'precondition' scripts/db/backfill_execution_records_determinism.sql || exit 1

# [ID tsk_p2_preauth_003_rem_02_work_item_02] Confirm the 0132 migration file exists and carries SET NOT NULL and UNIQUE.
test -f schema/migrations/0132_execution_records_determinism_constraints.sql && grep -q 'SET NOT NULL' schema/migrations/0132_execution_records_determinism_constraints.sql && grep -q 'execution_records_determinism_unique' schema/migrations/0132_execution_records_determinism_constraints.sql || exit 1

# [ID tsk_p2_preauth_003_rem_02_work_item_02] Confirm MIGRATION_HEAD advanced to 0132.
test -f schema/migrations/MIGRATION_HEAD && grep -Fxq '0132' schema/migrations/MIGRATION_HEAD || exit 1

# [ID tsk_p2_preauth_003_rem_02_work_item_03] Confirm evidence file carries the determinism-enforced proof fields.
test -f evidence/phase2/tsk_p2_preauth_003_rem_02.json && cat evidence/phase2/tsk_p2_preauth_003_rem_02.json | grep -q 'unique_enforced' || exit 1

# [ID tsk_p2_preauth_003_rem_02_work_item_01] [ID tsk_p2_preauth_003_rem_02_work_item_02] [ID tsk_p2_preauth_003_rem_02_work_item_03]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_preauth_003_rem_02.json`

Required fields:
- `task_id`: "TSK-P2-PREAUTH-003-REM-02"
- `git_sha`, `timestamp_utc`, `status`: standard
- `checks`: array (NOT NULL x5, UNIQUE x1, FK NOT NULL x1, SQLSTATE x3)
- `observed_paths`: migration 0132 + backfill script + MIGRATION_HEAD
- `observed_hashes`: SHA-256 per path
- `command_outputs`: psql stdout per check
- `execution_trace`: timestamps per step
- `not_null_enforced`: true
- `unique_enforced`: true
- `fk_not_null_enforced`: true
- `backfill_null_count`: 0
- `negative_test_sqlstates`: [ "23502", "23502", "23505" ]

---

## Rollback

1. Author forward migration 0134+ containing `ALTER TABLE ... DROP CONSTRAINT execution_records_determinism_unique; ALTER TABLE ... ALTER COLUMN ... DROP NOT NULL;` x5 (in reverse order).
2. Advance MIGRATION_HEAD.
3. Flip INV-EXEC-TRUTH-001 to `in_progress` (REM-04 revert).
4. Re-open this task's meta.yml status to `ready`.
5. File exception in `docs/security/EXCEPTION_REGISTER.yml`.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Backfill runs on non-empty data with unknown hash provenance | FAIL | Precondition COUNT(*) > 0 aborts migration; REM-02b handles |
| UNIQUE placed on execution_id | FAIL | Stop condition + verifier checks `conkey` ordinals |
| SET NOT NULL on column that still has NULLs | CRITICAL_FAIL | Precondition guard inside migration |
| FK target drift | CRITICAL_FAIL | Verifier queries `pg_constraint.confrelid` |

---

## Approval (regulated surface)

- [ ] `evidence/phase2/approvals/TSK-P2-PREAUTH-003-REM-02.json` present
- [ ] Approved by: `<approver_id>`
- [ ] Approval timestamp: `<ISO 8601>`
