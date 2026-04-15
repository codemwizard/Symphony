# GF-W1-UI-008 Implementation Plan

## Failure Signature
`PHASE1.GF-W1.UI-008.BULK_TOKEN_ISSUANCE`

## Objective

Implement optional bulk token issuance functionality for issuing tokens to multiple workers simultaneously with progress tracking and CSV export.

## Pre-conditions

1. GF-W1-UI-003 (worker lookup) is complete
2. Token issuance API is functional
3. Sequential issuance pattern is established

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add bulk button, modal, sequential issuance, progress indicator, CSV export, summary |
| `evidence/phase1/gf_w1_ui_008.json` | CREATE | Evidence file |

## Stop Conditions

1. Parallel issuance used instead of sequential
2. No progress indicator shown
3. CSV not generated
4. Partial failures not reported in summary
5. Modal not dismissible

## Implementation Steps

### Step 1: Add Bulk Issue Button
**Tracking ID:** W1  
**What:** Add Bulk Issue button to main form  
**How:** Add button next to single issuance form  
**Done-when:** Button opens bulk issuance modal

### Step 2: Create Bulk Modal
**Tracking ID:** W2  
**What:** Create modal with textarea for phone numbers  
**How:** Add modal with textarea accepting comma-separated phone numbers  
**Done-when:** Modal displays with textarea and Submit button

### Step 3: Implement Sequential Issuance
**Tracking ID:** W3  
**What:** Implement sequential token issuance  
**How:** Loop through phone numbers, await each issueToken() call  
**Done-when:** Tokens issued one-by-one, not in parallel

### Step 4: Add Progress Indicator
**Tracking ID:** W4  
**What:** Add progress indicator  
**How:** Display "Issuing token X of Y..." message updating after each issuance  
**Done-when:** Progress updates in real-time

### Step 5: Generate CSV Export
**Tracking ID:** W5  
**What:** Generate CSV file with token URLs  
**How:** Create CSV blob with phone, worker_id, token_url, status columns  
**Done-when:** CSV downloads automatically after completion

### Step 6: Show Summary
**Tracking ID:** W6  
**What:** Show summary of results  
**How:** Display total, success count, failed count with details  
**Done-when:** Summary shows all results clearly

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'bulkIssue' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm bulk function exists |
| V2 | `grep -q 'text/csv' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm CSV export |

## Evidence Contract

```json
{
  "task_id": "GF-W1-UI-008",
  "timestamp": "ISO8601",
  "bulk_button_present": true,
  "modal_created": true,
  "sequential_issuance_implemented": true,
  "progress_indicator_present": true,
  "csv_export_implemented": true,
  "summary_displayed": true
}
```

## Rollback

1. Revert changes to `src/supervisory-dashboard/index.html`
2. Delete `evidence/phase1/gf_w1_ui_008.json`

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Parallel issuance | FUNCTIONAL.API_RATE_LIMIT_EXCEEDED | Use sequential await pattern |
| No progress | UI.NO_FEEDBACK_DURING_OPERATION | Update progress after each issuance |
| No CSV | FUNCTIONAL.NO_EXPORT_CAPABILITY | Generate CSV blob and trigger download |
| Partial failures hidden | FUNCTIONAL.INCOMPLETE_ERROR_REPORTING | Track and display all failures |
