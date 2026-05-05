# Wave 8 Architecture Overview

## Executive Summary

Wave 8 implements the authoritative signed-write boundary for Symphony's Phase 2A cryptographic enforcement. This architecture establishes a comprehensive cryptographic envelope that ensures all policy-relevant writes at the `asset_batches` boundary are cryptographically valid, replay-safe, and enforced via Ed25519 runtime parity with deterministic hashes.

## Core Architectural Components

### 1. Authoritative Boundary Enforcement

**Primary Enforcement Domain**: `asset_batches` table boundary
**Cryptographic Primitive**: Ed25519 signature verification via libsodium C-extension
**Enforcement Mechanism**: PostgreSQL BEFORE INSERT trigger with fail-closed rejection
**Runtime Path**: Direct database-level cryptographic validation

### 2. Cryptographic Surface Integration

**Database Layer**:
- `verify_ed25519_contract_bytes()` C-extension function (SEC-001)
- `wave8_cryptographic_enforcement()` PostgreSQL trigger function
- Signature format validation (128 hex characters for 64-byte Ed25519 signatures)
- Public key format validation (32 bytes for Ed25519)

**Application Layer**:
- .NET 10 runtime environment fidelity probes
- NSec.Cryptography libsodium binding for Ed25519 operations
- Canonical payload construction and hash generation

### 3. Contract Canonicalization

**Payload Contract**: `CANONICAL_ATTESTATION_PAYLOAD_v1.md`
- Field set: asset_id, project_id, occurred_at, scope, payload_hash
- Canonicalization rules: UTF-8 encoding, UUID handling, timestamp formatting
- Byte-level test vectors for reference implementation

### 4. Evidence and Verification Framework

**Evidence Generation**:
- Structured JSON evidence with git_sha, timestamps, execution traces
- Baseline drift verification for schema integrity
- Cross-referenced documentation artifacts

**Verification Strategy**:
- Negative test cases for malformed signatures
- Runtime environment fidelity validation
- Semantic fidelity testing on Wave 8 contract bytes

## Security Architecture

### 1. Fail-Closed Enforcement

**Principle**: Reject invalid cryptographic states rather than accepting with warnings
**Implementation**: 
- Cryptographic provider unavailability → P7813 error
- Invalid signatures → P7814 error
- Malformed data → P7808 error

### 2. Runtime Fidelity

**Environment Validation**:
- .NET 10 runtime family verification
- OpenSSL path validation on Linux systems
- Container image digest verification
- SDK version alignment checks

### 3. Cryptographic Integrity

**Signature Verification**:
- Ed25519 algorithm specification compliance
- libsodium C-extension integration
- Key format and length validation
- Deterministic hash construction

## Data Flow Architecture

```
Application Layer
       ↓
Canonical Payload Construction
       ↓
Ed25519 Signing (NSec.Cryptography)
       ↓
asset_batches INSERT Attempt
       ↓
PostgreSQL Trigger (wave8_cryptographic_enforcement)
       ↓
Signature Format Validation
       ↓
C-Extension Verification (verify_ed25519_contract_bytes)
       ↓
Accept/Reject Decision
```

## Integration Points

### 1. Database Schema Integration

**Migration Chain**:
- 0168: Attestation seam schema baseline
- 0171: Attestation kill-switch gate baseline  
- 0172: Asset batches dispatcher
- 0175: Transition hash match
- 0177: Wave 8 cryptographic boundary enforcement

**Trigger Ordering**:
1. `trg_wave8_reject_placeholders` - Reject placeholder values
2. `trg_wave8_asset_batches_dispatcher` - Canonical payload construction
3. `trg_enforce_transition_hash_match` - Hash recomputation
4. `trg_wave8_cryptographic_enforcement` - Signature verification

### 2. Application Runtime Integration

**.NET 10 Integration**:
- NSec.Cryptography libsodium binding
- Runtime environment fidelity probes
- Container image digest verification
- Production-parity execution paths

**Cross-References**:
- `CANONICAL_ATTESTATION_PAYLOAD_v1.md` - Payload contract definition
- `ED25519_SIGNING_CONTRACT.md` - Cryptographic specification
- `SEC-001` implementation evidence - C-extension verification
- `SEC-000` implementation evidence - Runtime fidelity proof

## Compliance and Governance

### 1. Phase 2A Boundary Requirements

**Authoritative Signed-Write**: ✅ Enforced at database level
**Cryptographic Validity**: ✅ Ed25519 signature verification
**Replay Safety**: ✅ Timestamp and scope validation
**Deterministic Hashes**: ✅ Canonical payload construction

### 2. Evidence-Driven Closure

**Task Completion Criteria**:
- Verifiable evidence of execution
- Structural tests with negative cases
- Cross-referenced documentation
- Baseline integrity verification

**Governance Trace**:
- All changes reference this architecture overview
- Downstream tasks link back to canonical contracts
- Evidence artifacts maintain provenance

## Implementation Status

### Completed Components
- ✅ Database cryptographic enforcement (DB-006)
- ✅ Runtime environment fidelity (SEC-000)
- ✅ Canonical payload contract (ARCH-001)
- ✅ Evidence framework integration

### Remaining Work
- 🔄 16 unimplemented Wave 8 tasks
- 🔄 Remaining ARCH task verification scripts
- 🔄 Complete integration testing

## Architectural Principles

1. **Cryptographic Primacy**: Database-level enforcement cannot be bypassed
2. **Fail-Closed Operation**: Invalid states cause explicit rejection, not acceptance
3. **Runtime Parity**: Production environment matches verification environment exactly
4. **Evidence Integrity**: All claims require verifiable proof with execution traces
5. **Canonical Authority**: Single source of truth for payload contracts and byte vectors

This architecture provides the foundation for Symphony's Phase 2A authoritative signed-write boundary, ensuring cryptographic integrity while maintaining system performance and operational reliability.
