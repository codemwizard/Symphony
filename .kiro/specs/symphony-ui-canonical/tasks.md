# Symphony UI Canonical Rewrite — Tasks

> Use Kiro's "Start Task" button. Complete each task fully and run its verification command before starting the next task. Tasks are ordered by dependency — do not skip ahead.

---

## Task 1 — Delete symphony_ui and establish clean CSS baseline

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. Delete the directory `symphony_ui/` entirely — it will not be used.
2. In `src/supervisory-dashboard/index.html`, locate the `:root { }` CSS block and ensure it contains exactly the tokens from the steering file: `--bg`, `--surface`, `--panel`, `--border`, `--gold`, `--gold-lt`, `--bright`, `--dim`, `--red`, `--red-lt`, `--amber`, `--amber-lt`, `--cream`, `--smoke`, `--mono`, `--serif`, `--body`. Add any missing tokens verbatim.
3. Confirm `<html>` and `<body>` have `overflow: hidden` so the page never scrolls at viewport level.

**Verification:** Open the dashboard. No scrollbar visible. Background is `#050c08`.

_Requirements: 1.7_

---

## Task 2 — Add three-tab layout with Programme Health as default

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. Ensure exactly three tabs labelled "Programme Health", "Monitoring Report", "Onboarding Console".
2. Each tab click shows only that tab's `<div>` and hides all others via CSS class toggle.
3. Tab bar is `position: sticky` and does not scroll.
4. Programme Health tab is active by default on page load.
5. Active tab has a 2px bottom border in `var(--bright)`.

**Verification:** Click each tab. Only one content area is visible. No layout shift.

_Requirements: 1.1_

---

## Task 3 — Programme Health tab: KPI row and disbursement status card

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. Inside the Programme Health screen div, create two rows:
   - Row 1: Four KPI cards — "Evidence Submissions", "Exceptions", "Complete", "Completeness Rate". Large number + small label.
   - Row 2: Full-width Disbursement Status card. Dynamic styling:
     - `rate < 1.0` or `total_collections == 0`: red background, text "NOT AUTHORIZED — Incomplete MRV (N%)"
     - `rate == 1.0` and `total_collections > 0`: green background, text "AUTHORIZED"
2. Wire to real data from the reveal endpoint. Extend the existing `initDashboard()` function.
3. All four cards and the disbursement card fit in the top 40% of the viewport.

**Verification:** KPI numbers update from API. Disbursement card is red when completeness < 100%.

_Requirements: 1.2, 1.3, 1.4_

---

## Task 4 — Programme Health tab: Activity table with financial columns

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. Below the KPI rows, add a table filling remaining viewport height (`flex: 1; overflow-y: auto`).
2. Columns: Instruction ID | Proof Type | Status | Net Weight | tCO₂ est. | Time
   - Status chip: green=PRESENT, amber=PENDING, red=MISSING
   - Net Weight: `net_weight_kg + " kg"` if WEIGHBRIDGE_RECORD, else "—"
   - tCO₂ est.: `(net_weight_kg * 0.00048).toFixed(4)` if weight present, else "—"
   - Time: `observed_at_utc` formatted as HH:mm local
3. Row click calls `GET /pilot-demo/api/instructions/{instructionId}/detail` and opens the drawer (Task 5).

**Verification:** Rows show weight and tCO₂ columns populated for WEIGHBRIDGE_RECORD entries.

_Requirements: 1.2, 1.6_

---

## Task 5 — Instruction detail drawer with GPS, sequence, registry status, and weighbridge data

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. Add a drawer div: `position: fixed; right: 0; width: 38%; height: 100%; transform: translateX(100%)`. On active: `translateX(0)`.
2. The drawer shows:
   - Instruction ID (monospace, truncated to 12 chars + "…")
   - Worker ID if present
   - Sequence number from API
   - **Registry Status: "NOT ISSUED" (amber chip)** — hardcoded for pilot
   - **Duplicate Check: "PASS" (green chip)** — derived from unique sequence_number
   - GPS: call `resolveNeighbourhoodLabel(lat, lon)` → show neighbourhood label only. Never show raw coordinates. Compute Haversine distance from (-15.4167, 28.2833) and show "Xm from boundary" with green chip ≤ 250m, red chip > 250m.
3. Evidence completeness: four PWRM0001 proof type rows (WEIGHBRIDGE_RECORD, COLLECTION_PHOTO, QUALITY_AUDIT_RECORD, TRANSFER_MANIFEST) — green PRESENT / red MISSING chip per row.
4. If WEIGHBRIDGE_RECORD has weighbridge_data: show plastic_type, net_weight_kg, tCO₂ estimate `(net * 0.00048).toFixed(6)`, and carbon credits estimate (equal to tCO₂).
5. Close button (×) top-right hides the drawer.

**Note:** Raw latitude/longitude must never appear in any DOM element. Use only neighbourhood labels.

**Verification:** Click a row. Drawer slides in. Sequence, registry status, duplicate check, zone label, and evidence completeness all populated. No raw coordinates visible.

_Requirements: 1.5, 1.6_

---

## Task 6 — Monitoring Report tab: full financial report display

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. Three sections filling 100vh:
   - Section 1 (~20%): Disbursement status banner (same red/green logic as Task 3 but from monitoring report).
   - Section 2 (~50%):
     a. **Additionality row**: "Baseline: 0 kg | Actual: N kg | Additionality: +N kg ● GREEN". Always shown. Green chip when actual > 0, amber when 0.
     b. Plastic totals table: PET, HDPE, LDPE, PP, PS, OTHER, TOTAL with kg values.
     c. tCO₂ and credits row: "Estimated tCO₂: X | Estimated Credits: X credits (1 credit = 1 tCO₂, indicative)".
   - Section 3 (~30%):
     a. **Benefit sharing block** (always shown, values "(indicative)"):
        - "Project Developer (50%): ZMW X"
        - "Community (30%): ZMW X"
        - "National Fund (20%): ZMW X"
     b. Three ZGFT alignment chips (green): "Pollution Prevention ✓", "Circular Economy ✓", "DNSH Declared ✓".
     c. "Generate Report" button with amber spinner while in-flight.
2. Wire to `GET /pilot-demo/api/monitoring-report/{programId}` on tab load and button click.
3. Use `TCO2_PER_KG = 0.00048`, `PRICE_PER_TCO2_ZMW = 150.0`, `BENEFIT_SHARE = {0.50, 0.30, 0.20}` from steering file constants.

**Verification:** Switch to Monitoring Report. Additionality row shows. Benefit-sharing split shows. tCO₂ and credits line shows. All values match the plastic totals from real API data.

_Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9_

---

## Task 7 — Onboarding Console tab: migrate to canonical CSS tokens

**Files touched:** src/supervisory-dashboard/index.html

**What to do:**
1. The Onboarding Console tab already contains working onboarding UI. Do not change any JavaScript or API calls.
2. Replace any inline colours or non-canonical CSS variables with the correct tokens.
3. All table rows, form inputs, and chips use the token colours.
4. Tab content fits within 100vh using `overflow-y: auto` on table containers.

**Verification:** Onboarding tab loads, tables populate from API, colours match rest of dashboard.

_Requirements: 3.1, 3.2, 3.3, 3.4_

---

## Task 8 — Create canonical recipient landing page

**Files touched:** src/recipient-landing/index.html (replaces index-2.html)

**What to do:**
1. Create `src/recipient-landing/index.html` as the canonical file.
2. Four steps, one visible at a time, with 4-dot step indicator at top.

**Step 1 — Token validation:**
- Read token from `window.location.hash.replace('#','').replace('token=','')`.
- Call `GET /api/public/evidence-links/context` with `x-evidence-link-token` header.
- Show role chip ("Waste Collector" if WASTE_COLLECTOR, else raw submitter_class).
- Show zone via `resolveNeighbourhoodLabel(expected_latitude, expected_longitude)`. Never show raw coordinates.
- Show TTL countdown (seconds remaining = `expires_at` epoch - `Date.now()/1000`).
- On error: full-screen red error card with error_code.
- "Continue to GPS Capture →" button advances to Step 2.

**Step 2 — GPS capture:**
- Call `navigator.geolocation.getCurrentPosition()`.
- Show neighbourhood label (never raw coordinates).
- Compute Haversine distance from (-15.4167, 28.2833) in JS.
- ≤ 250m: green banner "Within collection zone ✓ (Xm from boundary)".
- > 250m: amber banner "Outside zone — Xm from boundary. Submission may be rejected."
- "Continue to Form →" advances to Step 3 regardless of GPS result — server enforces.

