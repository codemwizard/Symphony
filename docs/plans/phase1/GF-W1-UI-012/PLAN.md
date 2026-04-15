# GF-W1-UI-012 Implementation Plan

## Failure Signature
`PHASE1.GF-W1.UI-012.PILOT_CRITERIA_TAB_STRUCTURE`

## Objective

Add the 5th and final tab "Pilot Success Criteria" to the supervisory dashboard to enable stakeholders to view real-time validation of Symphony's compliance posture as required by Act 4.1-4.3 of the pilot demo video script. This task creates only the tab structure and single-column layout placeholder, not the functional logic.

## Pre-conditions

1. GF-W1-UI-002 (worker token tab) is complete
2. Supervisory dashboard has 4 tabs
3. CSS token system is established
4. switchTab() function exists and works for existing tabs

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add tab button, screen-s6 div, single-column layout, category placeholders, gate status placeholder |
| `evidence/phase1/gf_w1_ui_012.json` | CREATE | Evidence file |

## Stop Conditions

1. Tab count remains 4 instead of 5
2. screen-s6 div does not exist
3. Layout does not fill 100vh (scrollbar appears)
4. Category placeholders missing
5. verify_tsk_p1_219.sh fails

## Implementation Steps

### Step 1: Add Tab Button
**Tracking ID:** W1  
**What:** Add Pilot Success Criteria tab button to tab bar  
**How:** Insert `<div class="tab" onclick="switchTab('s6',this)">Pilot Success Criteria</div>` after Worker Token Issuance tab  
**Done-when:** Tab bar shows 5 tabs, grep confirms onclick handler exists

### Step 2: Create Screen Container
**Tracking ID:** W2  
**What:** Create screen-s6 div with .screen class  
**How:** Add `<div id="screen-s6" class="screen">` after screen-worker-tokens  
**Done-when:** grep confirms screen-s6 exists with .screen class

### Step 3: Implement Single-Column Layout
**Tracking ID:** W3  
**What:** Add single-column layout with three category section placeholders  
**How:** Add three divs with IDs category-technical, category-operational, category-regulatory  
**Done-when:** Layout renders as single column filling 100vh

### Step 4: Add Gate Status Placeholder
**Tracking ID:** W4  
**What:** Add overall pilot gate status card placeholder at top  
**How:** Add div with ID overall-status at top of screen-s6  
**Done-when:** Gate status placeholder exists at top

### Step 5: Wire switchTab Function
**Tracking ID:** W5  
**What:** Ensure switchTab('s6') shows/hides screen-s6  
**How:** Verify existing switchTab() logic handles new screen ID correctly  
**Done-when:** Clicking tab switches to screen-s6, other screens hide

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'screen-s6' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm screen-s6 container exists |
| V2 | `grep -c 'onclick="switchTab' src/supervisory-dashboard/index.html \| grep -q '^5$' \|\| exit 1` | Confirm 5 tabs exist |
| V3 | `bash scripts/audit/verify_tsk_p1_219.sh \|\| exit 1` | Confirm tab count verifier passes |

## Evidence Contract

```json
{
  "task_id": "GF-W1-UI-012",
  "timestamp": "ISO8601",
  "tab_count_is_5": true,
  "screen_s6_exists": true,
  "single_column_layout_present": true,
  "three_category_placeholders_present": true,
  "gate_status_placeholder_present": true
}
```

## Rollback

1. Revert changes to `src/supervisory-dashboard/index.html` (remove tab button and screen-s6)
2. Delete `evidence/phase1/gf_w1_ui_012.json`

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Tab count remains 4 | FUNCTIONAL.PILOT_DEMO_INCOMPLETE | Run verify_tsk_p1_219.sh after implementation |
| Layout does not fill 100vh | UI.DESIGN_VIOLATION | Test layout in browser, ensure no scrollbar |
| Category placeholders missing | FUNCTIONAL.INCOMPLETE_STRUCTURE | Add all three category divs |
