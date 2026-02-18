-- 0014_tenants.sql
-- Tenant root (policy + commercial boundary)

CREATE TABLE IF NOT EXISTS public.tenants (
  tenant_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_key TEXT NOT NULL UNIQUE,
  tenant_name TEXT NOT NULL,
  tenant_type TEXT NOT NULL CHECK (tenant_type IN ('NGO','COOPERATIVE','GOVERNMENT','COMMERCIAL')),
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','CLOSED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tenants_status
  ON public.tenants(status);

REVOKE ALL ON TABLE public.tenants FROM PUBLIC;
