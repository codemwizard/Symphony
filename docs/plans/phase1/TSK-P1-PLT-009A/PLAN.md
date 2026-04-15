# Task Plan: TSK-P1-PLT-009A (Backend Alignment)

## Mission
Ensure the Token Issuance API returns an authoritative `sequence_number` to allow real-time UI/Ledger alignment.

## Constraints
- **Least Privilege**: Only modify `commands` layer, not core `domain`.
- **Fail Securely**: If the dispatch log lookup fails, return an error rather than a partial response.

## Proof Graph (ID Tracking)
## Proof Graph (ID Tracking)
- [ID tsk_p1_plt_009a_01] -> [ID tsk_p1_plt_009a_01]
- [ID tsk_p1_plt_009a_02] -> [ID tsk_p1_plt_009a_02]

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_plt_009a.sh`

## Evidence Paths
- `evidence/phase1/tsk_p1_plt_009a_response_alignment.json`

## Stop Conditions
- Stop if `EvidenceLinkSmsDispatchLog` is not available.
- Stop if the response schema diverges from existing pilot-API standards.
