# PROJ-001 PLAN

Task: PROJ-001
Owner role: SUPERVISOR
Depends on: CQRS-001, CMD-002
failure_signature: PHASE1.PROJ.001.REQUIRED

## objective
First projection set

## scope
- Create initial projection schemas: instruction status, evidence bundle, escrow summary, IPDR/dispute case, and member/program summary.
- Define deterministic projection updater paths from command-side durable state/events.
- Expose freshness metadata in projection models and responses.

## acceptance_criteria
- Each initial projection has schema, updater, and query model.
- Projection update path is deterministic and test-backed.
- Projection freshness semantics are visible in models/responses.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/db/verify_projection_freshness_and_scope.sh`
- `dotnet test services/ledger-api/dotnet/tests --filter Projection`
- `python3 scripts/audit/validate_evidence.py --task PROJ-001 --evidence evidence/phase1/proj_001_initial_projection_set.json`

## no_touch_warnings
- Do not put projection update logic inline between attestation and outbox creation.
- Do not let projection convenience shape command-table schema prematurely.

## evidence_output
- `evidence/phase1/proj_001_initial_projection_set.json`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/db/verify_projection_freshness_and_scope.sh`
- `dotnet test services/ledger-api/dotnet/tests --filter Projection`
- `python3 scripts/audit/validate_evidence.py --task PROJ-001 --evidence evidence/phase1/proj_001_initial_projection_set.json`
