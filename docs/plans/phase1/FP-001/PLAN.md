# FP-001 PLAN

Task: FP-001
Owner role: SUPERVISOR
Depends on: none
failure_signature: PHASE1.FP.001.REQUIRED

## objective
Architecture freeze and no-touch zone control

## scope
- Define Sprint-1 no-touch zones protecting DB invariants, append-only evidence, and tenant isolation.
- Define exception/rollback policy for architecture-affecting changes.
- Require every Sprint-1 change to declare blast radius and no-touch status.

## acceptance_criteria
- Architecture freeze docs exist and are repo-specific.
- No-touch zones, allowed-refactor zones, and exception template are published.
- Rollback guidance exists for code, schema, and CI-rule changes.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `python3 scripts/audit/validate_evidence.py --task FP-001 --evidence evidence/program/fp_001_architecture_freeze.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## no_touch_warnings
- Do not alter runtime code or DB schema under this task.

## evidence_output
- `evidence/program/fp_001_architecture_freeze.json`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `python3 scripts/audit/validate_evidence.py --task FP-001 --evidence evidence/program/fp_001_architecture_freeze.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
