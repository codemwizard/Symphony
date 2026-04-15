# Task Plan: TSK-P1-PLT-009B (Frontend Injection)

## Mission
Inject real database state into the Token Issuance UI to eliminate hardcoded data and allow issuance to real workers.

## Constraints
- **Graceful Failure**: If the worker lookup fails, display a clear message rather than an empty dropdown.
- **No Scope Creep**: Do not restyle the page; only inject missing data and align API calls.

## Proof Graph (ID Tracking)
- [ID tsk_p1_plt_009b_01] -> [ID tsk_p1_plt_009b_01]
- [ID tsk_p1_plt_009b_02] -> [ID tsk_p1_plt_009b_02]
- [ID tsk_p1_plt_009b_03] -> [ID tsk_p1_plt_009b_03]

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_plt_009b.sh`

## Evidence Paths
- `evidence/phase1/tsk_p1_plt_009b_frontend_injection.json`

## Stop Conditions
- Stop if the active tenant session cannot be resolved.
- Stop if the LedgerAPI returns a non-standard error for valid worker lookups.
