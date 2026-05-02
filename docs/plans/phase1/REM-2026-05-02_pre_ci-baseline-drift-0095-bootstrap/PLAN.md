# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Scope
- Record the fail## Final Root Cause
The addition of five RLS metadata tables (`_rls_table_config`, `_preserved_policies`, etc.) directly into migration `0095_rls_dual_policy_architecture.sql` caused the ephemeral CI database schema to drift from the canonical `schema/baseline.sql`. The `pre_ci.sh` pipeline correctly detected this discrepancy and blocked the push to maintain schema integrity.

## Final Solution Summary
- Performed an intentional baseline refresh by recreating the database from migrations and generating a new `schema/baseline.sql`.
- The new baseline now includes the required RLS infrastructure tables, satisfying the `PRECI.DB.ENVIRONMENT` gate.
- This update is justified by the remediation of migration `0095` (deterministic bootstrapping), fulfilling the policy requirement that baseline changes must be accompanied by a migration change.
.

## Initial Hypotheses
- pending
