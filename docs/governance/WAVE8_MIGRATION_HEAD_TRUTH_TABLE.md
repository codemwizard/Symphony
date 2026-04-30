# Wave 8 Migration Head Truth Table

**Status:** Authoritative
**Date:** 2026-04-29
**Related Tasks:** TSK-P2-W8-GOV-001

## Purpose

This truth table establishes the authoritative migration head for Wave 8 implementation and binds future task creation to the approved DoD control surface.

## Authoritative Wave 8 Boundary

**Table:** `asset_batches`

The `asset_batches` table is the sole authoritative Wave 8 boundary. All Wave 8 cryptographic enforcement, signature verification, hash recomputation, and replay legality checks must execute at this boundary.

## Migration Head Baseline

**Current Migration Head:** 0171 (Attestation kill-switch gate baseline present)

Wave 8 implementation will add migrations 0172 through 0180 to establish the authoritative enforcement topology.

## Planned Wave 8 Migrations

| Migration Number | Purpose | Domain | Authoritative Boundary |
|------------------|---------|--------|------------------------|
| 0172 | Wave 8 dispatcher topology | dispatcher topology | asset_batches |
| 0173 | Wave 8 placeholder cleanup | placeholder cleanup | asset_batches |
| 0174 | Wave 8 canonical payload | SQL canonicalization | asset_batches |
| 0175 | Wave 8 attestation hash enforcement | hash recomputation | asset_batches |
| 0176 | Wave 8 signer resolution surface | signer resolution | asset_batches |
| 0177 | Wave 8 crypto boundary enforcement | cryptographic enforcement wiring | asset_batches |
| 0178 | Wave 8 scope and timestamp enforcement | scope authorization, timestamp integrity, replay prevention | asset_batches |
| 0179 | Wave 8 key lifecycle enforcement | key lifecycle enforcement | asset_batches |
| 0180 | Wave 8 context binding enforcement | context binding | asset_batches |

## Migration Dependency Rules

1. **Forward-Only**: All Wave 8 migrations are forward-only. No rollback migrations will be provided.
2. **Sequential**: Migrations must be applied in numerical order (0172 → 0180).
3. **Boundary Binding**: Each migration must reference the `asset_batches` table as the authoritative boundary.
4. **Contract Conformance**: Each migration must conform to the Wave 8 contract documents (CANONICAL_ATTESTATION_PAYLOAD_v1.md, TRANSITION_HASH_CONTRACT.md, ED25519_SIGNING_CONTRACT.md).

## Migration Head Validation

Before any Wave 8 task implementation:

1. Verify that migration 0171 is applied and verified.
2. Verify that the `asset_batches` table exists.
3. Verify that the `schema_migrations` table tracks migration state.
4. Verify that no migrations beyond 0171 are applied (clean baseline).

## Task Creation Binding

All future Wave 8 task creation must:

1. Reference this truth table as the migration baseline.
2. Specify the exact migration numbers it will add.
3. Explicitly state how the migration enforces behavior at the `asset_batches` boundary.
4. Include a verifier that proves the migration executes at the authoritative boundary.

## Migration Head Update Procedure

When the migration head advances:

1. Update this table with the new migration number.
2. Record the purpose, domain, and boundary binding.
3. Update the MIGRATION_HEAD file in schema/migrations/.
4. Re-run migration head validation for all dependent tasks.

## References

- WAVE8_GOVERNANCE_REMEDIATION_ADR.md
- WAVE8_CLOSURE_RUBRIC.md
- schema/migrations/MIGRATION_HEAD
