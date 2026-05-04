# TSK-P2-GOV-CONV-017 PLAN — Create Phase-3 non-claimable stub docs only

Task: TSK-P2-GOV-CONV-017
Owner: ARCHITECT
failure_signature: PHASE2.STRICT.TSK-P2-GOV-CONV-017.PROOF_FAIL
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

Create Phase-3 non-claimable stub docs only. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_gov_conv_017.sh` | CREATE | Verifier for this task |
| `evidence/phase2/gov_conv_017_phase3_stub.json` | CREATE | Output artifact |
| `tasks/TSK-P2-GOV-CONV-017/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase2/TSK-P2-GOV-CONV-017/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID gov_conv_017_w01] Create docs/PHASE3/README.md marking Phase-3 as not open
- [ID gov_conv_017_w02] Create docs/PHASE3/phase3_contract.yml with zero implementation rows
- [ID gov_conv_017_w03] Add explicit non-claimable status and future-phase placeholder
- [ID gov_conv_017_w04] Ensure stub prevents premature Phase-3 work initiation
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_gov_conv_017.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_gov_conv_017.sh > evidence/phase2/gov_conv_017_phase3_stub.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_gov_conv_017.sh

# 2. Local parity check
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh
```
