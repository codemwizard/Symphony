# TSK-P3-PRE-005 PLAN — Update Task Generator for Phase 3 Mode

Task: TSK-P3-PRE-005
Owner: SECURITY_GUARDIAN
failure_signature: PHASE3.STRICT.TSK-P3-PRE-005.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any migration or regulated file without prior approval metadata.
- Approval artifacts MUST be created BEFORE editing regulated surfaces.
- Stage A: Before editing (approvals/YYYY-MM-DD/BRANCH-<branch>.md and .approval.json)
- Stage B: After PR opening (approvals/YYYY-MM-DD/PR-<number>.md and .approval.json)
- Conformance check: `bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=<branch>`

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---
## Objective

Update Task Generator for Phase 3 Mode. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p3_pre_005.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_pre_005_generator_update.json` | CREATE | Output artifact |
| `tasks/TSK-P3-PRE-005/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-PRE-005/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_pre_005_w01] Add wave as an optional field in the JSON config schema. When phase == 3, validate that wave is from the Phase 3 approved group registry.
- [ID tsk_p3_pre_005_w02] Add Phase 3 task ID pattern validation: when phase == 3, task_id must match canonical regex.
- [ID tsk_p3_pre_005_w03] Inject Phase 3 must_read entries into generated meta.yml.
- [ID tsk_p3_pre_005_w04] Update PLAN.md generation to reference Phase 3 constitutional documents in the Pre-conditions section.
- [ID tsk_p3_pre_005_w05] Add --phase3 convenience flag that sets phase=3, is_regulated=true, and injects Phase 3 defaults automatically.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_tsk_p3_pre_005.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p3_pre_005.sh > evidence/phase3/tsk_p3_pre_005_generator_update.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_tsk_p3_pre_005.sh

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
