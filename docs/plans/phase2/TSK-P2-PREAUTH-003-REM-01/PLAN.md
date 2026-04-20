# TSK-P2-PREAUTH-003-REM-01 PLAN — Add nullable determinism columns via migration 0131 (expand phase)

Task: TSK-P2-PREAUTH-003-REM-01
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-003-02
failure_signature: PHASE2.PREAUTH.EXECUTION_RECORDS.DETERMINISM_COLUMNS_MISSING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
remediation_casefile: docs/plans/remediation/REM-2026-04-20_execution-truth-anchor/PLAN.md

---

## Objective

Migration 0118 created `public.execution_records` without any determinism columns. That makes replayability impossible (no `input_hash`/`output_hash`), tamper detection impossible (no `runtime_version`), and multi-tenant audit impossible (no `tenant_id`). This task closes that expand-phase gap by authoring forward migration `0131_execution_records_determinism_columns.sql`, which adds `input_hash TEXT`, `output_hash TEXT`, `runtime_version TEXT`, `tenant_id UUID` as NULLABLE, and advancing `schema/migrations/MIGRATION_HEAD` to `0131`. A verifier inspects the live schema via `information_schema.columns` and emits a proof-carrying evidence JSON. No edit to 0118 is permitted.

---

## Architectural Context

This task is one half of an expand/contract migration pair mandated by INV-097. Adding columns and immediately tightening them to NOT NULL in one migration would either corrupt existing rows or force a destructive delete. Expand-first (REM-01) then contract (REM-02) is the discipline that keeps forward-only migrations safe under partial rollouts. This task runs first because REM-02's constraints cannot exist without the columns, and REM-03's append-only trigger must come after both, so that the trigger is installed on a table whose shape is already finalised.

---

## Pre-conditions

- [ ] `TSK-P2-PREAUTH-003-02` is `status=completed` in its meta.yml (Wave 3 terminal task).
- [ ] `schema/migrations/MIGRATION_HEAD` currently reads `0130`.
- [ ] `DATABASE_URL` is set to a database where migrations 0001-0130 have been applied in order.
- [ ] This PLAN.md has been reviewed and approval metadata sidecar is staged at `evidence/phase2/approvals/TSK-P2-PREAUTH-003-REM-01.json`.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0131_execution_records_determinism_columns.sql` | CREATE | Forward migration adding four nullable determinism columns |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Advance from 0130 to 0131 |
| `scripts/db/verify_execution_records_determinism_columns.sh` | CREATE | Proof-carrying verifier that inspects live schema |
| `evidence/phase2/tsk_p2_preauth_003_rem_01.json` | CREATE | Evidence emitted by the verifier |
| `tasks/TSK-P2-PREAUTH-003-REM-01/meta.yml` | MODIFY | Status transitions planned -> ready -> in-progress -> completed |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-01/PLAN.md` | CREATE | This document |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-01/EXEC_LOG.md` | CREATE | Append-only execution record |

Any file modified that is not on this list => FAIL_REVIEW.

---

## Stop Conditions

- **If any ALTER statement targets `schema/migrations/0118_create_execution_records.sql`** -> STOP (violates forward-only hard constraint).
- **If the new migration adds any column as NOT NULL** -> STOP (belongs to REM-02's contract phase).
- **If MIGRATION_HEAD is not advanced** -> STOP (migration ordering gate will reject).
- **If the verifier lacks an `|| exit 1` failure path on every check** -> STOP.
- **If evidence is static or self-declared instead of derived from `information_schema`** -> STOP.
- **If ≥3 weak signals** -> STOP.

---

## Implementation Steps

### Step 1: Author migration 0131

**What:** `[ID tsk_p2_preauth_003_rem_01_work_item_01]` Create the new migration file with four idempotent `ADD COLUMN IF NOT EXISTS` statements on `public.execution_records`. Default values omitted. Comments reference this task id and the REM casefile id.

**How:**

```sql
-- Migration 0131: execution_records determinism columns (expand phase)
-- Task: TSK-P2-PREAUTH-003-REM-01
-- Casefile: REM-2026-04-20_execution-truth-anchor

BEGIN;

