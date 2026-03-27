# Interpretation Pack Schema Specification

## Overview

Interpretation packs provide domain-specific semantic layers that enable adapters to translate sector-specific business rules into neutral platform operations. This schema defines the canonical structure for storing and managing interpretation rules across all domains.

## Core Schema

### interpretation_packs Table

```sql
CREATE TABLE interpretation_packs (
  interpretation_pack_id UUID PRIMARY KEY DEFAULT uuid_v7_or_random(),
  domain TEXT NOT NULL CHECK (domain IN (
    'CARBON_MARKET', 'TAXONOMY', 'CLAIMS_SUBSTANTIATION', 'METHODOLOGY'
  )),
  jurisdiction_code TEXT NOT NULL,
  authority_level TEXT NOT NULL CHECK (authority_level IN (
    'SOVEREIGN', 'REGULATORY', 'INTERNAL', 'DEFAULT'
  )),
  legal_source_reference TEXT NOT NULL,
  rule_text TEXT NOT NULL,
  confidence_level TEXT NOT NULL CHECK (confidence_level IN (
    'CONFIRMED', 'PRACTICE_ASSUMED', 'PENDING_CLARIFICATION'
  )),
  effective_from TIMESTAMPTZ NOT NULL,
  supersedes_id UUID NULL REFERENCES interpretation_packs(interpretation_pack_id),
  adapter_registration_id UUID NULL REFERENCES adapter_registrations(adapter_id),
  dependency_refs JSONB NULL CHECK (jsonb_typeof(dependency_refs) = 'object'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by TEXT NOT NULL DEFAULT CURRENT_USER,
  
  -- Business constraints
  CONSTRAINT interpretation_pack_unique_active_domain 
    UNIQUE (domain, jurisdiction_code, authority_level) 
    WHERE (supersedes_id IS NULL),
  CONSTRAINT interpretation_pack_valid_effective_from 
    CHECK (effective_from <= CURRENT_TIMESTAMP)
);
```

### Indexes

```sql
-- Performance indexes
CREATE INDEX idx_interpretation_packs_domain ON interpretation_packs(domain);
CREATE INDEX idx_interpretation_packs_jurisdiction ON interpretation_packs(jurisdiction_code);
CREATE INDEX idx_interpretation_packs_effective_from ON interpretation_packs(effective_from);
CREATE INDEX idx_interpretation_packs_adapter ON interpretation_packs(adapter_registration_id);
```

## Field Specifications

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `interpretation_pack_id` | UUID | PRIMARY KEY | System-generated unique identifier |
| `domain` | TEXT | NOT NULL | Domain of interpretation (carbon, taxonomy, claims, etc.) |
| `jurisdiction_code` | TEXT | NOT NULL | Legal jurisdiction (e.g., "ZM", "EU", "US-CA") |
| `authority_level` | TEXT | NOT NULL | Authority level (sovereign, regulatory, internal) |
| `legal_source_reference` | TEXT | NOT NULL | Legal reference (e.g., "ZM-SI-5-2026-S3.2") |
| `rule_text` | TEXT | NOT NULL | Full text of interpretation rule |
| `confidence_level` | TEXT | NOT NULL | Confidence in interpretation |
| `effective_from` | TIMESTAMPTZ | NOT NULL | When interpretation takes effect |
| `supersedes_id` | UUID | NULL FK | Previous interpretation this supersedes |
| `adapter_registration_id` | UUID | NULL FK | Associated adapter registration |
| `dependency_refs` | JSONB | NULL object | Dependencies on other packs/rules |
| `created_at` | TIMESTAMPTZ | NOT NULL | Creation timestamp |
| `created_by` | TEXT | NOT NULL | Creator identification |

### JSONB Schema Examples

#### dependency_refs
```json
{
  "interpretation_packs": ["pack_id_1", "pack_id_2"],
  "regulations": ["reg_id_1", "reg_id_2"],
  "methodologies": ["method_id_1"],
  "business_rules": ["rule_id_1", "rule_id_2"]
}
```

