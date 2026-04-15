---
failure_signature: PRECI.AUDIT.PII_LEAKAGE
root_cause: Phone number passed as URL query parameter in worker lookup endpoint (src/supervisory-dashboard/index.html:4625), violating PII handling policy. Phone numbers in URL query parameters are logged in web server access logs, creating compliance and security risk.
---

# REM-2026-04-08_pii_leakage_worker_lookup Implementation Plan

## Failure Signature
`PRECI.AUDIT.PII_LEAKAGE`

## Objective
Fix PII leakage violation by moving phone number from URL query parameter to POST request body for worker lookup endpoint.

## Root Cause
Phone number is passed as a URL query parameter in the worker lookup API call:
```javascript
const response = await fetch(`/pilot-demo/api/workers/lookup?phone=${encodeURIComponent(phone)}`, {
  method: 'GET',
  credentials: 'include'
});
```

This violates PII handling policy because:
1. Phone numbers in URL query parameters are logged in web server access logs
2. URLs may be cached by proxies, CDNs, or browser history
3. URLs may appear in referrer headers when navigating to other pages
4. Creates compliance risk for data privacy regulations

## Pre-conditions
1. Current implementation uses GET with phone in query parameter
2. Backend endpoint `/pilot-demo/api/workers/lookup` accepts GET requests
3. PII leakage lint gate blocks pre_ci passage

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Change worker lookup to POST with phone in request body |
| `services/ledger-api/dotnet/src/LedgerApi/Program.cs` | MODIFY | Update worker lookup endpoint to accept POST with JSON body |
| `scripts/audit/lint_pii_leakage_payloads.sh` | VERIFY | Confirm PII leakage lint passes after fix |
| `evidence/phase1/rem_2026_04_08_pii_leakage_worker_lookup.json` | CREATE | Evidence file |

## Stop Conditions
1. Phone number still in URL query parameter
2. Backend endpoint still accepts GET instead of POST
3. Request body not properly formatted as JSON
4. PII leakage lint still fails
5. Worker lookup functionality broken

## Implementation Steps

### Step 1: Update Frontend to Use POST with JSON Body
**Tracking ID:** W1  
**What:** Change worker lookup API call from GET with query parameter to POST with JSON body  
**How:** 
- Change method from 'GET' to 'POST'
- Add 'Content-Type': 'application/json' header
- Move phone from URL query parameter to JSON request body
- Keep credentials: 'include' for session cookie  
**Done-when:** 
- Frontend sends POST request with `{"phone": "+260971100001"}` in body
- No phone number in URL
- grep confirms no `?phone=` pattern in worker lookup call

### Step 2: Update Backend Endpoint to Accept POST
**Tracking ID:** W2  
**What:** Modify `/pilot-demo/api/workers/lookup` endpoint to accept POST with JSON body  
**How:**
- Change endpoint from MapGet to MapPost
- Read phone from JSON request body instead of query parameter
- Maintain same response format and error handling
- Keep session cookie authentication  
**Done-when:**
- Endpoint accepts POST requests with JSON body
- Endpoint returns same worker data as before
- Endpoint rejects GET requests (or deprecate gracefully)
- grep confirms endpoint uses MapPost and reads from request body

### Step 3: Verify PII Leakage Lint Passes
**Tracking ID:** W3  
**What:** Run PII leakage lint to confirm phone number no longer in URL  
**How:** Execute `bash scripts/audit/lint_pii_leakage_payloads.sh`  
**Done-when:**
- Lint exits 0 (success)
- Evidence file shows status: "PASS"
- No findings for phone in URL query parameter

### Step 4: Test Worker Lookup Functionality
**Tracking ID:** W4  
**What:** Verify worker lookup still works correctly after changes  
**How:**
- Test valid worker lookup (worker-chunga-001)
- Test invalid worker (404 error)
- Test worker with wrong supplier_type
- Test inactive worker  
**Done-when:**
- All test scenarios pass
- Error handling works correctly
- Token issuance flow continues to work

