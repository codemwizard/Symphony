# TSK-P2-W8-SEC-001 PLAN - Ed25519 verification primitive

Task: TSK-P2-W8-SEC-001
Owner: SECURITY_GUARDIAN
failure_signature: P2.W8.TSK_P2_W8_SEC_001.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Implement the Ed25519 verification primitive against the contract-defined
signature input bytes inside the environment already proven honest by
`TSK-P2-W8-SEC-000`.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `cryptographic primitive`
- Contract authority outranks implementation authority.
- `SEC-000` proves the environment is honest.
- `SEC-001` proves the primitive is correct in that environment.
- No advisory fallback is permitted for Wave 8 completion work.

## Dependencies

TSK-P2-W8-ARCH-003, TSK-P2-W8-ARCH-006, TSK-P2-W8-SEC-000

## Work Items

### Step 1
**What:** [ID w8_sec_001_work_01] Consume the runtime/provider honesty proof from `TSK-P2-W8-SEC-000` and document the authoritative Ed25519 verification implementation standard for Wave 8 inside that proven environment.
**Done when:** [ID w8_sec_001_work_01] The authoritative Ed25519 verification standard is documented as consuming the environment/provider honesty proven by `SEC-000`.

### Step 2
**What:** [ID w8_sec_001_work_02] Implement a verification primitive that verifies signatures over the contract-defined input bytes and rejects non-canonical or differently canonicalized byte streams.
**Done when:** [ID w8_sec_001_work_02] The primitive verifies signatures over contract-defined bytes and rejects non-canonical byte interpretations.

### Step 3
**What:** [ID w8_sec_001_work_03] Add primitive-level tests for malformed signatures, wrong keys, valid signatures over contract-defined bytes, and fail-closed behavior inside the proven runtime environment.
**Done when:** [ID w8_sec_001_work_03] Primitive-level tests prove malformed-signature failure, wrong-key failure, valid-signature success, and fail-closed runtime behavior inside the proven environment.

## Verification

```bash
bash scripts/security/verify_tsk_p2_w8_sec_001.sh > evidence/phase2/tsk_p2_w8_sec_001.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-SEC-001/PLAN.md --meta tasks/TSK-P2-W8-SEC-001/meta.yml
```
