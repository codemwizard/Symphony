# TSK-P1-066 Plan

Failure_Signature: PHASE1.INGRESS.AMOUNT.BOUNDS.MISSING
Origin_Task_ID: TSK-P1-066

## Mission
Enforce bounded amount validation on ingress commands.

## Constraints
- Validation must stay deterministic and client-visible semantics must remain explicit.
- Boundary coverage must include negative tests.

## Verification Commands
- `bash scripts/dev/pre_ci.sh`
- `rg -n "amount_minor" services/ledger-api/dotnet/src/LedgerApi/Commands/IngressAndKycHandlers.cs`

## Repro_Command
- `rg -n "amount_minor" services/ledger-api/dotnet/src/LedgerApi/Commands/IngressAndKycHandlers.cs`

## Evidence Paths
- `evidence/phase1/ingress_api_contract_tests.json`
