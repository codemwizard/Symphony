# GF-W1-UI-005 Implementation Plan

## Failure Signature
`PHASE1.GF-W1.UI-005.RECENT_TOKENS_LIST`

## Objective

Implement recent tokens list showing last 10 issued tokens with dynamic status calculation and expiry display to provide operators with token issuance history visibility.

## Pre-conditions

1. GF-W1-UI-004 (token issuance logic) is complete
2. Token issuance successfully returns token data
3. Two-column layout has right column placeholder for recent tokens

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add recentTokens array, addToRecentTokens(), renderRecentTokens(), status calculation, click handler |
| `evidence/phase1/gf_w1_ui_005.json` | CREATE | Evidence file |

## Stop Conditions

1. Tokens stored in localStorage (must be in-memory only)
2. Status not calculated dynamically (hardcoded)
3. List shows more than 10 tokens
4. Status chips not color-coded
5. Click handler not wired

## Implementation Steps

### Step 1: Create recentTokens Array
**Tracking ID:** W1  
**What:** Create in-memory recentTokens array  
**How:** Add `let recentTokens = [];` at top of script section  
**Done-when:** Array exists and is accessible

### Step 2: Implement addToRecentTokens
**Tracking ID:** W2  
**What:** Implement addToRecentTokens() function  
**How:** Add function that unshifts new token, slices to 10 items, calls renderRecentTokens()  
**Done-when:** Function adds token, maintains 10-item limit, triggers render

### Step 3: Implement renderRecentTokens
**Tracking ID:** W3  
**What:** Implement renderRecentTokens() function with table display  
**How:** Add function that generates table rows for each token with worker_id, expiry, status chip  
**Done-when:** Function renders table with all token details

### Step 4: Add Status Calculation
**Tracking ID:** W4  
**What:** Add status calculation logic  
**How:** Add function that checks expiry time, usage flag, revoked flag to determine ACTIVE/EXPIRED/USED/REVOKED  
**Done-when:** Status is calculated dynamically based on token state

### Step 5: Add Click Handler
**Tracking ID:** W5  
**What:** Add click handler to show token detail panel  
**How:** Add onclick to table rows calling showTokenDetail(tokenId)  
**Done-when:** Clicking row opens token detail panel

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'recentTokens.*\\[\\]' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm recentTokens array exists |
| V2 | `grep -q 'renderRecentTokens' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm render function exists |
| V3 | `grep -q 'addToRecentTokens' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm add function exists |

## Evidence Contract

```json
{
  "task_id": "GF-W1-UI-005",
  "timestamp": "ISO8601",
  "recent_tokens_array_created": true,
  "add_function_implemented": true,
  "render_function_implemented": true,
  "status_calculation_logic_present": true,
  "click_handler_wired": true
}
```

## Rollback

1. Revert changes to `src/supervisory-dashboard/index.html`
2. Delete `evidence/phase1/gf_w1_ui_005.json`

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Tokens in localStorage | SECURITY.PERSISTENT_TOKEN_STORAGE | Use in-memory array only |
| Status not dynamic | FUNCTIONAL.INCORRECT_STATUS_DISPLAY | Calculate from expiry/usage/revoked flags |
| More than 10 tokens | UI.DESIGN_VIOLATION | Slice array to 10 items |
| No color coding | UI.DESIGN_VIOLATION | Use chip-auth/chip-hold/chip-sim classes |
