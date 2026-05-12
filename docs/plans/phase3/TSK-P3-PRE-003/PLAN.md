# TSK-P3-PRE-003 PLAN — Formalize Task ID Nomenclature Standard

Task: TSK-P3-PRE-003
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-PRE-003.PROOF_FAIL
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

Formalize Task ID Nomenclature Standard. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p3_pre_003.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_pre_003_nomenclature.json` | CREATE | Output artifact |
| `tasks/TSK-P3-PRE-003/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-PRE-003/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_pre_003_w01] Inventory all existing task ID suffixes from Phases 0-2 by scanning tasks/*/meta.yml and extracting unique group patterns.
- [ID tsk_p3_pre_003_w02] Define the canonical task ID format specification: TSK-P<phase>-<group>-<sequence> with rules for each segment.
- [ID tsk_p3_pre_003_w03] Define the Phase 3 approved group registry derived from Phase 3 capability boundary.
- [ID tsk_p3_pre_003_w04] Document retroactive suffixes from Phases 0-2 as legacy-approved with explicit note that these are not valid for Phase 3 unless re-approved.
- [ID tsk_p3_pre_003_w05] Define validation rules: Phase 3 task IDs MUST use an approved Phase 3 group suffix; legacy suffixes are rejected for phase 3 tasks.
- [ID tsk_p3_pre_003_w06] Write docs/operations/TASK_ID_NOMENCLATURE.md containing the format spec, Phase 3 registry, legacy inventory, and validation rules.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_tsk_p3_pre_003.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p3_pre_003.sh > evidence/phase3/tsk_p3_pre_003_nomenclature.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_tsk_p3_pre_003.sh

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
