# TSK-P3-CLEAN-002 PLAN — Rewrite Phase 3 README planning posture

Task: TSK-P3-CLEAN-002
Owner: ARCHITECT
Depends on: none
Blocked by: TSK-P3-CLEAN-001
failure_signature: PHASE3.STRICT.TSK-P3-CLEAN-002.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
surface_specific_plan: docs/PHASE3/implementation_plans/TSK-P3-CAP-000_governance_cleanup.md

---

## Objective

Rewrite docs/PHASE3/README.md to remove stale external-trust-surface posture
language and replace it with the current planning-only posture, including
canonical references to source pack, capability boundary, DAG, and master
implementation plan.

---

## Pre-conditions

- [ ] TSK-P3-CLEAN-001 blocked_by gate is cleared.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/PHASE3/README.md` | MODIFY | Rewrite to planning-only posture |
| `scripts/audit/verify_tsk_p3_clean_002.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_clean_002.json` | CREATE | Output artifact |
| `tasks/TSK-P3-CLEAN-002/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-CLEAN-002/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If README claims Phase 3 implementation is executable** -> STOP
- **If README introduces new planning scope not in the master plan** -> STOP
- **If stale external-trust-surface phrases remain** -> STOP

---

## Implementation Steps

### Step 1: Remove stale posture
**What:** Remove all external-trust-surface language.
**How:** [ID tsk_p3_clean_002_work_01] Identify and remove stale phrases.
**Done when:** No stale external-trust-surface phrases remain.

### Step 2: Add planning posture
**What:** Add planning-only statement and canonical references.
**How:** [ID tsk_p3_clean_002_work_02] Add references to PHASE3_SOURCE_PACK.md, PHASE3_CAPABILITY_BOUNDARY.md, PHASE3_TASK_DAG.md, PHASE3_MASTER_IMPLEMENTATION_PLAN.md.
**Done when:** All four canonical references are present.

### Step 3: Verify no execution claims
**What:** [ID tsk_p3_clean_002_work_03] Confirm no executable status claims.
**Done when:** Search confirms no execution-readiness language.

### Step 4: Emit evidence
```bash
bash scripts/audit/verify_tsk_p3_clean_002.sh > evidence/phase3/tsk_p3_clean_002.json
```

---

## Verification

```bash
bash scripts/audit/verify_tsk_p3_clean_002.sh
bash scripts/dev/pre_ci.sh
```

---

## Evidence Contract

File: `evidence/phase3/tsk_p3_clean_002.json`

Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes
