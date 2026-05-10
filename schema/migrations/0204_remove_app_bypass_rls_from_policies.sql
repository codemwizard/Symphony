-- Migration: 0204_remove_app_bypass_rls_from_policies.sql
-- Purpose: Remove app.bypass_rls predicate from RLS policies on tenant-isolated tables.
--          This is a forward-only migration that drops and recreates the affected policies
--          using only app.current_tenant_id for tenant isolation.
-- Task: TSK-P2-RLS-BYPASS-004
-- Security: Removes a policy escape hatch that weakened tenant isolation guarantees.

DO $$
BEGIN
    -- Recreate tenant_registry policy WITHOUT bypass_rls
    DROP POLICY IF EXISTS rls_tenant_isolation_tenant_registry ON public.tenant_registry;
    CREATE POLICY rls_tenant_isolation_tenant_registry ON public.tenant_registry
        USING (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::uuid
        );

    -- Recreate programme_registry policy WITHOUT bypass_rls
    DROP POLICY IF EXISTS rls_tenant_isolation_programme_registry ON public.programme_registry;
    CREATE POLICY rls_tenant_isolation_programme_registry ON public.programme_registry
        USING (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::uuid
        );

    -- Recreate programme_policy_binding policy WITHOUT bypass_rls
    DROP POLICY IF EXISTS rls_tenant_isolation_programme_policy_binding ON public.programme_policy_binding;
    CREATE POLICY rls_tenant_isolation_programme_policy_binding ON public.programme_policy_binding
        USING (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::uuid
        );
END $$;
