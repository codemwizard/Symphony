# TSK-P2-W8-ARCH-003 PLAN - Signing and replay contract hardening

Task: TSK-P2-W8-ARCH-003
Owner: ARCHITECT
failure_signature: P2.W8.TSK_P2_W8_ARCH_003.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Freeze signature semantics, replay law, and failure classes so the Wave 8
signing contract becomes the sole semantic authority without turning framework
availability into a fake open question.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `signature semantics`
- Contract authority outranks implementation authority.
- Runtime/provider-path proof belongs to `TSK-P2-W8-SEC-000`.
- No advisory fallback is permitted for Wave 8 completion work.

## Intent

Wave 8 must not leave signing semantics distributed across code comments,
timestamp folklore, verifier conventions, or provider drift. This contract
hardens the signature boundary into a single replay authority while treating
runtime/provider fidelity as a prerequisite gate proven by `SEC-000`.

## Dependencies

TSK-P2-W8-ARCH-001, TSK-P2-W8-ARCH-002

## Work Items

### Step 1
**What:** [ID w8_arch_003_work_01] Define the exact signature input bytes, including whether Ed25519 signs canonical payload bytes directly, hash bytes, or a domain-separated envelope and how raw-byte versus encoded-byte semantics are interpreted.
**Done when:** [ID w8_arch_003_work_01] The signing contract explicitly defines the exact bytes Ed25519 signs and rejects non-canonical byte interpretations.

### Step 2
**What:** [ID w8_arch_003_work_02] Add persisted-before-signing timestamp rules, project and entity scope authorization rules, and signer-precedence law that hard-fails on overlapping active matches.
**Done when:** [ID w8_arch_003_work_02] The signing contract explicitly defines scope authorization and precedence rules that hard-fail when multiple active keys match the same resolution query.

### Step 3
**What:** [ID w8_arch_003_work_03] Centralize replay law, including duplicate decision semantics, nonce semantics, same-signature cross-context semantics, and same-canonical-bytes different-`occurred_at` semantics.
**Done when:** [ID w8_arch_003_work_03] Replay semantics are centralized in the signing contract rather than inferred across separate documents.

### Step 4
**What:** [ID w8_arch_003_work_04] State that Wave 8 requires the first-party `.NET 10` Ed25519 surface, forbids third-party providers or fallbacks, and defers concrete runtime/provider-path proof to `TSK-P2-W8-SEC-000`.
**Done when:** [ID w8_arch_003_work_04] The signing contract requires the first-party `.NET 10` Ed25519 surface, forbids third-party providers or fallbacks, and states that no downstream task may assume a callable surface before `SEC-000` proves runtime fidelity.

### Step 5
**What:** [ID w8_arch_003_work_05] Define fail-closed unavailable-crypto semantics for verifier unavailability, key lookup unavailability, signer-surface unavailability, unresolved functions/extensions, and dependency load failure.
**Done when:** [ID w8_arch_003_work_05] The signing contract explicitly states that unavailable crypto is itself a hard verification failure.

### Step 6
**What:** [ID w8_arch_003_work_06] Register named failure classes for key scope, timestamp invalidity, replay invalidity, precedence conflict, and unavailable-crypto failure.
**Done when:** [ID w8_arch_003_work_06] Named failure classes cover scope, timestamp, replay, precedence, and unavailable-crypto failures.

## Verification

```bash
python3 scripts/agent/verify_tsk_p2_w8_arch_003.py > evidence/phase2/tsk_p2_w8_arch_003.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-ARCH-003/PLAN.md --meta tasks/TSK-P2-W8-ARCH-003/meta.yml
```
