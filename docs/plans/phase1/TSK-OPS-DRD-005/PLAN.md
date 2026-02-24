# TSK-OPS-DRD-005 PLAN

failure_signature: PHASE1.DRD.ADVISORY_VERIFIER.MISSING
origin_task_id: TSK-OPS-DRD-005
repro_command: scripts/dev/pre_ci.sh

## Scope
- Add advisory-only DRD usage verifier with evidence output.
- No hard-fail behavior.

## verification_commands_run
- bash scripts/audit/verify_drd_policy_usage.sh evidence/phase0/drd_policy_usage.json
