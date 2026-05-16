# TSK-P3-CLEAN-006 PLAN — Verify archived Phase 3 files are excluded from task generation

Task: TSK-P3-CLEAN-006
Owner: ARCHITECT
Depends on: none
Blocked by: TSK-P3-CLEAN-001
failure_signature: PHASE3.STRICT.TSK-P3-CLEAN-006.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
surface_specific_plan: docs/PHASE3/implementation_plans/TSK-P3-CAP-000_governance_cleanup.md

---

## Objective

Verify that all files under docs/PHASE3/archive/ are marked non-canonical and
excluded from ingestion and task-generation input. No archived file may be cited
as a governing or canonical source by any Phase 3 planning document.

---

## Pre-conditions

- [ ] TSK-P3-CLEAN-001 blocked_by gate is cleared.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/PHASE3/archive/` | VERIFY/MODIFY | Ensure non-canonical markers present |
| `scripts/audit/verify_tsk_p3_clean_006.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_clean_006.json` | CREATE | Output artifact |
| `tasks/TSK-P3-CLEAN-006/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-CLEAN-006/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If archived files remain eligible as doctrine or task-generation input** -> STOP
- **If any archived file is cited as governing by a Phase 3 planning doc** -> STOP

---

## Implementation Steps

### Step 1: Audit archived files
**What:** [ID tsk_p3_clean_006_work_01] Check every file under docs/PHASE3/archive/ for non-canonical markers.
**Done when:** Every file has a non-canonical header or exclusion marker.

### Step 2: Verify exclusion
**What:** [ID tsk_p3_clean_006_work_02] Confirm exclusion from ingestion/task-generation config.
**Done when:** No archived path in any whitelist or source-pack canonical list.

### Step 3: Verify citations
**What:** [ID tsk_p3_clean_006_work_03] Search docs/PHASE3/ for archived file citations.
**Done when:** Zero citations of archived files as governing sources.

### Step 4: Emit evidence
```bash
bash scripts/audit/verify_tsk_p3_clean_006.sh > evidence/phase3/tsk_p3_clean_006.json
```

---

## Verification

```bash
bash scripts/audit/verify_tsk_p3_clean_006.sh
bash scripts/dev/pre_ci.sh
```

---

## Evidence Contract

File: `evidence/phase3/tsk_p3_clean_006.json`

Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes
