# TSK-P1-PLT-003 PLAN — Success Criteria Alignment

Task: TSK-P1-PLT-003
Owner: ARCHITECT
Depends on: TSK-P1-PLT-001
failure_signature: 1.PLT.003.KPI_FAILURE
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Enable the "Success Criteria" view in the pilot demo by providing the expected KPI and milestone data from the backend. This allows supervisors to track pilot objectives like plastic recovery weight and worker participation.

## Architectural Context

The success criteria for the Chunga Dumpsite pilot (PWRM0001) are defined at the programme level. This task implements a deterministic API for the pilot demo that reflects these targets.

---

## Pre-conditions

- [x] TSK-P1-PLT-001 is scaffolded.
- [x] Frontend expects JSON structure from `success-criteria.html` audited.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `services/ledger-api/dotnet/src/LedgerApi/Program.cs` | MODIFY | Add Success Criteria route and handler. |
| `tasks/TSK-P1-PLT-003/meta.yml` | MODIFY | Update status. |

---

## Stop Conditions

- **If the JSON structure deviates from the camelCase expectations of success-criteria.html (Line 207-280)** -> STOP
- **If the overallProgress is not a number** -> STOP

---

## Implementation Steps

### Step 1: Add Route
**What:** `[ID TSK-P1-PLT-003_work_item_01]` Add GET `/pilot-demo/api/pilot-success-criteria` to `Program.cs`.
**How:** Register route with `TryValidatePilotDemoOperatorCookie` check.
**Done when:** Route returns 401 without cookie.

### Step 2: Implement Data Object
**What:** `[ID TSK-P1-PLT-003_work_item_02]` Define the `PilotSuccessCriteria` result object.
**How:** Include fields: `riskLevel`, `overallProgress`, `programmeName`, `milestones`, `criteria`.
**Done when:** Unit test verifies the object serialization.

### Step 3: Populate Metrics
**What:** `[ID TSK-P1-PLT-003_work_item_03]` Return the deterministic metrics for PWRM0001.
**How:** Use values: Programme "Chunga Dumpsite Recovery", Progress 45%, Risk "LOW".
**Done when:** Frontend displays the ring chart correctly.

---

## Verification

```bash
# [ID TSK-P1-PLT-003_work_item_01]
curl -i http://localhost:5242/pilot-demo/api/pilot-success-criteria -H 'Cookie: symphony_pilot_demo_operator=VALID' | grep '200 OK' || exit 1

# [ID TSK-P1-PLT-003_work_item_02]
curl http://localhost:5242/pilot-demo/api/pilot-success-criteria -H 'Cookie: symphony_pilot_demo_operator=VALID' | grep 'overallProgress' || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_plt_003.json`

Required fields:
- `task_id`: "TSK-P1-PLT-003"
- `git_sha`: current commit
- `timestamp_utc`: current time
- `status`: "PASS"
- `checks`: array including KPI data validation
