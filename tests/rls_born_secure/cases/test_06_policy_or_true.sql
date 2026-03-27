-- TEST 6: Policy semantic bypass via OR TRUE
-- Purpose: Catches logical bypass that looks "correct" but breaks isolation
-- Expected: FAIL — POLICY_VIOLATION (enforced by lint_rls_born_secure.sh)

CREATE TABLE public.adapter_registrations (
  tenant_id uuid
);

ALTER TABLE public.adapter_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adapter_registrations FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_adapter_registrations
  ON public.adapter_registrations
  FOR ALL TO PUBLIC
  USING (
    tenant_id = public.current_tenant_id_or_null() OR TRUE
  )
  WITH CHECK (
    tenant_id = public.current_tenant_id_or_null()
  );
