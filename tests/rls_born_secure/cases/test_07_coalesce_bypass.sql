-- TEST 7: Policy using COALESCE indirection
-- Purpose: Catches semantically-always-true policy via COALESCE
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
    tenant_id = COALESCE(public.current_tenant_id_or_null(), tenant_id)
  )
  WITH CHECK (
    tenant_id = COALESCE(public.current_tenant_id_or_null(), tenant_id)
  );
