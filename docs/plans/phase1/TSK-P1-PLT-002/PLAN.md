# TSK-P1-PLT-002 PLAN — Reveal API Shim

Task: TSK-P1-PLT-002
Owner: ARCHITECT
Depends on: TSK-P1-PLT-001
failure_signature: 1.PLT.002.SHIM_FAILURE
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Expose the programme reveal logic to the pilot frontend by creating a shim route in `Program.cs`. This allows the "Programme Health" tab to fetch and display the invariants and test results that govern the pilot's logic.

## Architectural Context

The `SupervisoryRevealReadModelHandler` contains the logic for program transparency. However, its current API surface is restricted to the Administrative API. This task creates an authenticated bridge for the pilot role.

---

## Pre-conditions

- [x] TSK-P1-PLT-001 is scaffolded.
- [ ] `SupervisoryRevealReadModelHandler.cs` exists and is accessible.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `services/ledger-api/dotnet/src/LedgerApi/Program.cs` | MODIFY | Add Reveal shim route. |
| `tasks/TSK-P1-PLT-002/meta.yml` | MODIFY | Update status to completed. |

---

## Stop Conditions

- **If the shim modifies the response body returned by the ReadModel** -> STOP
- **If auth validation is bypassed** -> STOP

---

## Implementation Steps

### Step 1: Add Route
**What:** `[ID TSK-P1-PLT-002_work_item_01]` Implement the GET handler for `/pilot-demo/api/reveal/{programId}`.
**How:** Register the route in `Program.cs`.
**Done when:** Route returns 401 without cookie.

### Step 2: Implement Auth
**What:** `[ID TSK-P1-PLT-002_work_item_02]` Call `TryValidatePilotDemoOperatorCookie(ctx, null, out ..., out ...)` inside the handler.
**How:** Follow the pattern used in `monitoring-report` handler.
**Done when:** Route returns 200 with valid cookie.

### Step 3: Wire ReadModel
**What:** `[ID TSK-P1-PLT-002_work_item_03]` Inject `rootDir` and call `SupervisoryRevealReadModelHandler.Handle`.
**How:** Use `EvidenceMeta.ResolveRepoRoot` to get the root directory.
**Done when:** Response body contains valid reveal JSON.

---

## Verification

```bash
# [ID TSK-P1-PLT-002_work_item_01]
curl -i http://localhost:5242/pilot-demo/api/reveal/PGM-ZAMBIA-GRN-001 -H 'Cookie: symphony_pilot_demo_operator=VALID_COOKIE' | grep '200 OK' || exit 1

# [ID TSK-P1-PLT-002_work_item_03]
curl http://localhost:5242/pilot-demo/api/reveal/PGM-ZAMBIA-GRN-001 -H 'Cookie: symphony_pilot_demo_operator=VALID_COOKIE' | grep 'tests' || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_plt_002.json`

Required fields:
- `task_id`: "TSK-P1-PLT-002"
- `git_sha`: current commit
- `timestamp_utc`: current time
- `status`: "PASS"
- `checks`: array including reveal payload validation
