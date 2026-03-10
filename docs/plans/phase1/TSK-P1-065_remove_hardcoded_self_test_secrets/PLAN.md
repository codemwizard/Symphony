# TSK-P1-065 Plan

Failure_Signature: PHASE1.SECURITY.SELFTEST.SECRET.FALLBACK
Origin_Task_ID: TSK-P1-065

## Mission
Remove hardcoded self-test secrets from production-path code surfaces.

## Constraints
- Self-tests must remain runnable with explicit, non-hardcoded configuration.
- No fallback secret may silently enable production-path execution.

## Verification Commands
- `bash scripts/audit/run_security_fast_checks.sh`
- `bash scripts/audit/verify_tsk_p1_065.sh`

## Repro_Command
- `rg -n "tenant-context-self-test-key|pilot-self-test-key|ten-003-admin-key|phase1-reg-00[23]-self-test-key" services/ledger-api/dotnet/src/LedgerApi/Program.cs`

## Evidence Paths
- `evidence/phase1/tsk_p1_065_selftest_secret_posture.json`