## Domain Classifications

### CARBON_MARKET
- Carbon credit methodologies
- Emission reduction protocols
- Carbon sequestration standards
- Market trading rules
- Verification methodologies

### TAXONOMY
- Project classification systems
- Activity categorization
- Sector definitions
- Standard nomenclature

### CLAIMS_SUBSTANTIATION
- Evidence requirements
- Verification protocols
- Certification standards
- Audit methodologies
- Validation procedures

### METHODOLOGY
- Calculation methods
- Measurement protocols
- Data collection standards
- Quality assurance procedures
- Reporting requirements

## Authority Levels

### SOVEREIGN
- National laws and regulations
- Government-mandated standards
- International treaties
- Cross-border agreements

### REGULATORY
- Regional regulatory bodies
- Industry standards organizations
- Certification authorities
- Compliance frameworks

### INTERNAL
- Company policies
- Operational procedures
- Best practices
- Industry guidelines

### DEFAULT
- Fallback interpretations
- Temporary rules
- Emergency provisions
- Interim measures

## Confidence Levels

### CONFIRMED
- Legally binding
- Court-tested
- Regulatory approved
- Industry consensus

### PRACTICE_ASSUMED
- Common industry practice
- Historical precedent
- Expert consensus
- Professional standards

### PENDING_CLARIFICATION
- Under regulatory review
- Awaiting legal opinion
- Temporary implementation
- Pilot phase results

## API Operations

### Pack Management

```sql
-- Create new interpretation pack
INSERT INTO interpretation_packs (
  domain, jurisdiction_code, authority_level, legal_source_reference,
  rule_text, confidence_level, effective_from, dependency_refs
) VALUES (
  'CARBON_MARKET', 'ZM', 'SOVEREIGN', 'ZM-SI-5-2026-S3.2',
  'Carbon credits must be verified by accredited Verra auditors',
  'CONFIRMED', '2026-01-01T00:00:00Z',
  '{"interpretation_packs": ["base_carbon_pack"]}'
);

-- Get active packs for domain
SELECT * FROM interpretation_packs 
WHERE domain = 'CARBON_MARKET' 
  AND effective_from <= CURRENT_TIMESTAMP 
  AND supersedes_id IS NULL;

-- Get packs by jurisdiction
SELECT * FROM interpretation_packs 
WHERE jurisdiction_code = 'ZM' 
  AND domain = 'CARBON_MARKET';
```

### Version Management

```sql
-- Supersede old pack
UPDATE interpretation_packs 
SET supersedes_id = interpretation_pack_id,
    effective_to = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE interpretation_pack_id = $old_pack_id;

-- Activate new pack
INSERT INTO interpretation_packs (
  domain, jurisdiction_code, authority_level, rule_text,
  confidence_level, effective_from, supersedes_id
) VALUES (
  'CARBON_MARKET', 'ZM', 'SOVEREIGN', $new_rule_text,
  'CONFIRMED', '2026-07-01T00:00:00Z', $old_pack_id
);
```

### Query Operations

```sql
-- Get interpretation hierarchy
WITH RECURSIVE pack_hierarchy AS (
  SELECT interpretation_pack_id, domain, jurisdiction_code, authority_level,
         rule_text, confidence_level, effective_from, supersedes_id
  FROM interpretation_packs
  WHERE supersedes_id IS NULL
  
  UNION ALL
  
  SELECT p.interpretation_pack_id, p.domain, p.jurisdiction_code, 
         p.authority_level, p.rule_text, p.confidence_level, 
         p.effective_from, p.supersedes_id
  FROM interpretation_packs p
  JOIN pack_hierarchy ph ON p.supersedes_id = ph.interpretation_pack_id
)
SELECT * FROM pack_hierarchy 
ORDER BY domain, jurisdiction_code, authority_level, effective_from;

-- Get effective rule for specific case
SELECT ip.rule_text, ip.confidence_level, ip.effective_from
FROM interpretation_packs ip
WHERE ip.domain = 'CARBON_MARKET'
  AND ip.jurisdiction_code = 'ZM'
  AND ip.authority_level = 'SOVEREIGN'
  AND ip.effective_from <= CURRENT_TIMESTAMP
  AND ip.supersedes_id IS NULL;
```

