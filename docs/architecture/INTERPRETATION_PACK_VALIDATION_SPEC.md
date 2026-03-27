# Interpretation Pack Validation Specification

## Overview

This specification defines the deterministic algorithm for resolving interpretation pack conflicts and ensuring data integrity when multiple packs apply to the same context. The validation logic ensures predictable, auditable resolution of interpretation rules.

## Resolution Algorithm

### Input Parameters

- `domain`: Target domain (e.g., 'CARBON_MARKET')
- `jurisdiction_code`: Target jurisdiction (e.g., 'ZM', 'US-CA')
- `adapter_registration_id`: Optional UUID of calling adapter
- `current_timestamp`: Resolution timestamp

### Resolution Steps

#### Step 1: Candidate Selection

```sql
-- Find all active packs for domain and jurisdiction
WITH candidate_packs AS (
  SELECT interpretation_pack_id, domain, jurisdiction_code, authority_level,
         rule_text, confidence_level, effective_from, adapter_registration_id
  FROM interpretation_packs 
  WHERE domain = $domain
    AND jurisdiction_code = $jurisdiction_code
    AND effective_from <= $current_timestamp
    AND supersedes_id IS NULL
)
```

#### Step 2: Adapter Context Preference

```sql
-- Apply adapter context if provided
WITH context_filtered_packs AS (
  SELECT * FROM candidate_packs
  WHERE ($adapter_registration_id IS NULL 
         OR adapter_registration_id = adapter_registration_id)
)
```

#### Step 3: Authority Level Precedence

```sql
-- Apply authority precedence ordering
WITH ranked_packs AS (
  SELECT *,
         CASE authority_level
           WHEN 'SOVEREIGN' THEN 1
           WHEN 'REGULATORY' THEN 2
           WHEN 'INTERNAL' THEN 3
           WHEN 'DEFAULT' THEN 4
           ELSE 999
         END as authority_rank
  FROM context_filtered_packs
)
```

#### Step 4: Final Selection

```sql
-- Select highest priority pack
SELECT interpretation_pack_id, domain, jurisdiction_code, authority_level,
       rule_text, confidence_level, effective_from, adapter_registration_id
FROM ranked_packs
ORDER BY authority_rank ASC, effective_from DESC
LIMIT 1;
```

## Conflict Detection

### Data Integrity Failure

**Condition**: Two or more active packs exist with identical `(domain, jurisdiction_code, authority_level)` and `supersedes_id IS NULL`

**Error Code**: `P0001`
**Error Message**: `INTERP_CONFLICT`
**Action**: Raise SQLSTATE error with conflicting pack IDs

**SQLSTATE**: `P0001`
**Message Template**: `Interpretation pack conflict detected. Conflicting packs: {pack_id_list}`

### Uniqueness Constraint

```sql
-- Prevent duplicate active packs
CONSTRAINT interpretation_pack_unique_active_domain 
  UNIQUE (domain, jurisdiction_code, authority_level) 
  WHERE (supersedes_id IS NULL)
  DEFERRABLE INITIALLY DEFERRED
```

## Implementation Specification

### Function: resolve_interpretation_pack

```sql
CREATE OR REPLACE FUNCTION resolve_interpretation_pack(
  p_domain TEXT,
  p_jurisdiction_code TEXT,
  p_adapter_registration_id UUID DEFAULT NULL,
  p_current_timestamp TIMESTAMPTZ DEFAULT NOW()
) RETURNS TABLE (
  interpretation_pack_id UUID,
  domain TEXT,
  jurisdiction_code TEXT,
  authority_level TEXT,
  rule_text TEXT,
  confidence_level TEXT,
  effective_from TIMESTAMPTZ,
  adapter_registration_id UUID
) AS $$
DECLARE
  -- Variables for conflict detection
  conflicting_packs TEXT[];
  pack_count INTEGER;
  
BEGIN
  -- Check for data integrity failure
  SELECT ARRAY_AGG(interpretation_pack_id::TEXT)
  INTO conflicting_packs
  FROM interpretation_packs 
  WHERE domain = p_domain
    AND jurisdiction_code = p_jurisdiction_code
    AND authority_level IN ('SOVEREIGN', 'REGULATORY', 'INTERNAL', 'DEFAULT')
    AND effective_from <= p_current_timestamp
    AND supersedes_id IS NULL;
  
  -- Get count of conflicting packs
  pack_count := ARRAY_LENGTH(conflicting_packs);
  
  -- Raise error if conflict detected
  IF pack_count > 1 THEN
    RAISE EXCEPTION 'P0001' USING MESSAGE = 
      'Interpretation pack conflict detected. Conflicting packs: ' || 
      ARRAY_TO_STRING(conflicting_packs, ', ');
  END IF;
  
  -- Return resolved pack using deterministic algorithm
  RETURN QUERY
    SELECT ip.interpretation_pack_id, ip.domain, ip.jurisdiction_code,
           ip.authority_level, ip.rule_text, ip.confidence_level,
           ip.effective_from, ip.adapter_registration_id
    FROM (
      -- Step 1: Candidate selection
      WITH candidate_packs AS (
        SELECT interpretation_pack_id, domain, jurisdiction_code, authority_level,
               rule_text, confidence_level, effective_from, adapter_registration_id
        FROM interpretation_packs 
        WHERE domain = p_domain
          AND jurisdiction_code = p_jurisdiction_code
          AND effective_from <= p_current_timestamp
          AND supersedes_id IS NULL
      ),
      
      -- Step 2: Adapter context preference
      context_filtered_packs AS (
        SELECT * FROM candidate_packs
        WHERE (p_adapter_registration_id IS NULL 
               OR adapter_registration_id = p_adapter_registration_id)
      ),
      
      -- Step 3: Authority level precedence
      ranked_packs AS (
        SELECT *,
               CASE authority_level
                 WHEN 'SOVEREIGN' THEN 1
                 WHEN 'REGULATORY' THEN 2
                 WHEN 'INTERNAL' THEN 3
                 WHEN 'DEFAULT' THEN 4
                 ELSE 999
               END as authority_rank
        FROM context_filtered_packs
      )
      
      -- Step 4: Final selection
      SELECT interpretation_pack_id, domain, jurisdiction_code, authority_level,
             rule_text, confidence_level, effective_from, adapter_registration_id
      FROM ranked_packs
      ORDER BY authority_rank ASC, effective_from DESC
      LIMIT 1
    ) ip;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Function: validate_interpretation_integrity

```sql
CREATE OR REPLACE FUNCTION validate_interpretation_integrity(
  p_domain TEXT,
  p_jurisdiction_code TEXT
) RETURNS VOID AS $$
DECLARE
  conflict_count INTEGER;
