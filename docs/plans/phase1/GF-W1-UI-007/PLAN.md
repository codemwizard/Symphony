# GF-W1-UI-007 Implementation Plan

## Failure Signature
`PHASE1.GF-W1.UI-007.TOKEN_REVOCATION`

## Objective

Implement token revocation with confirmation dialog and API integration to allow operators to immediately invalidate compromised tokens.

## Pre-conditions

1. GF-W1-UI-006 (token detail panel) is complete
2. Token detail panel displays Revoke Token button
3. DELETE /pilot-demo/api/evidence-links/revoke/{token_id} endpoint is functional

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add revokeToken(), confirmation dialog, status update, list refresh, success/error messages |
| `evidence/phase1/gf_w1_ui_007.json` | CREATE | Evidence file |

## Stop Conditions

1. No confirmation dialog shown before revocation
2. Local status not updated after successful revocation
3. Recent tokens list not refreshed after revocation
4. Revoked tokens can be revoked again
5. No success/error messages displayed

## Implementation Steps

### Step 1: Implement revokeToken Function
**Tracking ID:** W1  
**What:** Implement revokeToken(tokenId) calling DELETE API  
**How:** Add async function with fetch() calling /pilot-demo/api/evidence-links/revoke/{token_id}  
**Done-when:** Function calls API, handles response

### Step 2: Add Confirmation Dialog
**Tracking ID:** W2  
**What:** Add confirmation dialog before revocation  
**How:** Add confirm() call with warning message "Are you sure? This cannot be undone."  
**Done-when:** Dialog shows before API call, revocation proceeds only if confirmed

### Step 3: Update Local Token Status
**Tracking ID:** W3  
**What:** Update local token status to REVOKED on success  
**How:** Find token in recentTokens array, set status = "REVOKED"  
**Done-when:** Token status updated in recentTokens array

### Step 4: Refresh Recent Tokens List
**Tracking ID:** W4  
**What:** Refresh recent tokens list to show updated status  
**How:** Call renderRecentTokens() after status update  
**Done-when:** List re-renders with REVOKED badge

### Step 5: Show Success/Error Messages
**Tracking ID:** W5  
**What:** Show success/error message after revocation attempt  
**How:** Add message div that displays "Token revoked successfully" or error message  
**Done-when:** Messages display appropriately based on API response

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'revokeToken' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm revoke function exists |
| V2 | `grep -q 'confirm.*revoke' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm confirmation dialog |
| V3 | `grep -q '/api/evidence-links/revoke' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm API endpoint |

## Evidence Contract

```json
{
  "task_id": "GF-W1-UI-007",
  "timestamp": "ISO8601",
  "revoke_function_implemented": true,
  "confirmation_dialog_present": true,
  "local_status_update_implemented": true,
  "list_refresh_implemented": true,
  "success_error_messages_present": true
}
```

## Rollback

1. Revert changes to `src/supervisory-dashboard/index.html`
2. Delete `evidence/phase1/gf_w1_ui_007.json`

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| No confirmation dialog | SECURITY.ACCIDENTAL_REVOCATION | Add confirm() before API call |
| Local status not updated | FUNCTIONAL.STALE_STATUS_DISPLAY | Update recentTokens array on success |
| List not refreshed | UI.STALE_DATA_DISPLAY | Call renderRecentTokens() after update |
| Duplicate revocations | FUNCTIONAL.DUPLICATE_REVOCATION_ATTEMPTS | Disable button for revoked tokens |
