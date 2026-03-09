# CQRS-002 EXEC_LOG

## status
completed

## summary
Added additive CQRS projection tables plus `symphony_command` and `symphony_query`
roles, then verified the grants remain read-only on the query side and mutation-capable
only on the command side.

## constraints
- Preserve Sprint-1 command durability proofs.
- Maintain tenant/object authorization rigor.
- Do not bypass command/query boundaries for convenience.

## planned_artifacts
- `schema/migrations/`
- `services/ledger-api/dotnet/src/LedgerApi/Infrastructure/`
- `services/ledger-api/dotnet/src/LedgerApi/Queries/`
- `services/ledger-api/dotnet/src/LedgerApi/Commands/`
- `docs/security/`
- `tasks/CQRS-002/meta.yml`
- `docs/plans/phase1/CQRS-002/PLAN.md`
- `docs/plans/phase1/CQRS-002/EXEC_LOG.md`
- `evidence/phase1/cqrs_002_db_role_separation.json`

## evidence_target
- `evidence/phase1/cqrs_002_db_role_separation.json`

## notes
Use transitional internal-only exceptions with expiry instead of broad permanent grants.

## commands_run
- `dotnet build services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -v minimal`
- `bash scripts/db/verify_command_query_role_separation.sh`
- `python3 scripts/audit/validate_evidence.py --task CQRS-002 --evidence evidence/phase1/cqrs_002_db_role_separation.json`
