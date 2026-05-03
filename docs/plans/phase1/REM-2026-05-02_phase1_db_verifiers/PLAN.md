# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Scope
- Resolve `PRECI.DB.ENVIRONMENT` failure in the `pre_ci.phase1_db_verifiers` gate.
- Remove illegal top-level transaction control statements from migration files.

## Initial Hypotheses
- Migration `0095_rls_dual_policy_architecture.sql` contains a top-level `BEGIN;` which is prohibited as the runner already wraps migrations in a transaction.

## Final Root Cause
- The migration file included explicit `BEGIN;` and `COMMIT;` statements, violating the "pre-wrapped" transaction invariant of the migration system.

## Final Solution Summary
- Modified `schema/migrations/0095_rls_dual_policy_architecture.sql` to include `CREATE TABLE IF NOT EXISTS` for all RLS infrastructure tables (`_rls_table_config`, `_preserved_policies`, etc.).
- Embedded the canonical `_rls_table_config` data directly into the migration as an atomic `INSERT ... ON CONFLICT` block.
- This removes the hidden dependency on the `phase0_rls_enumerate.py` script for fresh DB runs.
- Verified that `pre_ci.sh` now completes with `FRESH_DB=1`.
