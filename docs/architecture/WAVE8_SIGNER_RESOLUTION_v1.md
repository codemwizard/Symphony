# Wave 8 Signer Resolution

## Executive Summary

Wave 8 establishes a deterministic signer-resolution surface to eliminate ambiguous key lookup and legacy fallback behavior. This document provides a single authoritative method for resolving signing keys for cryptographic boundary enforcement.

## Signer Resolution

### Resolution Function
**Function Name**: `wave8_resolve_signer_key(scope_id, timestamp_utc)`
**Schema**: `functions/wave8_signer_resolution.sql`
**Purpose**: Resolve signing key from scope and timestamp deterministically

### Implementation Strategy
```sql
CREATE OR REPLACE FUNCTION wave8_resolve_signer_key(scope_id text, timestamp_utc timestamptz)
RETURNS text AS $$
DECLARE
    resolved_key text;
    key_valid_from timestamptz;
    key_valid_to timestamptz;
BEGIN
    -- Step 1: Validate inputs
    IF scope_id IS NULL OR timestamp_utc IS NULL THEN
        RAISE EXCEPTION 'P7808: Cannot resolve signer with null scope or timestamp'
        USING ERRCODE = 'P7808';
    END IF;
    
    -- Step 2: Get active signing key for scope
    SELECT public_key, valid_from, valid_to
    INTO resolved_key, key_valid_from, key_valid_to
    FROM signing_keys
    WHERE scope_id = signing_keys.scope_id
      AND active = true
      AND valid_from <= timestamp_utc
      AND valid_to >= timestamp_utc
    ORDER BY valid_from DESC
    LIMIT 1;
    
    -- Step 3: Validate key availability
    IF resolved_key IS NULL THEN
        RAISE EXCEPTION 'P7809: No valid signing key found for scope'
        USING ERRCODE = 'P7809';
    END IF;
    
    RETURN resolved_key;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
```

## Deterministic Lookup

### Key Selection Rules
**Priority Order**:
1. **Scope Match**: Exact scope identifier match
2. **Temporal Validity**: Key must be valid at timestamp
3. **Activation Status**: Key must be active
4. **Most Recent**: Choose newest valid key if multiple exist

### Fallback Prevention
**No Legacy Behavior**:
- No fallback to previous keys
- No application-layer key resolution
- No hardcoded key mappings
- No advisory key selection

**Error Handling**:
- P7808: Invalid input parameters
- P7809: No valid key found
- P7810: Key resolution failure

## Deterministic Rules

### Scope Resolution
- **Exact Match**: Scope identifiers must match exactly
- **Case Sensitive**: Scope resolution is case-sensitive
- **No Wildcards**: No pattern matching in scope resolution
- **Single Result**: Always returns exactly one key or fails

### Temporal Resolution
- **Timestamp Validation**: Keys must be valid at operation time
- **Overlap Handling**: Multiple valid keys handled by newest rule
- **Expiration**: Keys past validity period automatically rejected
- **Timezone Awareness**: All timestamps in UTC

### Key Management
**Activation Requirements**:
- Keys must be explicitly activated
- Activation timestamp recorded
- Deactivation timestamp optional
- Audit trail maintained

**Rotation Rules**:
- New keys activated before old keys expire
- Overlap period allowed for smooth transition
- Old keys automatically deactivated after expiration
- No automatic key fallback

## Implementation Requirements

### Database Functions
**Core Functions**:
1. `wave8_resolve_signer_key(scope_id, timestamp_utc)` - Main resolution
2. `wave8_validate_key_scope(scope_id)` - Scope validation
3. `wave8_check_key_temporal_validity(key_id, timestamp_utc)` - Temporal check

### Trigger Integration
**Integration Points**:
1. **Cryptographic Enforcement**: Use resolved key for signature verification
2. **Hash Validation**: Include key identifier in hash computation
3. **Audit Logging**: Log all key resolution attempts
4. **Error Reporting**: Provide clear failure diagnostics

### Performance Considerations
**Optimization Strategies**:
1. **Indexing**: Proper indexes on scope_id and timestamp columns
2. **Caching**: Cache frequently used key resolutions
3. **Batching**: Process multiple operations efficiently
4. **Connection Pooling**: Manage database connections effectively

## Enforcement Boundaries

### Authoritative Boundary
- **Database Authority**: Key resolution owned by database layer
- **No Application Override**: Application cannot bypass key resolution
- **Deterministic**: Same inputs always produce same result

### Security Considerations
**Access Control**:
- Key resolution requires appropriate privileges
- Audit trail of all key accesses
- No unauthorized key exposure
- Secure key storage and transmission

**Authentication**:
- Keys must be cryptographically verified
- Key rotation requires proper authorization
- Compromised keys immediately deactivated
- Secure key backup and recovery

## Error Handling

### SQLSTATE Codes
- **P7808**: Invalid input parameters
- **P7809**: No valid key found
- **P7810**: Key resolution failure
- **P7811**: Key scope validation failure
- **P7812**: Key temporal validity failure

### Recovery Procedures
**Failure Modes**:
1. **Key Not Found**: Immediate failure, no fallback
2. **Invalid Scope**: Clear error message with valid scopes
3. **Temporal Issues**: Check system clock and key validity
4. **Database Errors**: Proper error propagation and logging

This signer resolution ensures Wave 8's cryptographic boundary operates with deterministic, authoritative key management.
