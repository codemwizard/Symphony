-- 0015_tenant_clients.sql
-- Client identities within a tenant

CREATE TABLE IF NOT EXISTS public.tenant_clients (
  client_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id),
  client_key TEXT NOT NULL,
  display_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','REVOKED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (tenant_id, client_key)
);

CREATE INDEX IF NOT EXISTS idx_tenant_clients_tenant
  ON public.tenant_clients(tenant_id);

REVOKE ALL ON TABLE public.tenant_clients FROM PUBLIC;
