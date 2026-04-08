# Symphony UI Canonical Rewrite — Design

## What Is Being Changed

```
src/supervisory-dashboard/index.html → REWRITTEN in place (same path, same URL)
src/recipient-landing/index.html → NEW canonical file (replaces index-2.html)
symphony_ui/ → IGNORED entirely — do not reference it
```

## What Is NOT Being Changed

- All backend routes (Program.cs unchanged)
- All self-test runners
- All evidence files
- The CSS token system (colours, fonts) — identical to existing dashboard

---

## Supervisory Dashboard Layout

Three tabs, each fills 100vh:

```
┌─────────────────────────────────────────────────────────────┐
│ TOPBAR: Symphony logo · programme badge · tenant pill      │
│ TABS: [Programme Health] [Monitoring Report] [Onboarding]  │
├─────────────────────────────────────────────────────────────┤
│ Tab 1: Programme Health                                     │
│ ┌─────────────────┐ ┌────────────────────────────────┐     │
│ │ KPI ROW (4)     │ │ DISBURSEMENT STATUS (large)    │     │
│ │ Submissions     │ │ ● NOT AUTHORIZED — red         │     │
│ │ Exceptions      │ │ Incomplete MRV (25%)           │     │
│ │ Complete        │ │ or ● AUTHORIZED — green        │     │
│ │ Completeness %  │ │                                │     │
│ └─────────────────┘ └────────────────────────────────┘     │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ ACTIVITY TABLE (fixed height, overflow-y: auto)      │   │
│ │ Instruction | Type | Status | Weight | tCO₂ | Time   │   │
│ │ CHG-001 | WEIG | ●GREEN | 12.4kg | 0.006 | 14:22     │   │
│ │ CHG-002 | COLL | ●AMBER | —      | —     | 14:25     │   │
│ └──────────────────────────────────────────────────────┘   │
│ [Click row → drawer slides in from right]                  │
│                                                             │
│ Tab 2: Monitoring Report                                    │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ DISBURSEMENT BANNER (red/green, full width)          │   │
│ │                                                       │   │
│ │ ADDITIONALITY ROW:                                    │   │
│ │ Baseline: 0 kg | Actual: 20.4 kg | +20.4 kg ●GRN     │   │
│ │                                                       │   │
│ │ PLASTIC TABLE: PET|HDPE|LDPE|PP|PS|OTHER|TOTAL       │   │
│ │                12.4| 8.0| 0  | 0| 0| 0   | 20.4      │   │
│ │                                                       │   │
│ │ tCO₂ est: 0.0098 tCO₂ | Credits: 0.0098 (indicative) │   │
│ │                                                       │   │
│ │ BENEFIT SHARING (SI 116) (indicative)                │   │
│ │ Project Developer (50%): ZMW 0.74                     │   │
│ │ Community (30%): ZMW 0.44                             │   │
│ │ National Fund (20%): ZMW 0.29                         │   │
│ │                                                       │   │
│ │ ZGFT: ●Pollution Prevention ●Circular Economy         │   │
│ │       ●DNSH Declared                                  │   │
│ │ [Generate Report] button                              │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                             │
│ Tab 3: Onboarding Console                                   │
│ (existing onboarding UI, styled to match new tokens)        │
└─────────────────────────────────────────────────────────────┘
```

## Instruction Detail Drawer

Slides from right, `position: fixed`, width 38%, overlays content:

```
┌─────────────────────────────────────────┐
│ CHG-2026-00001                          │
│ Worker: Mercy Banda (Chunga Worker 001) │
│ Sequence: #1                            │
│ Registry Status: NOT ISSUED ● AMBER     │
│ Duplicate Check: PASS ● GREEN           │
│ GPS: Chunga Dumpsite, Lusaka            │
│      42m from boundary ● GREEN          │
├─────────────────────────────────────────┤
│ EVIDENCE COMPLETENESS                   │
│ ● WEIGHBRIDGE_RECORD PRESENT ● GREEN    │
│ ● COLLECTION_PHOTO PRESENT ● GREEN      │
│ ● QUALITY_AUDIT PRESENT ● GREEN         │
│ ○ TRANSFER_MANIFEST MISSING ● RED       │
├─────────────────────────────────────────┤
│ WEIGHBRIDGE DATA                        │
│ Plastic Type: PET                       │
│ Net Weight: 12.4 kg                     │
│ tCO₂ estimate: 0.005952 tCO₂            │
│ Credits (est.): 0.005952 credits        │
└─────────────────────────────────────────┘
```

Notes:
- GPS shown as neighbourhood label only (never raw coordinates)
- "Registry Status: NOT ISSUED" is hardcoded for pilot — no live registry integration
- "Duplicate Check: PASS" is derived from sequence_number being unique per instruction_id

## Monitoring Report — Financial Computations

All values computed client-side from report API response using constants from ui-canonical-design.md:

```javascript
const tco2    = report.plastic_totals_kg.TOTAL * TCO2_PER_KG;
const credits = tco2;                               // 1 credit = 1 tCO₂
const valueZmw = tco2 * PRICE_PER_TCO2_ZMW;
const split   = benefitSplit(valueZmw);
```

All three benefit-share rows shown even when zero. All marked "(indicative)".

## Additionality Row

Hardcoded baseline = 0 kg (pilot baseline). Always shown:

```javascript
const baseline = 0;
const actual   = report.plastic_totals_kg.TOTAL;
const delta    = actual - baseline;
// colour: green if delta > 0, amber if delta == 0
```

## Worker Landing Page Layout

Single card, max-width 480px, centred, one step at a time:

```
Step 1: Token validation → show role + zone label + TTL countdown
Step 2: GPS capture → show zone label + zone check chip (no raw coords)
Step 3: Weighbridge form → plastic type, weights, net (readonly), photo upload
Step 4: Receipt → instruction_id, sequence_number, green success banner
```

Progress shown as 4-dot step indicator at top.

## API Polling

- Dashboard fetches reveal data on tab load and every 15 seconds
- Monitoring report fetches on tab switch and on "Generate Report" click
- No WebSocket — polling only
- Loading state: amber spinner in the header area
- Error state: red banner with retry button

## Self-Test Script Location

`scripts/dev/verify_ui_e2e.sh` — end-to-end shell script (curl only).
Output evidence: `evidence/phase1/ui_e2e_verification.json`.
