# TSK-P2-PREAUTH-003-REM-03 PLAN — Append-only + temporal-binding triggers via migration 0133

Task: TSK-P2-PREAUTH-003-REM-03
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-003-REM-02
failure_signature: PHASE2.PREAUTH.EXECUTION_RECORDS.TRIGGERS_MISSING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
remediation_casefile: docs/plans/remediation/REM-2026-04-20_execution-truth-anchor/PLAN.md

---

## Objective

Install two BEFORE triggers on `public.execution_records` via forward migration 0133:
(1) **append-only trigger** `execution_records_append_only_trigger` that raises `SQLSTATE GF056` on any UPDATE or DELETE, mirroring the `project_boundaries_append_only` pattern at <ref_snippet file="/home/ubuntu/Symphony/schema/migrations/0127_project_boundaries.sql" lines="30-42" />.
(2) **temporal-binding trigger** `execution_records_temporal_binding_trigger` that raises `SQLSTATE GF058` on INSERT when the caller-supplied `interpretation_version_id` does not equal `resolve_interpretation_pack(NEW.project_id, NEW.execution_timestamp)`, delegating to the function at <ref_snippet file="/home/ubuntu/Symphony/schema/migrations/0116_create_interpretation_packs.sql" lines="60-81" />.

Both functions are `SECURITY DEFINER`, harden `search_path = pg_catalog, public`, and have EXECUTE revoked from PUBLIC. No edit to 0118/0131/0132.

---

## Architectural Context

Until this migration lands, `execution_records` rows are mutable and the `interpretation_version_id` column can be populated with any value (including the *currently active* pack rather than the pack that was active *at `execution_timestamp`*). The append-only gap makes the table unusable as a regulatory truth ledger; the temporal gap lets policy drift invalidate historical reproducibility. Both gaps are closed at the DB layer, not at the application layer, because application-layer enforcement is trivially bypassable by any role with `INSERT` or `UPDATE` privilege on the table.

Splitting the enforcement into two triggers with two functions preserves single-responsibility: each can be rolled back independently, each has a distinct `SQLSTATE`, each has its own negative test. A fused trigger is an explicit anti-pattern (`meta.anti_patterns`).

---

## Pre-conditions

- [ ] `TSK-P2-PREAUTH-003-REM-02` is `status=completed` and evidence validates.
- [ ] `schema/migrations/MIGRATION_HEAD` reads `0132`.
- [ ] Migration 0116 is applied (so `resolve_interpretation_pack` exists).
- [ ] At least one row in `public.interpretation_packs` exists for every `project_id` used in test INSERTs.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0133_execution_records_triggers.sql` | CREATE | Two functions + two triggers + revokes |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | 0132 -> 0133 |
| `scripts/db/verify_execution_records_triggers.sh` | CREATE | Inspects `pg_trigger`, `pg_proc.proconfig`, drives negatives |
| `scripts/db/tests/test_execution_records_append_only_negative.sh` | CREATE | N1 + N2 SQLSTATE GF056 |
| `scripts/db/tests/test_execution_records_temporal_binding_negative.sh` | CREATE | N3 SQLSTATE GF058 |
| `evidence/phase2/tsk_p2_preauth_003_rem_03.json` | CREATE | Evidence emitted by verifier |
| `tasks/TSK-P2-PREAUTH-003-REM-03/meta.yml` | MODIFY | Status progression |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-03/PLAN.md` | CREATE | This document |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-03/EXEC_LOG.md` | CREATE | Append-only record |

---

## Stop Conditions

- Append-only trigger attached as `AFTER` -> STOP.
- Either function missing `SECURITY DEFINER` or `SET search_path = pg_catalog, public` -> STOP.
- A single fused function handling both responsibilities -> STOP.
- EXECUTE not revoked from PUBLIC -> STOP.
- Negative tests not returning `GF056` / `GF058` -> STOP.
- Any ALTER targets 0118/0131/0132 -> STOP.
- Verifier missing `|| exit 1` on any check -> STOP.

---

## Implementation Steps

### Step 1: Author migration 0133

**What:** `[ID tsk_p2_preauth_003_rem_03_work_item_01]` Create `schema/migrations/0133_execution_records_triggers.sql` with the exact structure below (this is byte-level guidance — implementer must not drift):

```sql
-- Migration 0133: execution_records triggers (append-only + temporal binding)
-- Task: TSK-P2-PREAUTH-003-REM-03
-- Casefile: REM-2026-04-20_execution-truth-anchor

