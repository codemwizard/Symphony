# GF-W1-UI-015 Implementation Plan
## Failure Signature
`PHASE1.GF-W1.UI-015.OPERATIONAL_CRITERIA`
## Objective
Implement operational criteria section showing 5 criteria with status indicators and verification methods.
## Files to Change
| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add operational criteria using renderCategory() |
| `evidence/phase1/gf_w1_ui_015.json` | CREATE | Evidence file |
## Stop Conditions
1. Verification methods missing
2. Status indicators not color-coded
3. Criteria not clickable
## Implementation Steps
### Step 1-6: Similar to GF-W1-UI-014
Reuse renderCategory() function with operational-specific data.
## Verification
| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'category-operational' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm operational category exists |
## Evidence Contract
```json
{"task_id": "GF-W1-UI-015", "timestamp": "ISO8601", "operational_criteria_card_created": true}
```
## Rollback
1. Revert changes to `src/supervisory-dashboard/index.html`
2. Delete `evidence/phase1/gf_w1_ui_015.json`
