# PROJ-002 EXEC_LOG

## status
completed

## summary
Cut over the external evidence-pack and reporting queries to projection-backed reads,
kept tenant/object authorization in place, and exposed `projection_version` and `as_of_utc`
so clients can distinguish current versus stale projected state.

## constraints
- Preserve Sprint-1 command durability proofs.
- Maintain tenant/object authorization rigor.
- Do not bypass command/query boundaries for convenience.

## planned_artifacts
- `services/ledger-api/dotnet/src/LedgerApi/Queries/`
- `services/ledger-api/dotnet/src/LedgerApi/ReadModels/`
- `services/ledger-api/dotnet/src/LedgerApi/Infrastructure/`
- `tasks/PROJ-002/meta.yml`
- `docs/plans/phase1/PROJ-002/PLAN.md`
- `docs/plans/phase1/PROJ-002/EXEC_LOG.md`
- `evidence/phase1/proj_002_external_query_cutover.json`

## evidence_target
- `evidence/phase1/proj_002_external_query_cutover.json`

## notes
If parity is incomplete, version the endpoint or keep it internal-only until trustworthy.

## commands_run
- `dotnet build services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -v minimal`
- `dotnet test services/ledger-api/dotnet/tests/LedgerApi.Tests/LedgerApi.Tests.csproj --filter QueryProjection -v minimal`
- `bash scripts/audit/verify_no_hot_table_external_reads.sh`
- `python3 scripts/audit/validate_evidence.py --task PROJ-002 --evidence evidence/phase1/proj_002_external_query_cutover.json`
