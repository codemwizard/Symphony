# TSK-P2-W8-ARCH-006 PLAN - SQLSTATE registration

Task: TSK-P2-W8-ARCH-006
Owner: ARCHITECT
failure_signature: P2.W8.TSK_P2_W8_ARCH_006.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Register the concrete Wave 8 SQLSTATE failure classes so contracts, verifiers,
and runtime implementations share one explicit failure-domain map.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `SQLSTATE registry`
- Contracts define failure classes and the registry assigns codes.
- Provenance mismatches and provider-path failures must be explicit registry entries.

## Work Items

### Step 1
**What:** [ID w8_arch_006_work_01] Add the Wave 8 failure-class range and concrete code registrations to `docs/contracts/sqlstate_map.yml` as a merge update rather than a whole-file replacement.
**Done when:** [ID w8_arch_006_work_01] `sqlstate_map.yml` contains a Wave 8 merge update rather than a destructive registry replacement.

### Step 2
**What:** [ID w8_arch_006_work_02] Register transition-hash, signature, key-scope, timestamp, replay, signer-precedence, unavailable-crypto, provider-path-unavailable, SQLSTATE-provenance-mismatch, branch-provenance-mismatch, data-authority, and authority-mismatch failures.
**Done when:** [ID w8_arch_006_work_02] Concrete codes exist for the approved Wave 8 failure classes, including provider-path and provenance mismatch failures.

### Step 3
**What:** [ID w8_arch_006_work_03] Cross-reference the SQLSTATE registrations from the Wave 8 contracts so implementations inherit one failure-class mapping chain.
**Done when:** [ID w8_arch_006_work_03] The Wave 8 contracts reference the registry entries consistently.

## Verification

```bash
python3 scripts/agent/verify_tsk_p2_w8_arch_006.py > evidence/phase2/tsk_p2_w8_arch_006.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-ARCH-006/PLAN.md --meta tasks/TSK-P2-W8-ARCH-006/meta.yml
```
