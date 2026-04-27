# TSK-P2-W8-QA-002 PLAN - Behavioral evidence pack

Task: TSK-P2-W8-QA-002
Owner: QA_VERIFIER
failure_signature: P2.W8.TSK_P2_W8_QA_002.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Produce the final behavioral proof pack for Wave 8 so closure is based on
PostgreSQL acceptance/rejection behavior rather than structural theater.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `behavioral evidence`
- Reflection-only proof is inadmissible.
- Toy-crypto proof is inadmissible.
- Branch provenance must come from the production path, not wrapper-only markers.

## Work Items

### Step 1
**What:** [ID w8_qa_002_work_01] Build a verifier that executes the full Wave 8 rejection matrix at the authoritative `asset_batches` boundary, including malformed signature, wrong signer, wrong scope, revoked key, expired key, altered payload, altered registry snapshot, altered entity binding, canonicalization mismatch, and unavailable-crypto cases.
**Done when:** [ID w8_qa_002_work_01] The verifier executes the full rejection matrix at the authoritative `asset_batches` boundary.

### Step 2
**What:** [ID w8_qa_002_work_02] Add a valid-signature acceptance case that proves the boundary accepts correctly canonicalized, correctly hashed, correctly signed writes under an active authorized key.
**Done when:** [ID w8_qa_002_work_02] The verifier includes a valid-signature acceptance case at the authoritative boundary.

### Step 3
**What:** [ID w8_qa_002_work_03] Emit proof-carrying evidence with `observed_paths`, `observed_hashes`, `command_outputs`, and `execution_trace` for every behavioral case.
**Done when:** [ID w8_qa_002_work_03] Evidence includes proof-carrying fields for every behavioral case.

### Step 4
**What:** [ID w8_qa_002_work_04] Refuse completion if any verifier path does not physically cause PostgreSQL to accept or reject a write at `asset_batches`.
**Done when:** [ID w8_qa_002_work_04] Completion is blocked if any verifier path does not physically cause PostgreSQL to accept or reject a write at `asset_batches`.

### Step 5
**What:** [ID w8_qa_002_work_05] Reject reflection-only proof, toy-crypto proof, and wrapper-only branch markers as inadmissible evidence for behavioral closure.
**Done when:** [ID w8_qa_002_work_05] Reflection-only proof, toy-crypto proof, and wrapper-only branch markers are inadmissible and cannot satisfy behavioral evidence acceptance.

## Verification

```bash
bash scripts/audit/verify_tsk_p2_w8_qa_002.sh > evidence/phase2/tsk_p2_w8_qa_002.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-QA-002/PLAN.md --meta tasks/TSK-P2-W8-QA-002/meta.yml
```
