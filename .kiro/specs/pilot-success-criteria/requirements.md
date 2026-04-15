# Pilot Success Criteria Tab — Requirements

## Context

The supervisory dashboard currently has 3 tabs (soon to be 4 with worker token issuance) but the pilot demo requires 5 tabs. This spec addresses the missing "Pilot Success Criteria" tab (Tab 5), which provides stakeholders with real-time validation of Symphony's non-custodial architecture and regulatory compliance posture. This functionality is demonstrated in Act 4.1-4.3 of the pilot demo video script.

The tab serves as a live compliance dashboard showing that Symphony maintains its non-custodial posture, enforces tenant isolation, preserves evidence integrity, and operates within regulatory boundaries. This is critical for investor presentations, regulatory audits, and partner due diligence.

---

## Requirement 1 — Pilot Success Criteria Dashboard

### User Story
As a stakeholder or regulator, I want a dedicated tab showing real-time validation of Symphony's architectural and regulatory compliance criteria, so I can verify that the platform operates as claimed without holding funds or requiring payment licenses.

### Acceptance Criteria

**1.1** WHEN the "Pilot Success Criteria" tab is selected THEN it SHALL display three category sections:
- Technical Criteria (architecture and data integrity)
- Operational Criteria (functional capabilities)
- Regulatory Criteria (compliance and non-custodial posture)

**1.2** WHEN the tab loads THEN it SHALL call `GET /pilot-demo/api/pilot-success-criteria` and display results within 2 seconds or show an amber loading state.

**1.3** WHEN the criteria data is loaded THEN each criterion SHALL display:
- Criterion name
- Threshold or requirement
- Current status (PASS ✓ green / PENDING ⧗ amber / FAIL ✗ red)
- Last verified timestamp

**1.4** WHEN all criteria in a category pass THEN the category header SHALL show a green badge "ALL PASS".

**1.5** WHEN any criterion in a category fails THEN the category header SHALL show a red badge "ATTENTION REQUIRED".

**1.6** All content SHALL fit within one viewport (no scrollbar on the main content area).

---

## Requirement 2 — Technical Criteria Validation

### User Story
As a technical auditor, I want to see real-time validation of Symphony's technical architecture criteria, so I can verify that evidence trails are append-only, GPS is verified, and tenant isolation is enforced.

### Acceptance Criteria

**2.1** WHEN the Technical Criteria section is displayed THEN it SHALL show:
- Evidence trail append-only (INV-035, INV-091)
- GPS verification active (Geolocation API, not EXIF)
- Tenant isolation enforced at DB layer (INV-133)
- Policy version lock immutable (INV-090)
- Idempotency guard active (INV-011)
- Fail-closed under DB exhaustion (INV-039)

**2.2** WHEN a criterion is clicked THEN a detail panel SHALL appear showing:
- Invariant IDs referenced
- Verification method (e.g., "DB constraint check", "API endpoint test")
- Last verification timestamp
- Verification frequency (e.g., "Every API call", "Every 15 seconds")

**2.3** WHEN the evidence trail append-only criterion is verified THEN it SHALL:
- Query the evidence log for any UPDATE or DELETE operations
- Confirm all operations are INSERT only
- Display "PASS ✓" if no mutations detected
- Display "FAIL ✗" if any mutations detected

**2.4** WHEN the GPS verification criterion is verified THEN it SHALL:
- Confirm GPS is captured via Geolocation API
- Confirm EXIF metadata is NOT used
- Display "PASS ✓" if Geolocation API is active
- Display "FAIL ✗" if EXIF fallback is detected

**2.5** WHEN the tenant isolation criterion is verified THEN it SHALL:
- Confirm row-level security (RLS) policies are active
- Confirm cross-tenant queries are blocked
- Display "PASS ✓" if RLS is enforced
- Display "FAIL ✗" if RLS is bypassed

---

## Requirement 3 — Operational Criteria Validation

### User Story
As a programme operator, I want to see real-time validation of Symphony's operational capabilities, so I can verify that proof submission, dashboard access, and monitoring reports are functional.