BEGIN;

-- Append-only enforcement (mirror of project_boundaries_append_only from 0127)
CREATE OR REPLACE FUNCTION public.execution_records_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'GF056: execution_records is append-only, UPDATE/DELETE not allowed'
        USING ERRCODE = 'GF056';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER execution_records_append_only_trigger
BEFORE UPDATE OR DELETE ON public.execution_records
FOR EACH ROW EXECUTE FUNCTION public.execution_records_append_only();

REVOKE ALL ON FUNCTION public.execution_records_append_only() FROM PUBLIC;

-- Temporal-binding enforcement (delegates to resolve_interpretation_pack from 0116)
CREATE OR REPLACE FUNCTION public.enforce_execution_interpretation_temporal_binding()
RETURNS TRIGGER AS $$
DECLARE
    v_expected UUID;
BEGIN
    SELECT public.resolve_interpretation_pack(NEW.project_id, NEW.execution_timestamp)
        INTO v_expected;

    IF v_expected IS DISTINCT FROM NEW.interpretation_version_id THEN
        RAISE EXCEPTION
            'GF058: execution_records.interpretation_version_id temporal mismatch; expected pack resolved at execution_timestamp'
            USING ERRCODE = 'GF058';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER execution_records_temporal_binding_trigger
BEFORE INSERT ON public.execution_records
FOR EACH ROW EXECUTE FUNCTION public.enforce_execution_interpretation_temporal_binding();

REVOKE ALL ON FUNCTION public.enforce_execution_interpretation_temporal_binding() FROM PUBLIC;

COMMIT;
```

Then advance `schema/migrations/MIGRATION_HEAD` to `0133`.

**Done when:** The migration file exists, both trigger names and both `SET search_path = pg_catalog, public` appear, and MIGRATION_HEAD reads `0133`.

### Step 2: Write the three negative tests (before the verifier)

**What:** `[ID tsk_p2_preauth_003_rem_03_work_item_02]` Create two helpers:

- `scripts/db/tests/test_execution_records_append_only_negative.sh`: two psql invocations wrapped in `BEGIN; ... ROLLBACK;`, each asserts `SQLSTATE = 'GF056'`. N1 runs `UPDATE public.execution_records SET status='x' WHERE execution_id IN (SELECT execution_id FROM public.execution_records LIMIT 1)`. N2 runs `DELETE FROM public.execution_records WHERE execution_id IN (SELECT execution_id FROM public.execution_records LIMIT 1)`.
- `scripts/db/tests/test_execution_records_temporal_binding_negative.sh`: N3 INSERTs with a deliberately wrong `interpretation_version_id` (e.g. `gen_random_uuid()` that will not match any pack) and asserts `SQLSTATE = 'GF058'`.

Each helper uses `psql --set ON_ERROR_STOP=off --echo-errors -v` and captures SQLSTATE via `\errverbose` or the `VERBOSITY` knob, then compares to the expected value with `|| exit 1`.

**Done when:** Each helper returns exit 0 against a 0133-applied database.

### Step 3: Author the triggers verifier

**What:** `[ID tsk_p2_preauth_003_rem_03_work_item_03]` Create `scripts/db/verify_execution_records_triggers.sh`. The verifier must:

1. Require `DATABASE_URL`; `|| exit 1`.
2. Query `pg_trigger` for `tgname IN ('execution_records_append_only_trigger','execution_records_temporal_binding_trigger')` and for each, decode `tgtype` to confirm BEFORE + ROW + the expected event mask (UPDATE|DELETE for the first; INSERT for the second).
3. Query `pg_proc.proconfig` for both function OIDs and confirm `search_path=pg_catalog, public` is present.
4. Query `pg_proc.prosecdef=true` for both.
5. Drive the three negative-test helpers and capture returned SQLSTATEs.
6. Compute SHA-256 of migration 0133 + both helpers + the verifier itself.
7. Emit `evidence/phase2/tsk_p2_preauth_003_rem_03.json` with `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`, `triggers_installed` (bool), `search_path_hardened` (bool), `negative_test_sqlstates` (array), `trigger_definer_functions` (two names).
8. `|| exit 1` on any assertion failure.

**Done when:** Verifier exits 0 on a well-formed database and evidence contains the required proof fields.

### Step 4: Run and capture evidence

**What:** `[ID tsk_p2_preauth_003_rem_03_work_item_03]` Execute verifier, confirm evidence JSON lands, confirm pre_ci.sh returns 0.

**Done when:** All verification commands exit 0.

---

## Verification

```bash
# [ID tsk_p2_preauth_003_rem_03_work_item_03] Run the triggers verifier and emit evidence.
test -x scripts/db/verify_execution_records_triggers.sh && bash scripts/db/verify_execution_records_triggers.sh > evidence/phase2/tsk_p2_preauth_003_rem_03.json || exit 1

