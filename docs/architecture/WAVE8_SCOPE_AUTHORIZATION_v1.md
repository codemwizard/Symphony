# Wave 8 Scope Authorization

## Executive Summary

Wave 8 establishes scope authorization enforcement to distinguish cryptographic validity from authorization scope. This document provides deterministic validation that separates signature verification from scope authorization, preventing conflation of these distinct security concerns.

## Scope Authorization

### Authorization Function
**Function Name**: `wave8_validate_scope_authorization(scope_id, operation_timestamp)`
**Schema**: `functions/wave8_scope_authorization.sql`
**Purpose**: Validate scope authorization independently of signature validity

### Implementation Strategy
```sql
CREATE OR REPLACE FUNCTION wave8_validate_scope_authorization(scope_id text, operation_timestamp timestamptz)
RETURNS boolean AS $$
DECLARE
    scope_exists boolean;
    scope_active boolean;
    key_valid_from timestamptz;
    key_valid_to timestamptz;
BEGIN
    -- Step 1: Validate scope exists
    SELECT EXISTS(SELECT 1 FROM authorization_scopes WHERE scope_id = authorization_scopes.scope_id)
    INTO scope_exists;
    
    IF NOT scope_exists THEN
        RAISE EXCEPTION 'P7814: Authorization scope does not exist'
        USING ERRCODE = 'P7814';
    END IF;
    
    -- Step 2: Check if scope has active signing keys
    SELECT EXISTS(
        SELECT 1 FROM signing_keys 
        WHERE scope_id = authorization_scopes.scope_id 
          AND active = true
          AND valid_from <= operation_timestamp
          AND valid_to >= operation_timestamp
    ) INTO scope_active;
    
    IF NOT scope_active THEN
        RAISE EXCEPTION 'P7815: No active signing keys for scope'
        USING ERRCODE = 'P7815';
    END IF;
    
    -- Step 3: Scope is valid for operation
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
```

## Deterministic Validation

### Scope Validation Rules
**Scope Existence**: Must be defined in authorization_scopes table
- **Exact Match**: Scope identifiers must match exactly
- **Case Sensitive**: Scope resolution is case-sensitive
- **No Wildcards**: No pattern matching in scope validation

### Key Availability Rules
**Active Keys**: At least one key must be active for scope
- **Temporal Validity**: Keys must be valid at operation time
- **No Gaps**: No periods without valid keys for scope
- **Fallback Prevention**: No automatic scope fallback behavior

### Operation Validation
**Timestamp Validation**: Operation timestamp must be in UTC
- **Format Compliance**: ISO 8601 timestamp format
- **Range Checking**: Timestamp must be within reasonable range

## Failure Separation

### Distinct Error Domains
**Scope Authorization Failures**:
- P7814: Authorization scope does not exist
- P7815: No active signing keys for scope
- P7816: Scope authorization validation failure

**Cryptographic Failures**:
- P7817: Signature verification failed
- P7818: Invalid signature format
- P7819: Key not found for signature

### Separation Benefits
- **Clear Diagnostics**: Different error codes for different failure types
- **Targeted Remediation**: Specific fixes for authorization vs cryptographic issues
- **No Conflation**: Signature validity not confused with scope authorization
- **Independent Validation**: Each domain can fail independently

## Implementation Requirements

### Database Functions
**Core Functions**:
1. `wave8_validate_scope_authorization(scope_id, operation_timestamp)` - Main validation
2. `wave8_check_scope_exists(scope_id)` - Scope existence check
3. `wave8_check_scope_key_availability(scope_id, timestamp)` - Key availability check

### Trigger Integration
**Integration Points**:
1. **Before Insert**: Validate scope before new records
2. **Before Update**: Ensure scope remains valid for updates
3. **Error Handling**: Provide clear rejection reasons
4. **Audit Logging**: Log all scope validation attempts

### Error Handling
**SQLSTATE Codes**:
- P7814: Authorization scope does not exist
- P7815: No active signing keys for scope
- P7816: Scope authorization validation failure

### Performance Considerations
**Optimization Strategies**:
1. **Indexing**: Proper indexes on scope_id and timestamp columns
2. **Caching**: Cache frequently used scope validations
3. **Batching**: Process multiple operations efficiently
4. **Connection Management**: Efficient database connection handling

## Enforcement Boundaries

### Authoritative Boundary
- **Database Authority**: Scope authorization owned by database layer
- **No Application Override**: Application cannot bypass scope validation
- **Deterministic**: Same inputs always produce same result

### Security Considerations
**Access Control**:
- Scope authorization requires appropriate privileges
- Audit trail of all scope access attempts
- No unauthorized scope exposure
- Secure scope storage and transmission

**Authentication**:
- Scopes must be properly authorized
- Scope changes require proper authorization
- Compromised scopes immediately deactivated
- Secure scope backup and recovery

## Error Handling

### SQLSTATE Codes
- **P7814**: Authorization scope does not exist
- **P7815**: No active signing keys for scope
- **P7816**: Scope authorization validation failure

### Recovery Procedures
**Failure Modes**:
1. **Scope Not Found**: Immediate failure, no fallback
2. **Invalid Scope**: Clear error message with valid scopes
3. **No Keys Available**: Check key management processes
4. **Database Errors**: Proper error propagation and logging

### Monitoring Requirements
**Audit Trail**:
- Log all scope validation attempts
- Track scope creation and modification
- Monitor key availability for scopes
- Regular compliance reporting

This scope authorization ensures Wave 8's cryptographic boundary operates with proper separation of concerns between cryptographic validity and authorization scope.
