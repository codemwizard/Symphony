# Placeholder and Legacy Posture Inventory

**Task:** TSK-P2-W8-DB-002
**Date:** 2026-04-29
**Purpose:** Inventory of placeholder formats, legacy prefixes, and compatibility postures that would contaminate canonicalization or signature semantics

## Identified Placeholder Postures

### 1. Signature Placeholder Prefix
- **Migration:** 0153_set_signature_placeholder_posture.sql
- **Table:** state_transitions
- **Field:** transition_hash
- **Placeholder Pattern:** `PLACEHOLDER_PENDING_SIGNING_CONTRACT:`
- **Function:** add_signature_placeholder_posture()
- **Trigger:** tr_add_signature_placeholder
- **Purpose:** Adds placeholder prefix to transition_hash when signature contract is not yet implemented
- **Impact on Wave 8:** Contaminates canonicalization - cannot sign or verify with placeholder prefix

### 2. Data Authority Placeholder
- **Contract Reference:** DATA_AUTHORITY_DERIVATION_SPEC.md
- **Prohibited Value:** `non_reproducible`
- **Context:** Used as placeholder when data authority derivation is not implemented
- **Impact on Wave 8:** Violates determinism requirement - data authority must be reproducible

## Wave 8 Required Cleanup

Wave 8 cannot canonicalize placeholder values or compatibility prefixes and still claim cryptographic determinism. The following must be removed or rejected:

1. **Remove signature placeholder trigger** - The tr_add_signature_placeholder trigger on state_transitions must be removed
2. **Reject placeholder transition_hash values** - Any transition_hash starting with "PLACEHOLDER_" must be rejected at the authoritative boundary
3. **Reject non_reproducible data_authority** - The value "non_reproducible" must be rejected in data_authority fields

## Migration Strategy

The forward-only migration will:
1. Drop the signature placeholder trigger on state_transitions
2. Add CHECK constraints to reject placeholder values
3. Update the Wave 8 dispatcher to reject placeholder-style writes
