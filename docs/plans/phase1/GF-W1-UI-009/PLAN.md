# GF-W1-UI-009 Implementation Plan

## Failure Signature
`PHASE1.GF-W1.UI-009.TOKEN_E2E_VERIFICATION`

## Objective

Create end-to-end verification script testing complete worker token issuance lifecycle including issuance, submission, and security property enforcement.

## Pre-conditions

1. GF-W1-UI-004 (token issuance) is complete
2. POST /pilot-demo/api/evidence-links/issue endpoint is functional
3. Worker submission endpoint accepts tokens
4. Supervisory reveal endpoint is functional

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/dev/verify_worker_token_issuance_e2e.sh` | CREATE | End-to-end verification script |
| `evidence/phase1/worker_token_issuance_e2e.json` | CREATE | Evidence file |
| `.toolchain/script_integrity/verifier_hashes.sha256` | MODIFY | Add hash for new script |

## Stop Conditions

1. Script only tests happy path (no negative tests)
2. No evidence JSON emitted
3. Hardcoded tokens used instead of fresh issuance
4. Supervisory reveal not tested
5. Script does not exit 1 on failure

## Implementation Steps

### Step 1: Create Script File
**Tracking ID:** W1  
**What:** Create scripts/dev/verify_worker_token_issuance_e2e.sh  
**How:** Create executable shell script with shebang and set -eo pipefail  
**Done-when:** Script file exists and is executable

### Step 2: Implement Token Issuance Test
**Tracking ID:** W2  
**What:** Implement token issuance test  
**How:** Use curl to POST /pilot-demo/api/evidence-links/issue, verify HTTP 200, extract token  
**Done-when:** Token issued successfully, token value extracted

### Step 3: Implement Worker Submission Test
**Tracking ID:** W3  
**What:** Implement worker submission test using issued token  
**How:** Use curl to POST WEIGHBRIDGE_RECORD with token in Authorization header, verify HTTP 202  
**Done-when:** Submission succeeds with valid token

### Step 4: Implement Expiry Test
**Tracking ID:** W4  
**What:** Implement expiry enforcement test  
**How:** Issue token with 1-second TTL, wait 2 seconds, attempt submission, verify HTTP 401/403  
**Done-when:** Expired token is rejected

### Step 5: Implement Single-Use Test
**Tracking ID:** W5  
**What:** Implement single-use enforcement test  
**How:** Submit with token once (succeeds), attempt second submission with same token, verify rejection  
**Done-when:** Reused token is rejected

### Step 6: Implement GPS Validation Test
**Tracking ID:** W6  
**What:** Implement GPS validation test  
**How:** Submit with GPS coordinates outside 250m radius, verify rejection  
**Done-when:** Out-of-radius submission is rejected

### Step 7: Emit Evidence JSON
**Tracking ID:** W7  
**What:** Emit evidence JSON  
**How:** Write JSON with all test results to evidence/phase1/worker_token_issuance_e2e.json  
**Done-when:** Evidence file contains all required fields

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `test -x scripts/dev/verify_worker_token_issuance_e2e.sh \|\| exit 1` | Confirm script is executable |
| V2 | `bash scripts/dev/verify_worker_token_issuance_e2e.sh \|\| exit 1` | Confirm script passes |

## Evidence Contract

```json
{
  "task_id": "GF-W1-UI-009",
  "timestamp": "ISO8601",
  "token_issuance_success": true,
  "worker_submission_success": true,
  "supervisory_reveal_confirmed": true,
  "expiry_enforcement_confirmed": true,
  "single_use_enforcement_confirmed": true,
  "gps_validation_confirmed": true
}
```

## Rollback

1. Delete `scripts/dev/verify_worker_token_issuance_e2e.sh`
2. Delete `evidence/phase1/worker_token_issuance_e2e.json`
3. Revert `.toolchain/script_integrity/verifier_hashes.sha256`

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Only happy path tested | GOVERNANCE.INCOMPLETE_VERIFICATION | Add negative tests for expiry, single-use, GPS |
| No evidence JSON | GOVERNANCE.NO_AUDIT_TRAIL | Emit JSON with all test results |
| Hardcoded tokens | FUNCTIONAL.STALE_TEST_DATA | Issue fresh tokens via API |
| Supervisory reveal not tested | FUNCTIONAL.INCOMPLETE_E2E_TEST | Query reveal endpoint after submission |
