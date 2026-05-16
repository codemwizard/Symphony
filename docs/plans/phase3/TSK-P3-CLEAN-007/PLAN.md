# TSK-P3-CLEAN-007 PLAN — Maintain Phase 3 DAG artifacts after cleanup

Task: TSK-P3-CLEAN-007
Owner: ARCHITECT
Depends on: TSK-P3-CLEAN-001, TSK-P3-CLEAN-003
Blocked by: none after dependencies resolve
failure_signature: PHASE3.STRICT.TSK-P3-CLEAN-007.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
surface_specific_plan: docs/PHASE3/implementation_plans/TSK-P3-CAP-000_governance_cleanup.md

---

## Objective

Update docs/PHASE3/PHASE3_TASK_DAG.md and docs/PHASE3/phase3_task_dag.yml to
reflect the current status of all Wave 0 nodes after CLEAN-001 and CLEAN-003
are completed. Human and machine DAGs must agree on statuses, depends_on,
blocked_by, and surface mappings. No blocked_by entry may duplicate a
depends_on entry.

---

## Pre-conditions

- [ ] TSK-P3-CLEAN-001 is completed.
- [ ] TSK-P3-CLEAN-003 is completed.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/PHASE3/PHASE3_TASK_DAG.md` | MODIFY | Update Wave 0 node statuses |
| `docs/PHASE3/phase3_task_dag.yml` | MODIFY | Match human DAG statuses |
| `scripts/audit/verify_tsk_p3_clean_007.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_clean_007.json` | CREATE | Output artifact |
| `tasks/TSK-P3-CLEAN-007/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-CLEAN-007/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If blocked_by duplicates normal depends_on predecessors** -> STOP
- **If DAG and master plan diverge on surface mappings** -> STOP
- **If new DAG nodes are introduced** -> STOP

---

## Implementation Steps

### Step 1: Update human DAG
**What:** [ID tsk_p3_clean_007_work_01] Update PHASE3_TASK_DAG.md Wave 0 node statuses.
**Done when:** All completed nodes reflect their new status.

### Step 2: Update machine DAG
**What:** [ID tsk_p3_clean_007_work_02] Update phase3_task_dag.yml to match.
**Done when:** YAML parses and matches human DAG exactly.

### Step 3: Validate consistency
**What:** [ID tsk_p3_clean_007_work_03] Verify no blocked_by/depends_on overlap.
**Done when:** No duplicates found; master plan agreement confirmed.

### Step 4: Emit evidence
```bash
bash scripts/audit/verify_tsk_p3_clean_007.sh > evidence/phase3/tsk_p3_clean_007.json
```

---

## Verification

```bash
bash scripts/audit/verify_tsk_p3_clean_007.sh
bash scripts/dev/pre_ci.sh
```

---

## Evidence Contract

File: `evidence/phase3/tsk_p3_clean_007.json`

Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes
