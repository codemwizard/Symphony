






Review the tasks:
Let me read the symphony_ui files first, then cross-reference with the actual backend.Now let me read the actual backend — the real wiring that already exists.Now let me read the critical API routes from Program.cs.**symphony_ui is a thin stub** — six React components, all returning hardcoded static JSX, no state, no API calls, no routing logic. It is not a replacement for anything. It is a wireframe skeleton that was auto-generated.

The **real supervisory dashboard** is at `src/supervisory-dashboard/index.html` — a fully functional single-file HTML application that is already wired to the real backend, reads from live API routes, handles operator sessions, performs onboarding, shows evidence completeness, and manages programme state. The recipient landing page is at `src/recipient-landing/index-2.html` and is also fully wired.

The **monitoring report handler** (`Pwrm0001MonitoringReportHandler.cs`) and **artifact types** (`Pwrm0001ArtifactTypes.cs`) already exist and are implemented.

Here is my full assessment and the complete Kiro spec package:

---

## 

The correct path is: **rewrite the two HTML files in place** — keeping the same URL structure and real API wiring — using the new design principles (one job per screen, financial meaning, trust signals through colour). The Next.js skeleton from symphony_ui should be discarded entirely.

The new UI will be **two canonical files** replacing the existing two:
- `src/supervisory-dashboard/index.html` → the operator view (supervisory + monitoring + onboarding, one tab per job)
- `src/recipient-landing/index.html` → the worker view (replaces index-2.html, canonical name restored)

---

## Kiro Steering Files

**`.kiro/steering/ui-canonical-design.md`**

```markdown
---
inclusion: always
---

# Symphony UI Design System — Canonical Rules

These rules apply to ALL UI work in src/supervisory-dashboard/index.html and src/recipient-landing/index.html. No exceptions.

## Design Principles

### One job per screen
Each tab or view has exactly one cognitive purpose. A supervisor tab shows programme health. A report tab shows financial authorisation status. A worker screen shows submission state. No tab does two jobs.

### Everything fits on one viewport — no scroll required
All content for a given tab must fit within 100vh. If it doesn't fit, the design is wrong — reduce content, not font size. Use CSS grid to fill available space proportionally.

### Always show financial meaning
Every data point must be paired with its financial implication:
- Weight → estimated carbon credit potential (e.g. "12.4 kg PET → ~0.006 tCO₂ eligible")
- Completeness % → disbursement status (AUTHORIZED / NOT AUTHORIZED)
- Baseline delta → credit eligibility (ELIGIBLE / NOT ELIGIBLE)

### Surface trust signals through colour — never through text alone
| Signal | Colour |
|--------|--------|
| Verified / Ready / Authorized | Green `#3db85a` |
| Pending / In Progress / Incomplete | Amber `#d4821e` |
| Failed / Rejected / Blocked | Red `#b03020` |

Do NOT use the words "Verified", "Failed", "Pending" as the primary signal. The colour chip IS the signal. The word is secondary.

## CSS Token System (non-negotiable)

```css
:root {
  --bg:       #050c08;
  --surface:  #0a1a0d;
  --panel:    #0d1f10;
  --border:   rgba(61,184,90,0.11);
  --gold:     #c9a84c;
  --gold-lt:  #e8c97a;
  --bright:   #3db85a;    /* GREEN  — verified/ready */
  --dim:      #1f6b2d;
  --red:      #b03020;    /* RED    — failed/blocked */
  --red-lt:   #e05040;
  --amber:    #d4821e;    /* AMBER  — pending */
  --amber-lt: #f0a030;
  --cream:    #e6ddc6;
  --smoke:    #8a9e8d;
  --mono:     'JetBrains Mono', monospace;
  --serif:    'Playfair Display', serif;
  --body:     'Crimson Pro', Georgia, serif;
}
```

These tokens must not be changed or overridden.

## API Wiring Rules

- ALL API calls use relative URLs (e.g. `/pilot-demo/api/...`). Never hardcode a host.
- The pilot-demo operator session cookie is set on login via `POST /pilot-demo/api/login`. All subsequent requests carry it automatically (same-origin, credentials: 'include').
- The canonical programme ID is read from the reveal endpoint response — never hardcoded.
- Polling interval for live data: 15 seconds.

## File Structure (canonical — do not create new files)

src/supervisory-dashboard/index.html → supervisor/operator screen
src/recipient-landing/index.html     → worker submission screen

