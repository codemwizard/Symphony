# Wave 8 SQL Canonicalization

## Executive Summary

Wave 8 establishes SQL-authoritative canonical payload construction to ensure deterministic byte representation. This document moves canonicalization authority from application layer to database layer, preventing ambiguity in cryptographic boundary enforcement.

## SQL Canonicalization

### Canonicalization Function
**Function Name**: `wave8_canonicalize_payload(payload_jsonb)`
**Schema**: `functions/wave8_canonicalization.sql`
**Purpose**: Convert JSONB payload to canonical UTF-8 bytes

### Implementation Strategy
```sql
CREATE OR REPLACE FUNCTION wave8_canonicalize_payload(payload_jsonb jsonb)
RETURNS bytea AS $$
DECLARE
    canonical_json jsonb;
    canonical_text text;
    canonical_bytes bytea;
BEGIN
    -- Step 1: Validate input structure
    IF payload_jsonb IS NULL THEN
        RAISE EXCEPTION 'P7802: Cannot canonicalize null payload'
        USING ERRCODE = 'P7802';
    END IF;
    
    -- Step 2: Sort object properties alphabetically
    canonical_json := jsonb_build_object(
        SELECT key, value
        FROM jsonb_each(payload_jsonb)
        ORDER BY key ASC
    );
    
    -- Step 3: Convert to canonical text (RFC 8785)
    canonical_text := jsonb_pretty(canonical_json);
    
    -- Step 4: Remove unnecessary whitespace
    canonical_text := regexp_replace(canonical_text, '\s+', ' ', 'g');
    canonical_text := trim(canonical_text);
    
    -- Step 5: Convert to UTF-8 bytes
    canonical_bytes := convert_to(canonical_text, 'UTF8');
    
    RETURN canonical_bytes;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
```

## Payload Construction

### Input Validation
**Required Fields**:
- `task_id`: UUID (must match task record)
- `timestamp_utc`: ISO 8601 timestamp
- `environment_tuple`: JSON object with environment metadata
- `payload_data`: JSON object with actual payload

**Validation Rules**:
```sql
-- Example validation in trigger
IF NEW.payload_data IS NULL OR 
   jsonb_typeof(NEW.payload_data) != 'object' THEN
    RAISE EXCEPTION 'P7803: Invalid payload_data structure'
    USING ERRCODE = 'P7803';
END IF;
```

### Construction Process
1. **Input Assembly**: Gather all required fields
2. **Type Validation**: Ensure correct data types
3. **Canonicalization**: Apply deterministic ordering
4. **Byte Generation**: Convert to UTF-8 bytes
5. **Hash Computation**: Generate SHA-256 hash

## Deterministic Rules

### Ordering Rules
- **Object Properties**: Alphabetical (A-Z)
- **Array Elements**: Original order preserved
- **Null Values**: Explicitly handled
- **Numeric Types**: String representation preserved

### Encoding Rules
- **Character Set**: UTF-8 only
- **Line Endings**: LF (\n) only
- **Whitespace**: Normalized single spaces
- **Escape Sequences**: RFC 8785 compliant

### Hash Computation
```sql
-- Example hash computation
CREATE OR REPLACE FUNCTION wave8_compute_transition_hash(canonical_bytes bytea)
RETURNS text AS $$
BEGIN
    RETURN encode(sha256(canonical_bytes), 'hex');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
```

## Implementation Requirements

### Database Functions
**Core Functions**:
1. `wave8_canonicalize_payload(payload_jsonb)` - Main canonicalization
2. `wave8_compute_transition_hash(canonical_bytes)` - Hash computation
3. `wave8_validate_payload_structure(payload_jsonb)` - Structure validation

### Trigger Integration
**Integration Points**:
1. **Before Insert**: Validate and canonicalize payload
2. **Hash Storage**: Store computed transition hash
3. **Signature Verification**: Use canonical bytes for Ed25519

### Error Handling
**SQLSTATE Codes**:
- P7802: Null payload canonicalization
- P7803: Invalid payload structure
- P7804: Canonicalization failure
- P7805: Hash computation failure

### Performance Considerations
**Optimization Strategies**:
1. **Indexing**: Proper indexes on JSONB columns
2. **Caching**: Cache canonicalization results
3. **Batching**: Process multiple records efficiently
4. **Memory Management**: Limit payload size

## Enforcement Boundaries

### Authoritative Boundary
- **SQL Authority**: Database owns canonicalization logic
- **No Bypass**: Application cannot override canonical bytes
- **Deterministic**: Same input always produces same output

### Contract References
- **CANONICAL_ATTESTATION_PAYLOAD_v1.md**: Field definitions
- **TRANSITION_HASH_CONTRACT_v1.md**: Hash computation rules
- **ED25519_SIGNING_CONTRACT_v1.md**: Signature requirements

This SQL canonicalization ensures Wave 8's cryptographic boundary operates on deterministic, database-authoritative byte representations.
