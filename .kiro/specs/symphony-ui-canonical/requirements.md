# Symphony UI Canonical Rewrite — Requirements

## Context

The current supervisory dashboard (src/supervisory-dashboard/index.html) is functional but visually cluttered and does not enforce financial meaning or disbursement decisions. The recipient landing page exists as index-2.html (wrong canonical name). The symphony_ui/ Next.js skeleton is discarded — it is replaced by rewriting the two existing HTML files in place.

---

## Requirement 1 — Supervisory Dashboard: Programme Health Tab

### User Story
As a GreenTech4CE supervisor, I want to see programme health on a single screen with financial meaning attached to every metric, so I can immediately understand whether disbursement is authorised.

### Acceptance Criteria

**1.1** WHEN the dashboard loads THEN it SHALL fetch `GET /pilot-demo/api/reveal/{programId}` and display results within 2 seconds or show an amber loading state.

**1.2** WHEN the reveal data is loaded THEN the screen SHALL display: total evidence submissions, exception count, completeness percentage, disbursement status (AUTHORIZED green / NOT AUTHORIZED red), and a live activity table showing instruction_id, artifact_type, and status chip per row.

**1.3** WHEN completeness is below 100% THEN the disbursement status chip SHALL be red with text "NOT AUTHORIZED — Incomplete MRV (N%)".

**1.4** WHEN completeness reaches 100% and total_collections > 0 THEN the disbursement chip SHALL be green with text "AUTHORIZED".

**1.5** WHEN a row in the activity table is clicked THEN an instruction detail drawer SHALL appear showing: instruction_id, sequence number, registry status, duplicate check result, GPS distance from Chunga boundary, and evidence completeness per proof type.

**1.6** WHEN an instruction has a WEIGHBRIDGE_RECORD with structured_payload THEN the drawer SHALL display: plastic_type badge, net_weight_kg, estimated tCO₂ (net_weight_kg × 0.00048), and estimated carbon credits (equal to tCO₂ value).

**1.7** All content SHALL fit within one viewport (no scrollbar on the main content area).

---

## Requirement 2 — Supervisory Dashboard: Monitoring Report Tab

### User Story
As a GreenTech4CE programme manager, I want a monitoring report tab that shows plastic collection totals with financial authorisation status, additionality evidence, and benefit-sharing allocation, so I can confirm the programme qualifies for carbon credit issuance.

### Acceptance Criteria

**2.1** WHEN the Monitoring Report tab is selected THEN it SHALL call `GET /pilot-demo/api/monitoring-report/{programId}` and render results immediately.

**2.2** WHEN the report loads THEN it SHALL show: total_collections, complete_collections, proof_completeness_rate as a percentage, plastic_totals_kg broken down by type in a table, TOTAL weight, estimated tCO₂ from TOTAL, and estimated carbon credits.

**2.3** WHEN proof_completeness_rate < 1.0 THEN a red banner SHALL read "Disbursement Status: NOT AUTHORIZED — Reason: Incomplete MRV".

**2.4** WHEN proof_completeness_rate == 1.0 AND total_collections > 0 THEN a green banner SHALL read "Disbursement Status: AUTHORIZED".

**2.5** WHEN the three ZGFT alignment fields are all true THEN three green chips SHALL display: "Pollution Prevention ✓", "Circular Economy ✓", "DNSH Declared ✓".

**2.6** A "Generate Report" button SHALL re-trigger the API call and update the display without page reload.

**2.7** WHEN the report is displayed THEN an additionality row SHALL show: "Baseline: 0 kg | Actual: N kg | Additionality: +N kg" with a green chip when actual > 0.

**2.8** WHEN plastic_totals_kg.TOTAL > 0 THEN a benefit-sharing section SHALL show the three-way split: "Project Developer (50%): ZMW X", "Community (30%): ZMW X", "National Fund (20%): ZMW X", each labelled "(indicative)".

**2.9** WHEN plastic_totals_kg.TOTAL > 0 THEN a carbon credits section SHALL show "Estimated Carbon Credits: X credits (1 credit = 1 tCO₂, indicative)".

---

## Requirement 3 — Supervisory Dashboard: Onboarding Console Tab

### User Story
As a programme operator, I want an onboarding console tab to register tenants, programmes, and suppliers without leaving the dashboard.

### Acceptance Criteria

**3.1** WHEN the Onboarding tab is selected THEN it SHALL call `GET /api/admin/onboarding/status` and display tenant table and programme table.

**3.2** WHEN a tenant is registered via the form THEN `POST /api/admin/onboarding/tenants` SHALL be called and the table SHALL refresh within 1 second of success.

**3.3** WHEN a programme is activated THEN `PUT /api/admin/onboarding/programmes/{id}/activate` SHALL be called and the programme row SHALL show green ACTIVE chip.

**3.4** All form submission errors SHALL be shown inline as a red status message below the form — no alert() dialogs.

---

## Requirement 4 — Worker Recipient Landing Page

### User Story
As a waste collector at Chunga Dumpsite, I want a mobile-friendly submission page that guides me through identity confirmation, GPS capture, and weighbridge data entry, so I can submit a verifiable PWRM0001 evidence record.

### Acceptance Criteria

**4.1** WHEN the page loads with a token in the URL hash THEN it SHALL call `GET /api/public/evidence-links/context` and display: role ("Waste Collector"), collection zone via `resolveNeighbourhoodLabel` ("Chunga Dumpsite, Lusaka"), and remaining token TTL. Raw coordinates SHALL NOT appear in the DOM.

**4.2** WHEN the context shows submitter_class WASTE_COLLECTOR THEN the submission form SHALL render: Plastic Type dropdown (PET/HDPE/LDPE/PP/PS/OTHER), Gross Weight (kg), Tare Weight (kg), Net Weight (auto-calculated read-only), a photo upload zone, and a GPS capture trigger.

**4.3** WHEN GPS is captured THEN the banner SHALL show the neighbourhood label and "Within zone ✓" in green OR "Outside zone ✗" in red based on distance from Chunga anchor (-15.4167, 28.2833). Raw coordinates SHALL NOT be shown.

**4.4** WHEN the form is submitted THEN it SHALL: upload photo to `POST /api/public/evidence-links/upload`, then call `POST /v1/evidence-links/submit` with the full structured payload, then display a green success receipt showing instruction_id and sequence_number.

**4.5** WHEN the backend returns 400 with violations THEN each violation SHALL be displayed as a red inline error message next to the relevant field.

**4.6** WHEN the backend returns 422 GPS_MATCH_FAILED THEN the banner SHALL show "Location rejected — you must be within 250m of the collection point" in red.

**4.7** The entire form SHALL be usable on a 375px wide mobile screen without horizontal scroll.

---

## Requirement 5 — End-to-End Verification

### User Story
As a technical lead, I want a self-test that confirms the full UI → API → database cycle works for a complete PWRM0001 collection event.

### Acceptance Criteria

**5.1** A self-test script SHALL submit a complete WEIGHBRIDGE_RECORD through the real backend (not mocked), verify HTTP 202, then call the monitoring report endpoint and verify the weight appears in plastic_totals_kg.

**5.2** The test SHALL confirm the monitoring report shows additionality > 0 when actual weight > 0.

**5.3** The test SHALL confirm the benefit-sharing split sums to the total estimated value.

**5.4** The test SHALL confirm the supervisory reveal endpoint returns the instruction with the correct artifact_type label "Weighbridge Collection Record".

**5.5** The test SHALL exit 0 only when all four checks pass: evidence submitted, monitoring report updated, additionality confirmed, supervisory label correct.
