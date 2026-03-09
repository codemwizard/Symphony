# TSK-P1-067 Plan

## Mission
Sanitize database failure messages at client boundaries.

## Constraints
- Preserve operator-grade diagnostics without leaking raw DB internals to clients.

## Verification Commands
- `bash scripts/audit/run_security_fast_checks.sh`
- `rg -n "Database operation failed|ex.Message" services/ledger-api/dotnet/src/LedgerApi/Infrastructure/Stores.cs`

## Evidence Paths
- `evidence/phase0/security_insecure_patterns.json`
