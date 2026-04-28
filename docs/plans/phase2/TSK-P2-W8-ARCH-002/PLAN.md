# TSK-P2-W8-ARCH-002 PLAN - Transition hash contract

Task: TSK-P2-W8-ARCH-002
Owner: ARCHITECT
failure_signature: P2.W8.TSK_P2_W8_ARCH_002.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Freeze deterministic transition-hash semantics before any runtime task attempts recomputation or signing.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `hash contract`
- Contract authority outranks implementation authority.
- SQL is the authoritative runtime executor only where this task implements runtime behavior.
- No advisory fallback is permitted for Wave 8 completion work.

## Scope Discipline

- This task is invalid if it expands into more than one primary enforcement domain.
- If implementation reveals a second enforcement domain, stop and create a follow-on pack.
- No completion credit is permitted unless the artifacts or behavior declared here are fully delivered.

## Intent

This task removes ambiguity around hash input selection and output encoding so later tasks cannot treat hashing as implementation folklore.

## Dependencies

TSK-P2-W8-ARCH-001

## Deliverables

| File | Action | Reason |
|------|--------|--------|
| `docs/contracts/TRANSITION_HASH_CONTRACT.md` | CREATE | Deliver or update the task-controlled artifact |
| `scripts/agent/verify_tsk_p2_w8_arch_002.py` | CREATE | Deliver or update the task-controlled artifact |
| `evidence/phase2/tsk_p2_w8_arch_002.json` | CREATE | Deliver or update the task-controlled artifact |

## Stop Conditions

- Stop if the work expands beyond `hash contract`.
- Stop if approval metadata is missing for a regulated-surface edit.
- Stop if the verifier path cannot be tied directly to the work-item IDs below.
- Stop if evidence cannot satisfy `TSK-P1-240` proof-carrying fields.

## Work Items

### Step 1
**What:** [ID w8_arch_002_work_01] Define the exact field set, prohibited extras, and canonicalization rules for `transition_hash` version 1.
**Done when:** [ID w8_arch_002_work_01] `TRANSITION_HASH_CONTRACT.md` explicitly defines the field set and prohibited extras for version 1 hashing.

### Step 2
**What:** [ID w8_arch_002_work_02] Define SHA-256, lowercase hex encoding, hash-before-signature ordering, and deterministic replay expectations.
**Done when:** [ID w8_arch_002_work_02] The contract explicitly defines RFC 8785 canonicalization, SHA-256, lowercase hex output, and hash-before-signature ordering.

### Step 3
**What:** [ID w8_arch_002_work_03] Define mismatch semantics and required failure classes for invalid input, canonicalization failure, and recomputation mismatch.
**Done when:** [ID w8_arch_002_work_03] The contract explicitly defines fail-closed mismatch semantics and named failure classes.

## Verification

```bash
python3 scripts/agent/verify_tsk_p2_w8_arch_002.py > evidence/phase2/tsk_p2_w8_arch_002.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-ARCH-002/PLAN.md --meta tasks/TSK-P2-W8-ARCH-002/meta.yml
```

## Evidence Contract

Evidence file: `evidence/phase2/tsk_p2_w8_arch_002.json`

Required proof fields:
- `task_id`
- `git_sha`
- `timestamp_utc`
- `status`
- `checks`
- `observed_paths`
- `observed_hashes`
- `command_outputs`
- `execution_trace`

## Approval and Trace

- Stage A approval metadata is required before regulated-surface edits.
- `EXEC_LOG.md` is append-only and must carry remediation trace markers.
