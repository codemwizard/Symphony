# TSK-P1-PLT-005 PLAN — Onboarding Field Mapping

Task: TSK-P1-PLT-005
Owner: ARCHITECT
Depends on: TSK-P1-PLT-001
failure_signature: 1.PLT.005.ONBOARDING_FAILURE
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Fix the payload mismatches in `onboarding.html` that prevent tenant and worker registration. This task aligns the frontend's object structure with the backend's strict C# Record definitions.

## Architectural Context

The backend handlers for onboarding use direct JSON property mapping from the Request body. Any deviation in naming (e.g., `key` vs `tenant_key`) results in a 400 error or silent failure to bind values.

---

## Pre-conditions

- [x] TSK-P1-PLT-001 is scaffolded.
- [x] `onboarding.html` (Line 448-590) audited for fetch shapes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/symphony-pilot/onboarding.html` | MODIFY | Update JSON payloads in fetch calls. |
| `tasks/TSK-P1-PLT-005/meta.yml` | MODIFY | Update status. |

---

## Stop Conditions

- **If the frontend continues to send camelCase keys for worker registration** -> STOP
- **If the Fetch response check fails to distinguish between 401 (Auth) and 400 (Bad Format)** -> STOP

---

## Implementation Steps

### Step 1: Fix Tenant Payload
**What:** `[ID TSK-P1-PLT-005_work_item_01]` Update `registerTenant` in `onboarding.html`.
**How:** Change `body: JSON.stringify({ key, displayName })` to `body: JSON.stringify({ tenant_key: key, display_name: displayName })`.
**Done when:** A test tenant is successfully created.

### Step 2: Fix Worker Payload
**What:** `[ID TSK-P1-PLT-005_work_item_02]` Update `registerWorker` in `onboarding.html`.
**How:** Map `tenant` $\to$ `tenant_id`, `name` $\to$ `supplier_name`, and `payoutTarget` $\to$ `payout_target`.
**Done when:** A test worker is successfully created.

### Step 3: Add Cookie Support
**What:** `[ID TSK-P1-PLT-005_work_item_03]` Ensure `credentials: 'include'` is set on all onboarding fetch calls.
**How:** Update the fetch options object in all registration and status check functions.
**Done when:** The operator cookie is observed in the request headers during browser testing.

---

## Verification

### Manual Verification
1. Open the pilot onboarding page.
2. Register a new tenant "Chunga Coop" (key: `chunga-coop`).
3. Verify the tenant appears in the "REGISTERED TENANTS" table.
4. Register a worker "John Banda" for "Chunga Coop".
5. Verify success banner appears.

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_plt_005.json`

Required fields:
- `task_id`: "TSK-P1-PLT-005"
- `status`: "PASS"
- `checks`: array including tenant and worker registration validation
