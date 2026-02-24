# TSK-OPS-DRD-001 PLAN

failure_signature: PHASE1.DRD.POLICY.CANONICALIZATION_REQUIRED
origin_task_id: TSK-OPS-DRD-001
repro_command: scripts/dev/pre_ci.sh

## Scope
- Add canonical DRD policy in `.agent/policies/`.
- Add agent policy index and human mirror with canonical precedence + sync stamp.

## verification_commands_run
- test -f .agent/policies/debug-remediation-policy.md
- test -f .agent/README.md
- test -f docs/process/debug-remediation-policy.md