# [ID tsk_p2_preauth_003_rem_03_work_item_01] Confirm migration 0133 exists and names both triggers.
test -f schema/migrations/0133_execution_records_triggers.sql && grep -q 'execution_records_append_only_trigger' schema/migrations/0133_execution_records_triggers.sql && grep -q 'execution_records_temporal_binding_trigger' schema/migrations/0133_execution_records_triggers.sql || exit 1

# [ID tsk_p2_preauth_003_rem_03_work_item_01] Confirm migration 0133 hardens search_path in SECURITY DEFINER function bodies.
test -f schema/migrations/0133_execution_records_triggers.sql && grep -q 'SET search_path = pg_catalog, public' schema/migrations/0133_execution_records_triggers.sql || exit 1

# [ID tsk_p2_preauth_003_rem_03_work_item_01] Confirm MIGRATION_HEAD advanced to 0133.
test -f schema/migrations/MIGRATION_HEAD && grep -Fxq '0133' schema/migrations/MIGRATION_HEAD || exit 1

# [ID tsk_p2_preauth_003_rem_03_work_item_02] Confirm both negative-test helpers exist.
test -x scripts/db/tests/test_execution_records_append_only_negative.sh && test -x scripts/db/tests/test_execution_records_temporal_binding_negative.sh || exit 1

# [ID tsk_p2_preauth_003_rem_03_work_item_03] Confirm evidence file carries the triggers_installed proof field.
test -f evidence/phase2/tsk_p2_preauth_003_rem_03.json && cat evidence/phase2/tsk_p2_preauth_003_rem_03.json | grep -q 'triggers_installed' || exit 1

# [ID tsk_p2_preauth_003_rem_03_work_item_01] [ID tsk_p2_preauth_003_rem_03_work_item_02] [ID tsk_p2_preauth_003_rem_03_work_item_03]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_preauth_003_rem_03.json`

Required fields:
- `task_id`: "TSK-P2-PREAUTH-003-REM-03"
- `git_sha`, `timestamp_utc`, `status`
- `checks`: array
- `observed_paths`: migration 0133 + both negative-test helpers + MIGRATION_HEAD
- `observed_hashes`: SHA-256 per path
- `command_outputs`: raw `pg_trigger` / `pg_proc` stdout + SQLSTATE captures from negative tests
- `execution_trace`: timestamps
- `triggers_installed`: true
- `search_path_hardened`: true
- `negative_test_sqlstates`: [ "GF056", "GF056", "GF058" ]
- `trigger_definer_functions`: [ "public.execution_records_append_only", "public.enforce_execution_interpretation_temporal_binding" ]

---

## Rollback

1. Author forward migration 0134+ that runs `DROP TRIGGER execution_records_append_only_trigger ON public.execution_records; DROP TRIGGER execution_records_temporal_binding_trigger ON public.execution_records; DROP FUNCTION public.execution_records_append_only(); DROP FUNCTION public.enforce_execution_interpretation_temporal_binding();`.
2. Advance MIGRATION_HEAD.
3. Flip INV-EXEC-TRUTH-001 to `in_progress` (REM-04 revert).
4. File exception in `docs/security/EXCEPTION_REGISTER.yml`.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Trigger attached AFTER instead of BEFORE | CRITICAL_FAIL | Stop condition + pg_trigger.tgtype bitmask verified |
| search_path not hardened | CRITICAL_FAIL | Stop condition + pg_proc.proconfig verified |
| EXECUTE on function granted to PUBLIC | FAIL | Migration contains explicit REVOKE, verifier could optionally extend |
| Temporal trigger uses wrong function | CRITICAL_FAIL | resolve_interpretation_pack is the only allowed delegate; verifier spot-checks via pg_proc.prosrc substring |

---

## Approval (regulated surface)

- [ ] `evidence/phase2/approvals/TSK-P2-PREAUTH-003-REM-03.json` present
- [ ] Approved by: `<approver_id>`
- [ ] Approval timestamp: `<ISO 8601>`
