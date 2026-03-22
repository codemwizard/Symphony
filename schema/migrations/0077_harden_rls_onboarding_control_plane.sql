-- Migration: 0077_harden_rls_onboarding_control_plane.sql
-- Purpose: Harden RLS policies with NULLIF and administrative bypass for bootstrap.
-- Task: TSK-P1-217-STORES

DO $$ 
BEGIN
    -- Harden tenant_registry policy
    DROP POLICY IF EXISTS rls_tenant_isolation_tenant_registry ON public.tenant_registry;
    CREATE POLICY rls_tenant_isolation_tenant_registry ON public.tenant_registry
        USING (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::uuid
            OR current_setting('app.bypass_rls', true) = 'on'
        );

    -- Harden programme_registry policy
    DROP POLICY IF EXISTS rls_tenant_isolation_programme_registry ON public.programme_registry;
    CREATE POLICY rls_tenant_isolation_programme_registry ON public.programme_registry
        USING (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::uuid
            OR current_setting('app.bypass_rls', true) = 'on'
        );

    -- Harden programme_policy_binding policy
    DROP POLICY IF EXISTS rls_tenant_isolation_programme_policy_binding ON public.programme_policy_binding;
    CREATE POLICY rls_tenant_isolation_programme_policy_binding ON public.programme_policy_binding
        USING (
            tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::uuid
            OR current_setting('app.bypass_rls', true) = 'on'
        );
END $$;
