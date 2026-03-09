# CQRS-002 PLAN

Task: CQRS-002
Owner role: SUPERVISOR
Depends on: CQRS-001
failure_signature: PHASE1.CQRS.002.REQUIRED

## objective
Command-side and query-side DB role separation

## scope
- Define command-side DB role with mutation rights restricted to command-side surfaces.
- Define query-side DB role with read-only access restricted to projection/read surfaces.
- Bind store code to the correct role paths and document allowed surfaces.

## acceptance_criteria
- Query role cannot mutate data.
- Query role is scoped to projections/read models where available.
- Command role and query role separation is documented and testable.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/db/verify_command_query_role_separation.sh`
- `python3 scripts/audit/validate_evidence.py --task CQRS-002 --evidence evidence/phase1/cqrs_002_db_role_separation.json`

## no_touch_warnings
- Do not weaken existing RLS to make this task easier.
- Do not grant query roles access to write tables to preserve old read shortcuts.

## evidence_output
- `evidence/phase1/cqrs_002_db_role_separation.json`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/db/verify_command_query_role_separation.sh`
- `python3 scripts/audit/validate_evidence.py --task CQRS-002 --evidence evidence/phase1/cqrs_002_db_role_separation.json`
