# TSK-P1-067 Plan

Failure_Signature: PHASE1.DB.ERROR.LEAKAGE
Origin_Task_ID: TSK-P1-067

## Mission
Sanitize database failure messages at client boundaries.

## Constraints
- Preserve operator-grade diagnostics without leaking raw DB internals to clients.

## Verification Commands
- `bash scripts/audit/run_security_fast_checks.sh`
- `rg -n "Database operation failed|ex.Message" services/ledger-api/dotnet/src/LedgerApi/Infrastructure/Stores.cs`

## Repro_Command
- `rg -n "Fail\\(ex.Message\\)|db_failed:\\{ex.Message\\}" services/ledger-api/dotnet/src/LedgerApi/Infrastructure/Stores.cs`

## Evidence Paths
- `evidence/phase1/tsk_p1_067_db_error_sanitization.json`
