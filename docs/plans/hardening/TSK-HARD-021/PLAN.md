# TSK-HARD-021 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

- Implement canonical task pack requirements.
- Add verifier + schema contract.
- Generate evidence artifact.
- Run pre_ci before closeout.

failure_signature: HARDENING.REMEDIATION.TRACE.REQUIRED
origin_task_id: TSK-HARD-021

## repro_command
- RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh

## verification_commands_run
- bash scripts/audit/verify_tsk_hard_021.sh
- RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh

## final_status
- completed
