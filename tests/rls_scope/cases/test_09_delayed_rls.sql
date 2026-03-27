-- TEST 9: Delayed RLS block (indexes between CREATE TABLE and RLS)
-- Purpose: Proves flexible ordering works — RLS after CREATE TABLE, not immediately
-- Expected: PASS

CREATE TABLE public.adapter_registrations (
  tenant_id uuid
);

CREATE INDEX idx_adapter_tenant ON public.adapter_registrations (tenant_id);

ALTER TABLE public.adapter_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adapter_registrations FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_adapter_registrations
  ON public.adapter_registrations
  AS RESTRICTIVE FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());
