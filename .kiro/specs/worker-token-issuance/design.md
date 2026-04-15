# Worker Token Issuance Tab — Design

## What Is Being Changed

```
src/supervisory-dashboard/index.html → ADD Tab 4 "Worker Token Issuance"
Tab bar → UPDATE to include 4th tab
Tab count → 3 → 4 (moving toward 5 total)
```

## What Is NOT Being Changed

- All backend routes (Program.cs unchanged)
- Existing 3 tabs (Programme Health, Monitoring Report, Onboarding Console)
- CSS token system (colours, fonts)
- Worker landing page (src/recipient-landing/index.html)

---

## Tab Layout

Tab 4 fills 100vh, two-column layout:

```
┌─────────────────────────────────────────────────────────────┐
│ TOPBAR: Symphony logo · programme badge · tenant pill      │
│ TABS: [Programme Health] [Monitoring Report] [Onboarding]  │
│       [Worker Token Issuance] ← NEW                         │
├─────────────────────────────────────────────────────────────┤
│ Tab 4: Worker Token Issuance                                │
│ ┌──────────────────────┐ ┌────────────────────────────┐    │
│ │ ISSUANCE FORM        │ │ RECENT TOKENS              │    │
│ │                      │ │                            │    │
│ │ Programme Context    │ │ Token List (last 10)       │    │
│ │ Chunga Dumpsite      │ │ worker-chunga-001          │    │
│ │ Lusaka, Zambia       │ │ Issued: 14:22              │    │
│ │                      │ │ Status: ●ACTIVE            │    │
│ │ Worker Phone Number  │ │ Expiry: 3m 42s             │    │
│ │ [+260971100001    ]  │ │                            │    │
│ │                      │ │ worker-chunga-002          │    │
│ │ Worker Details       │ │ Issued: 14:18              │    │
│ │ ✓ worker-chunga-001  │ │ Status: ●USED              │    │
│ │ ✓ WASTE_COLLECTOR    │ │ Expiry: EXPIRED            │    │
│ │ ✓ ACTIVE             │ │                            │    │
│ │ ✓ Chunga Dumpsite    │ │ [Click row for details]    │    │
│ │                      │ │                            │    │
│ │ [Request Token]      │ │                            │    │
│ │                      │ │                            │    │
│ │ TOKEN RESULT         │ │                            │    │
│ │ ✓ Token issued       │ │                            │    │
│ │ Worker: worker-001   │ │                            │    │
│ │ Expiry: 5m 00s       │ │                            │    │
│ │ GPS: Chunga Dumpsite │ │                            │    │
│ │ Radius: 250m         │ │                            │    │
│ │                      │ │                            │    │
│ │ Worker Landing URL:  │ │                            │    │
│ │ http://localhost:... │ │                            │    │
│ │ [Copy Link]          │ │                            │    │
│ │                      │ │                            │    │
│ │ SECURITY PROPERTIES  │ │                            │    │
│ │ Type: Evidence-Link  │ │                            │    │
│ │ Signature: HMAC-256  │ │                            │    │
│ │ TTL: 5 minutes       │ │                            │    │
│ │ GPS Lock: ✓          │ │                            │    │
│ │ Single-use: ✓        │ │                            │    │
│ └──────────────────────┘ └────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Token Issuance Flow

```javascript
// Step 1: Worker lookup on phone number blur
async function lookupWorker(msisdn) {
  const resp = await fetch(`/pilot-demo/api/workers/lookup?msisdn=${encodeURIComponent(msisdn)}`, {
    credentials: 'include'
  });
  if (!resp.ok) {
    showWorkerError('Worker not registered');
    disableTokenButton();
    return;
  }
  const worker = await resp.json();
  if (worker.supplier_type !== 'WASTE_COLLECTOR') {
    showWorkerError('Invalid supplier type. Only WASTE_COLLECTOR can receive tokens.');
    disableTokenButton();
    return;
  }
  if (worker.status !== 'ACTIVE') {
    showWorkerError('Worker is inactive. Cannot issue token.');
    disableTokenButton();
    return;
  }
  showWorkerDetails(worker);
  enableTokenButton();
}

// Step 2: Token issuance
async function issueToken() {
  const msisdn = document.getElementById('worker-phone').value;
  const worker = currentWorkerDetails; // from lookup
  
  const resp = await fetch('/pilot-demo/api/evidence-links/issue', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify({
      worker_id: worker.worker_id,
      msisdn: msisdn,
      program_id: currentProgramId
    })
  });
  
  if (!resp.ok) {
    showTokenError(await resp.text());
    return;
  }
  
  const token = await resp.json();
  showTokenResult(token);
  addToRecentTokens(token);
  startCountdownTimer(token.expiry_timestamp);
}

// Step 3: Token result display
function showTokenResult(token) {
  document.getElementById('token-worker-id').textContent = token.worker_id;
  document.getElementById('token-expiry').textContent = '5m 00s';
  document.getElementById('token-gps').textContent = resolveNeighbourhoodLabel(token.gps_lat, token.gps_lon);
  document.getElementById('token-radius').textContent = '250m';
  
  const workerUrl = `${window.location.origin}/recipient-landing/#token=${token.token}`;
  document.getElementById('worker-url').textContent = workerUrl;
  document.getElementById('worker-url').dataset.url = workerUrl;
}

// Step 4: Copy to clipboard
function copyWorkerLink() {
  const url = document.getElementById('worker-url').dataset.url;
  navigator.clipboard.writeText(url);
  showCopyConfirmation();
}
```

---

## Recent Tokens List

Stored in memory (no persistence required for pilot demo):

```javascript
const recentTokens = []; // max 10 items

function addToRecentTokens(token) {
  recentTokens.unshift({
    worker_id: token.worker_id,
    issued_at: new Date().toISOString(),
    expiry_at: token.expiry_timestamp,
    status: 'ACTIVE', // ACTIVE | EXPIRED | USED | REVOKED
    token_id: token.token_id
  });
  if (recentTokens.length > 10) recentTokens.pop();
  renderRecentTokens();
}

function renderRecentTokens() {
  const tbody = document.getElementById('recent-tokens-body');
  tbody.innerHTML = recentTokens.map(t => {
    const status = getTokenStatus(t);
    const statusClass = status === 'ACTIVE' ? 'green' : status === 'USED' ? 'amber' : 'red';
    const expiry = status === 'EXPIRED' ? 'EXPIRED' : formatTimeRemaining(t.expiry_at);
    
    return `
      <tr onclick="showTokenDetail('${t.token_id}')">
        <td>${t.worker_id}</td>
        <td>${formatTime(t.issued_at)}</td>
        <td><span class="status-chip chip-${statusClass}">${status}</span></td>
        <td>${expiry}</td>
      </tr>
    `;
  }).join('');
}

function getTokenStatus(token) {
  if (token.status === 'REVOKED') return 'REVOKED';
  if (token.status === 'USED') return 'USED';
  if (new Date(token.expiry_at) < new Date()) return 'EXPIRED';
  return 'ACTIVE';
}
```

---

## Token Detail Panel (Slide-out)

Slides from right when token row is clicked:

```
┌─────────────────────────────────────────┐
│ Token Details                           │
│ worker-chunga-001                       │
│                                         │
│ Issued: 2026-04-08 14:22:15 UTC        │
│ Expires: 2026-04-08 14:27:15 UTC       │
│ Status: ●ACTIVE                         │
│                                         │
│ Security Properties:                    │
│ • Type: Evidence-Link Token             │
│ • Signature: HMAC-SHA256                │
│ • GPS Lock: Chunga Dumpsite, Lusaka     │
│ • Radius: 250 meters                    │
│ • Single-use: Yes                       │
│                                         │
│ Usage:                                  │
│ • Submissions: 0                        │
│ • Last used: Never                      │
│                                         │
│ [Revoke Token]                          │
│ [Close]                                 │
└─────────────────────────────────────────┘
```

---

## Token Revocation Flow

```javascript
async function revokeToken(tokenId) {
  if (!confirm('Revoke token? This action cannot be undone.')) return;
  
  const resp = await fetch(`/pilot-demo/api/evidence-links/revoke/${tokenId}`, {
    method: 'DELETE',
    credentials: 'include'
  });
  
  if (!resp.ok) {
    showError('Failed to revoke token');
    return;
  }
  
  // Update local state
  const token = recentTokens.find(t => t.token_id === tokenId);
  if (token) {
    token.status = 'REVOKED';
    renderRecentTokens();
  }
  
  closeTokenDetail();
  showSuccess('Token revoked successfully');
}
```

---

## Countdown Timer

Updates every second for active tokens:

```javascript
let countdownInterval = null;

function startCountdownTimer(expiryTimestamp) {
  if (countdownInterval) clearInterval(countdownInterval);
  
  countdownInterval = setInterval(() => {
    const now = new Date();
    const expiry = new Date(expiryTimestamp);
    const remaining = expiry - now;
    
    if (remaining <= 0) {
      document.getElementById('token-expiry').textContent = 'EXPIRED';
      document.getElementById('token-expiry').style.color = 'var(--red-lt)';
      clearInterval(countdownInterval);
      return;
    }
    
    const minutes = Math.floor(remaining / 60000);
    const seconds = Math.floor((remaining % 60000) / 1000);
    document.getElementById('token-expiry').textContent = `${minutes}m ${seconds.toString().padStart(2, '0')}s`;
  }, 1000);
}
```

---

## API Endpoints

All endpoints use relative URLs and `credentials: 'include'`:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/pilot-demo/api/workers/lookup?msisdn={phone}` | GET | Validate worker exists |
| `/pilot-demo/api/evidence-links/issue` | POST | Issue new token |
| `/pilot-demo/api/evidence-links/revoke/{token_id}` | DELETE | Revoke token |

---

## CSS Classes (Reuse Existing Tokens)

All styling uses existing CSS token system from supervisory dashboard:

- `.dcard` — card container
- `.status-chip` — status badges
- `.chip-auth` (green), `.chip-hold` (amber), `.chip-sim` (red)
- `.btn-primary` — primary action button
- `.btn-ghost` — secondary action button
- `var(--bright)` — green for success
- `var(--amber-lt)` — amber for warnings
- `var(--red-lt)` — red for errors

---

## Self-Test Script Location

`scripts/dev/verify_worker_token_issuance_e2e.sh` — end-to-end shell script (curl only).
Output evidence: `evidence/phase1/worker_token_issuance_e2e.json`.

---

## Neighbourhood Label Function (Reuse)

```javascript
function resolveNeighbourhoodLabel(lat, lon) {
  if (lat >= -15.43 && lat <= -15.40 && lon >= 28.26 && lon <= 28.30)
    return "Chunga Dumpsite, Lusaka";
  return "Lusaka";
}
```

Raw coordinates are NEVER displayed in the UI.
