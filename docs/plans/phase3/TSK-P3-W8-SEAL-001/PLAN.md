# TSK-P3-W8-SEAL-001 PLAN — Activate epoch sealing process by implementing EpochSealingCommand populating proof_pack_batches Merkle tree

Task: TSK-P3-W8-SEAL-001
Owner: DB_FOUNDATION
failure_signature: PHASE3.STRICT.TSK-P3-W8-SEAL-001.PROOF_FAIL
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

Activate epoch sealing process by implementing EpochSealingCommand populating proof_pack_batches Merkle tree. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/db/verify_p3_epoch_sealing.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_w8_seal_001_epoch_sealing.json` | CREATE | Output artifact |
| `tasks/TSK-P3-W8-SEAL-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-W8-SEAL-001/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_w8_seal_001_work_item_01] Create EpochSealingCommand.cs in LedgerApi/Commands that accepts evidence_node_id batch or time range, filters to constitutional data classes (evidentiary/provenance/replay), computes SHA-256 leaf hashes from canonical payloads, builds Merkle tree, and writes to proof_pack_batches and proof_pack_batch_leaves tables from migration 0066.
- [ID tsk_p3_w8_seal_001_work_item_02] Record each epoch seal run in archive_verification_runs with run_scope, years_covered, canonicalization_versions_covered, and PASS/FAIL outcome.
- [ID tsk_p3_w8_seal_001_work_item_03] Create EpochSealingCommandTests.cs with xunit tests verifying: Merkle root computation correctness, operational nodes excluded from sealing, empty batch rejection, and leaf hash independently re-computable from canonical payload.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/db/verify_p3_epoch_sealing.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/db/verify_p3_epoch_sealing.sh > evidence/phase3/tsk_p3_w8_seal_001_epoch_sealing.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/db/verify_p3_epoch_sealing.sh

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
