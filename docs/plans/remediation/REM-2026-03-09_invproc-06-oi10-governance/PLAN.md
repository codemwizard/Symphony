# Remediation Plan

failure_signature: GOVERNANCE.INVPROC06.OI10.CI_CLOSEOUT_AND_HUMAN_REVIEW
origin_task_id: TASK-INVPROC-06|TASK-OI-10
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Summary
- Wire invariant-process governance closeout verification into CI/local gating.
- Bind mandatory human governance review to branch approval artifacts and approval metadata.
- Keep Phase-1 contract and evidence registry aligned with the new governance evidence outputs.

## Reproduction
repro_command: scripts/dev/pre_ci.sh

## Verification Commands
verification_commands_run:
- bash scripts/audit/verify_invproc_06_ci_wiring_closeout.sh
- bash scripts/audit/verify_human_governance_review_signoff.sh
- bash scripts/audit/run_invariants_fast_checks.sh
- scripts/dev/pre_ci.sh
