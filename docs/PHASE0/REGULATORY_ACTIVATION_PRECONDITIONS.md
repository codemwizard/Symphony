# Regulatory Activation Preconditions (Phase-0)

## Purpose
Phase-0 establishes a mechanically defensible foundation. This document defines the preconditions required to activate (promote) high-stakes roadmap invariants into mechanically enforced invariants in Phase-1/2.

This avoids:
- implicit scope creep in Phase-0,
- and ambiguity during audits ("why is this not enforced yet?").

## Roadmap Invariants Covered
- `INV-106` (alias `INV-BOZ-04`) Payment finality / instruction irrevocability
- `INV-107` (alias `INV-ZDPA-01`) PII decoupling + erasure survivability
- `INV-108` (alias `INV-IPDR-02`) Rail truth-anchor sequence continuity

## Preconditions (Common)
Before promotion, each invariant must have:
- A canonical ADR defining semantics, boundaries, and failure modes.
- Mechanical enforcement in code or DB (constraints/triggers/verifiers).
- CI and local parity wiring (pre-ci matches CI failure modes).
- Evidence artifacts emitted for verification (and uploaded in CI).

## Preconditions Per Invariant
### INV-106 (Finality)
- ISO 20022 reversal workflow modeled and implemented (camt.056 semantics).
- Rail adapter produces a durable, auditable "committed/accepted" signal.
- DB constraints/triggers block forbidden cancel/void transitions after finality.
- Tests prove fail-closed behavior and verify reversal-only pathway.

### INV-107 (ZDPA Erasure Survivability)
- PII vault/tokenization design exists (raw PII isolation).
- Ledger references identity_hash or tokens, not raw PII.
- Key/salt management procedures exist and are auditable.
- Purge/mask mechanism exists and is mechanically tested.
- Evidence verification succeeds pre- and post-purge.

### INV-108 (Rail Truth-Anchor Sequence)
- Rail profiles defined (e.g., ZM-NFS) with:
- scoping attributes (rail_participant_id, rail_id/profile),
- sequence reference columns,
- and definition of "successful dispatch".
- DB constraints/indexes enforce NOT NULL on success and uniqueness in scope.
- CI integration tests cover duplicates and missing anchors.

## Promotion Procedure (Mechanical)
1. Update `docs/invariants/INVARIANTS_MANIFEST.yml` status from `roadmap` -> `implemented`.
2. Add or wire the verifier/test into:
   - `scripts/dev/pre_ci.sh`
   - `.github/workflows/invariants.yml` (or the appropriate CI job)
3. Update invariants docs and regenerate QUICK to avoid drift:
   - `docs/invariants/INVARIANTS_IMPLEMENTED.md`
   - `docs/invariants/INVARIANTS_ROADMAP.md`
   - `docs/invariants/INVARIANTS_QUICK.md`
4. Ensure `scripts/audit/run_invariants_fast_checks.sh` is green.

