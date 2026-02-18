# TSK-P1-015 Execution Log

failure_signature: PHASE1.TSK.P1.015
origin_task_id: TSK-P1-015

## repro_command
`scripts/dev/pre_ci.sh`

## verification_commands_run
- `dotnet build services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -nologo -v minimal`
- `scripts/services/test_ingress_api_contract.sh`
- `scripts/audit/run_security_fast_checks.sh`
- `scripts/audit/run_invariants_fast_checks.sh`
- `scripts/dev/pre_ci.sh`

## final_status
COMPLETED

Plan: `docs/plans/phase1/TSK-P1-015_ingress_api_mvp_pilot_surface/PLAN.md`

## Final Summary
- Scaffolded initial .NET 10 ingress API service at `services/ledger-api/dotnet/src/LedgerApi`.
- Implemented fail-closed ingress handling with durable-store adapters (file mode for deterministic local tests; `psql` mode for DB-backed runtime path).
- Added deterministic self-test harness and wrapper script (`scripts/services/test_ingress_api_contract.sh`) generating:
  - `evidence/phase1/ingress_api_contract_tests.json`
  - `evidence/phase1/ingress_ack_attestation_semantics.json`
- Full `scripts/dev/pre_ci.sh` now passes with ingress contract evidence emitted deterministically.
