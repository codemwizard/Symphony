# TSK-P3-PRE-007 PLAN — Define Phase 3 Task Registry Schema

Task: TSK-P3-PRE-007
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-PRE-007.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---
## Objective

Define Phase 3 Task Registry Schema. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p3_pre_007.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_pre_007_registry_schema.json` | CREATE | Output artifact |
| `tasks/TSK-P3-PRE-007/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-PRE-007/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_pre_007_w01] Define the phase3_task_registry.yml YAML schema with top-level and per-task fields.
- [ID tsk_p3_pre_007_w02] Define the approved task_type values: IMPL, VERIFY, CERT, GOV, PERSIST, API, DOC, OPS.
- [ID tsk_p3_pre_007_w03] Define the approved ci_tier values with semantic meaning: T0 to T4.
- [ID tsk_p3_pre_007_w04] Create docs/PHASE3/phase3_task_registry.yml with the schema as header comments and 3 example tasks.
- [ID tsk_p3_pre_007_w05] Document the governance contract: this registry is a read-only planning index.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_tsk_p3_pre_007.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p3_pre_007.sh > evidence/phase3/tsk_p3_pre_007_registry_schema.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_tsk_p3_pre_007.sh

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
