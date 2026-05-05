# Wave 8 Dispatcher Topology

## Executive Summary

Wave 8 establishes a single authoritative dispatcher trigger topology for cryptographic boundary enforcement. This document removes multi-trigger ambiguity and defines the explicit execution sequence that all downstream tasks must reference.

## Trigger Sequence

### 1. Placeholder Rejection Trigger
**Trigger**: `trg_wave8_reject_placeholders`
**Execution Order**: 1 (First)
**Purpose**: Reject placeholder values and malformed data before any processing
**SQLSTATE**: P7801 (Wave 8: placeholder or malformed data)

### 2. Canonical Payload Construction Trigger
**Trigger**: `trg_wave8_asset_batches_dispatcher`
**Execution Order**: 2
**Purpose**: Construct canonical payload bytes from input data
**Dependencies**: `CANONICAL_ATTESTATION_PAYLOAD_v1.md`

### 3. Transition Hash Computation Trigger
**Trigger**: `trg_enforce_transition_hash_match`
**Execution Order**: 3
**Purpose**: Recompute and verify transition hash matches payload
**Dependencies**: `TRANSITION_HASH_CONTRACT_v1.md`

### 4. Cryptographic Enforcement Trigger
**Trigger**: `trg_wave8_cryptographic_enforcement`
**Execution Order**: 4 (Final)
**Purpose**: Authoritative Ed25519 signature verification
**Dependencies**: `ED25519_SIGNING_CONTRACT_v1.md`
**SQLSTATE**: P7814 (Wave 8: signature verification failed)

## Execution Topology

```
INSERT INTO asset_batches
    ↓
trg_wave8_reject_placeholders (1)
    ↓
trg_wave8_asset_batches_dispatcher (2)
    ↓
trg_enforce_transition_hash_match (3)
    ↓
trg_wave8_cryptographic_enforcement (4)
```

## Key Architectural Rules

### Single Dispatcher Rule
- **One Path**: Only `trg_wave8_asset_batches_dispatcher` may construct canonical payloads
- **No Bypass**: All cryptographic validation must pass through trigger sequence
- **Authoritative Boundary**: Final trigger (`trg_wave8_cryptographic_enforcement`) is the authoritative boundary

### No Credit/No Fallback Rule
- **No Advisory**: Invalid cryptographic states must cause hard rejection, not advisory warnings
- **No Fallback**: Unavailable cryptographic providers must cause failure, not fallback behavior
- **Fail-Closed**: System must default to rejection rather than acceptance

### Deterministic Execution Rule
- **Fixed Order**: Triggers must execute in the exact sequence defined above
- **No Race Conditions**: Trigger order must prevent race conditions in validation
- **Atomic Operations**: Each trigger must complete atomically or rollback entirely

## Implementation Requirements

### Trigger Dependencies
- All triggers must reference their dependent contracts explicitly
- No trigger may skip validation steps in the sequence
- Each trigger must handle its specific failure modes

### SQLSTATE Registration
- All Wave 8 SQLSTATE codes must be registered in the SQLSTATE registry
- Failure codes must follow Wave 8 naming convention (P78xx range)
- Error messages must provide actionable diagnostic information

### Cross-Reference Requirements
- All implementation tasks must reference this topology document
- Contract documents must reference specific trigger responsibilities
- Verification scripts must validate trigger execution order

## Enforcement Boundaries

### Authoritative Boundary
- `asset_batches` table is the single authoritative Wave 8 boundary
- No application-layer validation may bypass database-level enforcement
- All writes must pass through the complete trigger sequence

### Contract Authority
- `CANONICAL_ATTESTATION_PAYLOAD_v1.md` defines payload structure
- `TRANSITION_HASH_CONTRACT_v1.md` defines hash computation rules
- `ED25519_SIGNING_CONTRACT_v1.md` defines cryptographic requirements

This topology establishes the foundation for Wave 8's authoritative signed-write boundary enforcement.
