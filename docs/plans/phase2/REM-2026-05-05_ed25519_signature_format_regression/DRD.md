# DRD: Ed25519 Signature Format Validation Regression

## Metadata
- Template Type: Full
- Incident Class: Cryptographic Enforcement Failure
- Severity: L2
- Status: Open
- Owner: SECURITY_GUARDIAN_AGENT
- Date Opened: 2026-05-05
- Date Resolved: TBD
- Task: TSK-P2-W8-DB-006-REM-04
- Branch: fix/ed25519-signature-format-regression
- Commit Range: TBD

## Summary
Validator accepts only 64 hex characters for NEW.signature, but Ed25519 signatures are 64 bytes (128 hex characters). This validation rejects valid signatures and breaks cryptographic enforcement trigger for correctly formed inputs on asset_batches.

## Impact
- Total delay: TBD minutes
- Failed attempts: 0 (proactive identification)
- Full reruns before convergence: N/A
- Runtime per rerun: N/A
- Estimated loop waste: N/A

## Timeline
| Window | Duration | First blocker | Notes |
|---|---:|---|---|
| 2026-05-05T09:18Z | TBD | Code review finding | Signature format validation identified |

## Diagnostic Trail
- First-fail artifacts: Code review of signature validation logic
- Commands: 
  - `grep -n -A 2 -B 2 "signature.*hex.*64" schema/migrations/*.sql`
  - `grep -n "Ed25519" docs/contracts/ED25519_SIGNING_CONTRACT.md`

## Root Causes
1. Validator author confused byte length with hex character length
2. Ed25519 signatures are 64 bytes = 128 hex characters, not 64 hex characters
3. Validation logic rejects legitimate cryptographic signatures
4. No verification against Ed25519 specification during implementation

## Contributing Factors
1. Insufficient understanding of Ed25519 signature encoding
2. Missing reference to cryptographic contract specifications
3. No automated testing with actual Ed25519 signatures
4. Lack of code review by cryptographic domain expert

## Recovery Loop Failure Analysis
N/A - Proactive identification before deployment prevents recovery loop

## What Unblocked Recovery
Proactive code review identified regression before deployment

## Corrective Actions Taken
- Files changed: TBD (signature validation logic to be corrected)
- Commands run: TBD (cryptographic verification tests and baseline checks to be run)

## Prevention Actions
| Action | Owner | Enforcement | Metric | Status | Target Date |
|---|---|---|---|---|
| Crypto spec reference requirement | SECURITY_GUARDIAN_AGENT | Mandatory pre-merge | Open | 2026-05-05 |
| Ed25519 test vectors in CI | SECURITY_GUARDIAN_AGENT | Automated test | Open | 2026-05-05 |
| Cryptographic domain review | SECURITY_GUARDIAN_AGENT | Human review | Open | 2026-05-05 |

## Early Warning Signs
- Signature validation changes without reference to cryptographic contracts
- Hard-coded validation lengths without specification backing

## Decision Points
- Whether to update validation to accept 128 hex characters or validate byte length
- Whether to add comprehensive Ed25519 test suite

## Verification Outcomes
- Command: TBD (cryptographic verification script with baseline drift check)
- Result: TBD

## Open Risks / Follow-ups
- Risk of legitimate signatures being rejected if deployed
- Need to verify all other cryptographic validations are correct
- Potential impact on asset_batches dispatcher functionality

## Bottom Line
Critical cryptographic enforcement regression that would break signed dispatcher path for valid Ed25519 signatures. Must be fixed before deployment to maintain cryptographic integrity guarantees.
