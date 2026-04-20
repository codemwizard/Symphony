# TSK-P2-PREAUTH-004-01 PLAN — Create policy_decisions table (migration 0134) as the Wave 4 cryptographic truth anchor row type

Task: TSK-P2-PREAUTH-004-01
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-004-00
Blocks: TSK-P2-PREAUTH-004-03
failure_signature: PHASE2.PREAUTH.POLICY_DECISIONS.SCHEMA_MISSING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
wave_reference: Wave 4 — Authority Binding
origin_task_id: TSK-P2-PREAUTH-004-01
repro_command: bash scripts/db/verify_policy_decisions_schema.sh
verification_commands_run: bash scripts/db/verify_policy_decisions_schema.sh
final_status: PLANNED

---

## Objective

Materialise the `policy_decisions` table exactly as the Wave 4 contract (`docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md`, sections *Cryptographic Contract* and *policy_decisions Schema*) pins it. The row is the Wave 4 cryptographic truth-anchor row type: append-only, FK-bound to `execution_records`, entity-bound via `(entity_type, entity_id)`, and committed by `decision_hash = sha256(canonical_json(decision_payload))` plus `signature = ed25519_sign(decision_hash, private_key)`. Migration 0134 expands the schema by exactly one table; no contract phase is required because every column lands `NOT NULL` in this migration (no backfill is possible — the table is created empty) and the append-only trigger ships in the same file so ledger semantics exist from row zero.

This task does not register the authority-transition binding invariant, does not verify signature authenticity, and does not create `state_rules`. Those are 004-03, a later wave, and 004-02 respectively.

---

## Architectural Context

`policy_decisions` is the Wave 4 analogue of Wave 3's `execution_records`. The two tables form a 1:many relationship (an execution can have multiple distinct decisions of different `decision_type`s but at most one of each type), bound by `execution_id`. The contract split across 004-00 (spec), this task (row type), 004-02 (rule type), and 004-03 (binding invariant) is deliberate: the row type can be exercised by inserts in isolation, but the authority anchor is real only when the binding invariant ties the row to an `execution_records` transition.

The three audit fixes from Wave-4-for-Devin.md land in this task as follows:

1. **Cryptographic binding.** `decision_hash TEXT NOT NULL CHECK (decision_hash ~ '^[0-9a-f]{64}$')` pins the column to a 64-character lowercase hex string, which is the exact output shape of `sha256(canonical_json(decision_payload))`. `signature TEXT NOT NULL CHECK (signature ~ '^[0-9a-f]{128}$')` pins the Ed25519 signature to 128-character lowercase hex (64 raw bytes hex-encoded). The regex is load-bearing: it makes it impossible to land a decision row with a malformed hash or signature, closing the "field exists but means nothing" defect the original Wave 4 draft had.

2. **Entity context.** `entity_type TEXT NOT NULL` and `entity_id UUID NOT NULL` land with the full row. Cross-entity replay is blocked by these columns plus 004-03's binding verifier (which asserts the columns match the canonical-JSON payload). Indexing `(entity_type, entity_id)` keeps entity-scoped audits cheap.

3. **Rule priority.** Not in scope of this task. Lives in 004-02 on `state_rules`.

---

## Pre-conditions