BEGIN
  -- Count active packs for domain/jurisdiction
  SELECT COUNT(*)
  INTO conflict_count
  FROM interpretation_packs 
  WHERE domain = p_domain
    AND jurisdiction_code = p_jurisdiction_code
    AND authority_level IN ('SOVEREIGN', 'REGULATORY', 'INTERNAL', 'DEFAULT')
    AND effective_from <= NOW()
    AND supersedes_id IS NULL;
  
  -- Raise error if more than one active pack
  IF conflict_count > 1 THEN
    RAISE EXCEPTION 'P0001' USING MESSAGE = 
      'Data integrity violation: Multiple active interpretation packs for domain ' || 
      p_domain || ', jurisdiction ' || p_jurisdiction_code;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Usage Examples

### Basic Resolution

```sql
-- Resolve carbon credit interpretation for Zambia
SELECT * FROM resolve_interpretation_pack(
  'CARBON_MARKET', 'ZM', NULL, NOW()
);
```

### Adapter Context Resolution

```sql
-- Resolve with specific adapter context
SELECT * FROM resolve_interpretation_pack(
  'CARBON_MARKET', 'ZM', 
  'vm0044-solar-adapter-uuid', NOW()
);
```

### Integrity Validation

```sql
-- Validate no conflicts exist
SELECT validate_interpretation_integrity('CARBON_MARKET', 'ZM');
```

## Error Handling

### Exception Types

1. **P0001 - INTERP_CONFLICT**: Data integrity failure
2. **P0002 - INVALID_DOMAIN**: Invalid domain specified
3. **P0003 - INVALID_JURISDICTION**: Invalid jurisdiction code
4. **P0004 - NO_ACTIVE_PACK**: No active pack found for context

### Recovery Procedures

#### Conflict Resolution
1. **Immediate Action**: Block operation with clear error message
2. **Audit Trail**: Log conflict detection with timestamp and context
3. **Manual Review**: Require manual intervention to resolve conflicts
4. **Data Cleanup**: Identify and resolve conflicting pack assignments

#### System Recovery
1. **Fallback Mechanism**: Use DEFAULT packs if no higher authority available
2. **Grace Period**: Allow temporary operation during conflict resolution
3. **Rollback Support**: Ability to revert to previous pack configuration

## Performance Considerations

### Indexing Strategy

```sql
-- Optimize for common resolution patterns
CREATE INDEX idx_interpretation_packs_resolution_lookup 
ON interpretation_packs(domain, jurisdiction_code, authority_level, effective_from, supersedes_id);

-- Optimize for adapter context lookups
CREATE INDEX idx_interpretation_packs_adapter_context 
ON interpretation_packs(adapter_registration_id, domain, jurisdiction_code);
```

### Query Optimization

- **Partial Indexes**: Support prefix searches on domain and jurisdiction
- **Covering Indexes**: Ensure resolution queries use optimal execution plans
- **Statistics**: Maintain accurate table statistics for query planning

## Testing Requirements

### Unit Tests

1. **Resolution Algorithm**: Test all authority precedence combinations
2. **Conflict Detection**: Verify duplicate pack detection
3. **Edge Cases**: Test with NULL adapter contexts
4. **Performance**: Benchmark resolution under high pack counts

### Integration Tests

1. **Adapter Integration**: Test with various adapter registration contexts
2. **Cross-Domain**: Verify isolation between different domains
3. **Temporal**: Test pack effective dates and supersession
4. **Concurrency**: Test simultaneous resolution requests

## Migration Path

### Phase 1: Core Schema
- Create `interpretation_packs` table
- Add basic constraints and indexes
- Implement validation functions

### Phase 2: Resolution Logic
- Implement `resolve_interpretation_pack` function
- Add conflict detection and error handling
- Create performance indexes

### Phase 3: Integration
- Connect to adapter registration system
- Implement audit logging
- Add monitoring and metrics

### Phase 4: Testing
- Create comprehensive test suite
- Performance benchmarking
- Load testing with high pack volumes

## Security Considerations

### Access Control

- **Domain Isolation**: RLS ensures domains only see their own packs
- **Jurisdiction Filtering**: Access limited by jurisdiction context
- **Authority Level**: Higher authority levels can override lower ones

### Audit Requirements

- **Change Tracking**: All modifications tracked via `updated_at` and `created_by`
- **State History**: Conflict detection events should be logged
- **Resolution Logging**: All pack resolutions should be auditable

### Data Integrity

- **Uniqueness Constraints**: Prevent duplicate active packs
- **Referential Integrity**: All references must be valid
- **Transaction Safety**: Resolution operations must be atomic
