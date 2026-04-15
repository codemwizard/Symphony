# Pilot Success Criteria Tab — Design

## What Is Being Changed

```
src/supervisory-dashboard/index.html → ADD Tab 5 "Pilot Success Criteria"
Tab bar → UPDATE to include 5th tab
Tab count → 4 → 5 (final count)
```

## What Is NOT Being Changed

- All backend routes (Program.cs unchanged)
- Existing 4 tabs (Programme Health, Monitoring Report, Onboarding Console, Worker Token Issuance)
- CSS token system (colours, fonts)

---

## Tab Layout

Tab 5 fills 100vh, single-column layout with three-section grid:

```
┌─────────────────────────────────────────────────────────────┐
│ TOPBAR: Symphony logo · programme badge · tenant pill      │
│ TABS: [Programme Health] [Monitoring Report] [Onboarding]  │
│       [Worker Token Issuance] [Pilot Success Criteria] ← NEW│
├─────────────────────────────────────────────────────────────┤
│ Tab 5: Pilot Success Criteria                               │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ OVERALL PILOT GATE STATUS                            │   │
│ │ ● PILOT GATE: PASS ✓                                 │   │
│ │ All success criteria met. Pilot ready for production │   │
│ │ Last verified: 2026-04-08 14:22:15 UTC               │   │
│ │ [Refresh Now] [Export Report]                        │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                             │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ TECHNICAL CRITERIA                    ●ALL PASS      │   │
│ ├──────────────────────────────────────────────────────┤   │
│ │ ✓ Evidence trail append-only          INV-035, 091  │   │
│ │ ✓ GPS verification active             Geolocation API│   │
│ │ ✓ Tenant isolation enforced           INV-133       │   │
│ │ ✓ Policy version lock immutable       INV-090       │   │
│ │ ✓ Idempotency guard active            INV-011       │   │
│ │ ✓ Fail-closed under DB exhaustion     INV-039       │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                             │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ OPERATIONAL CRITERIA                  ●ALL PASS      │   │
│ ├──────────────────────────────────────────────────────┤   │
│ │ ✓ Proof submission functional         4 types       │   │
│ │ ✓ Dashboard access working            Read-only     │   │
│ │ ✓ Monitoring report generation        PWRM0001      │   │
│ │ ✓ Token issuance functional           Evidence-link │   │
│ │ ✓ Worker landing page accessible      Mobile-opt    │   │
│ └──────────────────────────────────────────────────────┘   │
│                                                             │
│ ┌──────────────────────────────────────────────────────┐   │
│ │ REGULATORY CRITERIA                   ●ALL PASS      │   │
│ ├──────────────────────────────────────────────────────┤   │
│ │ ✓ Non-custodial posture maintained    INV-114       │   │
│ │ ✓ No settlement-rail claim            No funds held │   │
│ │ ✓ PII decoupled from audit trail      INV-115       │   │
│ │ ✓ Evidence survives data purge        INV-115       │   │
│ │ ✓ Supervisory view read-only          INV-111       │   │
│ │ ✓ No runtime DDL in production        Schema locked │   │
│ └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Criteria Data Structure

```javascript
const criteriaData = {
  overall_status: "PASS", // PASS | PENDING | FAIL
  last_verified: "2026-04-08T14:22:15Z",
  categories: {
    technical: {
      name: "Technical Criteria",
      status: "PASS", // ALL_PASS | ATTENTION_REQUIRED
      criteria: [
        {
          id: "tech-001",
          name: "Evidence trail append-only",
          status: "PASS", // PASS | PENDING | FAIL
          invariants: ["INV-035", "INV-091"],
          verification_method: "DB constraint check",
          last_verified: "2026-04-08T14:22:15Z",
          threshold: "No UPDATE or DELETE operations on evidence log"
        },
        {
          id: "tech-002",
          name: "GPS verification active",
          status: "PASS",
          invariants: [],
          verification_method: "Geolocation API check",
          last_verified: "2026-04-08T14:22:15Z",
          threshold: "Geolocation API used, not EXIF metadata"
        },
        // ... more criteria
      ]
    },
    operational: {
      name: "Operational Criteria",
      status: "PASS",
      criteria: [
        {
          id: "ops-001",
          name: "Proof submission functional",
          status: "PASS",
          verification_method: "Submit test WEIGHBRIDGE_RECORD",
          last_verified: "2026-04-08T14:22:15Z",
          threshold: "HTTP 202 response",
          response_time_ms: 142
        },
        // ... more criteria
      ]
    },
    regulatory: {
      name: "Regulatory Criteria",
      status: "PASS",
      criteria: [
        {
          id: "reg-001",
          name: "Non-custodial posture maintained",
          status: "PASS",
          invariants: ["INV-114"],
          verification_method: "No custody of funds",
          last_verified: "2026-04-08T14:22:15Z",
          threshold: "No balance tables in schema"
        },
        // ... more criteria
      ]
    }
  }
};
```

---

## Criteria Loading Flow

```javascript
let pollingInterval = null;

