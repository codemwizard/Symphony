# TSK-P1-HIER-010 PLAN

Task: TSK-P1-HIER-010
Owner role: SUPERVISOR
Depends on: TSK-P1-HIER-009
failure_signature: PHASE1.TSK.P1.HIER.010.PROGRAM_MIGRATION_CONTRACT

## objective
Satisfy the HIER-010 contract for `program_migration_events` and
`migrate_person_to_program()` with deterministic, verifier-backed behavior:
- required event columns including `new_member_id` and `created_at`
- SECURITY DEFINER hardened migration function signature
- additive migration semantics (source member remains)
- stable SQLSTATE on duplicate call

## implementation
- Add migration `0057_hier_010_program_migration_contract_alignment.sql` to align
  table and function semantics with HIER-010 deliverables.
- Add verifier `scripts/db/verify_hier_010_program_migration.sh` to assert
  schema/function posture and runtime deterministic behavior.
- Wire evidence into pre_ci + phase contract + semantic-integrity registry.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/db/verify_hier_010_program_migration.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-HIER-010 --evidence evidence/phase1/hier_010_program_migration.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
