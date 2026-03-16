-- 0075_supplier_registry_and_programme_allowlist.sql

CREATE TABLE IF NOT EXISTS public.supplier_registry (
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    supplier_id TEXT NOT NULL,
    supplier_name TEXT NOT NULL,
    payout_target TEXT NOT NULL,
    registered_latitude NUMERIC,
    registered_longitude NUMERIC,
    active BOOLEAN NOT NULL DEFAULT true,
    updated_at_utc TEXT NOT NULL,
    PRIMARY KEY (tenant_id, supplier_id)
);

DROP POLICY IF EXISTS "rls_tenant_isolation_supplier_registry" ON public.supplier_registry;
CREATE POLICY rls_tenant_isolation_supplier_registry ON public.supplier_registry
  AS RESTRICTIVE FOR ALL TO PUBLIC 
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());

ALTER TABLE public.supplier_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_registry FORCE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.program_supplier_allowlist (
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    program_id UUID NOT NULL REFERENCES public.programs(program_id) ON DELETE RESTRICT,
    supplier_id TEXT NOT NULL,
    allowed BOOLEAN NOT NULL DEFAULT true,
    updated_at_utc TEXT NOT NULL,
    PRIMARY KEY (tenant_id, program_id, supplier_id),
    FOREIGN KEY (tenant_id, supplier_id) REFERENCES public.supplier_registry(tenant_id, supplier_id) ON DELETE RESTRICT
);

DROP POLICY IF EXISTS "rls_tenant_isolation_program_supplier_allowlist" ON public.program_supplier_allowlist;
CREATE POLICY rls_tenant_isolation_program_supplier_allowlist ON public.program_supplier_allowlist
  AS RESTRICTIVE FOR ALL TO PUBLIC 
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());

ALTER TABLE public.program_supplier_allowlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_supplier_allowlist FORCE ROW LEVEL SECURITY;