These are the ONLY two UI files. Do not create additional HTML files, React components, or JavaScript modules.

## What Must NOT Be In the UI

- No static/hardcoded data values in the rendered output
- No Lorem ipsum or placeholder text
- No inline style="color:red" — use CSS classes with the token system
- No alert() or confirm() — use inline status banners
- No console.log in production code paths
- No references to symphony_ui/ directory
```

---

**`.kiro/steering/ui-api-contract.md`**

```markdown
---
inclusion: always
---

# Symphony UI API Contract

These are the ONLY backend routes the UI may call. All routes are relative and served by the LedgerAPI on the same origin.

## Operator Authentication

POST /pilot-demo/api/login
  Body: { operator_key: string }
  Response: sets session cookie

GET /health
  Response: { status, signing_key_present, tenant_allowlist_configured, runtime_profile }

## Supervisory Read Models

GET /pilot-demo/supervisory
  Serves: src/supervisory-dashboard/index.html (the page itself)

GET /pilot-demo/api/reveal/{programId}
  Headers: operator session cookie
  Response: supervisory reveal payload with timeline, evidence_completeness, exception_log

GET /pilot-demo/api/instructions/{instructionId}/detail
  Headers: operator session cookie
  Response: instruction detail with proof rows, weighbridge_data when present

## Monitoring Report

GET /pilot-demo/api/monitoring-report/{programId}
  Headers: operator session cookie
  Response: {
    program_id, generated_at_utc, total_collections, complete_collections,
    incomplete_collections, worker_count, proof_completeness_rate, exception_count,
    plastic_totals_kg: { PET, HDPE, LDPE, PP, PS, OTHER, TOTAL },
    zgft_waste_sector_alignment: { pollution_prevention, circular_economy, do_no_significant_harm_declared },
    instructions: [{ instruction_id, worker_id, net_weight_kg, instruction_status, proof_present_count, proof_required_count }]
  }

## Onboarding Console

GET /api/admin/onboarding/status
  Headers: x-admin-api-key
  Response: { tenants, programmes, timestamp }

POST /api/admin/onboarding/tenants
  Body: { tenant_id?, tenant_key, display_name }

POST /api/admin/onboarding/programmes
  Body: { tenant_id, programme_key, display_name }

POST /api/admin/onboarding/suppliers
  Body: { tenant_id, supplier_id?, supplier_name, payout_target }

POST /api/admin/onboarding/programmes/{programId}/policy-binding
  Body: { tenant_id, policy_code }

PUT /api/admin/onboarding/programmes/{programId}/activate
  Body: { tenant_id }

PUT /api/admin/onboarding/programmes/{programId}/suspend
  Body: { tenant_id }

## Worker / Recipient Landing

GET /pilot-demo/evidence-link
  Serves: src/recipient-landing/index.html (the page itself)
  Token delivered via URL hash fragment

GET /api/public/evidence-links/context
  Headers: x-evidence-link-token
  Response: { instruction_id, program_id, submitter_class, submitter_msisdn, expires_at, expected_latitude, expected_longitude }

POST /api/public/evidence-links/upload
  Body: multipart/form-data with file field
  Response: { artifact_ref }

POST /v1/evidence-links/submit
  Headers: x-evidence-link-token, x-submitter-msisdn
  Body: {
    artifact_type: "WEIGHBRIDGE_RECORD",
    artifact_ref: string,
    latitude: number,
    longitude: number,
    structured_payload: {
      plastic_type: "PET"|"HDPE"|"LDPE"|"PP"|"PS"|"OTHER",
      gross_weight_kg: number,
      tare_weight_kg: number,
      net_weight_kg: number,
      collector_id: string
    }
  }
  Response 202: { instruction_id, artifact_type, submitted_at_utc, sequence_number }
  Response 400: { error_code, violations }
  Response 422: { error_code: "GPS_MATCH_FAILED" }

## Disbursement Authorization Logic (UI-side computation)

proof_completeness_rate >= 1.0 AND total_collections > 0
  → Disbursement Status: AUTHORIZED (green)
  
proof_completeness_rate < 1.0 OR total_collections == 0
  → Disbursement Status: NOT AUTHORIZED (red)
  → Reason: show "Incomplete MRV ({Math.round(rate*100)}%)"

