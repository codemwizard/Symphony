# GF-W1-UI-002 Implementation Plan

## Failure Signature
`PHASE1.GF-W1.UI-002.WORKER_TOKEN_TAB_STRUCTURE`

## Objective

Add the 4th tab "Worker Token Issuance" to the supervisory dashboard to enable operators to generate evidence-link tokens for waste collectors as required by Act 2.1-2.2 of the pilot demo video script. This task creates only the tab structure and two-column layout placeholder, not the functional logic.

## Architectural Context

This task sits in the Green Finance pilot DAG after GF-W1-UI-001 (canonical UI rewrite). It adds the tab structure required for worker token issuance functionality. Subsequent tasks (GF-W1-UI-003 through GF-W1-UI-011) will add the lookup form, issuance logic, recent tokens list, and revocation functionality.

**Anti-patterns to avoid:**
- Adding all token issuance logic in one massive task (break into focused tasks)
- Hardcoding worker data instead of calling lookup API
- Displaying raw GPS coordinates (use neighbourhood labels only)
- Creating new HTML files (all tabs must be in src/supervisory-dashboard/index.html)

## Pre-conditions

1. GF-W1-UI-001 (canonical UI rewrite) is complete and merged
2. Supervisory dashboard has 3 tabs (Programme Health, Monitoring Report, Onboarding Console)
3. CSS token system is established (--bright, --surface, --panel, --border)
4. switchTab() function exists and works for existing tabs

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/supervisory-dashboard/index.html` | MODIFY | Add tab button, screen-worker-tokens div, two-column grid layout, programme context display |
| `scripts/audit/verify_tsk_p1_219.sh` | MODIFY | Update tab count check from 3 to 4 |
| `evidence/phase1/gf_w1_ui_002.json` | CREATE | Create evidence file documenting tab count and screen existence |

## Stop Conditions

1. Tab count remains 3 instead of 4 after implementation
2. screen-worker-tokens div does not exist
3. Layout does not fill 100vh (scrollbar appears)
4. Programme context is hardcoded instead of dynamic
5. verify_tsk_p1_219.sh fails after implementation

## Implementation Steps

### Step 1: Add Tab Button
**Tracking ID:** W1  
**What:** Add Worker Token Issuance tab button to tab bar  
**How:** Insert `<div class="tab" onclick="switchTab('worker-tokens',this)">Worker Token Issuance</div>` after Onboarding Console tab  
**Done-when:** Tab bar shows 4 tabs, grep confirms onclick handler exists

### Step 2: Create Screen Container
**Tracking ID:** W2  
**What:** Create screen-worker-tokens div with .screen class  
**How:** Add `<div id="screen-worker-tokens" class="screen">` after screen-s3  
**Done-when:** grep confirms screen-worker-tokens exists with .screen class

### Step 3: Implement Two-Column Layout
**Tracking ID:** W3  
**What:** Add two-column grid layout inside screen-worker-tokens  
**How:** Add CSS grid with `grid-template-columns: 1fr 1fr` and two child divs (left: issuance-form-placeholder, right: recent-tokens-placeholder)  
**Done-when:** Layout renders as two columns filling 100vh

### Step 4: Add Programme Context Display
**Tracking ID:** W4  
**What:** Add programme context display showing programme name and location  
**How:** Add div with programme_id and location label at top of screen-worker-tokens  
**Done-when:** Programme context displays "PGM-ZAMBIA-GRN-001" and "Chunga Dumpsite, Lusaka"

### Step 5: Wire switchTab Function
**Tracking ID:** W5  
**What:** Ensure switchTab('worker-tokens') shows/hides screen-worker-tokens  
**How:** Verify existing switchTab() logic handles new screen ID correctly  
**Done-when:** Clicking tab switches to screen-worker-tokens, other screens hide

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'screen-worker-tokens' src/supervisory-dashboard/index.html \|\| exit 1` | Confirm screen-worker-tokens container exists |
| V2 | `grep -c 'onclick="switchTab' src/supervisory-dashboard/index.html \| grep -q '^4$' \|\| exit 1` | Confirm 4 tabs exist |
| V3 | `bash scripts/audit/verify_tsk_p1_219.sh \|\| exit 1` | Confirm tab count verifier passes |

## Evidence Contract

The implementation MUST emit `evidence/phase1/gf_w1_ui_002.json` with these required fields:

```json
{
  "task_id": "GF-W1-UI-002",
  "timestamp": "ISO8601",
  "tab_count_is_4": true,
  "screen_worker_tokens_exists": true,
  "two_column_layout_present": true,
  "programme_context_displayed": true
}
```

## Rollback

If implementation fails or introduces regressions:

1. Revert changes to `src/supervisory-dashboard/index.html` (remove tab button and screen-worker-tokens)
2. Revert changes to `scripts/audit/verify_tsk_p1_219.sh` (restore tab count check to 3)
3. Delete `evidence/phase1/gf_w1_ui_002.json`
4. Run `bash scripts/audit/verify_tsk_p1_219.sh` to confirm rollback success (should pass with 3 tabs)

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Tab count remains 3 instead of 4 | FUNCTIONAL.PILOT_DEMO_INCOMPLETE | Run verify_tsk_p1_219.sh after implementation, confirm tab count == 4 |
| Layout does not fill 100vh | UI.DESIGN_VIOLATION | Test layout in browser, ensure no scrollbar appears |
| Programme context hardcoded | FUNCTIONAL.CONTEXT_LOSS | Fetch programme_id from reveal endpoint, use resolveNeighbourhoodLabel() for location |
