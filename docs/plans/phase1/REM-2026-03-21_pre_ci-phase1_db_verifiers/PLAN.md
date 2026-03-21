# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/dev/pre_ci.sh
final_status: RESOLVED

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.
- The `DB-BASELINE-DRIFT` gate failed because migration 0077 was added but the canonical baseline schema was not regenerated.

## Initial Hypotheses
- Regenerate the baseline using `generate_baseline_snapshot.sh` to include the new RLS control-plane tables.