ALTER TABLE public.execution_records ADD COLUMN IF NOT EXISTS input_hash       TEXT;
ALTER TABLE public.execution_records ADD COLUMN IF NOT EXISTS output_hash      TEXT;
ALTER TABLE public.execution_records ADD COLUMN IF NOT EXISTS runtime_version  TEXT;
ALTER TABLE public.execution_records ADD COLUMN IF NOT EXISTS tenant_id        UUID;

COMMENT ON COLUMN public.execution_records.input_hash      IS 'Canonicalised input payload SHA-256. Tightened to NOT NULL by REM-02.';
COMMENT ON COLUMN public.execution_records.output_hash     IS 'Canonicalised output payload SHA-256. Tightened to NOT NULL by REM-02.';
COMMENT ON COLUMN public.execution_records.runtime_version IS 'Adapter runtime version string. Tightened to NOT NULL by REM-02.';
COMMENT ON COLUMN public.execution_records.tenant_id       IS 'Tenant scope for multi-tenant audit isolation. Tightened to NOT NULL by REM-02.';

COMMIT;
```

**Done when:** `test -f schema/migrations/0131_execution_records_determinism_columns.sql && grep -q 'execution_records' schema/migrations/0131_execution_records_determinism_columns.sql` exits 0.

### Step 2: Advance MIGRATION_HEAD

**What:** `[ID tsk_p2_preauth_003_rem_01_work_item_02]` Overwrite `schema/migrations/MIGRATION_HEAD` so its content is exactly the four characters `0131` (no trailing newline drift beyond repo convention — preserve whatever trailing-newline style 0130 used).

**How:** `printf '0131\n' > schema/migrations/MIGRATION_HEAD` (or match the existing trailing-byte format as verified by `xxd`).

**Done when:** `grep -Fxq '0131' schema/migrations/MIGRATION_HEAD` exits 0.

### Step 3: Write the negative tests (before the verifier)

**What:** `[ID tsk_p2_preauth_003_rem_01_work_item_03]` Before authoring the main verifier, write two negative-test shell helpers that drive a disposable test database: N1 drops three of four columns and asserts the verifier exits non-zero; N2 leaves MIGRATION_HEAD at 0130 and asserts the pre-CI migration-head gate rejects.

**How:** Store the helpers alongside the verifier (`scripts/db/tests/test_execution_records_determinism_columns_negative.sh`). They must drive the verifier as a subprocess and assert exit code.

**Done when:** N1 and N2 each exit 0 themselves while making the verifier exit non-zero.

### Step 4: Author the verifier

**What:** `[ID tsk_p2_preauth_003_rem_01_work_item_03]` Author `scripts/db/verify_execution_records_determinism_columns.sh`. The verifier must:

1. Require `DATABASE_URL` to be set; `|| exit 1` otherwise.
2. Execute `psql -qAt -c "SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='execution_records' AND column_name IN ('input_hash','output_hash','runtime_version','tenant_id');"` and assert all four names appear.
3. Read `schema/migrations/MIGRATION_HEAD` and assert it equals `0131`.
4. Compute SHA-256 of the migration file and the verifier script itself.
5. Emit JSON with fields: `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks` (array), `observed_paths` (migration file + MIGRATION_HEAD), `observed_hashes` (the two SHAs), `command_outputs` (raw psql stdout), `execution_trace` (timestamps per check), `columns_added` (list), `migration_head_value`.
6. Exit 1 on any assertion failure.

**How:** Use `bash -Eeuo pipefail` and emit JSON via `jq -n --arg …` for schema safety. Write to `evidence/phase2/tsk_p2_preauth_003_rem_01.json`.

**Done when:** `test -x scripts/db/verify_execution_records_determinism_columns.sh` exits 0 and N1+N2 exercises drive it to expected exit codes.

### Step 5: Emit evidence

**What:** `[ID tsk_p2_preauth_003_rem_01_work_item_03]` Run the verifier against a database with 0131 applied; confirm evidence JSON lands at the declared path with all required fields.

**How:**

```bash
test -x scripts/db/verify_execution_records_determinism_columns.sh && bash scripts/db/verify_execution_records_determinism_columns.sh > evidence/phase2/tsk_p2_preauth_003_rem_01.json || exit 1
test -f evidence/phase2/tsk_p2_preauth_003_rem_01.json && cat evidence/phase2/tsk_p2_preauth_003_rem_01.json | grep -q 'observed_hashes' || exit 1
```

**Done when:** The JSON file exists at `evidence/phase2/tsk_p2_preauth_003_rem_01.json` and contains the literal string `observed_hashes`.

---

## Verification

```bash
# [ID tsk_p2_preauth_003_rem_01_work_item_03] Run the verifier and emit evidence.
test -x scripts/db/verify_execution_records_determinism_columns.sh && bash scripts/db/verify_execution_records_determinism_columns.sh > evidence/phase2/tsk_p2_preauth_003_rem_01.json || exit 1

