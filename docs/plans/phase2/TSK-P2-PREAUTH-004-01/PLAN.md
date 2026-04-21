# TSK-P2-PREAUTH-004-01 PLAN — Create policy_decisions table (migration 0134) as the Wave 4 cryptographic truth anchor row type

Task: TSK-P2-PREAUTH-004-01
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-004-00
Blocks: TSK-P2-PREAUTH-004-02, TSK-P2-PREAUTH-004-03
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
- **If any of the six contracted negative tests (N1–N6) is omitted from the harness** → STOP.

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

Append-only trigger (same migration file). Follows the Wave 3 convention established in `schema/migrations/0133_execution_records_triggers.sql` for append-only ledger enforcement: custom GF-prefixed SQLSTATE (so rejections do not collide with CHECK violations on the same table, which also raise `23514`), `SECURITY DEFINER` with hardened `search_path`, and explicit `REVOKE EXECUTE ... FROM PUBLIC`.

```
CREATE OR REPLACE FUNCTION public.enforce_policy_decisions_append_only()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'GF061: policy_decisions is append-only, UPDATE/DELETE not allowed'
    USING ERRCODE = 'GF061';
  RETURN NULL;
END;
$$ SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER enforce_policy_decisions_append_only
BEFORE UPDATE OR DELETE ON public.policy_decisions
FOR EACH ROW EXECUTE FUNCTION public.enforce_policy_decisions_append_only();

REVOKE ALL ON FUNCTION public.enforce_policy_decisions_append_only() FROM PUBLIC;
```

SQLSTATE `GF061` is the next free code in the Wave 3/4 GF-prefix sequence (after `GF060` for K13 taxonomy alignment). Rationale:

1. `23514` (standard PostgreSQL `check_violation`, raised natively by the `decision_hash` and `signature` CHECK regexes on this same table) must remain distinct from append-only rejections, so the negative-test harness can differentiate N3 (CHECK violation) from N5/N6 (append-only rejection) by SQLSTATE alone.
2. It matches the repo convention for append-only triggers: `GF050` `statutory_levy_registry`, `GF051` `exchange_rate_audit_log`, `GF055` `project_boundaries` + `protected_areas`, `GF056` `execution_records`.

`SECURITY DEFINER` with `SET search_path = pg_catalog, public` is required by `AGENTS.md` for all trigger functions executing under the definer's privileges (mirrors 0133). The function is revoke-first (`REVOKE ALL ... FROM PUBLIC`) even though it only raises, to match the established privilege posture on every other GF-trigger in the repo.

Note on registry: `docs/contracts/sqlstate_map.yml` currently pins its `code_pattern` to `^P\d{4}$` (enforced by `docs/contracts/sqlstate_map.schema.json` and `scripts/audit/check_sqlstate_map_drift.sh`), so `GF`-prefixed codes cannot be registered in that file without a separate schema change. The authoritative declaration of `GF061` therefore lives in this PLAN and is mirrored verbatim into `schema/migrations/0134_policy_decisions.sql` at IMPLEMENT-TASK time, matching the pattern used by every in-use GF code. Harmonising the registry with the in-use GF convention is tracked as a follow-up in `docs/remediation/2026-04-20_wave4-pr192-devin-review.md`.

---

## Payload → Column Mapping (NON-NEGOTIABLE)

The canonical-JSON `decision_payload` that 004-03 recomputes the `sha256` over is reconstructed from the `policy_decisions` row columns. The mapping MUST be implemented as follows; any deviation breaks `decision_hash` recompute (004-03 V3 scenario) and silently invalidates every downstream signature / authority-binding proof. This table is the single source of truth for the IMPLEMENT-TASK writer of migration 0134 and for the 004-03 verifier.

| Payload field (canonical JSON key) | `policy_decisions` column | Type / serialisation |
|---|---|---|
| `policy_decision_id` | `policy_decision_id` | UUID (lowercase hex, RFC 4122 canonical form) |
| `execution_id`       | `execution_id`       | UUID (lowercase hex, RFC 4122 canonical form) |
| `decision_type`      | `decision_type`      | TEXT (verbatim) |
| `authority_scope`    | `authority_scope`    | TEXT (verbatim) |
| `declared_by`        | `declared_by`        | UUID (lowercase hex, RFC 4122 canonical form) |
| `entity_type`        | `entity_type`        | TEXT (verbatim) |
| `entity_id`          | `entity_id`          | UUID (lowercase hex, RFC 4122 canonical form) |
| `issued_at`          | `signed_at`          | RFC 3339 UTC string (`YYYY-MM-DDTHH:MM:SS.ffffffZ`) |

Notes:

