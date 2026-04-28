# TSK-P2-PREAUTH-004-02 PLAN — Create state_rules table (migration 0135) with rule_priority and deterministic tiebreak

Task: TSK-P2-PREAUTH-004-02
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-004-00, TSK-P2-PREAUTH-004-01
Blocks: TSK-P2-PREAUTH-004-03, TSK-P2-PREAUTH-005-00
failure_signature: PHASE2.PREAUTH.STATE_RULES.SCHEMA_MISSING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
wave_reference: Wave 4 — Authority Binding
origin_task_id: TSK-P2-PREAUTH-004-02
repro_command: bash scripts/db/verify_state_rules_schema.sh
verification_commands_run: bash scripts/db/verify_state_rules_schema.sh
final_status: PLANNED

---

## Objective

Materialise the `state_rules` table exactly as the Wave 4 contract (`docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md`, section *state_rules Schema*) pins it. The row encodes which `(from_state → to_state)` transitions are permissible when a given `required_decision_type` is present, and `rule_priority INT NOT NULL DEFAULT 0` resolves conflicts so that rule selection is a total order. The deterministic tiebreak (lower `state_rule_id` UUID wins on equal priority) is a contract on the consumer (Wave 5 state machine) — it is documented in this PLAN but not enforced by DDL because the state machine, not the database, performs rule selection. The task closes the deadlock defect in the original Wave 4 draft by making the data model capable of expressing a total order.

This task does not create `policy_decisions`, does not implement the rule-selection runtime logic, and does not register the authority-transition binding invariant.

---

## Architectural Context

`state_rules` is the configuration side of Wave 4 (what transitions are permitted), where `policy_decisions` (004-01) is the evidence side (which authority actually authorised a specific run). Both are read by the Wave 5 state machine: given a transition candidate, the machine queries `state_rules` for rules matching the source state, filters by `required_decision_type` against the set of `policy_decisions` bound to the execution, and selects the winning rule by `rule_priority DESC, state_rule_id ASC`.

The three Wave 4 audit fixes from Wave-4-for-Devin.md land in this task as follows:

1. **Cryptographic binding.** Not in scope of this task. Lives on `policy_decisions` (004-01).

2. **Entity context.** Not in scope of this task. Lives on `policy_decisions` (004-01).

3. **Rule priority.** `rule_priority INT NOT NULL DEFAULT 0`. Higher priority wins. Negative values are valid (explicit deny rules). Adding a `CHECK (rule_priority >= 0)` is an anti-pattern and is tested against (N3). The deterministic tiebreak on equal priority is lexicographic ordering of `state_rule_id` (UUID) — this is not enforced by DDL because the database does not select rules, but it is pinned in the contract so the Wave 5 consumer is a pure function of the rule set.

---

## Pre-conditions

- [ ] `TSK-P2-PREAUTH-004-00` is merged.
- [ ] `schema/migrations/MIGRATION_HEAD` reads `0134` at the start of this task (004-01 must be applied before 004-02 so the `0135` number is not in dispute).
- [ ] No prior migration creates or references `public.state_rules`.

This task can run in parallel with 004-01 at the **PLAN** layer (no shared files). At the **IMPLEMENT** layer it is sequenced after 004-01 because `MIGRATION_HEAD` is a shared mutable file and only one migration at a time can advance it.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0135_state_rules.sql` | CREATE | Materialise the table, constraints, and index. |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Advance head from `0134` to `0135`. |
| `scripts/db/verify_state_rules_schema.sh` | CREATE | DB-shape verifier that proves the 7 columns, the `rule_priority` default, the UNIQUE, and the index are present; emits evidence JSON. |
| `scripts/db/tests/test_state_rules_negative.sh` | CREATE | Harness that exercises N1 (NOT NULL reject), N2 (UNIQUE reject), and N3 (negative-priority accept). |
| `evidence/phase2/tsk_p2_preauth_004_02.json` | CREATE | Emitted by the verifier. |
| `tasks/TSK-P2-PREAUTH-004-02/meta.yml` | MODIFY | Populate full meta per Task Creation Process §2 Step 4. |
| `docs/plans/phase2/TSK-P2-PREAUTH-004-02/PLAN.md` | CREATE/REWRITE | This document. |
| `docs/plans/phase2/TSK-P2-PREAUTH-004-02/EXEC_LOG.md` | MODIFY | Log the task authorship. |

Any file modified that is not on this list => FAIL_REVIEW.

---

## Stop Conditions

- **If any ALTER TABLE statement targets an applied migration (0001-0134)** → STOP.
- **If `rule_priority` is omitted, nullable, has a default other than 0, or is constrained by `CHECK (rule_priority >= 0)`** → STOP (reopens deadlock or breaks deny rules).
- **If `UNIQUE (from_state, to_state, required_decision_type)` is missing** → STOP (duplicate-rule ambiguity).
- **If `MIGRATION_HEAD` is not advanced to `0135`** → STOP.
- **If runtime DDL is introduced in `src/` or `packages/`** → STOP.
- **If any of the three contracted negative tests is omitted from the harness** → STOP.

---

## Schema Specification (authoritative for migration 0135)

```
CREATE TABLE public.state_rules (
  state_rule_id           UUID        NOT NULL PRIMARY KEY,
  from_state              TEXT        NOT NULL,
  to_state                TEXT        NOT NULL,
  required_decision_type  TEXT        NOT NULL,
  allowed                 BOOLEAN     NOT NULL,
  rule_priority           INT         NOT NULL DEFAULT 0,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (from_state, to_state, required_decision_type)
);