### Acceptance Criteria

**3.1** WHEN the Operational Criteria section is displayed THEN it SHALL show:
- Proof submission functional (4 proof types accepted)
- Dashboard access working (supervisory read-only view)
- Monitoring report generation (PWRM0001 report available)
- Token issuance functional (evidence-link tokens issued)
- Worker landing page accessible (mobile-optimized)

**3.2** WHEN a criterion is clicked THEN a detail panel SHALL appear showing:
- Test method (e.g., "Submit test WEIGHBRIDGE_RECORD")
- Last test timestamp
- Test result (success/failure)
- Response time (e.g., "142ms")

**3.3** WHEN the proof submission criterion is verified THEN it SHALL:
- Attempt to submit a test WEIGHBRIDGE_RECORD
- Confirm HTTP 202 response
- Display "PASS ✓" if submission succeeds
- Display "FAIL ✗" if submission fails

**3.4** WHEN the dashboard access criterion is verified THEN it SHALL:
- Confirm supervisory reveal endpoint returns data
- Confirm read-only access (no write operations)
- Display "PASS ✓" if access is read-only
- Display "FAIL ✗" if write access is detected

**3.5** WHEN the monitoring report criterion is verified THEN it SHALL:
- Call `GET /pilot-demo/api/monitoring-report/{programId}`
- Confirm report contains plastic_totals_kg
- Display "PASS ✓" if report is generated
- Display "FAIL ✗" if report generation fails

---

## Requirement 4 — Regulatory Criteria Validation

### User Story
As a regulator or compliance officer, I want to see real-time validation of Symphony's regulatory compliance posture, so I can verify that the platform is non-custodial, does not claim settlement-rail status, and maintains PII decoupling.

### Acceptance Criteria

**4.1** WHEN the Regulatory Criteria section is displayed THEN it SHALL show:
- Non-custodial posture maintained (INV-114)
- No settlement-rail claim (no funds held)
- PII decoupled from audit trail (INV-115)
- Evidence survives data purge (INV-115)
- Supervisory view read-only (INV-111)
- No runtime DDL in production paths

**4.2** WHEN a criterion is clicked THEN a detail panel SHALL appear showing:
- Regulatory reference (e.g., "Payment Services Directive 2")
- Compliance method (e.g., "No custody of funds")
- Last audit timestamp
- Audit frequency (e.g., "Continuous")

**4.3** WHEN the non-custodial posture criterion is verified THEN it SHALL:
- Confirm no balance tables exist in schema
- Confirm no fund transfer operations in API
- Display "PASS ✓" if no custody detected
- Display "FAIL ✗" if custody operations detected

**4.4** WHEN the no settlement-rail claim criterion is verified THEN it SHALL:
- Confirm no payment initiation endpoints exist
- Confirm no settlement instructions in evidence log
- Display "PASS ✓" if no settlement claims detected
- Display "FAIL ✗" if settlement operations detected

**4.5** WHEN the PII decoupling criterion is verified THEN it SHALL:
- Confirm PII is stored separately from evidence log
- Confirm evidence log contains only hashes/references
- Display "PASS ✓" if PII is decoupled
- Display "FAIL ✗" if PII is embedded in evidence

---

## Requirement 5 — Overall Pilot Gate Status

### User Story
As a project manager, I want to see an overall pilot gate status that summarizes all criteria, so I can quickly determine if the pilot is ready for production or requires attention.

### Acceptance Criteria

**5.1** WHEN all criteria pass THEN the overall gate status SHALL display:
- Large green badge: "PILOT GATE: PASS ✓"
- Message: "All success criteria met. Pilot ready for production evaluation."
- Timestamp of last full verification

**5.2** WHEN any criterion fails THEN the overall gate status SHALL display:
- Large red badge: "PILOT GATE: ATTENTION REQUIRED ✗"
- Message: "N criteria require attention. Review details below."
- List of failed criteria with links to detail panels

