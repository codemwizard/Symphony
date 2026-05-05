# Wave 8 Timestamp Validation

## Executive Summary

Wave 8 establishes timestamp validation enforcement to ensure deterministic temporal validation. This document provides validation that prevents timestamp manipulation and ensures consistent temporal behavior at the cryptographic boundary.

## Timestamp Validation

### Validation Function
**Function Name**: `wave8_validate_timestamp(operation_timestamp)`
**Schema**: `functions/wave8_timestamp_validation.sql`
**Purpose**: Validate timestamp format and range deterministically

### Implementation Strategy
```sql
CREATE OR REPLACE FUNCTION wave8_validate_timestamp(operation_timestamp timestamptz)
RETURNS boolean AS $$
DECLARE
    utc_now timestamptz;
    time_diff interval;
BEGIN
    -- Step 1: Validate timestamp is not null
    IF operation_timestamp IS NULL THEN
        RAISE EXCEPTION 'P7820: Timestamp cannot be null'
        USING ERRCODE = 'P7820';
    END IF;
    
    -- Step 2: Get current UTC time
    utc_now := now() AT TIME ZONE 'UTC';
    
    -- Step 3: Check timestamp is not too far in future (5 minutes)
    time_diff := operation_timestamp - utc_now;
    IF time_diff > INTERVAL '5 minutes' THEN
        RAISE EXCEPTION 'P7821: Timestamp too far in future'
        USING ERRCODE = 'P7821';
    END IF;
    
    -- Step 4: Check timestamp is not too far in past (24 hours)
    time_diff := utc_now - operation_timestamp;
    IF time_diff > INTERVAL '24 hours' THEN
        RAISE EXCEPTION 'P7822: Timestamp too far in past'
        USING ERRCODE = 'P7822';
    END IF;
    
    -- Step 5: Timestamp is valid
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
```

## Deterministic Rules

### Timestamp Format
- **Format**: ISO 8601 with timezone
- **Timezone**: UTC only
- **Precision**: Microsecond precision
- **Consistency**: Same format across all operations

### Validation Rules
- **Range Check**: ±5 minutes future, ±24 hours past
- **Format Check**: Valid ISO 8601 format
- **Timezone Check**: UTC timezone required
- **Null Check**: Timestamp cannot be null

### Performance Considerations
- **Indexing**: Timestamp columns indexed
- **Caching**: Cache current UTC time
- **Batching**: Process multiple timestamps efficiently

## Failure Handling

### SQLSTATE Codes
- P7820: Timestamp cannot be null
- P7821: Timestamp too far in future
- P7822: Timestamp too far in past
- P7823: Timestamp format validation failure

### Error Recovery
- **Hard Fail**: Invalid timestamps cause rejection
- **No Advisory**: No advisory warnings for timestamp issues
- **Clear Diagnostics**: Specific error messages for each failure type

## Implementation Requirements

### Database Functions
- `wave8_validate_timestamp(operation_timestamp)` - Main validation
- `wave8_check_timestamp_range(timestamp)` - Range validation
- `wave8_normalize_timestamp(timestamp)` - Format normalization

### Trigger Integration
- Before Insert: Validate timestamp before new records
- Before Update: Ensure timestamp remains valid
- Error Handling: Clear rejection reasons

This timestamp validation ensures Wave 8's cryptographic boundary operates with deterministic temporal behavior.
