# TSK-P2-GOV-CONV-018 PLAN — Verify Phase-3 stub non-claimability only

Task: TSK-P2-GOV-CONV-018
Owner: SECURITY_GUARDIAN
failure_signature: PHASE2.STRICT.TSK-P2-GOV-CONV-018.PROOF_FAIL
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

Verify Phase-3 stub non-claimability only. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_gov_conv_018.sh` | CREATE | Verifier for this task |
| `evidence/phase2/gov_conv_018_phase3_verification.json` | CREATE | Output artifact |
| `tasks/TSK-P2-GOV-CONV-018/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase2/TSK-P2-GOV-CONV-018/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID gov_conv_018_w01] Create verifier that checks Phase-3 stub non-claimability status
- [ID gov_conv_018_w02] Verify README.md contains explicit non-open language
- [ID gov_conv_018_w03] Verify phase3_contract.yml has zero implementation rows
- [ID gov_conv_018_w04] Ensure verifier rejects any premature Phase-3 opening artifacts
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_gov_conv_018.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_gov_conv_018.sh > evidence/phase2/gov_conv_018_phase3_verification.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_gov_conv_018.sh

# 2. Local parity check
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh
```
