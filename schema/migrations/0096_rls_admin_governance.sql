-- =============================================================================
-- 0096_rls_admin_governance.sql
-- Phase 7: Admin Access & Role Governance
--
-- This migration enforces the trust boundaries required by the dual-policy 
-- RLS architecture, specifically setting the OWNER of the SECURITY DEFINER 
-- tenant context functions to a dedicated, unprivileged reader role.
--
-- Rationale: SECURITY DEFINER functions run with the privileges of their owner.
-- If owned by an admin, any bug in the function could allow privilege escalation.
-- By setting the owner to a heavily restricted role (symphony_reader), we limit
-- the blast radius of any potential exploits in the context-setting logic,
-- strictly bounding the function to only setting the GUC.
-- =============================================================================

BEGIN;

DO $$
BEGIN
    -- 1. Create the dedicated restricted role if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_reader') THEN
        CREATE ROLE symphony_reader NOLOGIN NOINHERIT;
        -- Explicitly revoke all default public schema privileges from the new role
        REVOKE ALL ON SCHEMA public FROM symphony_reader;
    END IF;

    -- 2. Explicitly revoke any potentially dangerous privileges
    -- The reader role only needs enough privilege to execute its own functions
    -- None of these should be granted, but we revoke them defensively
    REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM symphony_reader;
    REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM symphony_reader;
    REVOKE ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public FROM symphony_reader;

    -- 3. Phase 7.1: Set ownership of tenant functions to the restrict role
    -- This binds the SECURITY DEFINER execution context to symphony_reader
    ALTER FUNCTION public.set_tenant_context(uuid) OWNER TO symphony_reader;
    ALTER FUNCTION public.current_tenant_id() OWNER TO symphony_reader;
    ALTER FUNCTION public.current_tenant_id_or_null() OWNER TO symphony_reader;
    
    -- Note: execute permission is already granted TO PUBLIC via 0095

    -- 4. Audit logging
    RAISE NOTICE 'Phase 7 RLS Admin Governance verified: tenant functions owned by symphony_reader';
END $$;

COMMIT;
