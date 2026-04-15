# Pilot Success Criteria Tab — Tasks

## Task 1: Add Pilot Success Criteria Tab to Supervisory Dashboard

**Owner**: UI Developer  
**Priority**: HIGH  
**Estimated Effort**: 3 hours

### Description
Add the 5th and final tab "Pilot Success Criteria" to the supervisory dashboard tab bar and create the screen container with single-column layout.

### Subtasks
- [ ] 1.1 Add tab button to tab bar with `onclick="switchTab('s6',this)"`
- [ ] 1.2 Create `#screen-s6` div with `.screen` class
- [ ] 1.3 Implement single-column layout with three category sections
- [ ] 1.4 Add overall pilot gate status card at top
- [ ] 1.5 Wire `switchTab()` function to show/hide new screen

### Acceptance Criteria
- Tab bar shows 5 tabs (Programme Health, Monitoring Report, Onboarding Console, Worker Token Issuance, Pilot Success Criteria)
- Clicking "Pilot Success Criteria" tab switches to new screen
- Screen layout matches design (single-column, fills 100vh)
- `verify_tsk_p1_219.sh` passes (tab count == 5)

### Dependencies
- None

---

## Task 2: Implement Overall Pilot Gate Status Display

**Owner**: UI Developer  
**Priority**: HIGH  
**Estimated Effort**: 2 hours

### Description
Create the overall pilot gate status card showing PASS/PENDING/FAIL with color-coded badges and last verified timestamp.

### Subtasks
- [ ] 2.1 Add overall status card HTML structure
- [ ] 2.2 Implement `renderOverallStatus()` function
- [ ] 2.3 Add color-coded badges (green PASS, amber PENDING, red FAIL)
- [ ] 2.4 Add last verified timestamp display
- [ ] 2.5 Add "Refresh Now" and "Export Report" buttons

### Acceptance Criteria
- Overall status card displays prominently at top of tab
- Badge color matches status (green/amber/red)
- Last verified timestamp is formatted correctly
- Buttons are visible and clickable

### Dependencies
- Task 1 (tab structure)

---

## Task 3: Implement Technical Criteria Section

**Owner**: UI Developer  
**Priority**: HIGH  
**Estimated Effort**: 4 hours

### Description
Create the technical criteria section showing 6 criteria with status indicators and invariant references.

### Subtasks
- [ ] 3.1 Add technical criteria card HTML structure
- [ ] 3.2 Implement `renderCategory()` function for technical criteria
- [ ] 3.3 Add criterion rows with status indicators (✓ ⧗ ✗)
- [ ] 3.4 Add invariant ID display for each criterion
- [ ] 3.5 Add click handler to show criterion detail panel
- [ ] 3.6 Add category status badge (ALL PASS / ATTENTION REQUIRED)

### Acceptance Criteria
- Technical criteria section shows all 6 criteria
- Status indicators use correct symbols and colors
- Invariant IDs are displayed where applicable
- Category badge shows correct status
- Clicking criterion opens detail panel

### Dependencies
- Task 2 (overall status)

---

## Task 4: Implement Operational Criteria Section

**Owner**: UI Developer  
**Priority**: HIGH  
**Estimated Effort**: 3 hours

### Description
Create the operational criteria section showing 5 criteria with status indicators and verification methods.

### Subtasks
- [ ] 4.1 Add operational criteria card HTML structure
- [ ] 4.2 Implement `renderCategory()` function for operational criteria
- [ ] 4.3 Add criterion rows with status indicators
- [ ] 4.4 Add verification method display for each criterion
- [ ] 4.5 Add click handler to show criterion detail panel
- [ ] 4.6 Add category status badge

### Acceptance Criteria
- Operational criteria section shows all 5 criteria
- Status indicators use correct symbols and colors
- Verification methods are displayed
- Category badge shows correct status
- Clicking criterion opens detail panel

### Dependencies
- Task 3 (technical criteria)

---

## Task 5: Implement Regulatory Criteria Section

**Owner**: UI Developer  
**Priority**: HIGH  
**Estimated Effort**: 3 hours

### Description
Create the regulatory criteria section showing 6 criteria with status indicators and compliance references.

### Subtasks
- [ ] 5.1 Add regulatory criteria card HTML structure
- [ ] 5.2 Implement `renderCategory()` function for regulatory criteria
- [ ] 5.3 Add criterion rows with status indicators
- [ ] 5.4 Add invariant ID display for each criterion
- [ ] 5.5 Add click handler to show criterion detail panel
- [ ] 5.6 Add category status badge

### Acceptance Criteria
- Regulatory criteria section shows all 6 criteria
- Status indicators use correct symbols and colors
- Invariant IDs are displayed where applicable
- Category badge shows correct status
- Clicking criterion opens detail panel

### Dependencies
- Task 4 (operational criteria)

---

## Task 6: Implement Criterion Detail Slide-out Panel

**Owner**: UI Developer  
**Priority**: HIGH  
**Estimated Effort**: 3 hours

### Description
Create the criterion detail slide-out panel showing detailed information and "Run Verification Now" button.

### Subtasks
- [ ] 6.1 Create slide-out panel HTML structure (reuse existing `.slideout` class)
- [ ] 6.2 Implement `showCriterionDetail()` function
- [ ] 6.3 Add criterion details display (status, invariants, verification method, threshold, last verified)
- [ ] 6.4 Add "Run Verification Now" button
- [ ] 6.5 Add "Close" button
- [ ] 6.6 Implement `runVerificationNow()` function calling API

