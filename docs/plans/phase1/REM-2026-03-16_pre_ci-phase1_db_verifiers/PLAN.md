# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/security/lint_ddl_lock_risk.sh && scripts/dev/pre_ci.sh
final_status: PASS

## Scope
- The `lint_ddl_lock_risk.sh` script failed on `0076_onboarding_control_plane.sql` because it uses `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`.
- `ALTER TABLE` is restricted by default, but RLS application is required for tenant isolation and is standard Phase-0 policy.

## Initial Hypotheses
- We need to add the 6 `ALTER TABLE` statement fingerprints to `docs/security/ddl_allowlist.json` to waive the lint for these specific RLS commands.
