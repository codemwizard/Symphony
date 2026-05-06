# Wave 8 Placeholder Cleanup

## Executive Summary

Wave 8 establishes strict canonicalization rules that reject placeholder values and legacy compatibility prefixes. This document defines the systematic removal of non-deterministic data patterns that would compromise cryptographic boundary enforcement.

## Placeholder Rejection

### Placeholder Value Detection
**Pattern**: Any value matching placeholder patterns
- `null`, `undefined`, `placeholder`
- Empty strings or whitespace-only values
- Default sentinel values (`-1`, `0xDEADBEEF`, etc.)
- Test data patterns (`test_*`, `demo_*`, `sample_*`)

### Rejection Behavior
- **Hard Fail**: All placeholder values trigger immediate rejection
- **SQLSTATE**: P7801 (Wave 8: placeholder or malformed data)
- **No Advisory**: Rejection is not advisory, it's a hard boundary violation

### Implementation Points
```sql
-- Example placeholder rejection in trigger
IF NEW.field_name IS NULL OR 
   NEW.field_name IN ('placeholder', 'undefined', 'test_*') THEN
    RAISE EXCEPTION 'P7801: placeholder or malformed data'
    USING ERRCODE = 'P7801';
END IF;
```

## Legacy Posture Removal

### Legacy Pattern Identification
**Compatibility Prefixes to Remove**:
- `LEGACY_` prefixes on field names
- `COMPAT_` prefixes on values
- Version-specific workarounds (`V1_COMPAT_`, `V2_MIGRATION_`)
- Deprecated field mappings (`old_field_name` → `new_field_name`)

### Migration Strategy
1. **Identify**: Scan all Wave 8 tables for legacy patterns
2. **Block**: Reject writes containing legacy patterns
3. **Migrate**: Provide migration path for valid legacy data
4. **Enforce**: Remove compatibility layers after migration window

### Enforcement Rules
- **No Fallback**: Legacy patterns cannot trigger fallback behavior
- **No Credit**: Legacy compatibility cannot be used for credit
- **Fail-Closed**: System defaults to rejection rather than acceptance

## Canonicalization Rules

### Input Validation
**Pre-Canonicalization Checks**:
1. **Type Validation**: All inputs must match expected types
2. **Range Validation**: Numeric values within defined ranges
3. **Format Validation**: String values match expected patterns
4. **Reference Validation**: Foreign keys reference valid entities

### Canonicalization Process
1. **Normalization**: Convert to standard representation
2. **Validation**: Apply business rules and constraints
3. **Canonicalization**: Generate canonical byte representation
4. **Verification**: Ensure canonicalization is deterministic

### Byte-Level Rules
- **UTF-8 Encoding**: All text encoded as UTF-8
- **RFC 8785**: JSON canonicalization following RFC 8785
- **Deterministic Order**: Object properties in defined order
- **No Ambiguity**: Eliminate multiple valid representations

## Implementation Requirements

### Database Triggers
**Trigger Responsibilities**:
1. **Input Validation**: Reject invalid data before processing
2. **Canonicalization**: Ensure deterministic representation
3. **Placeholder Detection**: Identify and reject placeholder patterns
4. **Legacy Blocking**: Prevent legacy pattern introduction

### Application Layer
**Validation Points**:
1. **API Input**: Validate at application boundary
2. **Business Logic**: Apply domain-specific rules
3. **Data Access**: Ensure canonical data persistence
4. **Error Handling**: Provide clear rejection reasons

### Monitoring and Auditing
**Required Logging**:
1. **Rejection Events**: Log all placeholder/legacy rejections
2. **Canonicalization Events**: Track canonicalization process
3. **Pattern Detection**: Monitor for new legacy patterns
4. **Compliance Reporting**: Regular compliance status reports

## Enforcement Boundaries

### Authoritative Boundary
- **Wave 8 Contract**: All data must comply with Wave 8 canonicalization
- **No Bypass**: Application cannot bypass database-level enforcement
- **Deterministic**: Same input always produces same canonical output

### Failure Semantics
- **Hard Rejection**: Invalid data causes immediate failure
- **Clear Diagnostics**: Rejection reasons must be actionable
- **No Recovery**: Invalid data cannot be automatically recovered

This cleanup ensures Wave 8's cryptographic boundary operates on deterministic, canonical data only.