# [ID tsk_p2_preauth_003_rem_01_work_item_01] Confirm the 0131 migration file exists and touches execution_records.
test -f schema/migrations/0131_execution_records_determinism_columns.sql && grep -q 'execution_records' schema/migrations/0131_execution_records_determinism_columns.sql || exit 1

# [ID tsk_p2_preauth_003_rem_01_work_item_02] Confirm MIGRATION_HEAD advanced to 0131.
test -f schema/migrations/MIGRATION_HEAD && grep -Fxq '0131' schema/migrations/MIGRATION_HEAD || exit 1

# [ID tsk_p2_preauth_003_rem_01_work_item_03] Confirm evidence file contains the observed_hashes proof-carrying field.
test -f evidence/phase2/tsk_p2_preauth_003_rem_01.json && cat evidence/phase2/tsk_p2_preauth_003_rem_01.json | grep -q 'observed_hashes' || exit 1

# [ID tsk_p2_preauth_003_rem_01_work_item_01] [ID tsk_p2_preauth_003_rem_01_work_item_02] [ID tsk_p2_preauth_003_rem_01_work_item_03]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_preauth_003_rem_01.json`

Required fields:
- `task_id`: "TSK-P2-PREAUTH-003-REM-01"
- `git_sha`: commit SHA at emission time
- `timestamp_utc`: ISO 8601
- `status`: "PASS"
- `checks`: array of check objects, one per assertion; each carries `id`, `type`, `result`, `observed`, `expected`
- `observed_paths`: [ "schema/migrations/0131_execution_records_determinism_columns.sql", "schema/migrations/MIGRATION_HEAD" ]
- `observed_hashes`: SHA-256 of the two observed paths
- `command_outputs`: raw stdout of each psql/filesystem probe
- `execution_trace`: per-step start/end timestamps
- `columns_added`: [ "input_hash", "output_hash", "runtime_version", "tenant_id" ]
- `migration_head_value`: "0131"

---

## Rollback

If this task must be reverted:
1. Author migration 0134 (or higher) containing `ALTER TABLE public.execution_records DROP COLUMN IF EXISTS input_hash, output_hash, runtime_version, tenant_id;` only after confirming REM-02 and REM-03 have been reverted first.
2. Advance MIGRATION_HEAD to the rollback migration's number.
3. Set this task's `status` back to `ready` in `tasks/TSK-P2-PREAUTH-003-REM-01/meta.yml`.
4. File exception in `docs/security/EXCEPTION_REGISTER.yml` with rationale and expiry.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| ALTER accidentally targets 0118 | CRITICAL_FAIL | Stop condition + pre-commit grep gate `grep -L '0118_create_execution_records.sql' migration-diff` |
| Column accidentally added NOT NULL | FAIL | Stop condition + REM-02 negative test N2 catches this in CI |
| MIGRATION_HEAD not bumped | FAIL | Verification command grep-checks the file |
| Runtime DDL drift | CRITICAL_FAIL | Stop condition forbids; also guarded by existing DDL allowlist |

---

## Approval (regulated surface)

- [ ] Approval metadata artifact exists at: `evidence/phase2/approvals/TSK-P2-PREAUTH-003-REM-01.json`
- [ ] Approved by: `<approver_id>`
- [ ] Approval timestamp: `<ISO 8601>`