## Business Rules

### Uniqueness Constraints

1. **Active Pack Uniqueness**: Only one active pack per `(domain, jurisdiction_code, authority_level)`
2. **No Circular Supersession**: A pack cannot supersede itself (directly or indirectly)
3. **Temporal Validity**: `effective_from` must be <= current timestamp
4. **Dependency Integrity**: All referenced packs must exist and be effective

### State Management

1. **Draft State**: Created but not yet effective
2. **Active State**: Currently in effect (`effective_from <= NOW()` and `supersedes_id IS NULL`)
3. **Superseded State**: Replaced by newer version (`supersedes_id IS NOT NULL`)
4. **Expired State**: Past effective period but not superseded

## Integration Points

### Core Platform Integration

- **RLS Policies**: All queries filtered by domain/jurisdiction context
- **Audit Trail**: `created_at`, `updated_at`, `created_by` for change tracking
- **UUID Generation**: Time-ordered IDs for auditability

### Adapter Integration

- **Rule Resolution**: Adapters resolve domain-specific rules via interpretation packs
- **Context Application**: Apply jurisdiction and authority level filters
- **Version Compatibility**: Support multiple concurrent versions during transition

### Migration Considerations

- **Forward Compatibility**: New fields can be added with NULL defaults
- **Backward Compatibility**: Existing packs remain valid until superseded
- **Data Migration**: Pack data can be migrated between versions

## Security Considerations

### Access Control

- **Domain Isolation**: RLS ensures domains only see their own packs
- **Jurisdiction Filtering**: Access limited by jurisdiction context
- **Authority Level**: Higher authority levels can override lower ones

### Audit Requirements

- **Change Tracking**: All modifications tracked via `updated_at` and `created_by`
- **State History**: Supersession events should be logged
- **Reference Validation**: Dependency references should be audited

## Example Usage

### Carbon Credit Interpretation Pack

```sql
-- Zambia carbon credit interpretation
INSERT INTO interpretation_packs (
  domain, jurisdiction_code, authority_level, legal_source_reference,
  rule_text, confidence_level, effective_from, adapter_registration_id
) VALUES (
  'CARBON_MARKET', 'ZM', 'SOVEREIGN', 'ZM-SI-5-2026-S3.2',
  'Carbon credits must be verified by accredited Verra auditors before registry entry',
  'CONFIRMED', '2026-01-01T00:00:00Z',
  'vm0044_solar_adapter_uuid'
);
```

### Plastic Waste Interpretation Pack

```sql
-- Plastic waste methodology interpretation
INSERT INTO interpretation_packs (
  domain, jurisdiction_code, authority_level, legal_source_reference,
  rule_text, confidence_level, effective_from, dependency_refs
) VALUES (
  'TAXONOMY', 'ZM', 'REGULATORY', 'ZM-ENV-2024-15',
  'Plastic waste collection must be tracked by weight and categorized by type',
  'CONFIRMED', '2026-03-01T00:00:00Z',
  '{"interpretation_packs": ["base_taxonomy_pack"]}'
);
```

## Migration Path

### Phase 1: Core Schema
- Create `interpretation_packs` table
- Add basic constraints and indexes
- Implement RLS policies

### Phase 2: API Layer
- Create pack management functions
- Add validation procedures
- Implement audit logging

### Phase 3: Integration
- Connect to core platform services
- Implement adapter discovery
- Add monitoring and metrics

## Future Extensions

### Multi-Jurisdiction Support
- Cross-jurisdiction pack sharing
- Regional authority coordination
- International standard harmonization

### Advanced Features
- Pack dependency management
- Version rollback capabilities
- Automated conflict resolution

### Performance Optimizations
- Caching for active pack lookups
- Partitioning by domain or jurisdiction
- Index optimization for common queries
