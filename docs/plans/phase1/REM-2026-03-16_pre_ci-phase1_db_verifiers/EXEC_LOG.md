# REMEDIATION EXEC LOG

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/security/lint_ddl_lock_risk.sh && scripts/dev/pre_ci.sh
final_status: PASS

- created_at_utc: 2026-03-16T09:56:11Z
- action: remediation casefile scaffold created
- action: generated SHA256 statement fingerprints for the 6 `ALTER TABLE ... ROW LEVEL SECURITY` statements added in `0076_onboarding_control_plane.sql`.
- action: added the 6 fingerprints (DDL-ALLOW-0056 to DDL-ALLOW-0061) to `docs/security/ddl_allowlist.json`.
- action: ran `scripts/security/lint_ddl_lock_risk.sh` locally to confirm the lock risk lint now passes cleanly.
- result: PASS
