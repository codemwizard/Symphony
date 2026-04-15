# GF-W1-UI-003 Implementation Plan

## Failure Signature
`PHASE1.GF-W1.UI-003.WORKER_LOOKUP_FORM`

## Objective

Implement worker lookup form with real-time registry validation to ensure operators can verify worker identity before issuing tokens. This prevents token issuance to unregistered workers or workers with invalid supplier_type.

## Architectural Context

This task sits after GF-W1-UI-002 (tab structure). It adds the worker lookup form that validates phone numbers and fetches worker details from the registry. The form must enforce supplier_type=WORKER validation and display neighbourhood labels instead of raw GPS coordinates.

**Anti-patterns to avoid:**
- Skipping phone number format validation
- Displaying raw GPS coordinates
- Enabling token issuance button before worker validation
- Not handling error states

## Pre-conditions

1. GF-W1-UI-002 (tab structure) is complete
2. screen-worker-tokens exists with two-column layout
3. GET /pilot-demo/api/workers/lookup endpoint is functional
4. resolveNeighbourhoodLabel() function exists in codebase

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add phone input, lookupWorker() function, worker details panel, error states, button |
| `evidence/phase1/gf_w1_ui_003.json` | CREATE | Create evidence file documenting validation and API integration |

## Stop Conditions

1. Phone validation missing or accepts invalid format
2. Raw GPS coordinates displayed anywhere
3. Button enabled before worker validation completes
4. supplier_type validation missing (accepts non-WORKER types)
5. Error states not handled (no feedback for invalid workers)

## Implementation Steps

### Step 1: Add Phone Number Input
**Tracking ID:** W1  
**What:** Add phone number input field with +260XXXXXXXXX format validation  
**How:** Add `<input type="tel" id="worker-phone" pattern="\\+260[0-9]{9}" onblur="validatePhoneFormat()">` with validation function  
**Done-when:** Input validates format on blur, shows error for invalid format

### Step 2: Implement lookupWorker Function
**Tracking ID:** W2  
**What:** Implement lookupWorker() function calling GET /pilot-demo/api/workers/lookup  
**How:** Add async function that fetches worker data, checks supplier_type=WORKER, calls resolveNeighbourhoodLabel() for GPS  
**Done-when:** Function fetches worker data, validates supplier_type, returns neighbourhood label

### Step 3: Add Worker Details Panel
**Tracking ID:** W3  
**What:** Add worker details display panel  
**How:** Add div showing worker_id, supplier_type, status, neighbourhood label with green confirmation styling  
**Done-when:** Panel displays all worker details with neighbourhood label (no raw coordinates)

### Step 4: Implement Error States
**Tracking ID:** W4  
**What:** Implement error states for invalid workers  
**How:** Add error message divs for: not registered (404), invalid supplier_type (!= WORKER), inactive status  
**Done-when:** Each error state shows appropriate red error message

### Step 5: Add Token Issuance Button
**Tracking ID:** W5  
**What:** Add Request Collection Token button (disabled by default)  
**How:** Add `<button id="issue-token-btn" disabled onclick="issueToken()">Request Collection Token</button>`, enable only after valid worker confirmed  
**Done-when:** Button is disabled until valid worker confirmed, enabled after confirmation

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'lookupWorker' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm lookupWorker function exists |
| V2 | `grep -q 'resolveNeighbourhoodLabel' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm neighbourhood label function used |
| V3 | `grep -q 'supplier_type.*WORKER' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm supplier_type validation exists |

## Evidence Contract

The implementation MUST emit `evidence/phase1/gf_w1_ui_003.json` with these required fields:

```json
{
  "task_id": "GF-W1-UI-003",
  "timestamp": "ISO8601",
  "phone_validation_implemented": true,
  "lookup_api_integrated": true,
  "worker_details_panel_present": true,
  "error_states_handled": true,
  "button_disabled_until_valid": true
}
```

## Rollback

If implementation fails:

1. Revert changes to `src/supervisory-dashboard/index.html` (remove phone input, lookupWorker function, worker details panel)
2. Delete `evidence/phase1/gf_w1_ui_003.json`

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Phone validation missing | FUNCTIONAL.INVALID_INPUT_ACCEPTED | Test with invalid formats, ensure validation triggers |
| Raw GPS coordinates displayed | UI.DESIGN_VIOLATION | Use resolveNeighbourhoodLabel() for all location displays |
| Button enabled prematurely | FUNCTIONAL.PREMATURE_TOKEN_ISSUANCE | Test button state before and after worker validation |
| supplier_type validation missing | SECURITY.INVALID_WORKER_TYPE_ACCEPTED | Explicitly check supplier_type === "WORKER" |
