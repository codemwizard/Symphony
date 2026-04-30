# ADR: Wave 8 Governance Truth Remediation

**Status:** Accepted
**Date:** 2026-04-29
**Context:** Wave 8 Implementation
**Related Tasks:** TSK-P2-W8-GOV-001

## Context

Wave 8 requires an authoritative governance truth anchor to ensure that all subsequent task packs inherit one consistent closure rubric, one admissibility policy, and one explicit list of inadmissible proof patterns. Previous waves suffered from ambiguous completion criteria and inconsistent enforcement boundaries.

## Decision

Wave 8 completion is measured **only** at the authoritative `asset_batches` boundary. Contract documents define Wave 8 semantics while SQL executes them at the `asset_batches` boundary. Contract authority outranks implementation authority.

### Key Principles

1. **Authoritative Boundary**: The `asset_batches` table is the sole authoritative Wave 8 boundary. No other table or surface may claim Wave 8 completion authority.

2. **Contract Authority**: Contract documents (CANONICAL_ATTESTATION_PAYLOAD_v1.md, TRANSITION_HASH_CONTRACT.md, ED25519_SIGNING_CONTRACT.md, etc.) define the semantic requirements. SQL runtime behavior must conform to these contracts, not the reverse.

3. **No Advisory Fallback**: Wave 8 completion work does not permit advisory fallback behavior. All enforcement must be fail-closed at the authoritative boundary. No advisory fallback is permitted.

4. **Evidence Admissibility**: Only proof-carrying evidence that satisfies the Wave 8 Evidence Admissibility Policy may be accepted for closure claims.

5. **Fake Completion Revocation**: Any previous Wave 8 completion claims that do not satisfy this governance truth are hereby revoked and must be re-implemented.

## Consequences

- All Wave 8 tasks must reference this ADR as the governance truth anchor.
- The Wave 8 Closure Rubric (WAVE8_CLOSURE_RUBRIC.md) defines the specific completion criteria.
- The Wave 8 Evidence Admissibility Policy (WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md) defines acceptable proof forms.
- Legacy Wave 8 artifacts (TSK-P2-REG-* and any TSK-P2-W8-CRYPTO-*) must be re-classified according to the Wave 8 Task Status Matrix.
- The unsplit TSK-P2-W8-DB-007 is superseded by TSK-P2-W8-DB-007a, TSK-P2-W8-DB-007b, and TSK-P2-W8-DB-007c and is non-executable for closure.

## References

- WAVE8_CLOSURE_RUBRIC.md
- WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md
- WAVE8_TASK_STATUS_MATRIX.md
- WAVE8_FALSE_COMPLETION_REVOCATION_LEDGER.md