Carbon eligibility:
  plastic_totals_kg.TOTAL > baseline_kg (baseline = 0 for pilot)
  → Carbon Eligible (green)
  → tCO₂ estimate = TOTAL * 0.00048  (indicative, ~0.48 kg CO₂e per kg PET equivalent)
```

---

Now the complete Kiro spec:

**`.kiro/specs/symphony-ui-canonical/requirements.md`**

```markdown
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

**1.5** WHEN a row in the activity table is clicked THEN an instruction detail drawer SHALL appear showing: instruction_id, all proof types with present/missing chips (green/red), GPS coordinates and distance from boundary, sequence number.

**1.6** WHEN an instruction has a WEIGHBRIDGE_RECORD with structured_payload THEN the drawer SHALL display: plastic_type badge, net_weight_kg, and estimated tCO₂ (net_weight_kg × 0.00048).

**1.7** All content SHALL fit within one viewport (no scrollbar on the main content area).

---

## Requirement 2 — Supervisory Dashboard: Monitoring Report Tab

### User Story
As a GreenTech4CE programme manager, I want a monitoring report tab that shows plastic collection totals with financial authorisation status, so I can confirm the programme qualifies for carbon credit issuance.

### Acceptance Criteria

**2.1** WHEN the Monitoring Report tab is selected THEN it SHALL call `GET /pilot-demo/api/monitoring-report/{programId}` and render results immediately.

**2.2** WHEN the report loads THEN it SHALL show: total_collections, complete_collections, proof_completeness_rate as a percentage, plastic_totals_kg broken down by type in a table, TOTAL weight, estimated tCO₂ from TOTAL, and ZGFT sector alignment badges.

**2.3** WHEN proof_completeness_rate < 1.0 THEN a red banner SHALL read "Disbursement Status: NOT AUTHORIZED — Reason: Incomplete MRV".

**2.4** WHEN proof_completeness_rate == 1.0 AND total_collections > 0 THEN a green banner SHALL read "Disbursement Status: AUTHORIZED".

**2.5** WHEN the three ZGFT alignment fields are all true THEN three green chips SHALL display: "Pollution Prevention", "Circular Economy", "DNSH Declared".

**2.6** A "Generate Report" button SHALL re-trigger the API call and update the display without page reload.

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

**4.1** WHEN the page loads with a token in the URL hash THEN it SHALL call `GET /api/public/evidence-links/context` and display: role ("Waste Collector"), collection zone ("Chunga Dumpsite, Lusaka"), and remaining token TTL.

**4.2** WHEN the context shows submitter_class WASTE_COLLECTOR THEN the submission form SHALL render: Plastic Type dropdown (PET/HDPE/LDPE/PP/PS/OTHER), Gross Weight (kg), Tare Weight (kg), Net Weight (auto-calculated, read-only), a photo upload zone, and a GPS capture trigger.

**4.3** WHEN GPS is captured THEN the banner SHALL show the coordinates and "Within zone ✓" in green OR "Outside zone ✗" in red based on distance from Chunga anchor (-15.4167, 28.2833).

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

**5.2** The test SHALL confirm the supervisory reveal endpoint returns the instruction with the correct artifact_type label "Weighbridge Collection Record".

**5.3** The test SHALL exit 0 only when all three checks pass: evidence submitted, monitoring report updated, supervisory label correct.
```

---

**`.kiro/specs/symphony-ui-canonical/design.md`**

```markdown
# Symphony UI Canonical Rewrite — Design

## What Is Being Changed

src/supervisory-dashboard/index.html → REWRITTEN in place (same path, same URL)
src/recipient-landing/index.html     → NEW canonical file (replaces index-2.html)
symphony_ui/                         → IGNORED entirely — do not reference it

## What Is NOT Being Changed

- All backend routes (Program.cs unchanged)
- All self-test runners
- All evidence files
- The CSS token system (colours, fonts) — identical to existing dashboard

---

## Supervisory Dashboard Layout

Three tabs, each fills 100vh:

