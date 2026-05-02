# REMEDIATION PLAN

failure_signature: PRECI.DB.ENVIRONMENT
root_cause: The Phase-2 verification scripts were incorrectly hardcoded to connect to the 'symphony' database instead of the ephemeral CI database ($DATABASE_URL), causing a 'data_authority_level ENUM does not exist' failure in the isolated CI environment.

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: bash scripts/db/verify_tsk_p2_preauth_006a_01.sh
final_status: CLOSED

## Scope
- Fix connection string logic in Phase-2 verification scripts to honor $DATABASE_URL.
- Remove hardcoded PGDATABASE overrides in pre_ci.sh.
