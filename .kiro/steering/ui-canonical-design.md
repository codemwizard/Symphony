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
- tCO₂ → carbon credits as unit of account (1 credit = 1 tCO₂)
- Benefit share → explicit three-way allocation (Project 50% / Community 30% / National Fund 20%)

### Additionality is explicit, not implied
Every report view must show the baseline comparison as a visible row:
```
Baseline: 0 kg
Actual: 20.4 kg
Additionality: +20.4 kg ● GREEN
```
Never rely on the operator inferring additionality from totals alone.

### Surface trust signals through colour — never through text alone
| Signal | Colour |
|--------|--------|
| Verified / Ready / Authorized | Green `#3db85a` |
| Pending / In Progress / Incomplete | Amber `#d4821e` |
| Failed / Rejected / Blocked | Red `#b03020` |

Do NOT use the words "Verified", "Failed", "Pending" as the primary signal. The colour chip IS the signal. The word is secondary.

### Double-counting protection is visible
Every instruction detail and every report must show:
- Instruction ID (monospace)
- Sequence number
- Registry status: `NOT ISSUED` (before credit issuance) or `ISSUED`
- Duplicate check: `PASS ● GREEN`

This makes the non-duplicability claim auditable at a glance.

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

## Carbon and Financial Computations (non-negotiable constants)

```javascript
const TCO2_PER_KG = 0.00048;          // indicative ~0.48 kg CO₂e per kg PET-equivalent
const PRICE_PER_TCO2_ZMW = 150.0;     // indicative ZMW price per tCO₂ for demo
const BENEFIT_SHARE = {
  project_developer: 0.50,
  community: 0.30,
  national_fund: 0.20
};

function estimateTco2(totalKg) {
  return totalKg * TCO2_PER_KG;
}

function estimateCredits(totalKg) {
  return estimateTco2(totalKg);   // 1 credit = 1 tCO₂
}

function estimateValue(totalKg) {
  return estimateTco2(totalKg) * PRICE_PER_TCO2_ZMW;
}

function benefitSplit(totalValueZmw) {
  return {
    project_developer: totalValueZmw * BENEFIT_SHARE.project_developer,
    community:         totalValueZmw * BENEFIT_SHARE.community,
    national_fund:     totalValueZmw * BENEFIT_SHARE.national_fund
  };
}
```

All financial display values are marked (indicative). Never present them as exact or legally binding.

## Neighbourhood label (no geocoding API)

```javascript
function resolveNeighbourhoodLabel(lat, lon) {
  if (lat >= -15.43 && lat <= -15.40 && lon >= 28.26 && lon <= 28.30)
    return "Chunga Dumpsite, Lusaka";
  return "Lusaka";
}
```

Raw latitude/longitude values are NEVER displayed in the DOM. The neighbourhood label is the only location string shown to users.

## API Wiring Rules

ALL API calls use relative URLs (e.g. /pilot-demo/api/...). Never hardcode a host.

The pilot-demo operator session cookie is set by GET /pilot-demo/supervisory on page load. All subsequent requests carry it automatically (same-origin, credentials: 'include').

The canonical programme ID is read from the reveal endpoint response — never hardcoded in JS logic.

Polling interval for live data: 15 seconds.

## File Structure (canonical — do not create new files)

```
src/supervisory-dashboard/index.html → supervisor/operator screen
src/recipient-landing/index.html     → worker submission screen
```

These are the ONLY two UI files. Do not create additional HTML files, React components, or JavaScript modules.

## What Must NOT Be In the UI

- No static/hardcoded data values in the rendered output
- No Lorem ipsum or placeholder text
- No inline style="color:red" — use CSS classes with the token system
- No alert() or confirm() — use inline status banners
- No console.log in production code paths
- No references to symphony_ui/ directory
- No raw coordinate values rendered in any DOM element
- No financial values presented without (indicative) qualifier
