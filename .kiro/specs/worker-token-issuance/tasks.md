# Worker Token Issuance Tab — Tasks

## Task 1: Add Worker Token Issuance Tab to Supervisory Dashboard

**Owner**: UI Developer  
**Priority**: HIGH  
**Estimated Effort**: 4 hours

### Description
Add the 4th tab "Worker Token Issuance" to the supervisory dashboard tab bar and create the screen container with two-column layout.

### Subtasks
- [ ] 1.1 Add tab button to tab bar with `onclick="switchTab('worker-tokens',this)"`
- [ ] 1.2 Create `#screen-worker-tokens` div with `.screen` class
- [ ] 1.3 Implement two-column grid layout (left: issuance form, right: recent tokens)
- [ ] 1.4 Add programme context display (name, location)
- [ ] 1.5 Wire `switchTab()` function to show/hide new screen

### Acceptance Criteria
- Tab bar shows 4 tabs (Programme Health, Monitoring Report, Onboarding Console, Worker Token Issuance)
- Clicking "Worker Token Issuance" tab switches to new screen
- Screen layout matches design (two-column, fills 100vh)
- `verify_tsk_p1_219.sh` passes (tab count >= 4)

### Dependencies
- None

---

## Task 2: Implement Worker Lookup Form

**Owner**: UI Developer  
**Priority**: HIGH  
**Estimated Effort**: 3 hours

### Description
Create the worker phone number input form with real-time validation against the worker registry.

### Subtasks
- [ ] 2.1 Add phone number input field with format validation (+260XXXXXXXXX)
- [ ] 2.2 Implement `lookupWorker()` function calling `GET /pilot-demo/api/workers/lookup`
- [ ] 2.3 Add worker details display panel (worker_id, supplier_type, status, GPS label)
- [ ] 2.4 Implement error states (not registered, invalid type, inactive)
- [ ] 2.5 Add "Request Collection Token" button (disabled until valid worker confirmed)

### Acceptance Criteria
- Phone number input validates format on blur
- Valid worker shows green confirmation with details
- Invalid worker shows red error message
- Button is disabled until valid WASTE_COLLECTOR worker is confirmed
- No raw GPS coordinates displayed (only neighbourhood labels)

### Dependencies
- Task 1 (tab structure)

---

## Task 3: Implement Token Issuance Logic

**Owner**: UI Developer  
**Priority**: HIGH  
**Estimated Effort**: 4 hours

### Description
Implement the token issuance API call and result display with security properties.

### Subtasks
- [ ] 3.1 Implement `issueToken()` function calling `POST /pilot-demo/api/evidence-links/issue`
- [ ] 3.2 Add token result display panel (worker_id, expiry, GPS label, radius)
- [ ] 3.3 Generate worker landing page URL with token in hash fragment
- [ ] 3.4 Add "Copy Link" button with clipboard API integration
- [ ] 3.5 Add security properties panel (type, signature, TTL, GPS lock, single-use)
- [ ] 3.6 Implement countdown timer updating every second

### Acceptance Criteria
- Token issuance succeeds for valid worker
- Token result shows all required fields
- Worker landing URL is correctly formatted
- Copy button copies full URL to clipboard
- Countdown timer updates in real-time
- Timer shows "EXPIRED" in red when time runs out

### Dependencies
- Task 2 (worker lookup)

---

## Task 4: Implement Recent Tokens List

**Owner**: UI Developer  
**Priority**: MEDIUM  
**Estimated Effort**: 3 hours

### Description
Create the recent tokens list showing last 10 issued tokens with status and expiry.

### Subtasks
- [ ] 4.1 Create in-memory `recentTokens` array (max 10 items)
- [ ] 4.2 Implement `addToRecentTokens()` function
- [ ] 4.3 Implement `renderRecentTokens()` function with table display
- [ ] 4.4 Add status calculation logic (ACTIVE / EXPIRED / USED / REVOKED)
- [ ] 4.5 Add click handler to show token detail panel

### Acceptance Criteria
- Recent tokens list shows last 10 tokens
- Status chips use correct colors (green/amber/red)
- Expiry shows countdown for active tokens, "EXPIRED" for expired
- Clicking row opens token detail slide-out panel

### Dependencies
- Task 3 (token issuance)

---

## Task 5: Implement Token Detail Slide-out Panel

**Owner**: UI Developer  
**Priority**: MEDIUM  
**Estimated Effort**: 2 hours

### Description
Create the token detail slide-out panel with revocation functionality.

### Subtasks
- [ ] 5.1 Create slide-out panel HTML structure (reuse existing `.slideout` class)
- [ ] 5.2 Implement `showTokenDetail()` function
- [ ] 5.3 Add token details display (issued, expires, status, security properties, usage)
- [ ] 5.4 Add "Revoke Token" button
- [ ] 5.5 Add "Close" button

### Acceptance Criteria
- Slide-out panel opens when token row is clicked
- Panel shows all token details
- Panel slides in from right with smooth animation
- Close button closes panel