CREATE INDEX idx_state_rules_from_priority ON public.state_rules (from_state, rule_priority DESC);
```

No CHECK constraint on `rule_priority` sign. No append-only trigger (rule configuration is expected to be mutable across waves as policy evolves; immutability would break policy iteration). Rule-selection runtime logic (priority + UUID tiebreak) is out of scope and will be implemented in Wave 5 against this data model.

---

## Rule Selection Contract (documentation only; enforced by Wave 5 consumer)

Given a transition `(from_state → to_state)` and a set of `policy_decisions` whose `decision_type` values are known, the state machine:

1. Queries `SELECT * FROM state_rules WHERE from_state = $1 ORDER BY rule_priority DESC, state_rule_id ASC`.
2. Iterates rows in order, selecting the first rule whose `required_decision_type` is present in the decision set and whose `to_state` matches the candidate transition.
3. Returns `allowed` on the selected rule.

This is a pure function of `(from_state, to_state, rule set, decision set)` — no non-determinism. The UUID tiebreak is what makes this deterministic under replay on identical rule sets. The state machine implementation lands in Wave 5.

---

## Implementation Steps

### Step 1: Author migration 0135

- [ID tsk_p2_preauth_004_02_work_item_01] Create `schema/migrations/0135_state_rules.sql` with the `CREATE TABLE public.state_rules` and `CREATE INDEX idx_state_rules_from_priority` statements exactly as specified above. The file must not contain `BEGIN;` or `COMMIT;` (B5). No CHECK on `rule_priority`. No trigger.
- **Done when:** `grep -q 'CREATE TABLE public.state_rules' schema/migrations/0135_state_rules.sql && grep -q 'rule_priority INT NOT NULL DEFAULT 0' schema/migrations/0135_state_rules.sql && grep -q 'UNIQUE (from_state, to_state, required_decision_type)' schema/migrations/0135_state_rules.sql` exits 0.

### Step 2: Advance MIGRATION_HEAD

- [ID tsk_p2_preauth_004_02_work_item_02] Write the exact token `0135` to `schema/migrations/MIGRATION_HEAD`.
- **Done when:** `grep -Fxq '0135' schema/migrations/MIGRATION_HEAD` exits 0.

### Step 3: Author the schema verifier

- [ID tsk_p2_preauth_004_02_work_item_03] Create `scripts/db/verify_state_rules_schema.sh` that connects to `$DATABASE_URL`, queries `information_schema.columns`, `information_schema.table_constraints`, and `pg_indexes`, and asserts:
  - All 7 columns are present with the declared types and `NOT NULL` posture.
  - `rule_priority` has `column_default` exactly `0` and `is_nullable` `NO`.
  - `PRIMARY KEY` on `state_rule_id` and `UNIQUE (from_state, to_state, required_decision_type)` exist.
  - `idx_state_rules_from_priority` exists with `DESC` ordering on `rule_priority`.
  
  Verifier writes `evidence/phase2/tsk_p2_preauth_004_02.json` with `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`, `columns_present`, `constraints_present`, `indexes_present`, `migration_head_value`.
- **Done when:** `bash scripts/db/verify_state_rules_schema.sh` exits 0 and `jq -e '.status=="PASS"' evidence/phase2/tsk_p2_preauth_004_02.json` exits 0.

### Step 4: Author the negative-test harness

- [ID tsk_p2_preauth_004_02_work_item_04] Create `scripts/db/tests/test_state_rules_negative.sh` that exercises N1 (NULL `required_decision_type` → 23502 reject), N2 (duplicate tuple → 23505 reject), and N3 (negative `rule_priority` → ACCEPT). Each attempt runs inside a savepoint. Harness exits 0 only when N1 and N2 are rejected and N3 is accepted.
- **Done when:** `bash scripts/db/tests/test_state_rules_negative.sh` against a DB with 0135 applied exits 0.

---

## Verification

- [ID tsk_p2_preauth_004_02_work_item_03] `test -x scripts/db/verify_state_rules_schema.sh && bash scripts/db/verify_state_rules_schema.sh > evidence/phase2/tsk_p2_preauth_004_02.json || exit 1`
- [ID tsk_p2_preauth_004_02_work_item_01] `test -f schema/migrations/0135_state_rules.sql && grep -q 'CREATE TABLE public.state_rules' schema/migrations/0135_state_rules.sql && grep -q 'rule_priority INT NOT NULL DEFAULT 0' schema/migrations/0135_state_rules.sql && grep -q 'UNIQUE (from_state, to_state, required_decision_type)' schema/migrations/0135_state_rules.sql || exit 1`
- [ID tsk_p2_preauth_004_02_work_item_02] `test -f schema/migrations/MIGRATION_HEAD && grep -Fxq '0135' schema/migrations/MIGRATION_HEAD || exit 1`
- [ID tsk_p2_preauth_004_02_work_item_04] `test -x scripts/db/tests/test_state_rules_negative.sh && bash scripts/db/tests/test_state_rules_negative.sh || exit 1`
- [ID tsk_p2_preauth_004_02_work_item_03] `test -f evidence/phase2/tsk_p2_preauth_004_02.json && grep -q 'observed_hashes' evidence/phase2/tsk_p2_preauth_004_02.json && grep -q 'migration_head_value' evidence/phase2/tsk_p2_preauth_004_02.json || exit 1`

---

## Evidence Contract

| Path | Writer | Must include |
|---|---|---|
| `evidence/phase2/tsk_p2_preauth_004_02.json` | `scripts/db/verify_state_rules_schema.sh` | `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`, `columns_present`, `constraints_present`, `indexes_present`, `migration_head_value` |

---

## Negative Tests (contracted)

| ID | Case | Expected outcome |
|---|---|---|
| N1 | Insert with `required_decision_type` NULL | Reject, SQLSTATE `23502` |
| N2 | Two inserts with identical `(from_state, to_state, required_decision_type)` | Second rejected, SQLSTATE `23505` |
| N3 | Insert with `rule_priority = -1` (explicit deny) | **Accept** — negative priority is valid |

N3 is a guard against the anti-pattern of adding `CHECK (rule_priority >= 0)`. If a future change adds such a CHECK, N3 fails and the harness exits non-zero.

---

## Failure Modes

| Mode | Severity |
|---|---|
| ALTER statement targets an applied migration | CRITICAL_FAIL |
| `rule_priority` missing / nullable / default != 0 | CRITICAL_FAIL |
| `CHECK (rule_priority >= 0)` present | FAIL |
| UNIQUE on `(from_state, to_state, required_decision_type)` missing | CRITICAL_FAIL |
| `idx_state_rules_from_priority` missing | FAIL |
| `MIGRATION_HEAD` not advanced | FAIL |
| Runtime DDL in `src/` or `packages/` | CRITICAL_FAIL |
| Evidence JSON missing `observed_hashes` / `execution_trace` | FAIL |
| Any of the three negative tests omitted | FAIL_REVIEW |

---

## Rollback

Forward-only. Rollback is a new migration that drops the index and table. Do not edit 0135 after merge.

---

## Risk

| Risk | Mitigation |
|---|---|
| Deadlock defect returns (rule_priority missing or with a cap) | N3 asserts negative priority is accepted; verifier asserts default=0 and nullability=NO |
| Rule lookup becomes O(n) at runtime | `idx_state_rules_from_priority` on `(from_state, rule_priority DESC)` is verified present by the schema verifier |
| Tiebreak is documented but not enforceable in SQL | Documented as a `proof_limitation` in meta; Wave 5 consumer owns enforcement |
| Migration ordering gate breaks | MIGRATION_HEAD advance is its own work item with explicit verification |

---

## Approval

Approved by: DB_FOUNDATION
Approval metadata: not required for CREATE-TASK authorship; IMPLEMENT-TASK run will require approval metadata on the regulated `schema/migrations/**` change per AGENTS.md.