**Step 3 — Weighbridge form (WASTE_COLLECTOR only):**
- Plastic Type: `<select>` with PET, HDPE, LDPE, PP, PS, OTHER.
- Gross Weight (kg): `<input type="number" step="0.01" min="0.01">`.
- Tare Weight (kg): `<input type="number" step="0.01" min="0">`.
- Net Weight: readonly `<input>`, computed as `(parseFloat(gross) - parseFloat(tare)).toFixed(2)`. Comment: `// display only — backend recomputes from gross-tare`.
- Photo upload zone: click triggers file input; show filename on selection.
- Collector ID: readonly, pre-filled from token context `worker_id` or `submitter_msisdn`.
- "Submit Evidence" button:
  a. Upload photo: `POST /api/public/evidence-links/upload` multipart.
  b. Submit: `POST /v1/evidence-links/submit` with `x-evidence-link-token` and `x-submitter-msisdn` headers. Body: `{ artifact_type: "WEIGHBRIDGE_RECORD", artifact_ref, latitude, longitude, structured_payload: { plastic_type, gross_weight_kg: parseFloat(...), tare_weight_kg: parseFloat(...), net_weight_kg: parseFloat(...), collector_id } }`.
  c. 202 → advance to Step 4.
  d. 400 INVALID_WEIGHBRIDGE_PAYLOAD → show each violation inline next to relevant field.
  e. 422 GPS_MATCH_FAILED → red banner "Location rejected — within 250m of collection point required".
  f. Other error → red banner with error_code.

**Step 4 — Receipt:**
- Green full-card state.
- instruction_id (monospace), sequence_number, submitted_at_utc.
- Text: "Your evidence has been recorded and sealed."

**Important:** `resolveNeighbourhoodLabel` from steering file must be defined in this file. Raw coordinates must never appear in any DOM element.

**Verification:** Open `/pilot-demo/evidence-link#token=<valid-token>`. Step 1 shows zone label not coordinates. Steps advance. Step 3 form submits to real backend. Step 4 shows instruction_id.

_Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

---

## Task 9 — Wire Program.cs to serve canonical recipient landing page

**Files touched:** `services/ledger-api/dotnet/src/LedgerApi/Program.cs`

**What to do:**
1. Find the route `GET /pilot-demo/evidence-link`.
2. Change the file it serves from `src/recipient-landing/index-2.html` to `src/recipient-landing/index.html`.
3. No other changes to Program.cs.

**Verification:** `curl http://localhost:5001/pilot-demo/evidence-link` returns 200 and the HTML contains the Step 1 token validation logic.

_Requirements: 4.1_

---

## Task 10 — End-to-end verification script

**Files touched:** `scripts/dev/verify_ui_e2e.sh` (new), `evidence/phase1/ui_e2e_verification.json` (output)

**What to do:**
Create `scripts/dev/verify_ui_e2e.sh` using `curl` only (no Python, no Node.js). Target a locally running LedgerAPI on port 5001.

Steps:
1. Set env vars and prepare isolated test state.
2. Issue an evidence link token: `POST /v1/evidence-links/issue` with WASTE_COLLECTOR, Chunga GPS, and a test instruction_id.
3. Extract token from response.
4. Submit a WEIGHBRIDGE_RECORD: `POST /v1/evidence-links/submit` with token, GPS at Chunga, and valid PET payload (gross=14.2, tare=1.8, net=12.4, collector_id from worker seed).
5. **Check A:** Assert HTTP 202.
6. Call `GET /pilot-demo/api/monitoring-report/PGM-ZAMBIA-GRN-001` with operator cookie.
7. **Check B:** Assert `plastic_totals_kg.PET > 0` in JSON response.
8. **Check C:** Assert `plastic_totals_kg.TOTAL > 0` AND additionality delta > 0.
9. Call `GET /pilot-demo/api/reveal/PGM-ZAMBIA-GRN-001` with operator cookie.
10. **Check D:** Assert timeline contains entry with `artifact_type: "WEIGHBRIDGE_RECORD"`.
11. Write evidence JSON to `evidence/phase1/ui_e2e_verification.json` with checks A-D each showing "PASS" or "FAIL".
12. Exit 0 if all four checks pass, exit 1 if any fail with a clear failure message per check.

**Verification:** Run `bash scripts/dev/verify_ui_e2e.sh`. Exits 0. Open evidence JSON and confirm all four checks show "PASS".

_Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
