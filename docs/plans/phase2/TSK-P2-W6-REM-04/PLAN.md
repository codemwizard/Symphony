# TSK-P2-W6-REM-04: API Input Contract Rejection

## Objective
Remediate Wave 6 implementation gap (GAP-W6-006).

## Implementation Steps
- [ ] Update C# Handlers in `services/ledger-api/dotnet/src/LedgerApi/Models/` to reject any payload containing `data_authority_level` during POST/PUT operations.
- [ ] The rejection logic must return an HTTP 400 Bad Request.

## Verification
- [ ] Write a verification script `scripts/audit/verify_api_input_contract.sh`.
- [ ] **MANDATORY**: The negative test must assert that the API returns the exact error string: `"authority fields are read-only"`. Any other error string is considered a failure.
