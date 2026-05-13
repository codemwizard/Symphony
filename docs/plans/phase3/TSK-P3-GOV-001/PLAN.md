# TSK-P3-GOV-001 PLAN — Build constitutional compilation pipeline validating Phase 3 invariant-to-task-to-verifier wiring

Task: TSK-P3-GOV-001
Owner: INVARIANTS_CURATOR
failure_signature: PHASE3.STRICT.TSK-P3-GOV-001.PROOF_FAIL
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

Build constitutional compilation pipeline validating Phase 3 invariant-to-task-to-verifier wiring. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/constitutional/compile_phase3_constraints.py` | CREATE | Verifier for this task |
| `evidence/phase3/constitutional_constraint_manifest.json` | CREATE | Output artifact |
| `tasks/TSK-P3-GOV-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-GOV-001/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_gov_001_work_item_01] Create scripts/constitutional/compile_phase3_constraints.py that parses PHASE3_INVARIANT_REGISTER.md and validates every INV-3xx has a verifier script path, severity, and negative test declaration.
- [ID tsk_p3_gov_001_work_item_02] Validate that data_class_registry.yml contains all six constitutional data classes with complete typed fields (deletion_permission, replay_obligation, redaction_permission, retention_floor).
- [ID tsk_p3_gov_001_work_item_03] Emit evidence/phase3/constitutional_constraint_manifest.json with per-invariant wiring status, data class registry completeness, and overall pass/fail determination.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/constitutional/compile_phase3_constraints.py`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
python3 scripts/constitutional/compile_phase3_constraints.py > evidence/phase3/constitutional_constraint_manifest.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
python3 scripts/constitutional/compile_phase3_constraints.py

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