### Acceptance Criteria
- Slide-out panel opens when criterion is clicked
- Panel shows all criterion details
- Panel slides in from right with smooth animation
- "Run Verification Now" button triggers API call
- Close button closes panel

### Dependencies
- Task 5 (regulatory criteria)

---

## Task 7: Implement API Integration

**Owner**: Backend Developer  
**Priority**: HIGH  
**Estimated Effort**: 4 hours

### Description
Implement the pilot success criteria API endpoint returning all criteria with statuses.

### Subtasks
- [ ] 7.1 Create `GET /pilot-demo/api/pilot-success-criteria` endpoint
- [ ] 7.2 Implement technical criteria verification logic
- [ ] 7.3 Implement operational criteria verification logic
- [ ] 7.4 Implement regulatory criteria verification logic
- [ ] 7.5 Return JSON response with all criteria and statuses
- [ ] 7.6 Add caching (30 second TTL)

### Acceptance Criteria
- Endpoint returns HTTP 200 with valid JSON
- Response includes all three categories
- Each criterion has required fields (id, name, status, last_verified)
- Response is cached for 30 seconds
- Endpoint is accessible via pilot-demo session cookie

### Dependencies
- None (backend task)

---

## Task 8: Implement Auto-Refresh Polling

**Owner**: UI Developer  
**Priority**: MEDIUM  
**Estimated Effort**: 2 hours

### Description
Implement auto-refresh polling that fetches criteria data every 30 seconds when tab is active.

### Subtasks
- [ ] 8.1 Implement `startPolling()` function with 30-second interval
- [ ] 8.2 Implement `stopPolling()` function
- [ ] 8.3 Add tab visibility check (only poll when tab is active)
- [ ] 8.4 Add subtle flash animation on changed criteria
- [ ] 8.5 Wire polling to tab switch events

### Acceptance Criteria
- Polling starts when tab is activated
- Polling stops when tab is deactivated
- Criteria data refreshes every 30 seconds
- Changed criteria show flash animation
- No polling when tab is not visible

### Dependencies
- Task 7 (API integration)

---

## Task 9: Implement Export Report Functionality

**Owner**: UI Developer  
**Priority**: MEDIUM  
**Estimated Effort**: 3 hours

### Description
Implement export report functionality for JSON and PDF formats.

### Subtasks
- [ ] 9.1 Add "Export Report" button click handler
- [ ] 9.2 Create export modal with format options (JSON / PDF)
- [ ] 9.3 Implement JSON export (client-side generation)
- [ ] 9.4 Implement PDF export (call backend endpoint)
- [ ] 9.5 Add deterministic fingerprint (SHA-256 hash)
- [ ] 9.6 Add download functionality

### Acceptance Criteria
- Export modal opens when button is clicked
- JSON export generates valid JSON file
- PDF export calls backend and downloads PDF
- Both formats include deterministic fingerprint
- Files are named with timestamp

### Dependencies
- Task 7 (API integration)

---

## Task 10: Create End-to-End Verification Script

**Owner**: QA Engineer  
**Priority**: HIGH  
**Estimated Effort**: 3 hours

### Description
Create self-test script verifying the pilot success criteria endpoint returns valid data.

### Subtasks
- [ ] 10.1 Create `scripts/dev/verify_pilot_success_criteria_e2e.sh`
- [ ] 10.2 Implement endpoint accessibility test (GET /pilot-demo/api/pilot-success-criteria)
- [ ] 10.3 Implement response validation (categories present, criteria valid)
- [ ] 10.4 Implement status validation (at least one PASS per category)
- [ ] 10.5 Emit evidence JSON to `evidence/phase1/pilot_success_criteria_e2e.json`

### Acceptance Criteria
- Script calls pilot success criteria endpoint and verifies HTTP 200
- Script confirms response contains all three categories
- Script confirms each criterion has required fields
- Script confirms at least one criterion per category is PASS
- Script exits 0 only when all checks pass

### Dependencies
- Task 7 (API integration)

---

## Task 11: Update TSK-P1-219 Verifier

**Owner**: QA Engineer  
**Priority**: HIGH  
**Estimated Effort**: 1 hour

### Description
Update the TSK-P1-219 verifier to expect 5 tabs (final count).

### Subtasks
- [ ] 11.1 Update `scripts/audit/verify_tsk_p1_219.sh` tab count check (4 → 5)
- [ ] 11.2 Add check for s6 tab existence
- [ ] 11.3 Add check for screen-s6 screen existence
- [ ] 11.4 Update evidence JSON schema
- [ ] 11.5 Update `.toolchain/script_integrity/verifier_hashes.sha256`

### Acceptance Criteria
- Verifier passes when 5 tabs exist
- Verifier checks for s6 tab specifically
- Verifier checks for screen-s6 screen
- Evidence JSON includes new checks

### Dependencies
- Task 1 (tab structure)

---

## Task 12: Integration Testing

**Owner**: QA Engineer  
**Priority**: HIGH  
**Estimated Effort**: 3 hours

### Description
Perform integration testing of the complete pilot success criteria flow.

### Subtasks
- [ ] 12.1 Test criteria loading on tab activation
- [ ] 12.2 Test overall status display (PASS / PENDING / FAIL)
- [ ] 12.3 Test all three category sections
- [ ] 12.4 Test criterion detail panel
- [ ] 12.5 Test "Run Verification Now" functionality
- [ ] 12.6 Test auto-refresh polling
- [ ] 12.7 Test export report (JSON and PDF)

### Acceptance Criteria
- All positive test cases pass
- All negative test cases show appropriate errors
- Polling works correctly
- Export generates valid files
- UI updates correctly in all scenarios

### Dependencies
- All previous tasks
