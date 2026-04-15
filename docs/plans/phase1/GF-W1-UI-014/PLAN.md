# GF-W1-UI-014 Implementation Plan
## Failure Signature
`PHASE1.GF-W1.UI-014.TECHNICAL_CRITERIA`
## Objective
Implement technical criteria section showing 6 criteria with status indicators and invariant references.
## Pre-conditions
1. GF-W1-UI-013 (overall gate status) is complete
## Files to Change
| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add technical criteria card, renderCategory(), criterion rows, invariant IDs, click handler, category badge |
| `evidence/phase1/gf_w1_ui_014.json` | CREATE | Evidence file |
## Stop Conditions
1. Criterion statuses hardcoded
2. Invariant IDs missing
3. Status indicators not color-coded
4. Criteria not clickable
5. Category badge missing
## Implementation Steps
### Step 1: Add Technical Criteria Card
**Tracking ID:** W1  
**What:** Add technical criteria card HTML structure  
**How:** Add div in category-technical with card styling  
**Done-when:** Card structure exists
### Step 2: Implement renderCategory
**Tracking ID:** W2  
**What:** Implement renderCategory('technical', categoryData) function  
**How:** Add function that generates criterion rows from data  
**Done-when:** Function renders criteria correctly
### Step 3: Add Criterion Rows
**Tracking ID:** W3  
**What:** Add criterion rows with status indicators  
**How:** Use ✓ ⧗ ✗ symbols with green/amber/red colors  
**Done-when:** Rows display with correct status indicators
### Step 4: Add Invariant IDs
**Tracking ID:** W4  
**What:** Add invariant ID display for each criterion  
**How:** Display invariant IDs from criterion data  
**Done-when:** Invariant IDs visible for applicable criteria
### Step 5: Add Click Handler
**Tracking ID:** W5  
**What:** Add click handler to show criterion detail panel  
**How:** Add onclick to criterion rows calling showCriterionDetail(id)  
**Done-when:** Clicking criterion opens detail panel
### Step 6: Add Category Badge
**Tracking ID:** W6  
**What:** Add category status badge  
**How:** Display ALL PASS (green) or ATTENTION REQUIRED (red) based on criteria statuses  
**Done-when:** Badge shows correct status
## Verification
| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'renderCategory' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm render function exists |
| V2 | `grep -q 'category-technical' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm technical category exists |
## Evidence Contract
```json
{
  "task_id": "GF-W1-UI-014",
  "timestamp": "ISO8601",
  "technical_criteria_card_created": true,
  "render_category_function_implemented": true,
  "criterion_rows_with_status_indicators": true,
  "invariant_ids_displayed": true,
  "click_handler_wired": true,
  "category_badge_present": true
}
```
## Rollback
1. Revert changes to `src/supervisory-dashboard/index.html`
2. Delete `evidence/phase1/gf_w1_ui_014.json`
## Risk Assessment
| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Statuses hardcoded | FUNCTIONAL.STALE_STATUS_DISPLAY | Fetch from API |
| Invariant IDs missing | GOVERNANCE.INCOMPLETE_AUDIT_TRAIL | Display from criterion data |
| Not color-coded | UI.DESIGN_VIOLATION | Use chip classes |
| Not clickable | FUNCTIONAL.NO_DETAIL_ACCESS | Add onclick handlers |
