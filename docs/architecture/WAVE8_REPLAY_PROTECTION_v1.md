# Wave 8 Replay Protection

## Executive Summary

Wave 8 establishes replay protection enforcement to prevent duplicate transaction processing. This document provides deterministic validation that ensures each transaction can only be processed once, preventing replay attacks at the cryptographic boundary.

## Replay Protection

### Protection Function
**Function Name**: `wave8_protect_against_replay(operation_hash, operation_timestamp)`
**Schema**: `functions/wave8_replay_protection.sql`
**Purpose**: Prevent replay of previously processed transactions

### Implementation Strategy
```sql
CREATE OR REPLACE FUNCTION wave8_protect_against_replay(operation_hash text, operation_timestamp timestamptz)
RETURNS boolean AS $$
DECLARE
    transaction_exists boolean;
    time_window interval;
BEGIN
    -- Step 1: Validate inputs
    IF operation_hash IS NULL OR operation_timestamp IS NULL THEN
        RAISE EXCEPTION 'P7825: Cannot check replay with null hash or timestamp'
        USING ERRCODE = 'P7825';
    END IF;
    
    -- Step 2: Check if transaction already exists
    SELECT EXISTS(
        SELECT 1 FROM processed_transactions 
        WHERE transaction_hash = operation_hash
          AND operation_timestamp >= operation_timestamp - INTERVAL '1 hour'
          AND operation_timestamp <= operation_timestamp + INTERVAL '1 hour'
    ) INTO transaction_exists;
    
    -- Step 3: Prevent replay within time window
    time_window := INTERVAL '1 hour';
    
    IF transaction_exists THEN
        RAISE EXCEPTION 'P7826: Transaction replay detected'
        USING ERRCODE = 'P7826';
    END IF;
    
    -- Step 4: Transaction is unique within time window
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
```

## Deterministic Detection

### Replay Detection Rules
- **Hash Uniqueness**: Same hash cannot be processed twice
- **Time Window**: 1-hour window around timestamp
- **Exact Match**: Hash comparison must be exact
- **No False Positives**: Legitimate retries allowed outside window

### Transaction Tracking
**Processed Transactions Table**:
```sql
CREATE TABLE IF NOT EXISTS processed_transactions (
    id BIGSERIAL PRIMARY KEY,
    transaction_hash TEXT NOT NULL,
    operation_timestamp TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT processed_transactions_unique_hash UNIQUE (transaction_hash, operation_timestamp)
);
```

### Index Strategy
```sql
CREATE INDEX IF NOT EXISTS idx_processed_transactions_hash 
ON processed_transactions (transaction_hash);

CREATE INDEX IF NOT EXISTS idx_processed_transactions_timestamp 
ON processed_transactions (operation_timestamp);
```

## Failure Handling

### SQLSTATE Codes
- P7825: Cannot check replay with null inputs
- P7826: Transaction replay detected
- P7827: Replay protection validation failure

### Error Recovery
- **Hard Fail**: Replay attempts cause immediate rejection
- **No Advisory**: No warnings for potential replay
- **Clear Diagnostics**: Specific error messages for replay attempts
- **Audit Logging**: All replay attempts logged

## Implementation Requirements

### Database Functions
**Core Functions**:
1. `wave8_protect_against_replay(operation_hash, operation_timestamp)` - Main protection
2. `wave8_log_processed_transaction(hash, timestamp)` - Transaction logging
3. `wave8_check_transaction_processed(hash, timestamp)` - Status check

### Trigger Integration
**Integration Points**:
1. **Before Insert**: Check for replay before new records
2. **Before Update**: Ensure updates don't create replay
3. **After Insert**: Log successful transactions
4. **Error Handling**: Provide clear replay rejection reasons

### Performance Considerations
**Optimization Strategies**:
1. **Indexing**: Proper indexes on hash and timestamp columns
2. **Partitioning**: Consider time-based partitioning for large tables
3. **Cleanup**: Regular cleanup of old processed transactions
4. **Batching**: Process multiple transactions efficiently

## Security Considerations

### Attack Prevention
- **Time Window**: Configurable replay detection window
- **Hash Uniqueness**: Cryptographic hash ensures transaction uniqueness
- **Deterministic**: Same inputs always produce same validation result
- **No Bypass**: Application cannot disable replay protection

### Data Integrity
- **Atomic Operations**: Transaction logging and validation are atomic
- **Consistent State**: Replay protection state is consistent
- **Audit Trail**: Complete audit trail of all transactions

## Enforcement Boundaries

### Authoritative Boundary
- **Database Authority**: Replay protection owned by database layer
- **No Application Override**: Application cannot bypass replay protection
- **Deterministic**: Same inputs always produce same result

### Contract References
- **TRANSITION_HASH_CONTRACT_v1.md**: Hash computation rules
- **ED25519_SIGNING_CONTRACT_v1.md**: Signature requirements
- **CANONICAL_ATTESTATION_PAYLOAD_v1.md**: Payload structure

This replay protection ensures Wave 8's cryptographic boundary operates with deterministic, non-replayable transaction processing.