### Step 5: Run Full Pre-CI
**Tracking ID:** W5  
**What:** Verify all pre_ci gates pass  
**How:** Execute `PRE_CI_CONTEXT=1 SKIP_DOTNET_QUALITY_LINT=1 bash scripts/dev/pre_ci.sh`  
**Done-when:**
- pre_ci exits 0
- PII leakage lint passes
- No new failures introduced

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'method.*POST' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm frontend uses POST |
| V2 | `grep -q 'Content-Type.*application/json' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm JSON content type |
| V3 | `! grep -q '/workers/lookup?phone=' src/supervisory-dashboard/index.html` | Confirm no phone in URL |
| V4 | `grep -q 'MapPost.*workers/lookup' services/ledger-api/dotnet/src/LedgerApi/Program.cs \|\| exit 1` | Confirm backend uses POST |
| V5 | `bash scripts/audit/lint_pii_leakage_payloads.sh \|\| exit 1` | Confirm PII lint passes |
| V6 | `test -f evidence/phase0/pii_leakage_payloads.json \|\| exit 1` | Confirm evidence exists |
| V7 | `cat evidence/phase0/pii_leakage_payloads.json \| grep '"status": "PASS"' \|\| exit 1` | Confirm PASS status |

## Evidence Contract

```json
{
  "task_id": "REM-2026-04-08_pii_leakage_worker_lookup",
  "timestamp": "ISO8601",
  "git_sha": "string",
  "status": "PASS",
  "frontend_updated": true,
  "backend_updated": true,
  "pii_lint_passed": true,
  "worker_lookup_tested": true,
  "checks": [
    {
      "id": "frontend_post_method",
      "status": "PASS",
      "command": "grep -q 'method.*POST' src/supervisory-dashboard/index.html"
    },
    {
      "id": "no_phone_in_url",
      "status": "PASS",
      "command": "! grep -q '/workers/lookup?phone=' src/supervisory-dashboard/index.html"
    },
    {
      "id": "backend_post_endpoint",
      "status": "PASS",
      "command": "grep -q 'MapPost.*workers/lookup' services/ledger-api/dotnet/src/LedgerApi/Program.cs"
    },
    {
      "id": "pii_leakage_lint",
      "status": "PASS",
      "command": "bash scripts/audit/lint_pii_leakage_payloads.sh"
    }
  ],
  "observed_paths": [
    "src/supervisory-dashboard/index.html",
    "services/ledger-api/dotnet/src/LedgerApi/Program.cs",
    "evidence/phase0/pii_leakage_payloads.json"
  ],
  "command_outputs": {},
  "execution_trace": []
}
```

## Rollback

1. Revert changes to `src/supervisory-dashboard/index.html`
2. Revert changes to `services/ledger-api/dotnet/src/LedgerApi/Program.cs`
3. Delete `evidence/phase1/rem_2026_04_08_pii_leakage_worker_lookup.json`

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Worker lookup breaks | FUNCTIONAL.WORKER_TOKEN_ISSUANCE_BLOCKED | Test all scenarios before committing |
| Backend doesn't accept POST | FUNCTIONAL.API_MISMATCH | Update backend first, test locally |
| Session cookie not sent | FUNCTIONAL.AUTH_FAILURE | Verify credentials: 'include' preserved |
| Error handling breaks | FUNCTIONAL.NO_ERROR_MESSAGES | Test all error scenarios |

## Security Considerations

1. **PII Protection**: Phone number no longer logged in access logs
2. **No Caching**: POST requests not cached by default
3. **No Referrer Leakage**: Phone number not in URL, won't appear in referrer headers
4. **Compliance**: Meets data privacy requirements for PII handling

## Testing Checklist

- [ ] Valid worker lookup (worker-chunga-001) returns worker data
- [ ] Invalid worker (not registered) returns 404 error
- [ ] Worker with supplier_type != "WORKER" shows error
- [ ] Inactive worker shows error
- [ ] Token issuance flow works end-to-end
- [ ] PII leakage lint passes
- [ ] Full pre_ci passes

## Notes

This is a security remediation task addressing a pre-existing PII leakage violation discovered during meta.yml schema fixes. The issue blocks all pre_ci runs and represents a compliance risk. The fix is straightforward: move phone number from URL query parameter to POST request body.

The worker lookup endpoint is only used in the supervisory dashboard for token issuance. No other endpoints or UI components are affected.

## Status

PLANNED - Ready for implementation
