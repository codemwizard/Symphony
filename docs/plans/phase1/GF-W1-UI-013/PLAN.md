# GF-W1-UI-013 Implementation Plan

## Failure Signature
`PHASE1.GF-W1.UI-013.OVERALL_GATE_STATUS`

## Objective

Implement overall pilot gate status card showing PASS/PENDING/FAIL with color-coded badges and last verified timestamp.

## Pre-conditions

1. GF-W1-UI-012 (tab structure) is complete
2. screen-s6 exists with overall-status placeholder

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add status card, renderOverallStatus(), badges, timestamp, buttons |
| `evidence/phase1/gf_w1_ui_013.json` | CREATE | Evidence file |

## Stop Conditions

1. Gate status hardcoded instead of computed
2. Badges not color-coded
3. Timestamp missing or not formatted
4. Action buttons missing
5. Status card not prominently displayed

## Implementation Steps

### Step 1: Add Status Card HTML
**Tracking ID:** W1  
**What:** Add overall status card HTML structure  
**How:** Add div with class s6-gate in overall-status placeholder  
**Done-when:** Card structure exists

### Step 2: Implement renderOverallStatus
**Tracking ID:** W2  
**What:** Implement renderOverallStatus(status, lastVerified) function  
**How:** Add function that sets badge class and message based on status  
**Done-when:** Function renders status correctly

### Step 3: Add Color-Coded Badges
**Tracking ID:** W3  
**What:** Add color-coded badges  
**How:** Use chip-auth (green), chip-hold (amber), chip-sim (red) classes  
**Done-when:** Badges display with correct colors

### Step 4: Add Timestamp Display
**Tracking ID:** W4  
**What:** Add last verified timestamp display  
**How:** Implement formatTimestamp() function, display formatted time  
**Done-when:** Timestamp displays correctly

### Step 5: Add Action Buttons
**Tracking ID:** W5  
**What:** Add Refresh Now and Export Report buttons  
**How:** Add buttons with onclick handlers  
**Done-when:** Buttons are visible and clickable

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'renderOverallStatus' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm render function exists |
| V2 | `grep -q 'overall-status' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm status card exists |

## Evidence Contract

```json
{
  "task_id": "GF-W1-UI-013",
  "timestamp": "ISO8601",
  "overall_status_card_created": true,
  "render_function_implemented": true,
  "color_coded_badges_present": true,
  "timestamp_display_implemented": true,
  "action_buttons_present": true
}
```

## Rollback

1. Revert changes to `src/supervisory-dashboard/index.html`
2. Delete `evidence/phase1/gf_w1_ui_013.json`

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Status hardcoded | FUNCTIONAL.STALE_STATUS_DISPLAY | Compute from criteria data |
| Badges not colored | UI.DESIGN_VIOLATION | Use chip classes |
| Timestamp missing | FUNCTIONAL.NO_DATA_FRESHNESS_INDICATOR | Add formatTimestamp() |
| Buttons missing | FUNCTIONAL.NO_MANUAL_CONTROLS | Add Refresh and Export buttons |