async function loadPilotCriteria() {
  showLoadingState();
  
  try {
    const resp = await fetch('/pilot-demo/api/pilot-success-criteria', {
      credentials: 'include'
    });
    
    if (!resp.ok) {
      showErrorState('Failed to load pilot success criteria');
      return;
    }
    
    const data = await resp.json();
    renderCriteria(data);
    startPolling();
  } catch (err) {
    showErrorState(err.message);
  }
}

function renderCriteria(data) {
  renderOverallStatus(data.overall_status, data.last_verified);
  renderCategory('technical', data.categories.technical);
  renderCategory('operational', data.categories.operational);
  renderCategory('regulatory', data.categories.regulatory);
}

function renderCategory(categoryId, category) {
  const container = document.getElementById(`category-${categoryId}`);
  const statusBadge = category.status === 'PASS' ? 
    '<span class="status-chip chip-auth">●ALL PASS</span>' :
    '<span class="status-chip chip-hold">●ATTENTION REQUIRED</span>';
  
  container.innerHTML = `
    <div class="dc-head">
      <div class="dc-head-title">${category.name}</div>
      ${statusBadge}
    </div>
    <div class="criteria-list">
      ${category.criteria.map(c => renderCriterion(c)).join('')}
    </div>
  `;
}

function renderCriterion(criterion) {
  const statusIcon = criterion.status === 'PASS' ? '✓' : 
                     criterion.status === 'PENDING' ? '⧗' : '✗';
  const statusClass = criterion.status === 'PASS' ? 'pass' : 
                      criterion.status === 'PENDING' ? 'pending' : 'fail';
  
  return `
    <div class="criteria-item" onclick="showCriterionDetail('${criterion.id}')">
      <div class="ci-ind ind-${statusClass}">${statusIcon}</div>
      <div class="ci-info">
        <div class="ci-name">${criterion.name}</div>
        <div class="ci-threshold">${criterion.threshold || ''}</div>
        ${criterion.invariants && criterion.invariants.length > 0 ? 
          `<div class="ci-threshold">${criterion.invariants.join(', ')}</div>` : ''}
      </div>
    </div>
  `;
}
```

---

## Overall Status Display

```javascript
function renderOverallStatus(status, lastVerified) {
  const statusEl = document.getElementById('overall-status');
  
  let badge, message, badgeClass;
  if (status === 'PASS') {
    badge = 'PILOT GATE: PASS ✓';
    message = 'All success criteria met. Pilot ready for production evaluation.';
    badgeClass = 'pass';
  } else if (status === 'PENDING') {
    badge = 'PILOT GATE: VERIFICATION IN PROGRESS ⧗';
    message = 'Criteria pending verification. Refresh in 30 seconds.';
    badgeClass = 'pending';
  } else {
    badge = 'PILOT GATE: ATTENTION REQUIRED ✗';
    message = 'Some criteria require attention. Review details below.';
    badgeClass = 'fail';
  }
  
  statusEl.innerHTML = `
    <div class="s6-gate ${badgeClass}">
      <div>
        <div class="s6-gate-label">Overall Pilot Gate Status</div>
        <div class="s6-gate-status ${badgeClass}">${badge}</div>
      </div>
      <div class="s6-gate-meta">
        <div class="s6-gate-note">Last verified: <span>${formatTimestamp(lastVerified)}</span></div>
      </div>
    </div>
    <div style="margin-top:12px;font-size:13px;color:var(--smoke);">${message}</div>
  `;
}
```

---

## Criterion Detail Slide-out Panel

```javascript
function showCriterionDetail(criterionId) {
  const criterion = findCriterionById(criterionId);
  if (!criterion) return;
  
  const panel = document.getElementById('criterion-detail-panel');
  panel.innerHTML = `
    <div class="so-hdr">
      <div>
        <div class="so-title">${criterion.name}</div>
        <div class="so-ref">${criterion.id}</div>
      </div>
      <div class="so-close" onclick="closeCriterionDetail()">✕ Close</div>
    </div>
    <div class="so-body">
      <div class="so-sec">
        <div class="so-sec-title">Status</div>
        <div class="status-chip chip-${criterion.status === 'PASS' ? 'auth' : 'hold'}">
          ${criterion.status}
        </div>
      </div>
      
      ${criterion.invariants && criterion.invariants.length > 0 ? `
        <div class="so-sec">
          <div class="so-sec-title">Invariants Referenced</div>
          <div>${criterion.invariants.join(', ')}</div>
        </div>
      ` : ''}
      
      <div class="so-sec">
        <div class="so-sec-title">Verification Method</div>
        <div>${criterion.verification_method}</div>
      </div>
      
      <div class="so-sec">
        <div class="so-sec-title">Threshold</div>
        <div>${criterion.threshold}</div>
      </div>
      
      <div class="so-sec">
        <div class="so-sec-title">Last Verified</div>
        <div>${formatTimestamp(criterion.last_verified)}</div>
      </div>
      
      ${criterion.response_time_ms ? `
        <div class="so-sec">
          <div class="so-sec-title">Response Time</div>
          <div>${criterion.response_time_ms}ms</div>
        </div>
      ` : ''}
      
      <button class="btn btn-primary" onclick="runVerificationNow('${criterionId}')">
        Run Verification Now
      </button>
    </div>
  `;
  
  panel.classList.add('open');
}

