# CQRS-001 PLAN

Task: CQRS-001
Owner role: SUPERVISOR
Depends on: CMD-002, INV-002
failure_signature: PHASE1.CQRS.001.REQUIRED

## objective
Command/query code separation

## scope
- Extract command handlers from monolithic service bootstrap code and separate them from query handlers.
- Define command-side and query-side interfaces and namespaces/assemblies.
- Prevent new business logic from landing in monolithic bootstrap files.

## acceptance_criteria
- Command handlers and query handlers are physically separated in code.
- Bootstrap files no longer own large bodies of command/query logic.
- No command-side mutation logic is callable through query abstractions.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `dotnet build services/ledger-api/dotnet/src/LedgerApi`
- `dotnet test services/ledger-api/dotnet/tests`
- `python3 scripts/audit/validate_evidence.py --task CQRS-001 --evidence evidence/phase1/cqrs_001_code_separation.json`

## no_touch_warnings
- Do not redesign attestation/outbox logic in this task.
- Do not introduce projections yet unless needed as stubs/interfaces only.

## evidence_output
- `evidence/phase1/cqrs_001_code_separation.json`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `dotnet build services/ledger-api/dotnet/src/LedgerApi`
- `dotnet test services/ledger-api/dotnet/tests`
- `python3 scripts/audit/validate_evidence.py --task CQRS-001 --evidence evidence/phase1/cqrs_001_code_separation.json`