- The payload field is named `issued_at`; the column is named `signed_at`. This naming was fixed in Wave 3 and is re-asserted here so no implementer silently maps `issued_at → created_at` or introduces a new `issued_at` column. See `docs/plans/phase2/TSK-P2-PREAUTH-004-03/PLAN.md` V3 scenario for the verifier's recompute contract.
- `decision_hash` and `signature` are NOT payload fields. They are derived from the canonical-JSON serialisation of the payload and therefore cannot recursively appear in it.
- `created_at` is a DB-assigned audit column and is NOT part of the canonical payload.
- Canonical JSON serialisation rules (key sort, whitespace, numeric normalisation) are pinned in the 004-00 contract and are not redefined here.

---

## Implementation Steps

### Step 1: Author migration 0134

- [ID tsk_p2_preauth_004_01_work_item_01] Create `schema/migrations/0134_policy_decisions.sql` with the `CREATE TABLE public.policy_decisions` statement exactly as specified above, the two `CREATE INDEX` statements, and no other DDL. The file must not contain `BEGIN;` or `COMMIT;` (migrations run inside the orchestrator's transaction envelope per bug-fix **B5** from PR #188). The file must not include `\i` or any include directive; backfill is not applicable because the table is empty at create time.
- **Done when:** `grep -q 'CREATE TABLE public.policy_decisions' schema/migrations/0134_policy_decisions.sql && grep -q 'entity_type' schema/migrations/0134_policy_decisions.sql && grep -q 'entity_id' schema/migrations/0134_policy_decisions.sql && grep -q "'\^\[0-9a-f\]{64}\$'" schema/migrations/0134_policy_decisions.sql` exits 0.

### Step 2: Install the append-only trigger in the same migration

- [ID tsk_p2_preauth_004_01_work_item_02] Append the `enforce_policy_decisions_append_only` function and trigger to `0134_policy_decisions.sql` exactly as specified in the *Schema Specification* section above. The function MUST be declared `SECURITY DEFINER SET search_path = pg_catalog, public` (mirrors 0133 hardening per AGENTS.md), MUST `RAISE EXCEPTION` with the literal message prefix `GF061:` and `USING ERRCODE = 'GF061'`, and MUST be followed by `REVOKE ALL ON FUNCTION public.enforce_policy_decisions_append_only() FROM PUBLIC;`. The trigger must fire `BEFORE UPDATE OR DELETE ON public.policy_decisions FOR EACH ROW`.
- **Done when:** all of the following greps against `schema/migrations/0134_policy_decisions.sql` exit 0: `grep -q 'enforce_policy_decisions_append_only'`, `grep -q 'BEFORE UPDATE OR DELETE'`, `grep -q "ERRCODE = 'GF061'"`, `grep -q 'SECURITY DEFINER'`, `grep -q 'search_path = pg_catalog, public'`, `grep -q 'REVOKE ALL ON FUNCTION public.enforce_policy_decisions_append_only'`.

### Step 3: Advance MIGRATION_HEAD

- [ID tsk_p2_preauth_004_01_work_item_03] Write the exact token `0134` to `schema/migrations/MIGRATION_HEAD`. No trailing whitespace beyond the single newline the repo convention requires.
- **Done when:** `grep -Fxq '0134' schema/migrations/MIGRATION_HEAD` exits 0.

### Step 4: Author the schema verifier

- [ID tsk_p2_preauth_004_01_work_item_04] Create `scripts/db/verify_policy_decisions_schema.sh` that connects to `$DATABASE_URL`, queries `information_schema.columns`, `information_schema.table_constraints`, `pg_trigger`, and `pg_proc`, asserts the 11 columns with the declared types and `NOT NULL` posture, asserts the `PRIMARY KEY`, `UNIQUE (execution_id, decision_type)`, `FK execution_id → execution_records(execution_id)`, both `CHECK` regexes, the two indexes, the append-only trigger for both `UPDATE` and `DELETE`, and the security posture of the append-only function (`prosecdef = true` and `proconfig` contains `search_path=pg_catalog, public`). The verifier must `set -euo pipefail` at the top and write `evidence/phase2/tsk_p2_preauth_004_01.json` with fields `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`, `columns_present`, `constraints_present`, `triggers_present`, `function_security_posture`, `migration_head_value`.
- **Done when:** `bash scripts/db/verify_policy_decisions_schema.sh` against a DB with 0134 applied exits 0 and the emitted evidence JSON passes `jq -e '.status=="PASS"'`.

### Step 5: Author the negative-test harness

- [ID tsk_p2_preauth_004_01_work_item_05] Create `scripts/db/tests/test_policy_decisions_negative.sh` that exercises six contracted rejection paths (N1–N6, including both `UPDATE` and `DELETE` append-only rejections) and exits 0 only when every insert, update, or delete is rejected with the expected `SQLSTATE` (N5 and N6 must both assert `SQLSTATE = 'GF061'`). Each attempt runs inside a savepoint so the harness can continue after each rejection.
- **Done when:** `bash scripts/db/tests/test_policy_decisions_negative.sh` against a DB with 0134 applied exits 0.

---

## Verification

Verifiers must run in this order. A single failure halts the chain.

- [ID tsk_p2_preauth_004_01_work_item_04] `test -x scripts/db/verify_policy_decisions_schema.sh && bash scripts/db/verify_policy_decisions_schema.sh > evidence/phase2/tsk_p2_preauth_004_01.json || exit 1`
- [ID tsk_p2_preauth_004_01_work_item_01] `test -f schema/migrations/0134_policy_decisions.sql && grep -q 'CREATE TABLE public.policy_decisions' schema/migrations/0134_policy_decisions.sql && grep -q 'entity_type' schema/migrations/0134_policy_decisions.sql && grep -q 'entity_id' schema/migrations/0134_policy_decisions.sql && grep -q "'\^\[0-9a-f\]{64}\$'" schema/migrations/0134_policy_decisions.sql || exit 1`
- [ID tsk_p2_preauth_004_01_work_item_02] `grep -q 'enforce_policy_decisions_append_only' schema/migrations/0134_policy_decisions.sql && grep -q 'BEFORE UPDATE OR DELETE' schema/migrations/0134_policy_decisions.sql && grep -q "ERRCODE = 'GF061'" schema/migrations/0134_policy_decisions.sql && grep -q 'SECURITY DEFINER' schema/migrations/0134_policy_decisions.sql && grep -q 'search_path = pg_catalog, public' schema/migrations/0134_policy_decisions.sql && grep -q 'REVOKE ALL ON FUNCTION public.enforce_policy_decisions_append_only' schema/migrations/0134_policy_decisions.sql || exit 1`
- [ID tsk_p2_preauth_004_01_work_item_03] `test -f schema/migrations/MIGRATION_HEAD && grep -Fxq '0134' schema/migrations/MIGRATION_HEAD || exit 1`
- [ID tsk_p2_preauth_004_01_work_item_05] `test -x scripts/db/tests/test_policy_decisions_negative.sh && bash scripts/db/tests/test_policy_decisions_negative.sh || exit 1`
- [ID tsk_p2_preauth_004_01_work_item_04] `test -f evidence/phase2/tsk_p2_preauth_004_01.json && grep -q 'observed_hashes' evidence/phase2/tsk_p2_preauth_004_01.json && grep -q 'migration_head_value' evidence/phase2/tsk_p2_preauth_004_01.json || exit 1`

---

## Evidence Contract

| Path | Writer | Must include |
|---|---|---|
| `evidence/phase2/tsk_p2_preauth_004_01.json` | `scripts/db/verify_policy_decisions_schema.sh` | `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`, `columns_present`, `constraints_present`, `triggers_present`, `function_security_posture`, `migration_head_value` |

Evidence is emitted only by the verifier. Hand-editing the JSON is a FAIL_REVIEW.

---

## Negative Tests (contracted for IMPLEMENT-TASK)

| ID | Case | Expected SQLSTATE |
|---|---|---|
| N1 | Insert with `execution_id` NULL | `23502` (NOT NULL) |
| N2 | Insert with `signature` NULL | `23502` |
| N3 | Insert with `decision_hash` of length 63 or non-hex characters | `23514` (CHECK) |
| N4 | Insert with `execution_id` that does not exist in `execution_records` | `23503` (FK) |
| N5 | `UPDATE` of an existing row | `GF061` (raised by `enforce_policy_decisions_append_only`) |
| N6 | `DELETE` of an existing row | `GF061` (raised by `enforce_policy_decisions_append_only`) |

All six must be exercised by `scripts/db/tests/test_policy_decisions_negative.sh`. Harness exits 0 only if every insert, update, or delete is rejected. N5 and N6 must assert `SQLSTATE = 'GF061'` (not merely that the mutation failed) so that an accidental CHECK-violation masquerading as append-only enforcement is caught.

---

## Failure Modes

| Mode | Severity |
|---|---|
| ALTER statement targets an applied migration (0001-0133) | CRITICAL_FAIL |
| 0134 applied but `MIGRATION_HEAD` reads `0133` | FAIL |
| `entity_type` or `entity_id` missing or nullable | CRITICAL_FAIL |
| CHECK regex on `decision_hash` or `signature` absent or incorrect | FAIL |
| Append-only trigger missing or does not cover `DELETE` | CRITICAL_FAIL |
| Append-only function not `SECURITY DEFINER` with `search_path = pg_catalog, public` | CRITICAL_FAIL |
| Append-only function ERRCODE is not `GF061` (e.g. left as `23514`) | CRITICAL_FAIL |
| Runtime DDL in `src/` or `packages/` | CRITICAL_FAIL |
| Evidence JSON missing `observed_hashes` or `execution_trace` | FAIL |
| Any of the six negative tests omitted, or N5/N6 assertion does not check `SQLSTATE = 'GF061'` | FAIL_REVIEW |

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
