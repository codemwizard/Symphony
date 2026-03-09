# CMD-002 PLAN

Task: CMD-002
Owner role: SUPERVISOR
Depends on: CMD-001
failure_signature: PHASE1.CMD.002.REQUIRED

## objective
Command lifecycle integrity and dispatch eligibility

## scope
- Tighten idempotent resubmission semantics across pending/attempt/terminal states.
- Define dispatch-eligible vs held states explicitly and verifier-back them.
- Prove no illegal state regressions in the command lifecycle.

## acceptance_criteria
- Command lifecycle states are explicit and test-backed.
- Dispatch eligibility is deterministic.
- Duplicate submission behavior is stable and proven.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `python3 scripts/audit/validate_evidence.py --task CMD-002 --evidence evidence/command_integrity/cmd_002_command_lifecycle_integrity.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## no_touch_warnings
- Do not introduce projections in this task.
- Do not mix query concerns into command lifecycle fixes.

## evidence_output
- `evidence/command_integrity/cmd_002_command_lifecycle_integrity.json`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `python3 scripts/audit/validate_evidence.py --task CMD-002 --evidence evidence/command_integrity/cmd_002_command_lifecycle_integrity.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
