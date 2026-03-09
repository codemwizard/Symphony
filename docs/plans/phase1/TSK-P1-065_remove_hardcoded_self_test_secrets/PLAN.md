# TSK-P1-065 Plan

## Mission
Remove hardcoded self-test secrets from production-path code surfaces.

## Constraints
- Self-tests must remain runnable with explicit, non-hardcoded configuration.
- No fallback secret may silently enable production-path execution.

## Verification Commands
- `bash scripts/audit/run_security_fast_checks.sh`
- `rg -n "test-api-key|signing key|secret" services/ledger-api/dotnet/src/LedgerApi/Program.cs`

## Evidence Paths
- `evidence/phase0/security_secrets_scan.json`
- `evidence/phase0/security_insecure_patterns.json`
