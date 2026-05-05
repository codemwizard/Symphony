# Wave 8 Key Lifecycle Enforcement

## Executive Summary

Wave 8 establishes key lifecycle enforcement to convert registry metadata into actual boundary behavior. This document defines the enforcement mechanisms that ensure signing keys follow proper lifecycle rules at the cryptographic boundary.

## Key Lifecycle

### Lifecycle States
**Active**: Key is currently valid for signing operations
- **Valid From**: Timestamp when key becomes effective
- **Valid To**: Timestamp when key expires
- **Scope**: Authorized domains/operations for key usage

**Inactive**: Key is no longer valid for signing
- **Deactivated**: Key was explicitly deactivated
- **Expired**: Key reached validity end time
- **Revoked**: Key was compromised or invalided

### Enforcement Function
**Function Name**: `wave8_enforce_key_lifecycle()`
**Schema**: `functions/wave8_key_lifecycle.sql`
**Purpose**: Validate key lifecycle state before allowing operations

### Implementation Strategy
```sql
CREATE OR REPLACE FUNCTION wave8_enforce_key_lifecycle(scope_id text, operation_timestamp timestamptz)
RETURNS boolean AS $$
DECLARE
    key_active boolean;
    key_valid_from timestamptz;
    key_valid_to timestamptz;
    key_scope text;
BEGIN
    -- Step 1: Get key lifecycle state
    SELECT active, valid_from, valid_to, scope_id
    INTO key_active, key_valid_from, key_valid_to, key_scope
    FROM signing_keys
    WHERE scope_id = signing_keys.scope_id
      AND active = true
    ORDER BY valid_from DESC
    LIMIT 1;
    
    -- Step 2: Validate key is active
    IF NOT key_active THEN
        RAISE EXCEPTION 'P7811: Key is not active for scope'
        USING ERRCODE = 'P7811';
    END IF;
    
    -- Step 3: Validate temporal validity
    IF operation_timestamp < key_valid_from OR operation_timestamp > key_valid_to THEN
        RAISE EXCEPTION 'P7812: Key is not valid at operation time'
        USING ERRCODE = 'P7812';
    END IF;
    
    -- Step 4: Validate scope match
    IF scope_id != key_scope THEN
        RAISE EXCEPTION 'P7813: Key scope mismatch for operation'
        USING ERRCODE = 'P7813';
    END IF;
    
    -- Step 5: Key is valid for operation
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
```

## Enforcement Rules

### Boundary Behavior
**No Fallback**: Cannot use expired or inactive keys
**No Advisory**: Key violations cause hard rejection
**Deterministic**: Same inputs always produce same validation result
**Fail-Closed**: System defaults to rejection rather than acceptance

### Trigger Integration
**Trigger**: `trg_wave8_key_lifecycle_enforcer`
**Table**: `asset_batches`
**Event**: BEFORE INSERT OR UPDATE

### Enforcement Logic
```sql
CREATE OR REPLACE TRIGGER trg_wave8_key_lifecycle_enforcer
BEFORE INSERT OR UPDATE ON asset_batches
FOR EACH ROW EXECUTE FUNCTION wave8_key_lifecycle_enforcer();
```

### Enforcer Function
```sql
CREATE OR REPLACE FUNCTION wave8_key_lifecycle_enforcer()
RETURNS trigger AS $$
DECLARE
    operation_scope text;
    operation_timestamp timestamptz;
BEGIN
    -- Extract operation scope from payload data
    operation_scope := NEW.payload_data->>'scope_id';
    operation_timestamp := NEW.timestamp_utc;
    
    -- Enforce key lifecycle rules
    PERFORM wave8_enforce_key_lifecycle(operation_scope, operation_timestamp);
    
    -- Allow operation if key validation passes
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
```

## Boundary Behavior

### Authoritative Boundary
- **Database Authority**: Key lifecycle enforcement owned by database layer
- **No Application Override**: Application cannot bypass key validation
- **Deterministic**: Same operation always produces same result

### Failure Semantics
- **Hard Rejection**: Invalid key state causes immediate failure
- **Clear Diagnostics**: Rejection reasons must be actionable
- **No Recovery**: Invalid key operations cannot be automatically recovered

## Implementation Requirements

### Database Functions
**Core Functions**:
1. `wave8_enforce_key_lifecycle(scope_id, operation_timestamp)` - Main validation
2. `wave8_key_lifecycle_enforcer()` - Trigger enforcement
3. `wave8_check_key_active(scope_id)` - Key status check

### Trigger Integration
**Integration Points**:
1. **Before Insert**: Validate key before new records
2. **Before Update**: Ensure key remains valid for updates
3. **Error Handling**: Provide clear rejection reasons
4. **Audit Logging**: Log all key validation attempts

### Error Handling
**SQLSTATE Codes**:
- P7811: Key is not active for scope
- P7812: Key is not valid at operation time
- P7813: Key scope mismatch for operation
- P7814: Key lifecycle validation failure

### Performance Considerations
**Optimization Strategies**:
1. **Indexing**: Proper indexes on scope_id and timestamp columns
2. **Caching**: Cache frequently used key validations
3. **Batching**: Process multiple operations efficiently
4. **Connection Management**: Efficient database connection handling

## Security Considerations

### Access Control
- Key lifecycle enforcement requires appropriate privileges
- Audit trail of all key access attempts
- No unauthorized key exposure
- Secure key storage and transmission

### Authentication
- Keys must be cryptographically verified
- Key rotation requires proper authorization
- Compromised keys immediately deactivated
- Secure key backup and recovery

## Enforcement Boundaries

### Authoritative Boundary
- **Database Authority**: Key lifecycle owned by database layer
- **No Application Override**: Application cannot bypass key validation
- **Deterministic**: Same operation always produces same result

### Contract References
- **WAVE8_SIGNER_RESOLUTION_v1.md**: Key resolution rules
- **ED25519_SIGNING_CONTRACT_v1.md**: Signature requirements
- **TRANSITION_HASH_CONTRACT_v1.md**: Hash computation rules

This key lifecycle enforcement ensures Wave 8's cryptographic boundary operates with properly managed, authoritative signing keys.
