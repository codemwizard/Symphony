# GF-W1-UI-011 Implementation Plan

## Failure Signature
`PHASE1.GF-W1.UI-011.WORKER_TOKEN_INTEGRATION_TEST`

## Objective

Perform comprehensive integration testing of the complete worker token issuance flow including all UI components, error states, and edge cases.

## Pre-conditions

1. GF-W1-UI-007 (token revocation) is complete
2. All worker token issuance UI components are implemented
3. Backend API endpoints are functional
4. Test workers exist in registry (worker-chunga-001, worker-chunga-002)

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `evidence/phase1/gf_w1_ui_011_integration_test_results.json` | CREATE | Document test results |

## Stop Conditions

1. Only happy path tested (no error states)
2. Timer accuracy not verified
3. Expiry not tested (didn't wait for expiry)
4. Test results not documented
5. Negative tests not performed

## Implementation Steps

### Step 1: Test Valid Worker Issuance
**Tracking ID:** W1  
**What:** Test token issuance for valid worker  
**How:** Enter +260971100001, verify worker details display, click Request Collection Token, verify token result  
**Done-when:** Token issued successfully, all details displayed correctly

### Step 2: Test Invalid Worker Scenarios
**Tracking ID:** W2  
**What:** Test token issuance for invalid workers  
**How:** Test: unregistered phone (404), wrong supplier_type (!= WORKER), inactive status  
**Done-when:** All error scenarios show appropriate error messages

### Step 3: Test Worker Landing Page
**Tracking ID:** W3  
**What:** Test worker landing page with issued token  
**How:** Copy token URL, open in new tab, verify page loads, submit WEIGHBRIDGE_RECORD  
**Done-when:** Landing page works with token, submission succeeds

### Step 4: Test Token Expiry
**Tracking ID:** W4  
**What:** Test token expiry enforcement  
**How:** Issue token with 5-minute TTL, wait 5 minutes, verify status changes to EXPIRED  
**Done-when:** Token shows EXPIRED status after expiry time

### Step 5: Test Token Revocation
**Tracking ID:** W5  
**What:** Test token revocation  
**How:** Issue token, click Revoke in detail panel, confirm dialog, verify REVOKED status  
**Done-when:** Token revoked successfully, status updated immediately

### Step 6: Test Recent Tokens List
**Tracking ID:** W6  
**What:** Test recent tokens list updates  
**How:** Issue multiple tokens, verify list updates, verify max 10 items, verify status chips  
**Done-when:** List updates correctly, shows correct statuses

### Step 7: Test Countdown Timer
**Tracking ID:** W7  
**What:** Test countdown timer accuracy  
**How:** Issue token, observe timer for 60 seconds, verify it updates every second  
**Done-when:** Timer updates accurately every second

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `test -f evidence/phase1/gf_w1_ui_011_integration_test_results.json \|\| exit 1` | Confirm test results documented |

## Evidence Contract

```json
{
  "task_id": "GF-W1-UI-011",
  "timestamp": "ISO8601",
  "valid_worker_issuance_tested": true,
  "invalid_worker_errors_tested": true,
  "worker_landing_page_tested": true,
  "token_expiry_tested": true,
  "token_revocation_tested": true,
  "recent_tokens_list_tested": true,
  "countdown_timer_tested": true,
  "test_scenarios": [
    {"scenario": "valid_worker", "result": "PASS"},
    {"scenario": "unregistered_worker", "result": "PASS"},
    {"scenario": "wrong_supplier_type", "result": "PASS"},
    {"scenario": "inactive_worker", "result": "PASS"},
    {"scenario": "worker_landing_page", "result": "PASS"},
    {"scenario": "token_expiry", "result": "PASS"},
    {"scenario": "token_revocation", "result": "PASS"},
    {"scenario": "recent_tokens_list", "result": "PASS"},
    {"scenario": "countdown_timer", "result": "PASS"}
  ]
}
```

## Rollback

1. Delete `evidence/phase1/gf_w1_ui_011_integration_test_results.json`

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Only happy path tested | GOVERNANCE.INCOMPLETE_TESTING | Test all error scenarios |
| Timer not verified | FUNCTIONAL.TIMER_DRIFT_UNDETECTED | Observe timer for 60 seconds |
| Expiry not tested | FUNCTIONAL.EXPIRY_ENFORCEMENT_UNVERIFIED | Wait for expiry and verify |
| Results not documented | GOVERNANCE.NO_TEST_EVIDENCE | Create evidence JSON with all results |