**5.3** WHEN any criterion is pending THEN the overall gate status SHALL display:
- Large amber badge: "PILOT GATE: VERIFICATION IN PROGRESS ⧗"
- Message: "N criteria pending verification. Refresh in M seconds."
- Countdown timer to next verification cycle

**5.4** The overall gate status SHALL be prominently displayed at the top of the tab with large, color-coded typography.

---

## Requirement 6 — Criterion Detail Panel

### User Story
As a technical auditor, I want to drill down into individual criteria to see verification methods, test results, and historical data, so I can understand how each criterion is validated.

### Acceptance Criteria

**6.1** WHEN a criterion is clicked THEN a slide-out panel SHALL appear from the right showing:
- Criterion name and description
- Invariant IDs referenced (if applicable)
- Verification method (detailed explanation)
- Last verification timestamp
- Verification frequency
- Historical pass/fail data (last 10 verifications)

**6.2** WHEN the panel is open THEN a "Run Verification Now" button SHALL be available to trigger immediate re-verification.

**6.3** WHEN "Run Verification Now" is clicked THEN it SHALL:
- Call the verification endpoint for that criterion
- Show a loading spinner
- Update the criterion status with new result
- Display success/failure message

**6.4** WHEN the panel shows historical data THEN it SHALL display:
- Timestamp of each verification
- Result (PASS / FAIL)
- Response time (if applicable)
- Error message (if failed)

**6.5** The panel SHALL include a "Close" button to dismiss the panel.

---

## Requirement 7 — Auto-Refresh and Polling

### User Story
As a stakeholder monitoring the pilot, I want the success criteria to auto-refresh periodically, so I can see real-time status without manually refreshing the page.

### Acceptance Criteria

**7.1** WHEN the Pilot Success Criteria tab is active THEN it SHALL poll `GET /pilot-demo/api/pilot-success-criteria` every 30 seconds.

**7.2** WHEN new data is received THEN it SHALL:
- Update all criterion statuses
- Update last verified timestamps
- Update overall gate status
- Show a subtle flash animation on changed criteria

**7.3** WHEN the tab is not active (user switched to another tab) THEN polling SHALL pause.

**7.4** WHEN the user switches back to the tab THEN polling SHALL resume immediately with a fresh fetch.

**7.5** A "Refresh Now" button SHALL be available to trigger immediate refresh without waiting for the next poll cycle.

---

## Requirement 8 — Export Compliance Report

### User Story
As a compliance officer, I want to export the pilot success criteria as a PDF or JSON report, so I can include it in regulatory submissions or investor presentations.

### Acceptance Criteria

**8.1** WHEN the "Export Report" button is clicked THEN a modal SHALL appear with export options:
- JSON (machine-readable)
- PDF (human-readable)

**8.2** WHEN JSON export is selected THEN it SHALL:
- Generate a JSON file with all criteria, statuses, and timestamps
- Include verification methods and invariant references
- Download file as `pilot_success_criteria_{timestamp}.json`

**8.3** WHEN PDF export is selected THEN it SHALL:
- Generate a formatted PDF with Symphony branding
- Include all criteria with color-coded status indicators
- Include overall gate status
- Include generation timestamp and git SHA
- Download file as `pilot_success_criteria_{timestamp}.pdf`

**8.4** The exported report SHALL include a deterministic fingerprint (SHA-256 hash) for audit verification.

---

## Requirement 9 — End-to-End Verification

### User Story
As a technical lead, I want a self-test that confirms the pilot success criteria endpoint returns valid data and all criteria are verifiable.

### Acceptance Criteria

**9.1** A self-test script SHALL call `GET /pilot-demo/api/pilot-success-criteria` and verify HTTP 200.

**9.2** The test SHALL confirm the response contains all three categories (technical, operational, regulatory).

**9.3** The test SHALL confirm each criterion has required fields (name, status, last_verified).

**9.4** The test SHALL confirm at least one criterion in each category is marked PASS.

**9.5** The test SHALL exit 0 only when all checks pass: endpoint accessible, categories present, criteria valid, statuses present.
