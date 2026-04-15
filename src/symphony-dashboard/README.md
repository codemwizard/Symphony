# Symphony Dashboard — 5-Page Frontend

Standalone HTML/CSS/JS frontend with direct API connectivity to the LedgerApi C# backend.
No build step. No framework. Open any `.html` file via an HTTP server.

## Pages

| File | Tab | API routes used |
|---|---|---|
| `supervisory.html` | Governed Disbursement | `GET /v1/supervisory/programmes/{id}/reveal`, `GET /v1/supervisory/instructions/{id}/detail`, `POST /v1/supervisory/programmes/{id}/export` |
| `workers.html` | Worker Onboarding | `POST /v1/admin/suppliers/upsert`, `POST /v1/admin/program-supplier-allowlist/upsert`, `POST /v1/evidence-links/issue` |
| `monitoring.html` | Monitoring Report | `GET /pilot-demo/api/monitoring-report/{id}`, `POST /v1/supervisory/programmes/{id}/export` |
| `criteria.html` | Pilot Criteria | `GET /pilot-demo/api/pilot-success` |
| `admin.html` | Admin Console | `GET /api/admin/onboarding/status`, `POST /api/admin/onboarding/tenants`, `POST /api/admin/onboarding/programmes`, `PUT /api/admin/onboarding/programmes/{id}/activate`, `POST /api/admin/onboarding/programmes/{id}/policy-binding`, `POST /v1/admin/suppliers/upsert`, `POST /v1/admin/program-supplier-allowlist/upsert` |

## Quick Start

### 1. Start the backend

```bash
cd /home/mwiza/workspace/Symphony
source /tmp/symphony_openbao/secrets.env
SYMPHONY_RUNTIME_PROFILE=pilot-demo \
INGRESS_STORAGE_MODE=db_psql \
dotnet run --project services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj
```

Backend runs on `http://localhost:8080`.

### 2. Serve the dashboard

**Option A — Python (simplest):**
```bash
cd src/symphony-dashboard
python3 -m http.server 3000
# Open: http://localhost:3000
```

**Option B — npx serve:**
```bash
cd src/symphony-dashboard
npx serve -p 3000
```

**Option C — Served directly by LedgerApi (same-origin, no CORS):**

Copy all files into `src/supervisory-dashboard/` alongside the existing `index.html`, or
add a static file route in `Program.cs` pointing at this directory.

### 3. CORS note

If accessing via a different origin than `localhost:8080`, the backend will reject requests due to the cookie-based auth. Serve the files at the same origin as the API, or add `CORS_ORIGINS=http://localhost:3000` to your environment (requires backend support).

The easiest approach is Option C — let LedgerApi serve the static files directly.

## Design

- **Fonts:** Playfair Display (headings) · JetBrains Mono (data/labels) · Crimson Pro (body)
- **Palette:** Deep forest green bg (#050c08) · Gold accents (#c9a84c) · Bright green data (#3db85a)
- **Shared CSS:** `_shared.css` — all 5 pages import this. Contains the full design system.
- **No dependencies:** All Google Fonts loaded via CDN. Zero npm packages.

## API Key

The dashboard reads `window.__SYMPHONY_UI_CONTEXT__.apiKey` when served by LedgerApi (injected at page load).
When served standalone, API calls that require auth will fail until you either:

1. Open the browser devtools and run: `window.__SYMPHONY_UI_CONTEXT__ = { apiKey: 'YOUR_KEY', tenantId: '...', programId: '...' }`
2. Or set a query param: `?apiKey=YOUR_KEY` (not implemented — add to `_shared.css` JS if needed)

For read-only endpoints (`/v1/supervisory/…`), the `x-api-key` header uses `EVIDENCE_SIGNING_KEY` from secrets.
The admin endpoints use `x-admin-api-key` which maps to `ADMIN_API_KEY` from OpenBao.
