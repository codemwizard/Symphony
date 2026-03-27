# Adapter Contract Interface Specification

## Overview

The Adapter Contract Interface defines the canonical schema and API for registering and managing domain-specific adapters in Symphony's neutral host architecture. This interface enables any sector (plastic, solar, carbon, etc.) to plug into the core platform without requiring schema modifications.

## Core Schema

### adapter_registrations Table

```sql
CREATE TABLE adapter_registrations (
  adapter_id UUID PRIMARY KEY DEFAULT uuid_v7_or_random(),
  adapter_code TEXT UNIQUE NOT NULL,
  methodology_code TEXT NOT NULL,
  methodology_authority TEXT NOT NULL,
  version_code TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT false,
  tenant_id UUID NOT NULL REFERENCES tenants(tenant_id),
  payload_schema_refs JSONB NOT NULL CHECK (jsonb_typeof(payload_schema_refs) = 'object'),
  checklist_refs JSONB NOT NULL CHECK (jsonb_typeof(checklist_refs) = 'object'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by TEXT NOT NULL DEFAULT CURRENT_USER,
  
  -- Business constraints
  CONSTRAINT adapter_registration_unique_active_methodology 
    UNIQUE (methodology_code, methodology_authority, version_code) 
    DEFERRABLE INITIALLY DEFERRED
);
```

### Field Specifications

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `adapter_id` | UUID | PRIMARY KEY | System-generated unique identifier |
| `adapter_code` | TEXT | UNIQUE NOT NULL | Globally unique adapter identifier (e.g., "PWRM001") |
| `methodology_code` | TEXT | NOT NULL | Methodology identifier (e.g., "PWRM") |
| `methodology_authority` | TEXT | NOT NULL | Authority defining the methodology (e.g., "Verra") |
| `version_code` | TEXT | NOT NULL | Version of the methodology (e.g., "v1.0") |
| `is_active` | BOOLEAN | NOT NULL DEFAULT false | Whether adapter is currently active |
| `tenant_id` | UUID | FK tenants NOT NULL | Symphony platform RLS requirement |
| `payload_schema_refs` | JSONB | NOT NULL object | Map of RECORD_TYPE to schema_ref_id |
| `checklist_refs` | JSONB | NOT NULL object | Map of CASE_TYPE to template_id |

### JSONB Schema Examples

#### payload_schema_refs
```json
{
  "PWRM_COLLECTION": "schema_abc123",
  "PWRM_TRANSPORT": "schema_def456",
  "PWRM_PROCESSING": "schema_ghi789"
}
```

#### checklist_refs
```json
{
  "REGISTRATION": "template_reg_001",
  "VERIFICATION": "template_ver_002",
  "AUDIT": "template_audit_003"
}
```

## API Operations

### Registration Flow

1. **Create Adapter Registration**
   ```sql
   INSERT INTO adapter_registrations (
     adapter_code, methodology_code, methodology_authority, version_code,
     tenant_id, payload_schema_refs, checklist_refs
   ) VALUES (
     'PWRM001', 'PWRM', 'Verra', 'v1.0',
     $tenant_id, $payload_schemas, $checklist_templates
   );
   ```

2. **Activate Adapter**
   ```sql
   UPDATE adapter_registrations 
   SET is_active = true, updated_at = NOW()
   WHERE adapter_code = 'PWRM001';
   ```

3. **Deactivate Adapter**
   ```sql
   UPDATE adapter_registrations 
   SET is_active = false, updated_at = NOW()
   WHERE adapter_code = 'PWRM001';
   ```

### Query Operations

```sql
-- Get active adapter by methodology
SELECT * FROM adapter_registrations 
WHERE methodology_code = 'PWRM' 
  AND is_active = true;

-- Get all adapters for a tenant
SELECT * FROM adapter_registrations 
WHERE tenant_id = $tenant_id;

-- Check schema reference exists
SELECT payload_schema_refs->'PWRM_COLLECTION' as schema_ref
FROM adapter_registrations 
WHERE adapter_code = 'PWRM001';
```

## Business Rules

### Uniqueness Constraints

