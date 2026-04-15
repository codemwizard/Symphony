# TSK-P1-PLT-001 PLAN — Serve Pilot via LegacyAPI

Task: TSK-P1-PLT-001
Owner: ARCHITECT
Depends on: GF-W1-UI-024
failure_signature: 1.PLT.001.AUTH_FAILURE
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Fix the 401 Unauthorized errors across the pilot demo by serving all pilot HTML files through `Program.cs` handlers. 
This ensures that every entry point (onboarding, monitoring, etc.) correctly injects the `symphony_pilot_demo_operator` cookie and the `SYMPHONY_PILOT_CONTEXT` script block into the frontend.

## Architectural Context

The system currently serves the main dashboard under `/pilot-demo/supervisory` but leaves other pilot pages to static file serving. Static serving bypasses the cookie generation logic in `Program.cs`. This task centralizes pilot routing to ensure unified authentication.

---

## Pre-conditions

- [x] Gap analysis confirms auth blocker.
- [ ] LedgerApi is building and runnable.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `services/ledger-api/dotnet/src/LedgerApi/Program.cs` | MODIFY | Add routes and cookie injection logic. |
| `tasks/TSK-P1-PLT-001/meta.yml` | MODIFY | Update status to completed. |

---

## Stop Conditions

- **If the operator cookie is orphaned (not set on all pilot routes)** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If the Context injection fails to find the __SYMPHONY_UI_CONTEXT__ token in the HTML** -> STOP

---

## Implementation Steps

### Step 1: Map Routes
**What:** `[ID TSK-P1-PLT-001_work_item_01]` Define new GET endpoints for `/pilot-demo/onboarding`, `/pilot-demo/monitoring`, and `/pilot-demo/token-issuance`.
**How:** Update `Program.cs` following the existing `/pilot-demo/supervisory` pattern.
**Done when:** Routes are reachable via curl.

### Step 2: Implement Context Injection
**What:** `[ID TSK-P1-PLT-001_work_item_02]` Read the HTML files from `src/symphony-pilot/` and replace the context placeholders.
**How:** Use `File.ReadAllText` and `html.Replace("__SYMPHONY_UI_CONTEXT__", ...)`.
**Done when:** The response body contains the injected JSON.

### Step 3: Implement Cookie Injection
**What:** `[ID TSK-P1-PLT-001_work_item_03]` Call `SetPilotDemoOperatorCookie` on each response.
**How:** Ensure the `CookieOptions` are set correctly (HttpOnly, Secure).
**Done when:** `Set-Cookie` header is observed in the response.

---

## Verification

```bash
# [ID TSK-P1-PLT-001_work_item_01]
curl -i http://localhost:5242/pilot-demo/onboarding | grep '200 OK' || exit 1

# [ID TSK-P1-PLT-001_work_item_03]
curl -i http://localhost:5242/pilot-demo/onboarding | grep 'set-cookie: symphony_pilot_demo_operator' || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_plt_001.json`

Required fields:
- `task_id`: "TSK-P1-PLT-001"
- `git_sha`: current commit
- `timestamp_utc`: current time
- `status`: "PASS"
- `checks`: array including cookie validation and route reachability
