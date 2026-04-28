# TSK-P2-W8-ARCH-004 PLAN - Data authority derivation contract

Task: TSK-P2-W8-ARCH-004
Owner: ARCHITECT
failure_signature: P2.W8.TSK_P2_W8_ARCH_004.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Freeze deterministic data-authority derivation so replay behavior and disabled-signature semantics cannot drift across implementations.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `authority derivation contract`
- Contract authority outranks implementation authority.
- SQL is the authoritative runtime executor only where this task implements runtime behavior.
- No advisory fallback is permitted for Wave 8 completion work.

## Scope Discipline

- This task is invalid if it expands into more than one primary enforcement domain.
- If implementation reveals a second enforcement domain, stop and create a follow-on pack.
- No completion credit is permitted unless the artifacts or behavior declared here are fully delivered.

## Intent

This task turns `data_authority` into a strict contract output rather than a placeholder or implementation-specific fingerprint.

## Dependencies

TSK-P2-W8-ARCH-002, TSK-P2-W8-ARCH-003

## Deliverables

| File | Action | Reason |
|------|--------|--------|
| `docs/contracts/DATA_AUTHORITY_DERIVATION_SPEC.md` | CREATE | Deliver or update the task-controlled artifact |
| `scripts/agent/verify_tsk_p2_w8_arch_004.py` | CREATE | Deliver or update the task-controlled artifact |
| `evidence/phase2/tsk_p2_w8_arch_004.json` | CREATE | Deliver or update the task-controlled artifact |

## Stop Conditions

- Stop if the work expands beyond `authority derivation contract`.
- Stop if approval metadata is missing for a regulated-surface edit.
- Stop if the verifier path cannot be tied directly to the work-item IDs below.
- Stop if evidence cannot satisfy `TSK-P1-240` proof-carrying fields.

## Work Items

### Step 1
**What:** [ID w8_arch_004_work_01] Define the exact version 1 input tuple, canonicalization rules, digest algorithm, output encoding, and version semantics for `data_authority`.
**Done when:** [ID w8_arch_004_work_01] `DATA_AUTHORITY_DERIVATION_SPEC.md` explicitly defines the exact input tuple, canonicalization, digest, encoding, and version semantics.

### Step 2
**What:** [ID w8_arch_004_work_02] Define exact behavior when signature enforcement is disabled so all implementations derive the same authority output under that condition.
**Done when:** [ID w8_arch_004_work_02] The contract explicitly defines deterministic behavior when signature enforcement is disabled.

### Step 3
**What:** [ID w8_arch_004_work_03] Reference the replay law from `ED25519_SIGNING_CONTRACT.md` rather than redefining replay semantics independently.
**Done when:** [ID w8_arch_004_work_03] The contract references replay law from `ED25519_SIGNING_CONTRACT.md` rather than redefining it.

## Verification

```bash
python3 scripts/agent/verify_tsk_p2_w8_arch_004.py > evidence/phase2/tsk_p2_w8_arch_004.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-ARCH-004/PLAN.md --meta tasks/TSK-P2-W8-ARCH-004/meta.yml
```

## Evidence Contract

Evidence file: `evidence/phase2/tsk_p2_w8_arch_004.json`

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
