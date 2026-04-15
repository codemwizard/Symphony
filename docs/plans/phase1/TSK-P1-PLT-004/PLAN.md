# TSK-P1-PLT-004 PLAN — Monitoring & Export Generator

Task: TSK-P1-PLT-004
Owner: ARCHITECT
Depends on: TSK-P1-PLT-001
failure_signature: 1.PLT.004.MRV_FAILURE
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Synchronize the "Monitoring Report" tab with the backend data and enable the ZEMA reporting pack generation. This task ensures the Article 6 compliance chips are data-driven and the "GENERATE" button produces actual PDF/JSON artifacts.

## Architectural Context

The backend `Pwrm0001MonitoringReportHandler` generates a complex JSON reporting structure. This task creates a specific pilot-demo bridge that flattens this data for the UI and triggers the legacy export logic.

---

## Pre-conditions

- [x] TSK-P1-PLT-001 is scaffolded.
- [x] `Pwrm0001MonitoringReportHandler.cs` audited for Article 6 field names.
- [x] `generate_programme_reporting_pack.sh` exists.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `services/ledger-api/dotnet/src/LedgerApi/Program.cs` | MODIFY | Add Monitoring and Export handlers. |
| `src/symphony-pilot/monitoring-report.html` | MODIFY | Update field mappings and Export button logic. |
| `tasks/TSK-P1-PLT-004/meta.yml` | MODIFY | Update status. |

---

## Stop Conditions

- **If the export script is triggered multiple times per button click (lack of idempotency/throttle)** -> STOP
- **If the JSON mapping results in undefined fields in the UI** -> STOP

---

## Implementation Steps

### Step 1: Implement Flat Mapping
**What:** `[ID TSK-P1-PLT-004_work_item_01]` Update `Program.cs` to flatten `zgft_waste_sector_alignment` before returning to the pilot UI.
**How:** Extract `pollution_prevention`, `circular_economy`, and `do_no_significant_harm_declared` to top-level keys.
**Done when:** Frontend chips reflect the true/false values from the ReadModel.

### Step 2: Implement Export Shim
**What:** `[ID TSK-P1-PLT-004_work_item_02]` Add POST `/pilot-demo/api/monitoring-report/{programId}/export` to `Program.cs`.
**How:** Validate cookie, then call `Process.Start` to run the export bash script.
**Done when:** Shim returns a 201 Created with artifact paths.

### Step 3: Wire UI Button
**What:** `[ID TSK-P1-PLT-004_work_item_03]` Update `fetchMonitoringReport` in the HTML to handle the generation success and display download links.
**How:** Add a results area to the card that appears after generation.
**Done when:** User can click "GENERATE" and see download links.

---

## Verification

```bash
# [ID TSK-P1-PLT-004_work_item_02]
curl -i http://localhost:5242/pilot-demo/api/monitoring-report/PGM-ZAMBIA-GRN-001/export -H 'Cookie: symphony_pilot_demo_operator=VALID' | grep '200 OK' || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_plt_004.json`

Required fields:
- `task_id`: "TSK-P1-PLT-004"
- `git_sha`: current commit
- `timestamp_utc`: current time
- `status`: "PASS"
- `checks`: array including export artifact presence validation