- [ ] `TSK-P2-PREAUTH-004-00` is `status=completed` or equivalently merged, with `docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md` on main.
- [ ] `schema/migrations/MIGRATION_HEAD` reads `0133` at the start of this task (migrations 0131-0133 from Wave 3 are applied).
- [ ] `public.execution_records` exists with a `PRIMARY KEY` on `execution_id` (Wave 3 delivered this).
- [ ] No prior migration creates or references `public.policy_decisions`.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0134_policy_decisions.sql` | CREATE | Materialise the table, constraints, indexes, and append-only trigger. |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Advance head from `0133` to `0134`. |
| `scripts/db/verify_policy_decisions_schema.sh` | CREATE | DB-shape verifier that proves the 11 columns, the constraints, the indexes, and the trigger are present; emits evidence JSON. |
| `scripts/db/tests/test_policy_decisions_negative.sh` | CREATE | Negative-test harness that proves each of the five contracted rejection paths fires. |
| `evidence/phase2/tsk_p2_preauth_004_01.json` | CREATE | Emitted by the verifier; not hand-authored. |
| `tasks/TSK-P2-PREAUTH-004-01/meta.yml` | MODIFY | Populate full meta per Task Creation Process §2 Step 4 to match this PLAN. |
| `docs/plans/phase2/TSK-P2-PREAUTH-004-01/PLAN.md` | CREATE/REWRITE | This document. |
| `docs/plans/phase2/TSK-P2-PREAUTH-004-01/EXEC_LOG.md` | MODIFY | Log the task authorship action during CREATE-TASK; implementation run will append on IMPLEMENT-TASK. |

Any file modified that is not on this list => FAIL_REVIEW.

---

## Stop Conditions

- **If any ALTER TABLE statement targets an applied migration (0001-0133)** → STOP (AGENTS.md forward-only hard constraint).
- **If migration 0134 omits any of the 11 contracted columns, or makes `entity_type` / `entity_id` nullable** → STOP (cross-entity replay remains open).
- **If `decision_hash` column lacks `CHECK (decision_hash ~ '^[0-9a-f]{64}$')` or `signature` lacks `CHECK (signature ~ '^[0-9a-f]{128}$')`** → STOP (crypto contract is not enforceable by SQL alone).
- **If `UNIQUE (execution_id, decision_type)` is missing** → STOP (duplicate decisions of the same type per execution would break the rule-selection contract).
- **If `enforce_policy_decisions_append_only` trigger is missing or does not block `UPDATE` and `DELETE`** → STOP (ledger mutability).
- **If `MIGRATION_HEAD` is not advanced to `0134`** → STOP (migration-ordering gate fails).
- **If runtime DDL is introduced in `src/` or `packages/`** → STOP (AGENTS.md hard constraint).
- **If any of the five contracted negative tests is omitted from the harness** → STOP.

---

## Schema Specification (authoritative for migration 0134)

```
CREATE TABLE public.policy_decisions (
  policy_decision_id  UUID        NOT NULL PRIMARY KEY,
  execution_id        UUID        NOT NULL REFERENCES public.execution_records(execution_id),
  decision_type       TEXT        NOT NULL,
  authority_scope     TEXT        NOT NULL,
  declared_by         UUID        NOT NULL,
  entity_type         TEXT        NOT NULL,
  entity_id           UUID        NOT NULL,
  decision_hash       TEXT        NOT NULL CHECK (decision_hash ~ '^[0-9a-f]{64}$'),
  signature           TEXT        NOT NULL CHECK (signature ~ '^[0-9a-f]{128}$'),
  signed_at           TIMESTAMPTZ NOT NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (execution_id, decision_type)
);

CREATE INDEX idx_policy_decisions_entity      ON public.policy_decisions (entity_type, entity_id);
CREATE INDEX idx_policy_decisions_declared_by ON public.policy_decisions (declared_by);
```

Append-only trigger (same migration file):

```
CREATE OR REPLACE FUNCTION public.enforce_policy_decisions_append_only()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION USING
    ERRCODE = '23514',
    MESSAGE = 'policy_decisions is append-only';
END;
$$;

