# TSK-P3-CLEAN-005 PLAN — Resolve non-canonical MADD/MAIN duplicate doctrine copy

Task: TSK-P3-CLEAN-005
Owner: ARCHITECT
Depends on: none
Blocked by: TSK-P3-CLEAN-001
failure_signature: PHASE3.STRICT.TSK-P3-CLEAN-005.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
surface_specific_plan: docs/PHASE3/implementation_plans/TSK-P3-CAP-000_governance_cleanup.md

---

## Objective

Resolve the duplicate or non-canonical MADD/MAIN integration doctrine copy so
that Phase 3 planning cites only canonical doctrine. The duplicate must be
archived, marked non-canonical, or merged with a source-lineage decision.

---

## Pre-conditions

- [ ] TSK-P3-CLEAN-001 blocked_by gate is cleared.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE-2.md` | MODIFY | Archive or mark non-canonical |
| `scripts/audit/verify_tsk_p3_clean_005.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_clean_005.json` | CREATE | Output artifact |
| `tasks/TSK-P3-CLEAN-005/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-CLEAN-005/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If duplicate doctrine is treated as canonical without lineage decision** -> STOP
- **If merge is performed without source-lineage decision recorded** -> STOP
- **If Phase 3 planning documents still cite the duplicate** -> STOP

---

## Implementation Steps

### Step 1: Identify duplicate
**What:** [ID tsk_p3_clean_005_work_01] Identify the duplicate MADD/MAIN doctrine copy.
**Done when:** File is identified and canonical status is recorded.

### Step 2: Resolve duplicate
**What:** [ID tsk_p3_clean_005_work_02] Archive, mark non-canonical, or merge.
**Done when:** Duplicate has non-canonical header or lineage decision.

### Step 3: Verify citations
**What:** [ID tsk_p3_clean_005_work_03] Confirm Phase 3 planning docs cite only canonical doctrine.
**Done when:** No PHASE3 doc cites the duplicate as governing.

### Step 4: Emit evidence
```bash
bash scripts/audit/verify_tsk_p3_clean_005.sh > evidence/phase3/tsk_p3_clean_005.json
```

---

## Verification

```bash
bash scripts/audit/verify_tsk_p3_clean_005.sh
bash scripts/dev/pre_ci.sh
```

---

## Evidence Contract

File: `evidence/phase3/tsk_p3_clean_005.json`

Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes
