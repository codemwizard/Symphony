# TSK-P2-W8-QA-001 PLAN - Three-surface determinism vectors

Task: TSK-P2-W8-QA-001
Owner: QA_VERIFIER
failure_signature: P2.W8.TSK_P2_W8_QA_001.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Prove determinism across the contract source, the frozen `LedgerApi` runtime,
and the SQL runtime for the same Wave 8 inputs.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `determinism evidence`
- Contract vectors are frozen independently.
- The `.NET` runtime surface for this task is the frozen `LedgerApi` path.
- SQL and `.NET` consume the same vectors; they do not generate them.

## Work Items

### Step 1
**What:** [ID w8_qa_001_work_01] Create or update attestation test vectors that contain contract-source canonical bytes, expected hash, and signature-verification expectations, and freeze them independently of runtime implementation logic.
**Done when:** [ID w8_qa_001_work_01] Attestation test vectors exist, define canonical bytes, expected hash, and expected verification outcomes, and are not implementation-generated.

### Step 2
**What:** [ID w8_qa_001_work_02] Build a verifier that compares contract vector bytes, frozen `LedgerApi` runtime bytes, and SQL authoritative runtime bytes for the same logical inputs.
**Done when:** [ID w8_qa_001_work_02] The verifier compares contract, frozen `LedgerApi` runtime, and SQL runtime outputs directly.

### Step 3
**What:** [ID w8_qa_001_work_03] Emit evidence showing three-surface equality for bytes, hash, and verification outcome and fail if runtime vectors are regenerated from implementation logic.
**Done when:** [ID w8_qa_001_work_03] Evidence proves three-surface equality for bytes, hash, and verification result and fails if runtime vectors are regenerated from implementation logic.

## Verification

```bash
bash scripts/audit/verify_tsk_p2_w8_qa_001.sh > evidence/phase2/tsk_p2_w8_qa_001.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-QA-001/PLAN.md --meta tasks/TSK-P2-W8-QA-001/meta.yml
```
