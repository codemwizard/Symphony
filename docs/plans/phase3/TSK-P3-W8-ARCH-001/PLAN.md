# TSK-P3-W8-ARCH-001 PLAN — Connect TamperEvidentChain application hash chain to DB proof_pack_batches Merkle system

Task: TSK-P3-W8-ARCH-001
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-W8-ARCH-001.PROOF_FAIL
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

Connect TamperEvidentChain application hash chain to DB proof_pack_batches Merkle system. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_p3_hash_chain_bridge.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_w8_arch_001_hash_chain_bridge.json` | CREATE | Output artifact |
| `tasks/TSK-P3-W8-ARCH-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-W8-ARCH-001/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_w8_arch_001_work_item_01] Add ExtractLeafHashes method to TamperEvidentChain.cs that reads an NDJSON chain file and yields (artifact_id, leaf_hash) tuples from each entry's chain_record.current_hash and instruction_id, enabling the EpochSealingCommand to bridge application-layer hashes into proof_pack_batch_leaves.
- [ID tsk_p3_w8_arch_001_work_item_02] Create TamperEvidentChainBridgeTests.cs with xunit tests verifying: application chain hash matches DB leaf hash for the same record, round-trip write-to-NDJSON then extract-leaf then seal-to-Merkle then verify-proof, and corrupted NDJSON line rejection.
- [ID tsk_p3_w8_arch_001_work_item_03] Document the external verifier workflow in a code comment block: regulator receives Merkle root, receives leaf proofs, independently recomputes SHA-256 from NDJSON log, verifies leaf against proof, reconstructs constitutional state.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_p3_hash_chain_bridge.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_p3_hash_chain_bridge.sh > evidence/phase3/tsk_p3_w8_arch_001_hash_chain_bridge.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_p3_hash_chain_bridge.sh

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
