# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.AUDIT.GATES

origin_gate_id: pre_ci.phase0_ordered_checks
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/audit/verify_drd_casefile.sh --clear
final_status: OPEN

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Initial Hypotheses
- The PRECI.AUDIT.GATES failure and subsequent DRD lockout were triggered by the out-of-band creation of `schema/migrations/0204_remove_app_bypass_rls_from_policies.sql` without running `scripts/db/generate_baseline_snapshot.sh` to update the canonical baseline hash. This caused a structural drift detection which escalated to a pipeline lockout due to consecutive un-remediated failures.
