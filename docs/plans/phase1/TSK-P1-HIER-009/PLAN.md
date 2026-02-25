# TSK-P1-HIER-009 PLAN

Task: TSK-P1-HIER-009
Owner role: SUPERVISOR
Depends on: TSK-P1-HIER-008
failure_signature: PHASE1.TSK.P1.HIER.009.SQLSTATE_MAPPING_EXHAUSTIVE

## objective
Enforce the canonical SQLSTATE mapping for `verify_instruction_hierarchy()` and verify each
declared failure path with deterministic test fixtures and evidence:
- tenant->participant: `P7299`
- participant->program: `P7300`
- program->entity: `P7301`
- entity->member: `P7302`
- member->device: `P7303`

## implementation
- Add forward-only migration to align `verify_instruction_hierarchy()` SQLSTATE assignments.
- Add verifier `scripts/db/verify_hier_009_instruction_hierarchy_sqlstates.sh` that:
  - executes known-bad link fixtures for each declared failure path;
  - captures SQLSTATE for each case;
  - writes `sqlstate_mapping_verified: [{link, expected, actual, pass}]`;
  - documents reserved SQLSTATE gaps `P7304-P7307`.
- Wire evidence path and verifier into task metadata and Phase-1 contract.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/db/verify_hier_009_instruction_hierarchy_sqlstates.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-HIER-009 --evidence evidence/phase1/hier_009_instruction_hierarchy_sqlstates.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
