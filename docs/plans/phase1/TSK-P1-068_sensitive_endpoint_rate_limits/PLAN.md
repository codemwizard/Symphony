# TSK-P1-068 Plan

## Mission
Add endpoint-specific rate limiting for sensitive surfaces.

## Constraints
- Do not weaken existing access-control or tenant-boundary semantics.
- Protected endpoints must have explicit and testable policy assignment.

## Verification Commands
- `bash scripts/audit/run_security_fast_checks.sh`
- `rg -n "RateLimiter|RequireRateLimiting|rate limit" services/ledger-api/dotnet/src/LedgerApi/Program.cs`

## Evidence Paths
- `evidence/phase0/security_secure_config_lint.json`