function closeCriterionDetail() {
  document.getElementById('criterion-detail-panel').classList.remove('open');
}

async function runVerificationNow(criterionId) {
  showLoadingSpinner();
  
  try {
    const resp = await fetch(`/pilot-demo/api/pilot-success-criteria/verify/${criterionId}`, {
      method: 'POST',
      credentials: 'include'
    });
    
    if (!resp.ok) {
      showError('Verification failed');
      return;
    }
    
    const result = await resp.json();
    updateCriterionStatus(criterionId, result.status);
    showSuccess('Verification complete');
    closeCriterionDetail();
  } catch (err) {
    showError(err.message);
  }
}
```

---

## Auto-Refresh Polling

```javascript
function startPolling() {
  if (pollingInterval) clearInterval(pollingInterval);
  
  pollingInterval = setInterval(async () => {
    // Only poll if tab is active
    if (document.getElementById('screen-s6').classList.contains('visible')) {
      await loadPilotCriteria();
    }
  }, 30000); // 30 seconds
}

function stopPolling() {
  if (pollingInterval) {
    clearInterval(pollingInterval);
    pollingInterval = null;
  }
}

// Stop polling when tab is switched away
function switchTab(tabId, tabEl) {
  // ... existing tab switching logic ...
  
  if (tabId === 's6') {
    loadPilotCriteria();
  } else {
    stopPolling();
  }
}
```

---

## Export Report

```javascript
async function exportReport(format) {
  const data = currentCriteriaData; // cached from last load
  
  if (format === 'json') {
    const json = JSON.stringify(data, null, 2);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `pilot_success_criteria_${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);
  } else if (format === 'pdf') {
    // Call backend to generate PDF
    const resp = await fetch('/pilot-demo/api/pilot-success-criteria/export/pdf', {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    
    if (!resp.ok) {
      showError('PDF generation failed');
      return;
    }
    
    const blob = await resp.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `pilot_success_criteria_${Date.now()}.pdf`;
    a.click();
    URL.revokeObjectURL(url);
  }
}
```

---

## CSS Classes (Reuse Existing Tokens)

All styling uses existing CSS token system from supervisory dashboard:

- `.s6-gate` — overall gate status card
- `.s6-card` — category card
- `.criteria-item` — individual criterion row
- `.ci-ind` — status indicator (✓ ⧗ ✗)
- `.status-chip` — status badges
- `.chip-auth` (green), `.chip-hold` (amber), `.chip-sim` (red)
- `.slideout` — detail panel
- `var(--bright)` — green for PASS
- `var(--amber-lt)` — amber for PENDING
- `var(--red-lt)` — red for FAIL

---

## API Endpoints

All endpoints use relative URLs and `credentials: 'include'`:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/pilot-demo/api/pilot-success-criteria` | GET | Load all criteria |
| `/pilot-demo/api/pilot-success-criteria/verify/{id}` | POST | Run single criterion verification |
| `/pilot-demo/api/pilot-success-criteria/export/pdf` | POST | Generate PDF report |

---

## Self-Test Script Location

`scripts/dev/verify_pilot_success_criteria_e2e.sh` — end-to-end shell script (curl only).
Output evidence: `evidence/phase1/pilot_success_criteria_e2e.json`.
