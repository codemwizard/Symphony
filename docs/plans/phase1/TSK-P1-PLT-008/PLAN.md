# TSK-P1-PLT-008 PLAN — Align Pilot Onboarding UI with Backend APIs

Task: TSK-P1-PLT-008
Owner: ARCHITECT
Depends on: TSK-P1-PLT-007
failure_signature: 1.PLT.tsk-p1-plt-008.DRD-BLOCKED
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective
Remediate the broken UI state generated during `onboarding.html` workflows by updating javascript API payload signatures and data extraction maps. This closes the semantic drift between the mock frontend representation and the explicitly enforced LedgerApi JSON extraction layer, allowing the E2E verification of tenant and programme workflows.

---

## Architectural Context
The frontend was originally written expecting camelCase keys and automatically computed arrays (like NextJS). The backend returns raw arrays with snake_case keys. This DRD L1 task corrects the semantic mismatch, ensuring the workflow integrity.

---

## Pre-conditions

- [x] TSK-P1-PLT-007 is status=completed and evidence validates.
- [x] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `src/symphony-pilot/onboarding.html` | MODIFY | Correct payload key maps and extract dropdown UUIDs |
| `scripts/audit/verify_tsk_p1_plt_008.sh` | CREATE | Anti-drift regex check on correct string payloads |
| `docs/plans/phase1/TSK-P1-PLT-008/REM-L1-ONBOARDING.md` | CREATE | DRD trace required by policy |
| `tasks/TSK-P1-PLT-008/meta.yml` | MODIFY | Update status to completed |
| `docs/plans/phase1/TSK-P1-PLT-008/EXEC_LOG.md` | CREATE | Track execution |

---

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP

---

## Implementation Steps

### Step 1: DRD Scaffolding
**What:** `[ID tsk_p1_plt_008_work_item_01]` Scaffold the DRD Lite log.
**How:** Create `REM-L1-ONBOARDING.md` using the Lite Template format.
**Done when:** The DRD Markdown file persists in the plan directory mapping the Bad Request errors.

### Step 2: Response Dictionary Updates
**What:** `[ID tsk_p1_plt_008_work_item_02]` Re-map table values to snake_case.
**How:** Update `.key` to `.tenant_key`, `.name` to `.display_name`, and `.id` to `.programme_id` in both rendering strings. Compute stats functionally from array length.
**Done when:** JS functions reference exact C# record properties.

### Step 3: UUID Dropdown Sourcing
**What:** `[ID tsk_p1_plt_008_work_item_03]` Inject proper dropdown UUIDs.
**How:** Use `value="${t.tenant_id}"` and `data-tenant="${p.tenant_id}"`.
**Done when:** UUIDs are embedded in the respective HTML option objects.

### Step 4: Inject Tenant Identity Across Endpoints
**What:** `[ID tsk_p1_plt_008_work_item_04]` Send `tenant_id` alongside requests.
**How:** Use `dataset.tenant` extraction and mutate the JSON `body` properties sent through the `fetch` execution blocks.
**Done when:** Both policy bind and programme activation pass `tenant_id` up explicitly.

### Step 5: Verification Constraint
**What:** `[ID tsk_p1_plt_008_work_item_05]` Enforce anti-drift proof generation.
**How:** Create `scripts/audit/verify_tsk_p1_plt_008.sh` matching the JS components for missing UUIDs and missing `tenant_id` blocks.
**Done when:** The integration wrapper shell script exits non-zero against unfixed/dummy code, and exits 0 against the target implementation.

### Step N: Emit evidence
**What:** `[ID tsk_p1_plt_008_work_item_05]` Run verifier and validate evidence schema.
**How:**
```bash
test -x scripts/audit/verify_tsk_p1_plt_008.sh && bash scripts/audit/verify_tsk_p1_plt_008.sh > evidence/phase1/tsk_p1_plt_008_ui_alignment.json || exit 1
```
**Done when:** Verification executes natively through failure paths and the explicit JSON schema is written to disk.

---

## Verification

```bash
# [ID tsk_p1_plt_008_work_item_01] [ID tsk_p1_plt_008_work_item_02] [ID tsk_p1_plt_008_work_item_03] [ID tsk_p1_plt_008_work_item_04] [ID tsk_p1_plt_008_work_item_05]
test -x scripts/audit/verify_tsk_p1_plt_008.sh && bash scripts/audit/verify_tsk_p1_plt_008.sh > evidence/phase1/tsk_p1_plt_008_ui_alignment.json || exit 1

# [ID tsk_p1_plt_008_work_item_05]
test -f evidence/phase1/tsk_p1_plt_008_ui_alignment.json && cat evidence/phase1/tsk_p1_plt_008_ui_alignment.json | grep "observed_hashes" || exit 1

# [ID tsk_p1_plt_008_work_item_05]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_plt_008_ui_alignment.json`

Required fields:
- `task_id`: "TSK-P1-PLT-008"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects (including positive and negative assertions)
- `observed_paths`: explicitly matched source documents
- `observed_hashes`: execution chain sha values
- `command_outputs`: explicit logging buffer
- `execution_trace`: runtime path sequence

---

## Rollback

If this task must be reverted:
1. Revert modifications inside `src/symphony-pilot/onboarding.html` via git hash rollback.
2. Remove validation traces.
3. Update status back to 'ready' in meta.yml.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Evidence file missing | FAIL | Halt CI explicitly. |
| Onboarding JS relies on undefined camelCase fields | CRITICAL_FAIL | Hard Regex string requirement. |
| Verification strings lack fail domain `\|\| exit 1` | FAIL_REVIEW | Proof graph semantic verifier. |
