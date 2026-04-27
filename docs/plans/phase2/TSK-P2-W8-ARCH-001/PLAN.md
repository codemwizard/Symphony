# TSK-P2-W8-ARCH-001 PLAN - Canonical attestation payload contract

Task: TSK-P2-W8-ARCH-001
Owner: ARCHITECT
failure_signature: P2.W8.TSK_P2_W8_ARCH_001.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Freeze the canonical attestation payload definition so every later hash, signature, and replay rule resolves against one byte-level contract.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `canonicalization contract`
- Contract authority outranks implementation authority.
- SQL is the authoritative runtime executor only where this task implements runtime behavior.
- No advisory fallback is permitted for Wave 8 completion work.

## Scope Discipline

- This task is invalid if it expands into more than one primary enforcement domain.
- If implementation reveals a second enforcement domain, stop and create a follow-on pack.
- No completion credit is permitted unless the artifacts or behavior declared here are fully delivered.

## Intent

Wave 8 cannot tolerate implementation-defined canonicalization. This task freezes the field set, normalization, and byte vectors before any DB or crypto work claims progress.

## Dependencies

TSK-P2-W8-GOV-001

## Deliverables

| File | Action | Reason |
|------|--------|--------|
| `docs/contracts/CANONICAL_ATTESTATION_PAYLOAD_v1.md` | CREATE | Deliver or update the task-controlled artifact |
| `scripts/agent/verify_tsk_p2_w8_arch_001.py` | CREATE | Deliver or update the task-controlled artifact |
| `evidence/phase2/tsk_p2_w8_arch_001.json` | CREATE | Deliver or update the task-controlled artifact |

## Stop Conditions

- Stop if the work expands beyond `canonicalization contract`.
- Stop if approval metadata is missing for a regulated-surface edit.
- Stop if the verifier path cannot be tied directly to the work-item IDs below.
- Stop if evidence cannot satisfy `TSK-P1-240` proof-carrying fields.

## Work Items

### Step 1
**What:** [ID w8_arch_001_work_01] Define the exact canonical attestation payload field set, canonical field names, and source ordering for version 1.
**Done when:** [ID w8_arch_001_work_01] `CANONICAL_ATTESTATION_PAYLOAD_v1.md` explicitly defines the exact version 1 field set and source ordering.

### Step 2
**What:** [ID w8_arch_001_work_02] Define exact null, UUID, timestamp, UTF-8, and canonicalization algorithm/version rules for version 1 payload construction.
**Done when:** [ID w8_arch_001_work_02] The contract explicitly defines null, UUID, timestamp, UTF-8, and canonicalization rules rather than leaving them implementation-defined.

### Step 3
**What:** [ID w8_arch_001_work_03] Add frozen byte-level test vectors that show the canonical payload bytes for at least one valid attestation example.
**Done when:** [ID w8_arch_001_work_03] The contract contains frozen byte-level vectors that can be compared directly by SQL and application runtimes.

### Step 4
**What:** [ID w8_arch_001_work_04] Link the contract to the Wave 8 closure rubric so every downstream task references this document as the payload source of truth.
**Done when:** [ID w8_arch_001_work_04] Downstream contract references point back to this payload contract as the canonical definition source.

## Verification

```bash
python3 scripts/agent/verify_tsk_p2_w8_arch_001.py > evidence/phase2/tsk_p2_w8_arch_001.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-ARCH-001/PLAN.md --meta tasks/TSK-P2-W8-ARCH-001/meta.yml
```

## Evidence Contract

Evidence file: `evidence/phase2/tsk_p2_w8_arch_001.json`

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
