# Symphony Hardening: Implementation Plan and Final Tasks List

## Source of truth
This plan is derived from the canonical wave ordering in `docs/programs/symphony-hardening/WAVE_PLAN.md`
and invariant mappings in `docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md`.

## Mandatory design corrections (must be implemented)
1. Effect sealing: compute `effect_seal_hash = canon_hash(effect_payload, canon_version)` at quorum/approval completion.
   `effect_payload` must include:
   - `parent_instruction_id`
   - `adjustment_id`
   - `adjustment_type`
   - `delta_amount` and `currency`
   - `recipient_ref_hash` (inherited)
   - `policy_id` and `policy_version`
   - `cooling_required` and `cooling_until` (if derived)
   - `reference_strategy_name/version` (or stable strategy class)
   - `execution_mode`
   Execution insert/update must provide `outbound_effect_hash` and it must match `effect_seal_hash`.
2. Explicit terminal immutability (`P7101`): no vague metadata backdoor. Prefer append-only annotations table over terminal row updates.
3. Concurrency hardening: `SELECT ... FOR UPDATE` on approval/execute mutation paths, idempotency keys, duplicate prevention constraints.
4. Offline Safe Mode (`TSK-HARD-094`): execution fail-closed when offline mode is active; evidence records offline period and queued actions.
   Evidence events must still emit to local append-only storage while offline.
   Externally required signed artifacts must be flagged `UNSIGNED_DUE_TO_OFFLINE_DEPENDENCY`
   and re-signed on recovery with linkage to the unsigned event chain.
5. Decision-event evidence model: emit evidence at decision points (quorum, maker-checker pass/fail, cooling derivation, legal-hold pass/block, seal generation, execution attempt creation) not only terminal outcomes.
6. Re-entry reference integration: execution attempt must allocate and persist dispatch reference strategy + registry linkage; include alias collision and duplicate response classification.

## Execution method
1. Implement wave by wave in the canonical order below.
2. For each task, enforce DB-first controls and add verifier coverage before marking complete.
3. Never mark complete unless required files changed, verifier(s) pass, and evidence artifacts validate.
4. Run `scripts/dev/pre_ci.sh` at each task closeout.
5. Keep traceability current in `docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md`.
6. Definition of Done: task is done only if (a) verifier passes, (b) evidence artifact(s) are schema-valid, (c) traceability matrix row is updated, and (d) a negative-path test exists for the exploit the task closes.

## Wave implementation plan

### Wave 1: Zambia survivability and core containment foundation
Tasks:
- `TSK-HARD-000, 001, 002, 010, 011A, 012, 015, 016, 094, 101, 014, 013`

Implementation focus:
1. Program charter, contracts, schema/evidence harness, and baseline containment controls.
2. Inquiry and containment behavior with policy-driven resolution.
3. Malformed-response quarantine and drift-triggered fail-closed behavior.
4. Offline Safe Mode + mobile-money Zambia constraints.
5. Late callback/orphan handling and contradictory truth conflict handling.

Exit gate:
- Deterministic containment proven under silent rail, conflicting rail truth, malformed response, and offline periods.

### Wave 2: Adjustment governance core
Tasks:
- `TSK-HARD-020, 021, 022, 023, 025, 026, 024`

Implementation focus:
1. `adjustment_instruction`, `adjustment_approval`, `adjustment_execution` state model.
2. Recipient inheritance and bounded adjustment semantics.
3. Quorum and role heterogeneity enforcement.
4. Cooling-off + legal-hold gate semantics.
5. Approval attribution with role attestation.
6. Terminal immutability enforcement (`P7101`) at DB layer.

Exit gate:
- Human-in-the-loop layer is additive, immutable, maker-checker safe, and policy-snapshot driven.

### Wave 3: Rail re-entry and reference integrity
Tasks:
- `TSK-HARD-030, 031, 032, 033`

Implementation focus:
1. Two-layer reference strategy (lineage + dispatch reference).
2. Length-aware reference safety and outbound validation.
3. Alias collision handling and deterministic duplicate compatibility.
4. Registry linkage for every execution attempt.

Exit gate:
- Re-entry dispatch survives partner constraints and collisions without identity ambiguity.

### Wave 4: Cryptographic control-plane hardening
Tasks:
- `TSK-HARD-050, 051, 052, 053, 054, 011B, 096`

Implementation focus:
1. Key class separation and HSM/KMS-backed signing paths.
2. Signature metadata completeness and verifier strictness.
3. Rotation drills with historical verifiability.
4. Signed policy bundles (`011B`) and activation verification.
5. Assurance tier disclosure in evidence.

Exit gate:
- Signing and policy control plane is tamper-resistant and auditable end-to-end.

### Wave 5: Canonicalization continuity + DR and regulator continuity
Tasks:
- `TSK-HARD-060, 061, 062, 070, 071, 072, 073, 074, 097, 099, 102`

Implementation focus:
1. Canonicalization versioning and historical verifier loader.
2. Archive integrity and restoration continuity.
3. Public key archive and trust anchor archival.
4. Recovery ceremony controls and offline verification package.
5. Long-term retention verification.
6. Scoped regulator access with immutable audit evidence.

Exit gate:
- Verification continuity remains operational across recovery, rotation, and long retention windows.

### Wave 6: Productization, operations UX, reporting, privacy continuity
Tasks:
- `TSK-HARD-080, 081, 082, 090, 091, 092, 093, 095, 098, 040, 041, 042, 100`

Implementation focus:
1. High-volume signing scale path (Merkle/batch proofs).
2. Operations command center and BoZ demo reproducibility.
3. QA matrix completeness and feature-flag rollout evidence.
4. BoZ reporting outputs and penalty-defense pack generation.
5. Privacy-preserving audit semantics after erasure.
6. Approval retraction safety controls and anti-abuse evidence.

Exit gate:
- System is regulator-legible, operator-usable, privacy-safe, and production-scalable.

Dependency note:
- `TSK-HARD-098` depends on `TSK-HARD-095` submission audit trail primitives.
  `TSK-HARD-098` cannot be completed until `TSK-HARD-095` emits immutable submission attempt events.

## Final canonical tasks list (exact wave ordering)

### Wave 1
`TSK-HARD-000, 001, 002, 010, 011A, 012, 015, 016, 094, 101, 014, 013`

### Wave 2
`TSK-HARD-020, 021, 022, 023, 025, 026, 024`

### Wave 3
`TSK-HARD-030, 031, 032, 033`

### Wave 4
`TSK-HARD-050, 051, 052, 053, 054, 011B, 096`

### Wave 5
`TSK-HARD-060, 061, 062, 070, 071, 072, 073, 074, 097, 099, 102`

### Wave 6
`TSK-HARD-080, 081, 082, 090, 091, 092, 093, 095, 098, 040, 041, 042, 100`

## Notes
1. `011` is split: `011A` (Wave 1 unblocker) and `011B` (Wave 4 signed policy enforcement).
2. `103` is merged into `093` in the final ordering.