CREATE TRIGGER enforce_policy_decisions_append_only
BEFORE UPDATE OR DELETE ON public.policy_decisions
FOR EACH ROW EXECUTE FUNCTION public.enforce_policy_decisions_append_only();
```

SECURITY DEFINER is not required on the trigger function because it only raises; it does not read or write any other table. If a later wave needs SECURITY DEFINER hardening, it must also set `search_path = pg_catalog, public` per AGENTS.md.

---

## Implementation Steps

### Step 1: Author migration 0134

- [ID tsk_p2_preauth_004_01_work_item_01] Create `schema/migrations/0134_policy_decisions.sql` with the `CREATE TABLE public.policy_decisions` statement exactly as specified above, the two `CREATE INDEX` statements, and no other DDL. The file must not contain `BEGIN;` or `COMMIT;` (migrations run inside the orchestrator's transaction envelope per bug-fix **B5** from PR #188). The file must not include `\i` or any include directive; backfill is not applicable because the table is empty at create time.
- **Done when:** `grep -q 'CREATE TABLE public.policy_decisions' schema/migrations/0134_policy_decisions.sql && grep -q 'entity_type' schema/migrations/0134_policy_decisions.sql && grep -q 'entity_id' schema/migrations/0134_policy_decisions.sql && grep -q "'\^\[0-9a-f\]{64}\$'" schema/migrations/0134_policy_decisions.sql` exits 0.

### Step 2: Install the append-only trigger in the same migration

- [ID tsk_p2_preauth_004_01_work_item_02] Append the `enforce_policy_decisions_append_only` function and trigger to `0134_policy_decisions.sql`. The trigger must fire `BEFORE UPDATE OR DELETE ON public.policy_decisions FOR EACH ROW`.
- **Done when:** `grep -q 'enforce_policy_decisions_append_only' schema/migrations/0134_policy_decisions.sql && grep -q 'BEFORE UPDATE OR DELETE' schema/migrations/0134_policy_decisions.sql` exits 0.

### Step 3: Advance MIGRATION_HEAD

- [ID tsk_p2_preauth_004_01_work_item_03] Write the exact token `0134` to `schema/migrations/MIGRATION_HEAD`. No trailing whitespace beyond the single newline the repo convention requires.
- **Done when:** `grep -Fxq '0134' schema/migrations/MIGRATION_HEAD` exits 0.

### Step 4: Author the schema verifier

- [ID tsk_p2_preauth_004_01_work_item_04] Create `scripts/db/verify_policy_decisions_schema.sh` that connects to `$DATABASE_URL`, queries `information_schema.columns`, `information_schema.table_constraints`, and `pg_trigger`, asserts the 11 columns with the declared types and `NOT NULL` posture, asserts the `PRIMARY KEY`, `UNIQUE (execution_id, decision_type)`, `FK execution_id → execution_records(execution_id)`, both `CHECK` regexes, the two indexes, and the append-only trigger for both `UPDATE` and `DELETE`. The verifier must `set -euo pipefail` at the top and write `evidence/phase2/tsk_p2_preauth_004_01.json` with fields `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`, `columns_present`, `constraints_present`, `triggers_present`, `migration_head_value`.
- **Done when:** `bash scripts/db/verify_policy_decisions_schema.sh` against a DB with 0134 applied exits 0 and the emitted evidence JSON passes `jq -e '.status=="PASS"'`.

### Step 5: Author the negative-test harness

- [ID tsk_p2_preauth_004_01_work_item_05] Create `scripts/db/tests/test_policy_decisions_negative.sh` that exercises five contracted rejection paths (N1–N5) and exits 0 only when every insert or update is rejected with the expected `SQLSTATE`. Each attempt runs inside a savepoint so the harness can continue after each rejection.
- **Done when:** `bash scripts/db/tests/test_policy_decisions_negative.sh` against a DB with 0134 applied exits 0.

---

## Verification

Verifiers must run in this order. A single failure halts the chain.

- [ID tsk_p2_preauth_004_01_work_item_04] `test -x scripts/db/verify_policy_decisions_schema.sh && bash scripts/db/verify_policy_decisions_schema.sh > evidence/phase2/tsk_p2_preauth_004_01.json || exit 1`
- [ID tsk_p2_preauth_004_01_work_item_01] `test -f schema/migrations/0134_policy_decisions.sql && grep -q 'CREATE TABLE public.policy_decisions' schema/migrations/0134_policy_decisions.sql && grep -q 'entity_type' schema/migrations/0134_policy_decisions.sql && grep -q 'entity_id' schema/migrations/0134_policy_decisions.sql && grep -q "'\^\[0-9a-f\]{64}\$'" schema/migrations/0134_policy_decisions.sql || exit 1`
- [ID tsk_p2_preauth_004_01_work_item_02] `grep -q 'enforce_policy_decisions_append_only' schema/migrations/0134_policy_decisions.sql && grep -q 'BEFORE UPDATE OR DELETE' schema/migrations/0134_policy_decisions.sql || exit 1`
- [ID tsk_p2_preauth_004_01_work_item_03] `test -f schema/migrations/MIGRATION_HEAD && grep -Fxq '0134' schema/migrations/MIGRATION_HEAD || exit 1`
- [ID tsk_p2_preauth_004_01_work_item_05] `test -x scripts/db/tests/test_policy_decisions_negative.sh && bash scripts/db/tests/test_policy_decisions_negative.sh || exit 1`
- [ID tsk_p2_preauth_004_01_work_item_04] `test -f evidence/phase2/tsk_p2_preauth_004_01.json && grep -q 'observed_hashes' evidence/phase2/tsk_p2_preauth_004_01.json && grep -q 'migration_head_value' evidence/phase2/tsk_p2_preauth_004_01.json || exit 1`

---

## Evidence Contract

| Path | Writer | Must include |
|---|---|---|
| `evidence/phase2/tsk_p2_preauth_004_01.json` | `scripts/db/verify_policy_decisions_schema.sh` | `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`, `columns_present`, `constraints_present`, `triggers_present`, `migration_head_value` |

Evidence is emitted only by the verifier. Hand-editing the JSON is a FAIL_REVIEW.

---

## Negative Tests (contracted for IMPLEMENT-TASK)

| ID | Case | Expected SQLSTATE |
|---|---|---|
| N1 | Insert with `execution_id` NULL | `23502` (NOT NULL) |
| N2 | Insert with `signature` NULL | `23502` |
| N3 | Insert with `decision_hash` of length 63 or non-hex characters | `23514` (CHECK) |
| N4 | Insert with `execution_id` that does not exist in `execution_records` | `23503` (FK) |
| N5 | `UPDATE` of an existing row | Raised by `enforce_policy_decisions_append_only` |

All five must be exercised by `scripts/db/tests/test_policy_decisions_negative.sh`. Harness exits 0 only if every insert is rejected.

---

## Failure Modes

| Mode | Severity |
|---|---|
| ALTER statement targets an applied migration (0001-0133) | CRITICAL_FAIL |
| 0134 applied but `MIGRATION_HEAD` reads `0133` | FAIL |
| `entity_type` or `entity_id` missing or nullable | CRITICAL_FAIL |
| CHECK regex on `decision_hash` or `signature` absent or incorrect | FAIL |
| Append-only trigger missing or does not cover `DELETE` | CRITICAL_FAIL |
| Runtime DDL in `src/` or `packages/` | CRITICAL_FAIL |
| Evidence JSON missing `observed_hashes` or `execution_trace` | FAIL |
| Any of the five negative tests omitted | FAIL_REVIEW |

---

## Rollback

Migration 0134 is forward-only. Rollback is a new migration 013N that drops the trigger, indexes, and table. Do not edit 0134 after it is merged; do not hand-drop the table outside a migration.

---

## Risk

| Risk | Mitigation |
|---|---|
| Crypto contract exists in PLAN but column CHECK is weaker than spec | CHECK regex is literal and grep-verified in the verifier step |
| Trigger installed but does not cover DELETE | Trigger definition uses `BEFORE UPDATE OR DELETE`, confirmed by grep |
| Cross-entity replay remains open | `entity_type` + `entity_id` land `NOT NULL` in the same migration; 004-03 adds the binding verifier |
| Migration ordering gate breaks | `MIGRATION_HEAD` advanced to `0134` as a distinct work item with its own verification step |

---

## Approval

Approved by: DB_FOUNDATION
Approval metadata: not required for CREATE-TASK authorship; IMPLEMENT-TASK run will require approval metadata on the regulated `schema/migrations/**` change per AGENTS.md.
