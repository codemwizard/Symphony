# Wave 8 Hash Recomputation

## Executive Summary

Wave 8 establishes deterministic hash recomputation to prevent tampering with transition hash values. This document defines PostgreSQL-level validation that proves the database can recompute hashes and rejects mismatched values at the authoritative boundary.

## Hash Recomputation

### Recomputation Function
**Function Name**: `wave8_recompute_transition_hash(payload_bytes)`
**Schema**: `functions/wave8_hash_recomputation.sql`
**Purpose**: Recompute SHA-256 hash from canonical payload bytes

### Implementation Strategy
```sql
CREATE OR REPLACE FUNCTION wave8_recompute_transition_hash(payload_bytes bytea)
RETURNS text AS $$
DECLARE
    recomputed_hash text;
BEGIN
    -- Step 1: Validate input bytes
    IF payload_bytes IS NULL THEN
        RAISE EXCEPTION 'P7805: Cannot recompute hash from null bytes'
        USING ERRCODE = 'P7805';
    END IF;
    
    -- Step 2: Compute SHA-256 hash
    recomputed_hash := encode(sha256(payload_bytes), 'hex');
    
    -- Step 3: Return recomputed hash
    RETURN recomputed_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
```

## Deterministic Validation

### Hash Comparison Function
**Function Name**: `wave8_validate_transition_hash_match(stored_hash, payload_bytes)`
**Purpose**: Verify stored hash matches recomputed hash

### Validation Logic
```sql
CREATE OR REPLACE FUNCTION wave8_validate_transition_hash_match(stored_hash text, payload_bytes bytea)
RETURNS boolean AS $$
DECLARE
    recomputed_hash text;
BEGIN
    -- Recompute hash from payload bytes
    recomputed_hash := wave8_recompute_transition_hash(payload_bytes);
    
    -- Compare with stored hash
    RETURN stored_hash = recomputed_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
```

## Tamper Detection

### Mismatch Detection
**Trigger**: `trg_enforce_transition_hash_match`
**Table**: `asset_batches`
**Event**: BEFORE INSERT OR UPDATE

### Enforcement Logic
```sql
CREATE OR REPLACE TRIGGER trg_enforce_transition_hash_match
BEFORE INSERT OR UPDATE ON asset_batches
FOR EACH ROW EXECUTE FUNCTION wave8_transition_hash_enforcer();
```

### Enforcer Function
```sql
CREATE OR REPLACE FUNCTION wave8_transition_hash_enforcer()
RETURNS trigger AS $$
DECLARE
    payload_bytes bytea;
    stored_hash text;
    recomputed_hash text;
    hash_match boolean;
BEGIN
    -- Extract canonical payload bytes
    payload_bytes := NEW.canonical_payload_bytes;
    stored_hash := NEW.transition_hash;
    
    -- Validate inputs
    IF payload_bytes IS NULL OR stored_hash IS NULL THEN
        RAISE EXCEPTION 'P7806: Missing required hash validation data'
        USING ERRCODE = 'P7806';
    END IF;
    
    -- Recompute hash
    recomputed_hash := wave8_recompute_transition_hash(payload_bytes);
    
    -- Check for tampering
    hash_match := wave8_validate_transition_hash_match(stored_hash, payload_bytes);
    
    IF NOT hash_match THEN
        RAISE EXCEPTION 'P7807: Transition hash mismatch - possible tampering detected'
        USING ERRCODE = 'P7807';
    END IF;
    
    -- Hash is valid, allow operation
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
```

## Deterministic Rules

### Hash Computation
- **Algorithm**: SHA-256 only
- **Input**: Canonical UTF-8 payload bytes
- **Output**: Hexadecimal string (64 characters)
- **Consistency**: Same input always produces same hash

### Validation Rules
- **Byte-for-Byte**: Exact comparison required
- **No Tolerance**: Any difference indicates tampering
- **Deterministic**: Same payload bytes produce same hash

### Performance Considerations
- **Indexing**: Hash column should be indexed for lookups
- **Batching**: Process multiple records efficiently
- **Memory**: Handle large payloads without overflow

## Implementation Requirements

### Database Functions
**Core Functions**:
1. `wave8_recompute_transition_hash(payload_bytes)` - Main recomputation
2. `wave8_validate_transition_hash_match(stored_hash, payload_bytes)` - Validation
3. `wave8_transition_hash_enforcer()` - Trigger enforcement

### Trigger Integration
**Integration Points**:
1. **Before Insert**: Validate hash before new records
2. **Before Update**: Ensure hash matches updated payload
3. **Error Handling**: Provide clear tampering detection

### Error Handling
**SQLSTATE Codes**:
- P7805: Cannot recompute hash from null bytes
- P7806: Missing required hash validation data
- P7807: Transition hash mismatch - possible tampering detected

### Security Considerations
- **No Bypass**: Cannot disable hash validation
- **Deterministic**: Same algorithm always produces same result
- **Atomic**: Hash validation is all-or-nothing

## Enforcement Boundaries

### Authoritative Boundary
- **Database Authority**: Hash recomputation owned by database layer
- **No Application Override**: Application cannot bypass hash validation
- **Deterministic**: Same payload always produces same hash

### Contract References
- **TRANSITION_HASH_CONTRACT_v1.md**: Hash computation rules
- **CANONICAL_ATTESTATION_PAYLOAD_v1.md**: Payload structure
- **ED25519_SIGNING_CONTRACT_v1.md**: Signature requirements

This hash recomputation ensures Wave 8's cryptographic boundary can detect and prevent tampering with transition hash values.
