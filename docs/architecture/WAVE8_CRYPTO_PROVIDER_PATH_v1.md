# Wave 8 Cryptographic Provider Path Enforcement

## Executive Summary

Wave 8 establishes cryptographic provider path enforcement to ensure deterministic cryptographic operations. This document provides validation that prevents ambiguous or insecure provider selection at the cryptographic boundary.

## Provider Path Enforcement

### Enforcement Function
**Function Name**: `wave8_validate_crypto_provider_path(provider_path)`
**Schema**: `functions/wave8_crypto_provider_path.sql`
**Purpose**: Validate cryptographic provider path deterministically

### Implementation Strategy
```sql
CREATE OR REPLACE FUNCTION wave8_validate_crypto_provider_path(provider_path text)
RETURNS boolean AS $$
DECLARE
    provider_exists boolean;
    provider_secure boolean;
BEGIN
    -- Step 1: Validate provider path is not null
    IF provider_path IS NULL THEN
        RAISE EXCEPTION 'P7820: Crypto provider path cannot be null'
        USING ERRCODE = 'P7820';
    END IF;
    
    -- Step 2: Check if provider path exists in allowed providers
    SELECT EXISTS(
        SELECT 1 FROM allowed_crypto_providers 
        WHERE provider_path = allowed_crypto_providers.provider_path
          AND active = true
    ) INTO provider_exists;
    
    IF NOT provider_exists THEN
        RAISE EXCEPTION 'P7821: Crypto provider path not allowed'
        USING ERRCODE = 'P7821';
    END IF;
    
    -- Step 3: Check if provider path is secure
    provider_secure := provider_path LIKE '/usr/lib/%' 
                   OR provider_path LIKE '/opt/cryptography/%'
                   OR provider_path LIKE '/etc/ssl/%';
    
    IF NOT provider_secure THEN
        RAISE EXCEPTION 'P7822: Insecure crypto provider path'
        USING ERRCODE = 'P7822';
    END IF;
    
    -- Step 4: Provider path is valid
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
```

## Deterministic Validation

### Provider Path Rules
- **Exact Match**: Provider path must match allowed list exactly
- **Case Sensitive**: Provider path validation is case-sensitive
- **No Wildcards**: No pattern matching in provider validation
- **Single Result**: Always returns exactly one provider or fails

### Security Validation
- **Secure Paths**: Only system-approved cryptographic paths
- **No User Paths**: User-writable paths rejected
- **No Relative Paths**: Absolute paths required
- **No Injection**: Path traversal attacks prevented

### Allowed Providers Table
```sql
CREATE TABLE IF NOT EXISTS allowed_crypto_providers (
    id BIGSERIAL PRIMARY KEY,
    provider_path TEXT NOT NULL UNIQUE,
    provider_name TEXT NOT NULL,
    provider_version TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Failure Handling

### SQLSTATE Codes
- P7820: Crypto provider path cannot be null
- P7821: Crypto provider path not allowed
- P7822: Insecure crypto provider path
- P7823: Crypto provider path validation failure

### Error Recovery
- **Hard Fail**: Invalid provider paths cause immediate failure
- **No Advisory**: No warnings for provider path issues
- **Clear Diagnostics**: Specific error messages for each failure type
- **No Fallback**: No automatic provider path fallback

## Implementation Requirements

### Database Functions
**Core Functions**:
1. `wave8_validate_crypto_provider_path(provider_path)` - Main validation
2. `wave8_check_provider_allowed(provider_path)` - Allowed check
3. `wave8_check_provider_secure(provider_path)` - Security check

### Trigger Integration
**Integration Points**:
1. **Before Insert**: Validate provider before new records
2. **Before Update**: Ensure provider remains valid for updates
3. **Error Handling**: Provide clear rejection reasons
4. **Audit Logging**: Log all provider validation attempts

### Performance Considerations
**Optimization Strategies**:
1. **Indexing**: Proper indexes on provider_path columns
2. **Caching**: Cache frequently used provider validations
3. **Batching**: Process multiple operations efficiently
4. **Connection Management**: Efficient database connection handling

## Security Considerations

### Access Control
- Provider path enforcement requires appropriate privileges
- Audit trail of all provider access attempts
- No unauthorized provider exposure
- Secure provider storage and transmission

### Authentication
- Providers must be cryptographically verified
- Provider changes require proper authorization
- Compromised providers immediately deactivated
- Secure provider backup and recovery

## Enforcement Boundaries

### Authoritative Boundary
- **Database Authority**: Provider path enforcement owned by database layer
- **No Application Override**: Application cannot bypass provider validation
- **Deterministic**: Same inputs always produce same result

### Contract References
- **ED25519_SIGNING_CONTRACT_v1.md**: Signature requirements
- **TRANSITION_HASH_CONTRACT_v1.md**: Hash computation rules
- **CANONICAL_ATTESTATION_PAYLOAD_v1.md**: Payload structure

This cryptographic provider path enforcement ensures Wave 8's cryptographic boundary operates with deterministic, secure provider selection.
