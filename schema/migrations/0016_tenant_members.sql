-- 0016_tenant_members.sql
-- Member/beneficiary identities within a tenant

CREATE TABLE IF NOT EXISTS public.tenant_members (
  member_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id),
  member_ref TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','EXITED')),
  tpin_hash BYTEA,
  msisdn_hash BYTEA,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (tenant_id, member_ref)
);

CREATE INDEX IF NOT EXISTS idx_tenant_members_tenant
  ON public.tenant_members(tenant_id);

CREATE INDEX IF NOT EXISTS idx_tenant_members_status
  ON public.tenant_members(status);

REVOKE ALL ON TABLE public.tenant_members FROM PUBLIC;
