# GF-W1-UI-006 Implementation Plan

## Failure Signature
`PHASE1.GF-W1.UI-006.TOKEN_DETAIL_PANEL`

## Objective

Implement token detail slide-out panel showing complete token information including security properties and usage history.

## Pre-conditions

1. GF-W1-UI-005 (recent tokens list) is complete
2. Recent tokens list displays and is clickable
3. Existing .slideout CSS class is available

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add slideout panel HTML, showTokenDetail(), token details display, revoke button, close button |
| `evidence/phase1/gf_w1_ui_006.json` | CREATE | Evidence file |

## Stop Conditions

1. Panel does not use existing .slideout class
2. Security properties not displayed
3. Revoke button shown for revoked tokens
4. Panel does not slide in smoothly
5. Close button not functional

## Implementation Steps

### Step 1: Create Slideout Panel Structure
**Tracking ID:** W1  
**What:** Create slide-out panel HTML structure  
**How:** Add `<div id="token-detail-panel" class="slideout">` with header and body sections  
**Done-when:** Panel structure exists with .slideout class

### Step 2: Implement showTokenDetail
**Tracking ID:** W2  
**What:** Implement showTokenDetail(tokenId) function  
**How:** Add function that finds token in recentTokens array, populates panel, adds .open class  
**Done-when:** Function opens panel with correct token data

### Step 3: Add Token Details Display
**Tracking ID:** W3  
**What:** Add token details display sections  
**How:** Add divs showing issued, expires, status, security properties (type, signature, TTL, GPS lock, single-use), usage  
**Done-when:** All token details are displayed in panel

### Step 4: Add Revoke Button
**Tracking ID:** W4  
**What:** Add Revoke Token button  
**How:** Add button with onclick calling revokeToken(tokenId), hide if token already revoked  
**Done-when:** Button is visible for non-revoked tokens, hidden for revoked

### Step 5: Add Close Button
**Tracking ID:** W5  
**What:** Add Close button  
**How:** Add button with onclick removing .open class from panel  
**Done-when:** Button closes panel when clicked

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'showTokenDetail' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm show function exists |
| V2 | `grep -q 'slideout' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm slideout class used |

## Evidence Contract

```json
{
  "task_id": "GF-W1-UI-006",
  "timestamp": "ISO8601",
  "slideout_panel_created": true,
  "show_function_implemented": true,
  "token_details_displayed": true,
  "revoke_button_present": true,
  "close_button_present": true
}
```

## Rollback

1. Revert changes to `src/supervisory-dashboard/index.html`
2. Delete `evidence/phase1/gf_w1_ui_006.json`

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Panel animation broken | UI.ANIMATION_BROKEN | Test .slideout class behavior |
| Security properties missing | FUNCTIONAL.INCOMPLETE_TOKEN_INFO | Display all 5 properties |
| Revoke button incorrect state | UI.INCORRECT_BUTTON_STATE | Check token.revoked flag |
