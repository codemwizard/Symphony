# R-015 EXEC_LOG

Task: R-015
Source of truth: docs/contracts/SECURITY_REMEDIATION_DOD.yml
Canonical reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## repro_command
- `dotnet test services/ledger-api/dotnet/tests/LedgerApi.Tests/LedgerApi.Tests.csproj --configuration Release --nologo`

## actions_taken
- Added xUnit bootstrap project at `services/ledger-api/dotnet/tests/LedgerApi.Tests`.
- Added tests for rate-limit partition key and chunked-body max-size guard behavior.
- Wired CI security job to run the new test project.
- Added evidence writer `scripts/audit/record_r015_test_bootstrap_evidence.sh`.

## verification_commands_run
- `dotnet test services/ledger-api/dotnet/tests/LedgerApi.Tests/LedgerApi.Tests.csproj --configuration Release --nologo`
- `SYMPHONY_ENV=development bash scripts/audit/record_r015_test_bootstrap_evidence.sh`

## final_status
- completed