1. **Global Adapter Code**: Only one adapter can have a given `adapter_code`
2. **Active Methodology Uniqueness**: Only one active adapter per `(methodology_code, methodology_authority, version_code)` combination
3. **Tenant Isolation**: All adapters must belong to a valid tenant

### State Management

1. **Initial State**: `is_active = false` (registered but not activated)
2. **Active State**: `is_active = true` (fully operational)
3. **Deactivation**: Can be deactivated but not deleted (audit trail)

### Schema Validation

1. **JSONB Structure**: `payload_schema_refs` and `checklist_refs` must be valid JSON objects
2. **Reference Integrity**: Schema and template references should be validated by application layer
3. **Version Consistency**: Version codes should follow semantic versioning

## Integration Points

### Core Platform Integration

- **RLS Policies**: All queries automatically filtered by `tenant_id`
- **Audit Trail**: `created_at`, `updated_at`, `created_by` fields for change tracking
- **UUID Generation**: Uses `uuid_v7_or_random()` for time-ordered IDs

### Adapter Integration

- **Schema Registration**: Adapters register their payload schemas via `payload_schema_refs`
- **Checklist Templates**: Adapters provide case type templates via `checklist_refs`
- **Methodology Versioning**: Multiple versions of same methodology can coexist

### Migration Considerations

- **Forward Compatibility**: New fields can be added with NULL defaults
- **Backward Compatibility**: Existing adapters continue to work with schema changes
- **Data Migration**: Adapter data can be migrated between methodology versions

## Security Considerations

### Access Control

- **Tenant Isolation**: RLS ensures tenants only see their own adapters
- **Activation Control**: Only authorized users can activate/deactivate adapters
- **Schema Validation**: JSONB fields validated for structure and content

### Audit Requirements

- **Change Tracking**: All modifications tracked via `updated_at` and `created_by`
- **State History**: Activation/deactivation events should be logged
- **Reference Validation**: Schema and template references should be audited

## Example Usage

### Plastic Waste Recovery Adapter (PWRM)

```sql
-- Register PWRM adapter
INSERT INTO adapter_registrations (
  adapter_code, methodology_code, methodology_authority, version_code,
  tenant_id, payload_schema_refs, checklist_refs
) VALUES (
  'PWRM001', 'PWRM', 'Verra', 'v1.0',
  'tenant-uuid-here',
  '{"PWRM_COLLECTION": "pwrm_collection_v1", "PWRM_TRANSPORT": "pwrm_transport_v1"}',
  '{"REGISTRATION": "pwrm_reg_template", "VERIFICATION": "pwrm_verify_template"}'
);

-- Activate for use
UPDATE adapter_registrations 
SET is_active = true 
WHERE adapter_code = 'PWRM001';
```

### Solar Energy Adapter (VM0044)

```sql
-- Register solar adapter
INSERT INTO adapter_registrations (
  adapter_code, methodology_code, methodology_authority, version_code,
  tenant_id, payload_schema_refs, checklist_refs
) VALUES (
  'VM0044-001', 'VM0044', 'I-REC', 'v2.0',
  'tenant-uuid-here',
  '{"SOLAR_GENERATION": "solar_gen_v2", "SOLAR_CERTIFICATION": "solar_cert_v2"}',
  '{"REGISTRATION": "solar_reg_template", "AUDIT": "solar_audit_template"}'
);
```

## Migration Path

### Phase 1: Core Schema
- Create `adapter_registrations` table
- Add basic constraints and indexes
- Implement RLS policies

### Phase 2: API Layer
- Create registration/activation functions
- Add validation procedures
- Implement audit logging

### Phase 3: Integration
- Connect to core platform services
- Implement adapter discovery
- Add monitoring and metrics

## Future Extensions

### Multi-Tenant Enhancements
- Cross-tenant adapter sharing
- Global adapter marketplace
- Standardized methodology registry

### Advanced Features
- Adapter dependency management
- Version rollback capabilities
- Automated schema compatibility checking

### Performance Optimizations
- Caching for active adapter lookups
- Partitioning by tenant or methodology
- Index optimization for common queries
