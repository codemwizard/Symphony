# TSK-P1-068 Plan

Failure_Signature: PHASE1.API.SENSITIVE.RATE_LIMIT.MISSING
Origin_Task_ID: TSK-P1-068

## Mission
Add endpoint-specific rate limiting for sensitive surfaces.

## Constraints
- Do not weaken existing access-control or tenant-boundary semantics.
- Protected endpoints must have explicit and testable policy assignment.

## Verification Commands
- `bash scripts/audit/run_security_fast_checks.sh`
- `rg -n "RateLimiter|RequireRateLimiting|rate limit" services/ledger-api/dotnet/src/LedgerApi/Program.cs`

## Repro_Command
- `rg -n "RequireRateLimiting|AddPolicy\\(\"sensitive-endpoint\"" services/ledger-api/dotnet/src/LedgerApi/Program.cs`

## Evidence Paths
- `evidence/phase1/tsk_p1_068_sensitive_endpoint_rate_limits.json`
