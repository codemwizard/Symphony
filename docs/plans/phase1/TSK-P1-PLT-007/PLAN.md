# TSK-P1-PLT-007 PLAN — E2E Smoke Test Verification

Task: TSK-P1-PLT-007
Owner: ARCHITECT
Depends on: TSK-P1-PLT-001 through PLT-006
failure_signature: 1.PLT.007.SMOKE_TEST_FAILURE
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create a final mechanical gate that verifies the Pilot-to-Backend integration. This script ensures that all individual remediations work together as a single cohesive flow, producing verifiable evidence of a "Green" pilot state.

## Architectural Context

This task follows the `Verifier Integrity` policy from `TSK-P1-240`. Every work item in the pilot remediation pack must be covered by this automated smoke test before the feature is marked as Complete.

---

## Pre-conditions

- [x] TSK-P1-PLT-001 through 006 are scaffolded.
- [ ] LedgerApi is running.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_pilot_integration.sh` | NEW | Implement the E2E verification script. |
| `tasks/TSK-P1-PLT-007/meta.yml` | MODIFY | Update status. |

---

## Stop Conditions

- **If the script exits with code 0 but the evidence file shows a "FAIL" status** -> STOP
- **If the script fails to capture the correct Git SHA** -> STOP

---

## Implementation Steps

### Step 1: Create Script Stub
**What:** `[ID TSK-P1-PLT-007_work_item_01]` Create `scripts/audit/verify_pilot_integration.sh`.
**How:** Use `bash` with `set -euo pipefail`. Use `curl` for API probes.
**Done when:** Script runs and returns usage info.

### Step 2: Implement Flow Checks
**What:** `[ID TSK-P1-PLT-007_work_item_02]` Implement the sequential checks.
**How:**
1. Check `/pilot-demo/onboarding` for `Set-Cookie`.
2. Check `/pilot-demo/api/reveal` for `tests`.
3. Check `/pilot-demo/api/pilot-success-criteria` for `overallProgress`.
4. Check `/pilot-demo/api/monitoring-report` for `zgft` flags.
**Done when:** Script reports status for each check.

### Step 3: Produce Evidence
**What:** `[ID TSK-P1-PLT-007_work_item_03]` Write results to `evidence/phase1/pilot_integration_e2e.json`.
**How:** Use `cat` or `jq` to construct the evidence JSON matching the project's contract.
**Done when:** JSON file contains `git_sha` and `status: "PASS"`.

---

## Verification

```bash
# [ID TSK-P1-PLT-007_work_item_01]
chmod +x scripts/audit/verify_pilot_integration.sh
scripts/audit/verify_pilot_integration.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/pilot_integration_e2e.json`

Required fields:
- `task_id`: "TSK-P1-PLT-007"
- `git_sha`: current commit
- `timestamp_utc`: current time
- `status`: "PASS"
- `checks`: full array of pilot integration probes
