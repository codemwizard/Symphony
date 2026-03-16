-- Migration: 0076_onboarding_control_plane.sql
-- Purpose: Persist tenant registry, programme lifecycle, and policy binding
--          as governed onboarding control-plane state.
-- Task: TSK-P1-217
-- Depends on: 0075 (supplier_registry_and_programme_allowlist)


-- ─── tenant_registry ───────────────────────────────────────────────
-- Canonical source of known tenants for the hardened profile.
-- Replaces SYMPHONY_KNOWN_TENANTS as the operational source of truth.
CREATE TABLE IF NOT EXISTS public.tenant_registry (
    id              uuid PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    tenant_id       uuid NOT NULL UNIQUE,
    tenant_key      text NOT NULL UNIQUE,
    display_name    text NOT NULL,
    status          text NOT NULL DEFAULT 'ACTIVE'
                    CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')),
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

DROP POLICY IF EXISTS rls_tenant_isolation_tenant_registry ON public.tenant_registry;
CREATE POLICY rls_tenant_isolation_tenant_registry ON public.tenant_registry
    USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);
ALTER TABLE public.tenant_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_registry FORCE ROW LEVEL SECURITY;

-- ─── programme_registry ────────────────────────────────────────────
-- Programme lifecycle with governed state transitions.
CREATE TABLE IF NOT EXISTS public.programme_registry (
    id              uuid PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    tenant_id       uuid NOT NULL REFERENCES public.tenant_registry(tenant_id),
    programme_key   text NOT NULL,
    display_name    text NOT NULL,
    status          text NOT NULL DEFAULT 'CREATED'
                    CHECK (status IN ('CREATED', 'ACTIVE', 'SUSPENDED', 'CLOSED')),
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, programme_key)
);

DROP POLICY IF EXISTS rls_tenant_isolation_programme_registry ON public.programme_registry;
CREATE POLICY rls_tenant_isolation_programme_registry ON public.programme_registry
    USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);
ALTER TABLE public.programme_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.programme_registry FORCE ROW LEVEL SECURITY;

-- ─── programme_policy_binding ──────────────────────────────────────
-- Links programmes to policy identifiers. One active binding per programme.
CREATE TABLE IF NOT EXISTS public.programme_policy_binding (
    id              uuid PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    programme_id    uuid NOT NULL REFERENCES public.programme_registry(id),
    tenant_id       uuid NOT NULL REFERENCES public.tenant_registry(tenant_id),
    policy_code     text NOT NULL,
    version         integer NOT NULL DEFAULT 1,
    is_active       boolean NOT NULL DEFAULT true,
    bound_at        timestamptz NOT NULL DEFAULT now(),
    UNIQUE (programme_id, is_active) -- only one active binding per programme
);

DROP POLICY IF EXISTS rls_tenant_isolation_programme_policy_binding ON public.programme_policy_binding;
CREATE POLICY rls_tenant_isolation_programme_policy_binding ON public.programme_policy_binding
    USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);
ALTER TABLE public.programme_policy_binding ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.programme_policy_binding FORCE ROW LEVEL SECURITY;

-- ─── Migration bookkeeping ─────────────────────────────────────────
INSERT INTO public.schema_migrations (version, description, installed_by)
VALUES ('0076', 'onboarding_control_plane: tenant_registry, programme_registry, programme_policy_binding', current_user);