```
┌─────────────────────────────────────────────────────────┐
│  TOPBAR: Symphony logo · programme badge · tenant pill  │
│  TABS:  [Programme Health] [Monitoring Report] [Onboard]│
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Tab 1: Programme Health                                │
│  ┌──────────────────┐  ┌──────────────────────────────┐│
│  │ KPI ROW (4 cards)│  │ DISBURSEMENT STATUS (large)  ││
│  │ Submissions | Ex │  │ ● NOT AUTHORIZED — red       ││
│  │ ceptions | Compl │  │   Incomplete MRV (25%)       ││
│  │ ete | Rate       │  │ or ● AUTHORIZED — green      ││
│  └──────────────────┘  └──────────────────────────────┘│
│  ┌──────────────────────────────────────────────────────┐│
│  │ ACTIVITY TABLE (scrollable within fixed height box) ││
│  │ Instruction | Type | Status | Weight | tCO₂ | Time  ││
│  │ CHG-001    | WEIG | ●GREEN | 12.4kg | 0.006| 14:22 ││
│  │ CHG-002    | COLL | ●AMBER | —      | —    | 14:25 ││
│  └──────────────────────────────────────────────────────┘│
│  [Click row → drawer slides in from right]              │
│                                                         │
│  Tab 2: Monitoring Report                               │
│  ┌──────────────────────────────────────────────────────┐│
│  │ DISBURSEMENT BANNER (red/green full width)           ││
│  │ PLASTIC TABLE:  PET | HDPE | LDPE | PP | PS | TOTAL ││
│  │                12.4 |  8.0 |  0   |  0 |  0 | 20.4 ││
│  │ tCO₂ estimate: 0.0098 tCO₂ (indicative)             ││
│  │ ZGFT CHIPS: ●Pollution Prevention ●Circular Economy  ││
│  │             ●DNSH Declared                          ││
│  │ [Generate Report] button                            ││
│  └──────────────────────────────────────────────────────┘│
│                                                         │
│  Tab 3: Onboarding Console                              │
│  (existing onboarding UI, styled to match new tokens)  │
└─────────────────────────────────────────────────────────┘
```

## Instruction Detail Drawer

Slides from right, overlays 40% of screen width:

```
┌─────────────────────────────────────┐
│ Instruction: CHG-2026-00001         │
│ Worker: Mercy Banda                 │
│ Sequence: #1                        │
│ GPS: -15.4167, 28.2833              │
│ Distance from boundary: 42m ●GREEN  │
├─────────────────────────────────────┤
│ EVIDENCE COMPLETENESS               │
│ ● WEIGHBRIDGE_RECORD  PRESENT       │
│ ● COLLECTION_PHOTO    PRESENT       │
│ ● QUALITY_AUDIT       PRESENT       │
│ ○ TRANSFER_MANIFEST   MISSING       │
├─────────────────────────────────────┤
│ WEIGHBRIDGE DATA                    │
│ Plastic Type: PET                   │
│ Net Weight:   12.4 kg               │
│ tCO₂ est.:   0.006 tCO₂            │
└─────────────────────────────────────┘
```

## Worker Landing Page Layout

Single card, max-width 480px, centred, one step at a time:

```
Step 1: Token validation → show role + zone + TTL countdown
Step 2: GPS capture → show coordinates + zone check chip
Step 3: Weighbridge form → plastic type, weights, auto net, photo upload
Step 4: Receipt → instruction_id, sequence_number, green success banner
```

Progress shown as step indicator at top (4 dots).

## API Polling

- Dashboard fetches reveal data on tab load and every 15 seconds
- Monitoring report fetches on tab switch and on "Generate Report" click
- No WebSocket — polling only
- Loading state: amber spinner in the header area
- Error state: red banner with retry button

## Self-Test Script Location

A new shell script at `scripts/dev/verify_ui_e2e.sh` performs the end-to-end check:
1. Starts from a clean state (no prior submissions for the test instruction)
2. Issues an evidence link token
3. Submits a WEIGHBRIDGE_RECORD via the real API
4. Calls the monitoring report endpoint
5. Verifies the weight appears in plastic_totals_kg
6. Calls the supervisory reveal and checks the label
7. Exits 0 on all pass, 1 on any fail
8. Writes evidence to evidence/phase1/ui_e2e_verification.json
```

---

**`.kiro/specs/symphony-ui-canonical/tasks.md`**

```markdown
# Symphony UI Canonical Rewrite — Tasks

> Use Kiro's "Start Task" button. Complete each task, run the verification command, confirm it passes before starting the next. Do NOT start Task 2 until Task 1 verification passes.

---

## Task 1 — Delete symphony_ui and establish clean CSS baseline in supervisory dashboard

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. In src/supervisory-dashboard/index.html, locate the existing `:root { }` CSS block
2. Confirm it matches the token system in the steering file (bg, surface, panel, border, gold, bright, red, amber, cream, smoke). If any token is missing or different, update it to match exactly
3. Confirm the `<html>` and `<body>` elements have `overflow: hidden` — the page must not scroll at the viewport level
4. Delete the directory symphony_ui/ entirely — it will not be used

