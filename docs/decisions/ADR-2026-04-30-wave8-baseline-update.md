# ADR-2026-04-30: Wave 8 Baseline Schema Update

## Status
Accepted

## Context
Wave 8 boundary enforcement task (REM-2026-04-29_wave8_boundary_enforcement) added 16 new migrations (0172-0187) to the schema. These migrations implement:
- Wave 8 dispatcher topology
- Canonical payload construction
- Attestation hash enforcement
- Signer resolution surface
- Cryptographic enforcement wiring
- Scope and timestamp enforcement
- Key lifecycle enforcement
- Context binding enforcement
- Non-cryptographic boundary enforcement
- Crypto hardfail restoration
- Replay nonce registry
- Timestamp branch enforcement
- Replay branch enforcement
- Context binding non-signer enforcement
- Ed25519 verification integration

## Decision
Regenerate the baseline snapshot to reflect the new schema state after applying all 16 Wave 8 migrations.

## Rationale
The baseline snapshot (`schema/baseline.sql`) must reflect the current schema state after all migrations are applied. Since Wave 8 migrations add new tables, functions, triggers, and constraints to the schema, the baseline must be updated to:
1. Include new Wave 8 tables (wave8_signer_resolution, wave8_attestation_nonces)
2. Include new Wave 8 functions (construct_canonical_attestation_payload, recompute_transition_hash, wave8_cryptographic_enforcement, etc.)
3. Include new Wave 8 triggers (wave8_asset_batches_dispatcher, trg_wave8_cryptographic_enforcement, etc.)
4. Include new columns on existing tables (canonical_payload_bytes on asset_batches, superseded_by/superseded_at on wave8_signer_resolution)

## Consequences
- Positive: Baseline now accurately reflects the schema state with Wave 8 enforcement
- Positive: Baseline drift check will pass after this update
- Positive: Canonical hash provides deterministic fingerprint for future drift detection
- Neutral: Baseline cutoff is now 0187_wave8_integrate_ed25519_verification.sql (latest migration)

## Migration Changes
The following migrations were added in this PR:
- 0172_wave8_dispatcher_topology.sql
- 0173_wave8_placeholder_cleanup.sql
- 0174_wave8_canonical_payload.sql
- 0175_wave8_attestation_hash_enforcement.sql
- 0176_wave8_signer_resolution_surface.sql
- 0177_wave8_cryptographic_enforcement_wiring.sql
- 0178_wave8_scope_and_timestamp_enforcement.sql
- 0179_wave8_key_lifecycle_enforcement.sql
- 0180_wave8_context_binding_enforcement.sql
- 0181_wave8_non_crypto_boundary_enforcement.sql
- 0182_wave8_restore_crypto_hardfail.sql
- 0183_wave8_replay_nonce_registry.sql
- 0184_wave8_timestamp_branch_enforcement.sql
- 0185_wave8_replay_branch_enforcement.sql
- 0186_wave8_context_binding_non_signer_enforcement.sql
- 0187_wave8_integrate_ed25519_verification.sql

## Baseline Metadata
- Baseline date: 2026-04-30
- Baseline cutoff: 0187_wave8_integrate_ed25519_verification.sql
- Normalized schema SHA256: e57fa8a5c7f424f5998c9a551fdb0683e7267c2ece47807ea40763a1190b16c7
- Dump source: container:symphony-postgres