### Dependencies
- Task 4 (recent tokens list)

---

## Task 6: Implement Token Revocation

**Owner**: UI Developer  
**Priority**: MEDIUM  
**Estimated Effort**: 2 hours

### Description
Implement token revocation with confirmation dialog and API integration.

### Subtasks
- [ ] 6.1 Implement `revokeToken()` function calling `DELETE /pilot-demo/api/evidence-links/revoke/{token_id}`
- [ ] 6.2 Add confirmation dialog before revocation
- [ ] 6.3 Update local token status to "REVOKED" on success
- [ ] 6.4 Refresh recent tokens list
- [ ] 6.5 Show success/error message

### Acceptance Criteria
- Revoke button shows confirmation dialog
- Successful revocation updates token status to "REVOKED"
- Revoked tokens show red badge in recent tokens list
- Error message displays if revocation fails

### Dependencies
- Task 5 (token detail panel)

---

## Task 7: Add Bulk Token Issuance (Optional)

**Owner**: UI Developer  
**Priority**: LOW  
**Estimated Effort**: 4 hours

### Description
Add bulk token issuance functionality for multiple workers at once.

### Subtasks
- [ ] 7.1 Add "Bulk Issue" button to main form
- [ ] 7.2 Create modal with textarea for comma-separated phone numbers
- [ ] 7.3 Implement sequential token issuance for each phone number
- [ ] 7.4 Add progress indicator
- [ ] 7.5 Generate CSV file with all issued token URLs
- [ ] 7.6 Show summary (total, success, failed)

### Acceptance Criteria
- Bulk issue modal opens when button is clicked
- Tokens are issued sequentially for each phone number
- Progress indicator shows current status
- Summary shows success/failure counts
- CSV file downloads with all token URLs

### Dependencies
- Task 3 (token issuance)

---

## Task 8: Create End-to-End Verification Script

**Owner**: QA Engineer  
**Priority**: HIGH  
**Estimated Effort**: 3 hours

### Description
Create self-test script verifying the complete token issuance → worker submission → supervisory reveal cycle.

### Subtasks
- [ ] 8.1 Create `scripts/dev/verify_worker_token_issuance_e2e.sh`
- [ ] 8.2 Implement token issuance test (POST /pilot-demo/api/evidence-links/issue)
- [ ] 8.3 Implement worker submission test using issued token
- [ ] 8.4 Implement expiry enforcement test (attempt to use expired token)
- [ ] 8.5 Implement single-use enforcement test (attempt to reuse token)
- [ ] 8.6 Implement GPS validation test (submit outside radius)
- [ ] 8.7 Emit evidence JSON to `evidence/phase1/worker_token_issuance_e2e.json`

### Acceptance Criteria
- Script issues token via API and verifies HTTP 200
- Script submits WEIGHBRIDGE_RECORD using token and verifies HTTP 202
- Script confirms submission appears in supervisory reveal endpoint
- Script confirms expired token is rejected (HTTP 401/403)
- Script confirms reused token is rejected
- Script confirms GPS validation rejects out-of-radius submissions
- Script exits 0 only when all checks pass

### Dependencies
- Task 3 (token issuance)

---

## Task 9: Update TSK-P1-219 Verifier

**Owner**: QA Engineer  
**Priority**: HIGH  
**Estimated Effort**: 1 hour

### Description
Update the TSK-P1-219 verifier to expect 4 tabs instead of 3.

### Subtasks
- [ ] 9.1 Update `scripts/audit/verify_tsk_p1_219.sh` tab count check (3 → 4)
- [ ] 9.2 Add check for worker-tokens tab existence
- [ ] 9.3 Add check for screen-worker-tokens screen existence
- [ ] 9.4 Update evidence JSON schema
- [ ] 9.5 Update `.toolchain/script_integrity/verifier_hashes.sha256`

### Acceptance Criteria
- Verifier passes when 4 tabs exist
- Verifier checks for worker-tokens tab specifically
- Verifier checks for screen-worker-tokens screen
- Evidence JSON includes new checks

### Dependencies
- Task 1 (tab structure)

---

## Task 10: Integration Testing

**Owner**: QA Engineer  
**Priority**: HIGH  
**Estimated Effort**: 2 hours

### Description
Perform integration testing of the complete worker token issuance flow.

### Subtasks
- [ ] 10.1 Test token issuance for valid worker
- [ ] 10.2 Test token issuance for invalid worker (not registered, wrong type, inactive)
- [ ] 10.3 Test worker landing page with issued token
- [ ] 10.4 Test token expiry (wait 5 minutes)
- [ ] 10.5 Test token revocation
- [ ] 10.6 Test recent tokens list updates
- [ ] 10.7 Test countdown timer accuracy

### Acceptance Criteria
- All positive test cases pass
- All negative test cases show appropriate errors
- Token expiry is enforced correctly
- Revocation works as expected
- UI updates correctly in all scenarios

### Dependencies
- All previous tasks
