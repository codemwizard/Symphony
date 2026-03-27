-- Migration 0070: Green Finance Adapter Registrations
-- Phase 1 core schema for adapter contract interface

-- Create adapter_registrations table
CREATE TABLE IF NOT EXISTS public.adapter_registrations (
  -- Primary identifier
  adapter_registration_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  
  -- Tenant isolation (Symphony platform requirement)
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  
  -- Adapter identification
  adapter_code TEXT NOT NULL,
  methodology_code TEXT NOT NULL,
  methodology_authority TEXT NOT NULL,
  version_code TEXT NOT NULL,
  
  -- Activation state
  is_active BOOLEAN NOT NULL DEFAULT false,
  
  -- Schema and template references (as arrays per spec)
  payload_schema_refs JSONB NOT NULL DEFAULT '[]' CHECK (jsonb_typeof(payload_schema_refs) = 'array'),
  checklist_refs JSONB NOT NULL DEFAULT '[]' CHECK (jsonb_typeof(checklist_refs) = 'array'),
  entrypoint_refs JSONB NOT NULL DEFAULT '[]' CHECK (jsonb_typeof(entrypoint_refs) = 'array'),
  
  -- Semantic modes
  issuance_semantic_mode TEXT NOT NULL CHECK (issuance_semantic_mode IN ('STRICT', 'LENIENT', 'HYBRID')),
  retirement_semantic_mode TEXT NOT NULL CHECK (retirement_semantic_mode IN ('STRICT', 'LENIENT', 'HYBRID')),
  
  -- Jurisdiction compatibility
  jurisdiction_compatibility JSONB NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(jurisdiction_compatibility) = 'object'),
  
  -- Audit timestamp
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Business constraints
  CONSTRAINT adapter_registration_unique UNIQUE (tenant_id, adapter_code, methodology_code, version_code)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_adapter_registrations_tenant_id ON adapter_registrations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_adapter_registrations_adapter_code ON adapter_registrations(adapter_code);
CREATE INDEX IF NOT EXISTS idx_adapter_registrations_methodology ON adapter_registrations(methodology_code, methodology_authority);

-- RLS for tenant isolation (canonical 0059 pattern)
ALTER TABLE public.adapter_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adapter_registrations FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_adapter_registrations ON public.adapter_registrations
    FOR ALL TO PUBLIC
    USING (tenant_id = public.current_tenant_id_or_null())
    WITH CHECK (tenant_id = public.current_tenant_id_or_null());

-- Append-only trigger function
CREATE OR REPLACE FUNCTION adapter_registrations_append_only_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Block UPDATE and DELETE operations
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'adapter_registrations is append-only - % operations not allowed', TG_OP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Apply append-only trigger
CREATE TRIGGER adapter_registrations_append_only
    BEFORE UPDATE OR DELETE ON adapter_registrations
    FOR EACH ROW
    EXECUTE FUNCTION adapter_registrations_append_only_trigger();

-- Revoke-first privilege posture
REVOKE ALL ON TABLE adapter_registrations FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE adapter_registrations TO authenticated_role;
GRANT ALL ON TABLE adapter_registrations TO system_role;
