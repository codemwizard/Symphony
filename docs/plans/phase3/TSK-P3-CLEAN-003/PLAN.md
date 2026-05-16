# TSK-P3-CLEAN-003 PLAN — Add doctrine references to Phase 3 invariant register

Task: TSK-P3-CLEAN-003
Owner: INVARIANTS_CURATOR
Depends on: none
Blocked by: TSK-P3-CLEAN-001
failure_signature: PHASE3.STRICT.TSK-P3-CLEAN-003.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
surface_specific_plan: docs/PHASE3/implementation_plans/TSK-P3-CAP-000_governance_cleanup.md

---

## Objective

Add governing doctrine citations to each invariant row INV-301 through INV-310
in docs/PHASE3/PHASE3_INVARIANT_REGISTER.md. Preserve honest roadmap or
implementation status. Do not promote any invariant to implemented without
verifier evidence. Do not invent doctrine locally.

---

## Pre-conditions

- [ ] TSK-P3-CLEAN-001 blocked_by gate is cleared.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` | MODIFY | Add doctrine references |
| `scripts/audit/verify_tsk_p3_clean_003.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_clean_003.json` | CREATE | Output artifact |
| `tasks/TSK-P3-CLEAN-003/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-CLEAN-003/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If any invariant is marked implemented without verifier evidence on disk** -> STOP
- **If any doctrine citation does not resolve to an existing canonical document** -> STOP
- **If doctrine is invented locally** -> STOP

---

## Implementation Steps

### Step 1: Add doctrine references
**What:** [ID tsk_p3_clean_003_work_01] Add governing doctrine citations to INV-301 through INV-310.
**Done when:** Every invariant has at least one doctrine reference.

### Step 2: Preserve status honesty
**What:** [ID tsk_p3_clean_003_work_02] Verify no invariant is promoted to implemented without evidence.
**Done when:** All statuses reflect actual verifier/evidence state.

### Step 3: Validate citations
**What:** [ID tsk_p3_clean_003_work_03] Confirm all doctrine citations resolve to existing canonical files.
**Done when:** All cited files exist and are not archived/non-canonical.

### Step 4: Emit evidence
```bash
bash scripts/audit/verify_tsk_p3_clean_003.sh > evidence/phase3/tsk_p3_clean_003.json
```

---

## Verification

```bash
bash scripts/audit/verify_tsk_p3_clean_003.sh
bash scripts/dev/pre_ci.sh
```

---

## Evidence Contract

File: `evidence/phase3/tsk_p3_clean_003.json`

Required fields: task_id, git_sha, timestamp_utc, status, checks, observed_paths, observed_hashes