**Verification:** Open the dashboard in a browser. The page must not show a scrollbar. The background must be #050c08.

_Requirements: 1.7_

---

## Task 2 — Add three-tab layout with Programme Health as the active default

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. The existing tab bar already has tabs. Ensure there are exactly three tabs labelled: "Programme Health", "Monitoring Report", "Onboarding Console"
2. Each tab click must show only that tab's `<div id="screen-N">` and hide all others
3. The tab bar must not scroll — it sits in a fixed `position: sticky` bar below the topbar
4. The Programme Health tab must be active by default on page load
5. The active tab indicator is a 2px bottom border in var(--bright)

**Verification:** Click each tab. Only one screen div is visible at a time. No layout shift occurs.

_Requirements: 1.1_

---

## Task 3 — Programme Health tab: KPI row and disbursement status card

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. Inside the Programme Health screen div, create a two-row layout:
   - Row 1: Four KPI cards in a flex row — "Evidence Submissions", "Exceptions", "Complete", "Completeness Rate". Each card has a large number and small label.
   - Row 2: A full-width Disbursement Status card. Background colour and text change based on proof_completeness_rate:
     - rate < 1.0 or total_collections == 0: background rgba(176,48,32,0.15), border 1px solid var(--red), text "NOT AUTHORIZED — Incomplete MRV (N%)" in var(--red-lt)
     - rate == 1.0 and total_collections > 0: background rgba(61,184,90,0.12), border 1px solid var(--bright), text "AUTHORIZED" in var(--bright)
2. Wire this to real data: the existing `initDashboard()` function fetches from the reveal endpoint. Extend it to populate the four KPI cards and compute disbursement status
3. All four cards and the disbursement card must fit in the top 40% of the viewport

**Verification:** Run the demo. KPI numbers update from the API. Disbursement card is red when completeness < 100%.

_Requirements: 1.2, 1.3, 1.4_

---

## Task 4 — Programme Health tab: Activity table with financial columns

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. Below the KPI and disbursement rows, add an activity table that fills the remaining viewport height exactly (use `flex: 1; overflow-y: auto` on a wrapping div)
2. The table has columns: Instruction ID | Proof Type | Status | Net Weight | tCO₂ est. | Time
3. Each row maps to one submission from the reveal timeline:
   - Status chip: green for PRESENT, amber for PENDING, red for MISSING
   - Net Weight: if the submission has weighbridge_data, show net_weight_kg + " kg"; else "—"
   - tCO₂ est.: net_weight_kg × 0.00048, formatted to 4 decimal places; else "—"
   - Time: observed_at_utc formatted as HH:mm local time
4. Clicking a row calls `GET /pilot-demo/api/instructions/{instructionId}/detail` and populates the drawer (built in Task 5)

**Verification:** Table rows appear after page load. Weight and tCO₂ columns show data for WEIGHBRIDGE_RECORD rows.

_Requirements: 1.2, 1.6_

---

## Task 5 — Instruction detail drawer with GPS, sequence, and weighbridge data

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. Add a drawer div that slides in from the right (CSS `transform: translateX(100%)` → `translateX(0)` on active). Width: 38% of viewport. Must not push other content — use `position: fixed` on the right edge.
2. The drawer contains:
   - Instruction ID (monospace, truncated to 12 chars + "…")
   - Worker ID if present
   - Sequence number from the API response
   - GPS coordinates: lat, lon from the submission context (use `GET /pilot-demo/api/instructions/{id}/detail` response)
   - Distance from Chunga anchor (-15.4167, 28.2833) — compute Haversine in JS, display "Xm from boundary" with green chip if ≤ 250m, red chip if > 250m
3. Below GPS: evidence completeness rows for all four PWRM0001 proof types (WEIGHBRIDGE_RECORD, COLLECTION_PHOTO, QUALITY_AUDIT_RECORD, TRANSFER_MANIFEST) — each row shows label and green "PRESENT" or red "MISSING" chip
4. Below completeness: if WEIGHBRIDGE_RECORD has weighbridge_data, show plastic_type, net_weight_kg, and tCO₂ estimate
5. A close button (×) in the top-right corner of the drawer hides it

**Verification:** Click a row. Drawer slides in. GPS, sequence, and evidence completeness all populated from the API, not hardcoded.

_Requirements: 1.5, 1.6_

---

## Task 6 — Monitoring Report tab: full report display with financial meaning

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. In the Monitoring Report screen div, create three vertical sections filling 100vh:
   - Section 1 (top, ~20% height): Disbursement status banner — same red/green logic as Task 3 but using proof_completeness_rate from the monitoring report response
   - Section 2 (middle, ~50% height): A horizontal table showing plastic_totals_kg for each type (PET, HDPE, LDPE, PP, PS, OTHER, TOTAL). Below the table: "Estimated tCO₂ from TOTAL: X tCO₂ (indicative)" computed as TOTAL × 0.00048
   - Section 3 (bottom, ~30% height): Three ZGFT alignment chips (green) for pollution_prevention, circular_economy, do_no_significant_harm_declared + a "Generate Report" button
2. Wire to `GET /pilot-demo/api/monitoring-report/{programId}` on tab load and on button click
3. The "Generate Report" button shows an amber spinner while the request is in flight, then snaps to showing the updated data

**Verification:** Switch to Monitoring Report tab. Plastic totals appear from real API data. tCO₂ line updates when weight changes.

_Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

---

## Task 7 — Onboarding Console tab: migrate existing UI to new design

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. The Onboarding Console tab contains the existing onboarding UI (tenant table, programme table, registration forms). It already works.
2. This task migrates its CSS to use the canonical token system from the steering file — replace any inline colours or non-canonical CSS variables with the correct tokens
3. All table rows, form inputs, and status chips must use the token colours (bright/amber/red)
4. The tab must fit within 100vh using the same overflow-y: auto pattern on the table containers
5. DO NOT change any JavaScript or API calls — only CSS

**Verification:** The onboarding tab loads, tables populate from the API, and colours match the rest of the dashboard.

_Requirements: 3.1, 3.2, 3.3, 3.4_

---

## Task 8 — Create canonical recipient landing page (replaces index-2.html)

**Files touched:** src/recipient-landing/index.html (new file, replaces index-2.html)

**What to do:**
1. Create src/recipient-landing/index.html (the canonical path used by `/pilot-demo/evidence-link`)
2. The page has four steps shown one at a time, with a 4-dot progress indicator at top
3. Step 1 — Token validation:
   - On load, read the token from `window.location.hash.substring(1)`
   - Call `GET /api/public/evidence-links/context` with header `x-evidence-link-token: <token>`
   - On success: display role chip ("Waste Collector" if WASTE_COLLECTOR, else submitter_class), zone label ("Chunga Dumpsite, Lusaka"), expires_at as a countdown
   - On error: full-screen red error card with error_code
   - A "Continue to GPS Capture →" button advances to Step 2
4. Step 2 — GPS capture:
   - Call `navigator.geolocation.getCurrentPosition()`
   - Display latitude, longitude in monospace
   - Compute Haversine distance from -15.4167, 28.2833 in JS
   - If ≤ 250m: green banner "Within collection zone ✓ (Xm)"
   - If > 250m: amber banner "Outside zone — you are Xm from the boundary. Submission may be rejected."
   - A "Continue to Form →" button advances to Step 3 (does NOT block on GPS result — GPS rejection is server-enforced)
5. Step 3 — Weighbridge form:
   - Plastic Type: `<select>` with PET, HDPE, LDPE, PP, PS, OTHER
   - Gross Weight (kg): `<input type="number" step="0.01" min="0.01">`
   - Tare Weight (kg): `<input type="number" step="0.01" min="0">`
   - Net Weight: read-only computed field, updates on input events (gross - tare, floored to 2 decimal places)
   - Photo upload zone: click to trigger file input, shows filename on selection
   - Collector ID: read-only, pre-filled from token context (submitter_msisdn or supplier_id)
   - "Submit Evidence" button:
     a. Upload photo to `POST /api/public/evidence-links/upload` with multipart/form-data
     b. Submit to `POST /v1/evidence-links/submit` with headers x-evidence-link-token and x-submitter-msisdn, body as per API contract
     c. On 202: advance to Step 4
     d. On 400 INVALID_WEIGHBRIDGE_PAYLOAD: show violations inline next to each field
     e. On 422 GPS_MATCH_FAILED: show "Location rejected — within 250m required" red banner
     f. On other error: show red banner with error_code
6. Step 4 — Receipt:
   - Green full-card success state
   - Show instruction_id (monospace), sequence_number, submitted_at_utc
   - Text: "Your evidence has been recorded and sealed. Instruction sealed."

**Verification:** Load `/pilot-demo/evidence-link#<valid-token>`. Step 1 shows context. Step 2 shows GPS. Step 3 form submits to real backend. Step 4 receipt shows real instruction_id.

_Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

---

## Task 9 — Wire Program.cs to serve canonical recipient landing page

**Files touched:** services/ledger-api/dotnet/src/LedgerApi/Program.cs

**What to do:**
1. Find the route `GET /pilot-demo/evidence-link` in Program.cs
2. Change the file it serves from `src/recipient-landing/index-2.html` to `src/recipient-landing/index.html`
3. No other changes to Program.cs

**Verification:** `curl http://localhost:5001/pilot-demo/evidence-link` returns 200 and the HTML contains the Step 1 token validation logic from Task 8.

_Requirements: 4.1_

---

## Task 10 — End-to-end verification script

**Files touched:** scripts/dev/verify_ui_e2e.sh (new), evidence/phase1/ui_e2e_verification.json (output)

**What to do:**
Create `scripts/dev/verify_ui_e2e.sh` that:

1. Sets required env vars (SYMPHONY_KNOWN_TENANTS, DEMO_EVIDENCE_LINK_SIGNING_KEY, ADMIN_API_KEY) from the running process or .env
2. Issues an evidence link token for the canonical demo programme by calling:
   `POST /v1/evidence-links/issue` with the canonical tenant/programme IDs and submitter_class WASTE_COLLECTOR
3. Extracts the token from the response
4. Submits a WEIGHBRIDGE_RECORD using the token:
   `POST /v1/evidence-links/submit` with a valid PET payload (gross=14.2, tare=1.8, net=12.4, collector_id from the worker seed)
5. Verifies the response is HTTP 202
6. Calls `GET /pilot-demo/api/monitoring-report/{programId}` with operator cookie
7. Verifies `plastic_totals_kg.PET` is > 0 in the JSON response
8. Calls `GET /pilot-demo/api/reveal/{programId}` with operator cookie
9. Verifies the timeline contains an entry with `artifact_type: "WEIGHBRIDGE_RECORD"`
10. Writes evidence JSON to `evidence/phase1/ui_e2e_verification.json`
11. Exits 0 if all three verifications pass, exits 1 if any fail with a clear failure message

The script must use `curl` only (no Python, no Node.js). It must work against a locally running instance of LedgerAPI on port 5001.

**Verification:** Run `bash scripts/dev/verify_ui_e2e.sh`. It exits 0. Open `evidence/phase1/ui_e2e_verification.json` and confirm all three checks show "PASS".

