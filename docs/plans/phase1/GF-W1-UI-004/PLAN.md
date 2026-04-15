# GF-W1-UI-004 Implementation Plan

## Failure Signature
`PHASE1.GF-W1.UI-004.TOKEN_ISSUANCE_LOGIC`

## Objective

Implement token issuance logic that calls the backend API, displays token results with security properties, generates worker landing URLs, and provides a countdown timer for token expiry visibility.

## Pre-conditions

1. GF-W1-UI-003 (worker lookup form) is complete
2. Worker validation confirms supplier_type=WORKER
3. POST /pilot-demo/api/evidence-links/issue endpoint is functional

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add issueToken(), token result panel, URL generation, copy button, security properties, countdown timer |
| `evidence/phase1/gf_w1_ui_004.json` | CREATE | Evidence file |

## Stop Conditions

1. Token expiry hardcoded instead of from API response
2. Raw GPS coordinates displayed in token result
3. Countdown timer not implemented or not updating
4. Worker landing URL format incorrect (token not in hash fragment)
5. Copy button not functional

## Implementation Steps

### Step 1: Implement issueToken Function
**Tracking ID:** W1  
**What:** Implement issueToken() calling POST /pilot-demo/api/evidence-links/issue  
**How:** Add async function with fetch(), pass worker_id, handle response  
**Done-when:** Function calls API, receives token, parses response

### Step 2: Add Token Result Panel
**Tracking ID:** W2  
**What:** Add token result display panel  
**How:** Add div showing worker_id, expiry, neighbourhood label, radius  
**Done-when:** Panel displays all token details with neighbourhood label

### Step 3: Generate Worker Landing URL
**Tracking ID:** W3  
**What:** Generate worker landing page URL with token in hash fragment  
**How:** Construct URL as `/pilot-demo/worker-landing#token=${tokenValue}`  
**Done-when:** URL is correctly formatted with token in hash

### Step 4: Add Copy Link Button
**Tracking ID:** W4  
**What:** Add Copy Link button with clipboard integration  
**How:** Add button with onclick calling navigator.clipboard.writeText(url)  
**Done-when:** Button copies URL to clipboard, shows success message

### Step 5: Add Security Properties Panel
**Tracking ID:** W5  
**What:** Add security properties panel  
**How:** Add div showing type, signature, TTL, GPS lock, single-use  
**Done-when:** Panel displays all 5 security properties

### Step 6: Implement Countdown Timer
**Tracking ID:** W6  
**What:** Implement countdown timer updating every second  
**How:** Add setInterval(1000) calculating time remaining, show EXPIRED in red when <= 0  
**Done-when:** Timer updates every second, shows EXPIRED when time runs out

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'issueToken' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm issueToken function exists |
| V2 | `grep -q 'navigator.clipboard.writeText' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm clipboard integration |
| V3 | `grep -q 'setInterval.*1000' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm countdown timer |

## Evidence Contract

```json
{
  "task_id": "GF-W1-UI-004",
  "timestamp": "ISO8601",
  "token_issuance_api_integrated": true,
  "token_result_panel_present": true,
  "worker_landing_url_generated": true,
  "copy_link_functional": true,
  "security_properties_displayed": true,
  "countdown_timer_implemented": true
}
```

## Rollback

1. Revert changes to `src/supervisory-dashboard/index.html`
2. Delete `evidence/phase1/gf_w1_ui_004.json`

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Token expiry hardcoded | FUNCTIONAL.INCORRECT_EXPIRY_TIME | Use API response expiry field |
| Raw GPS displayed | UI.DESIGN_VIOLATION | Use resolveNeighbourhoodLabel() |
| Timer not updating | FUNCTIONAL.NO_EXPIRY_VISIBILITY | Test setInterval execution |
| URL format incorrect | FUNCTIONAL.TOKEN_UNUSABLE | Test URL with worker landing page |
