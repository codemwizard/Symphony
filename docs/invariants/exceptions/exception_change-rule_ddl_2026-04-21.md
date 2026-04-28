---
exception_id: EXC-20260421-POLICY-DECISIONS-004-01
inv_scope: change-rule
expiry: 2026-10-21
follow_up_ticket: TSK-P2-PREAUTH-004-03
reason: Forward migration 0134 creates public.policy_decisions (Wave 4 cryptographic truth anchor row type) and installs the enforce_policy_decisions_append_only trigger raising SQLSTATE GF061. Full invariant linkage (INVARIANTS_MANIFEST.yml + INVARIANTS_IMPLEMENTED.md for the Wave 4 authority-binding invariant) is deferred to TSK-P2-PREAUTH-004-03, which ships the enforce_authority_transition_binding function and registers INV-AUTH-TRANSITION-BINDING-01 in the same PR. 004-01 alone installs a row type and its append-only ledger semantics; the invariant anchor it supports (cryptographic truth anchor) is only complete once 004-03 wires recompute-on-read enforcement. Registering the invariant at 004-01 time would flip status=implemented without enforcement evidence covering the consuming surface — an explicit anti-pattern per the Wave 3 REM-04/REM-05 precedent.
author: db_foundation
created_at: 2026-04-21
---

# Exception: ddl structural change without invariants linkage (004-01 policy_decisions)

## Reason

Migration `0134_policy_decisions.sql` creates the `public.policy_decisions` table and installs the `enforce_policy_decisions_append_only` trigger function:

- Table: 11 columns all `NOT NULL`, `PRIMARY KEY` on `policy_decision_id`, `UNIQUE (execution_id, decision_type)`, `FOREIGN KEY (execution_id)` to `public.execution_records(execution_id)`, `CHECK (decision_hash ~ '^[0-9a-f]{64}$')`, `CHECK (signature ~ '^[0-9a-f]{128}$')`, indexes on `(entity_type, entity_id)` and `(declared_by)`.
- Trigger: `BEFORE UPDATE OR DELETE FOR EACH ROW` raising `SQLSTATE GF061`. Function declared `SECURITY DEFINER SET search_path = pg_catalog, public` with `REVOKE ALL ON FUNCTION ... FROM PUBLIC` (mirrors 0133 GF056 hardening per AGENTS.md).

These are the structural foundations of the Wave 4 authority-binding contract declared in `docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md`. The consuming invariant (`INV-AUTH-TRANSITION-BINDING-01`) is registered by `TSK-P2-PREAUTH-004-03` once `enforce_authority_transition_binding(p_execution_id, p_to_state_rule_id)` exists and enforces hash-recompute-on-read across the state-rule transition surface. Registering the invariant now — with 004-02 (`state_rules`) and 004-03 (enforcement function + verifier) not yet implemented — would declare enforcement complete before it exists.

## Evidence

structural_change: true
confidence_hint: 1.0
primary_reason: ddl
reason_types: ddl, migration_file_added_or_deleted, security

Matched files:
- schema/migrations/0134_policy_decisions.sql
- scripts/db/tests/test_policy_decisions_negative.sh
- scripts/db/verify_policy_decisions_schema.sh

## Mitigation

- No edit to migrations 0001–0133 (forward-only preserved; migration_head advanced 0133 → 0134).
- `enforce_policy_decisions_append_only()` is `SECURITY DEFINER` with `SET search_path = pg_catalog, public` (AGENTS.md hardening requirement; identical posture to 0133 GF056).
- `REVOKE ALL ON FUNCTION public.enforce_policy_decisions_append_only() FROM PUBLIC` is applied in the same migration.
- No `BEGIN`/`COMMIT` at file top-level (migrate.sh already wraps each migration in its own transaction).
- Proof-carrying verifier `scripts/db/verify_policy_decisions_schema.sh` inspects `information_schema.columns` (all 11 columns NOT NULL with contracted types), `information_schema.table_constraints` (PK + UNIQUE + FK + CHECK regexes), `pg_indexes` (both expected indexes), `pg_trigger.tgtype` (value `27` = ROW+BEFORE+UPDATE+DELETE), `pg_proc.prosecdef` and `pg_proc.proconfig` (SECURITY DEFINER + `search_path=pg_catalog, public`), and `has_function_privilege('public', ..., 'EXECUTE') = false`. It also drives the negative-test harness and emits self-validating evidence at `evidence/phase2/tsk_p2_preauth_004_01.json`.
- Negative-test harness `scripts/db/tests/test_policy_decisions_negative.sh` validates all six contracted SQLSTATEs (N1 23502, N2 23502, N3 23514, N4 23503, N5/N6 `GF061`). N5/N6 run inside a single seeded transaction with `SAVEPOINT`/`ROLLBACK` so no state leaks; a documented degraded branch asserts `pg_trigger` presence when `execution_records` has no seed row (the temporal-binding trigger from 0131 requires a valid interpretation_pack resolution to seed).
- Both scripts are wired into `scripts/audit/run_invariants_fast_checks.sh` `SHELL_SCRIPTS[]` so syntactic breakage fails the no-DB fast gate in addition to the DB-backed assertions under `scripts/dev/pre_ci.sh`.
- Entity binding is enforced cryptographically (via `decision_hash = sha256(canonical_json(decision_payload))` recompute, where `decision_payload` carries `entity_type` and `entity_id`) but not yet structurally at insert time because `execution_records` does not carry `entity_type`/`entity_id` columns. The Wave 5 prerequisite closing this gap is tracked in `docs/plans/remediation/REM-2026-04-21_entity-binding-structural-enforcement/PLAN.md` (implementing wave: **Wave 5**).
- Invariant linkage (`INVARIANTS_MANIFEST.yml` + `INVARIANTS_IMPLEMENTED.md` for `INV-AUTH-TRANSITION-BINDING-01`) is registered by `TSK-P2-PREAUTH-004-03`, whose PR depends on this one.