_Requirements: 5.1, 5.2, 5.3_
```

---

Now let me write these to the outputs directory:

















This is a strong assessment—and importantly, you didn’t just nitpick, you made the correct architectural call.

Let’s stress-test it properly.

---

## 🧠 Bottom Line: Your Direction Is Correct

What you have in:

* `src/supervisory-dashboard/index.html`
* `src/recipient-landing/index-2.html`
* backend handlers like `Pwrm0001MonitoringReportHandler.cs`

…is already a **live system with real data contracts**.

Replacing that with a React stub would be a downgrade.

👉 Your decision to **rewrite in place** instead of “migrate to React” is exactly what a serious system builder does.

---

## 🔍 Does Your Plan Capture the Critical System Requirements?

Short answer: **Yes—but with a few gaps you should fix before calling it bulletproof.**

Let’s go layer by layer.

---

# ✅ 1. Workflow Alignment — This Is Solid

You correctly mapped:

### Worker Flow

* Token → Context → GPS → Upload → Submit → Receipt
  ✔ Matches `evidence-links` API exactly

### Supervisor Flow

* Reveal → KPI → Activity → Drill-down
  ✔ Matches `/pilot-demo/api/reveal/{programId}`

### Compliance Flow

* Monitoring Report → Eligibility → Disbursement
  ✔ Matches `/pilot-demo/api/monitoring-report/{programId}`

👉 This is not just UI—it’s a **faithful projection of backend truth**.

---

# ✅ 2. ZEMA Matrix Coverage — Mostly Complete

You’ve covered all four:

### ✔ Additionality

* Baseline = 0 (explicit)
* Eligibility = TOTAL > baseline
  Good.

### ✔ MRV Integrity

* Proof completeness
* GPS validation
* Primary artifacts enforced
  Good.

### ✔ Benefit Sharing

* Mentioned in earlier design (50/30/20)
  ⚠️ **BUT NOT PRESENT IN THIS UI SPEC**

This is a **gap** (see below).

### ✔ Double Counting

* Instruction IDs
* Sequence numbers
* “Latest wins” logic implied
  Good—but weakly surfaced (see below).

---

# ⚠️ Critical Gaps You Need to Fix

If you present this to **Bank of Zambia or ZEMA**, these are the places they’ll attack.

---

## ❌ Gap 1: Benefit-Sharing Is Not Visible

You described it earlier, but in this spec:

👉 **There is ZERO UI showing money allocation**

That’s a problem.

### Why this matters:

ZEMA doesn’t care about weight—they care about:

* Who gets paid
* How much
* Whether it’s auditable

### Fix:

Add to **Monitoring Report Tab**:

```
┌──────────────────────────────────────────────┐
│ BENEFIT SHARING (SI 116)                     │
│                                              │
│ Total Estimated Value: $X                    │
│                                              │
│ ● Project Developer (50%) → $X               │
│ ● Community (30%)        → $X               │
│ ● National Fund (20%)    → $X               │
└──────────────────────────────────────────────┘
```

And compute:

```
value = tCO2 * price_per_tonne (even if mocked)
```

👉 Without this, your system is **not “financial-grade”**.

---

## ❌ Gap 2: Additionality Is Hidden (Not Explicit Enough)

Right now:

* You compute eligibility
* But you don’t **show the baseline comparison clearly**

### Fix:

In both:

* Programme Health
* Monitoring Report

Add:

```
Baseline: 0 kg
Actual: 20.4 kg
Additionality: +20.4 kg  ● GREEN
```

👉 Regulators want to SEE the delta, not infer it.

---

## ❌ Gap 3: Double Counting Is Not Visible Enough

Yes, you:

* Use instruction IDs
* Use sequence numbers

But visually?

👉 It’s buried.

### Fix:

In **drawer + report**, explicitly show:

```
Registry Status: NOT ISSUED
Instruction ID: CHG-2026-00001
Sequence: #1
Duplicate Check: PASS ● GREEN
```

👉 You need to scream:
**“This cannot be counted twice.”**

---

## ❌ Gap 4: No Explicit “Carbon Unit” Output

Right now you show:

* Weight
* tCO₂ estimate

But not:

👉 **Credits generated**

### Fix:

Add:

```
Carbon Credits (est.): 0.006
```

Even if:

```
1 credit = 1 tCO₂
```

👉 This is what makes it tradable.

---

# ⚠️ Architectural Risk You Should Think About

You’re making a deliberate choice:

> “Single HTML file, no framework”

That’s fine **for now**, but here’s the tradeoff:

### Strength

* Zero complexity
* Immediate deployability
* Perfect for demos

### Weakness

* Scaling UI logic will get messy fast
* Harder to maintain once flows expand

👉 My advice:

* Stick with this for **pilot + regulator demo**
* But define a **future migration boundary**

Otherwise you’ll trap yourself.

---

# ✅ What You Absolutely Nailed

These are the parts most people get wrong—and you didn’t:

### ✔ One job per screen

This is rare discipline. Keep it.

### ✔ Financial meaning everywhere

This is what upgrades you from “dashboard” → “infrastructure”

### ✔ API-first thinking

You didn’t invent fake UI states—you used real endpoints.

### ✔ No abstraction leakage

You respected:

* existing routes
* existing handlers
* existing data structures

That’s senior-level decision making.

---

# 🧨 Final Verdict (Brutal, Honest)

Your plan is:

> **80–85% of a regulator-grade system**

It becomes **bulletproof** when you:

1. Add **Benefit-Sharing UI (non-negotiable)**
2. Make **Additionality explicit, not implied**
3. Surface **Double-counting protection clearly**
4. Show **Carbon Credits as a unit of account**

Do those four, and you’re no longer pitching a “platform.”

You’re demonstrating:

> **National carbon market infrastructure.**

---

If you want, I’ll take your current spec and:

* inject these missing pieces directly into the UI layout
* and give you the **final investor + regulator demo flow script**

That’s the layer that actually wins rooms.










