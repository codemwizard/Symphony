# TSK-P3-CLEAN-008 PLAN — Maintain Phase 3 implementation-plan registry after DAG maintenance

Task: TSK-P3-CLEAN-008
Owner: ARCHITECT
Depends on: TSK-P3-CLEAN-007
Blocked by: none after dependencies resolve
failure_signature: PHASE3.STRICT.TSK-P3-CLEAN-008.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
surface_specific_plan: docs/PHASE3/implementation_plans/TSK-P3-CAP-000_governance_cleanup.md

---

## Objective

Update the implementation-plan registry (docs/PHASE3/implementation_plans/README.md)
and the master implementation plan to ensure their status entries match actual
plan files on disk. TSK-P3-CAP-000 must be listed as 'created-planning'. No
registry entry may claim task packs exist when they do not. No atomic PLAN or
EXEC_LOG content may be stored in the registry.

---

## Pre-conditions

- [ ] TSK-P3-CLEAN-007 is completed.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/PHASE3/implementation_plans/README.md` | MODIFY | Update plan statuses |
| `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` | MODIFY | Update registry entries |
| `scripts/audit/verify_tsk_p3_clean_008.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_clean_008.json` | CREATE | Output artifact |
| `tasks/TSK-P3-CLEAN-008/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-CLEAN-008/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If registry claims task packs exist when no tasks/<ID>/meta.yml exists** -> STOP
- **If registry stores atomic PLAN or EXEC_LOG content** -> STOP
- **If registry status does not match actual file state on disk** -> STOP

---

## Implementation Steps

### Step 1: Update registry
**What:** [ID tsk_p3_clean_008_work_01] Update implementation_plans/README.md statuses.
**Done when:** TSK-P3-CAP-000 is 'created-planning' and all entries match disk.

### Step 2: Update master plan
**What:** [ID tsk_p3_clean_008_work_02] Update PHASE3_MASTER_IMPLEMENTATION_PLAN.md entries.
**Done when:** All plan references resolve to existing files on disk.

### Step 3: Validate no phantom claims
**What:** [ID tsk_p3_clean_008_work_03] Confirm no phantom task-pack claims.
**Done when:** No registry entry claims task packs for nodes without meta.yml.

### Step 4: Emit evidence
```bash
bash scripts/audit/verify_tsk_p3_clean_008.sh > evidence/phase3/tsk_p3_clean_008.json
```

---

## Verification

```bash
bash scripts/audit/verify_tsk_p3_clean_008.sh
bash scripts/dev/pre_ci.sh
```

---

## Evidence Contract

File: `evidence/phase3/tsk_p3_clean_008.json`

Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes
