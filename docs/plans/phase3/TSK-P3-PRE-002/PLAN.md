# TSK-P3-PRE-002 PLAN — Define Phase 3 CI Tier Model

Task: TSK-P3-PRE-002
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-PRE-002.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---
## Objective

Define Phase 3 CI Tier Model. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p3_pre_002.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_pre_002_ci_tier_model.json` | CREATE | Output artifact |
| `tasks/TSK-P3-PRE-002/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-PRE-002/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_pre_002_w01] Define the 5 CI tiers (T0-T4) with trigger conditions, target execution time, and contents.
- [ID tsk_p3_pre_002_w02] For each tier, list which Phase 3 invariants (INV-301 through INV-310) will be checked.
- [ID tsk_p3_pre_002_w03] Define the tier assignment rules: how new tasks are assigned to tiers based on task_type and wave.
- [ID tsk_p3_pre_002_w04] Document the tier escalation policy: what happens when a T0 test fails vs a T3 test fails.
- [ID tsk_p3_pre_002_w05] Write docs/PHASE3/PHASE3_CI_TIER_MODEL.md containing the full specification.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_tsk_p3_pre_002.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p3_pre_002.sh > evidence/phase3/tsk_p3_pre_002_ci_tier_model.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_tsk_p3_pre_002.sh

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
