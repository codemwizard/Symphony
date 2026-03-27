-- Migration 0093: Green Finance Phase 1 Function - Verifier Read Token
-- SECURITY DEFINER functions with hardened search_path

-- Create verifier read tokens table
CREATE TABLE IF NOT EXISTS public.gf_verifier_read_tokens (
    -- Primary identifier
    token_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Token ownership and scope
    verifier_id UUID NOT NULL REFERENCES public.verifier_registry(verifier_id) ON DELETE RESTRICT,
    project_id UUID NOT NULL REFERENCES public.projects(project_id) ON DELETE RESTRICT,
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    
    -- Token security
    token_hash TEXT NOT NULL UNIQUE,
    scoped_tables JSONB NOT NULL,
    
    -- Timestamps
    issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ NULL,
    
    -- Audit trail
    issued_by TEXT NOT NULL DEFAULT current_user
);

-- Indexes for verifier read tokens
CREATE INDEX IF NOT EXISTS idx_gf_verifier_read_tokens_verifier ON gf_verifier_read_tokens(verifier_id);
CREATE INDEX IF NOT EXISTS idx_gf_verifier_read_tokens_project ON gf_verifier_read_tokens(project_id);
CREATE INDEX IF NOT EXISTS idx_gf_verifier_read_tokens_tenant ON gf_verifier_read_tokens(tenant_id);
CREATE INDEX IF NOT EXISTS idx_gf_verifier_read_tokens_hash ON gf_verifier_read_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_gf_verifier_read_tokens_expires ON gf_verifier_read_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_gf_verifier_read_tokens_revoked ON gf_verifier_read_tokens(revoked_at) WHERE revoked_at IS NOT NULL;

-- RLS for verifier read tokens (canonical 0059 pattern)
ALTER TABLE public.gf_verifier_read_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gf_verifier_read_tokens FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_gf_verifier_read_tokens ON public.gf_verifier_read_tokens
    FOR ALL TO PUBLIC
    USING (tenant_id = public.current_tenant_id_or_null())
    WITH CHECK (tenant_id = public.current_tenant_id_or_null());

-- Append-only trigger (no DELETE, limited UPDATE for revocation)
CREATE OR REPLACE FUNCTION gf_verifier_read_tokens_append_only_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'GF001', 'gf_verifier_read_tokens is append-only - DELETE operations not allowed';
    END IF;
    
    IF TG_OP = 'UPDATE' THEN
        -- Only allow setting revoked_at for revocation
        IF OLD.revoked_at IS NULL AND NEW.revoked_at IS NOT NULL THEN
            -- Allow revocation
            NEW.revoked_at = NOW();
            RETURN NEW;
        ELSIF OLD.revoked_at IS NOT NULL THEN
            -- Allow updates to revoked tokens (but not changing revoked_at back to NULL)
            IF NEW.revoked_at IS NULL THEN
                RAISE EXCEPTION 'GF002', 'Cannot un-revoke a token';
            END IF;
            RETURN NEW;
        ELSE
            RAISE EXCEPTION 'GF003', 'Only revocation updates allowed on gf_verifier_read_tokens';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER gf_verifier_read_tokens_append_only
    BEFORE UPDATE OR DELETE ON gf_verifier_read_tokens
    FOR EACH ROW
    EXECUTE FUNCTION gf_verifier_read_tokens_append_only_trigger();

-- Function to issue verifier read token
CREATE OR REPLACE FUNCTION issue_verifier_read_token(
    p_verifier_id UUID,
    p_project_id UUID,
    p_ttl_hours INTEGER DEFAULT 72
)
RETURNS TEXT AS $$
DECLARE
    v_token_id UUID;
    v_token_secret TEXT;
    v_token_hash TEXT;
    v_verifier_exists BOOLEAN;
    v_verifier_active BOOLEAN;
    v_verifier_scope JSONB;
    v_project_exists BOOLEAN;
    v_project_methodology UUID;
    v_tenant_id UUID;
BEGIN
    -- Validate inputs
    IF p_verifier_id IS NULL THEN
        RAISE EXCEPTION 'GF004', 'Verifier ID is required';
    END IF;
    
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'GF005', 'Project ID is required';
    END IF;
    
    IF p_ttl_hours IS NULL OR p_ttl_hours <= 0 OR p_ttl_hours > 8760 THEN
        RAISE EXCEPTION 'GF006', 'TTL hours must be between 1 and 8760 (1 year)';
    END IF;
    
    -- Check if verifier exists and is active
    SELECT EXISTS (
        SELECT 1 FROM verifier_registry
        WHERE verifier_id = p_verifier_id
    ), is_active, methodology_scope, tenant_id
    INTO v_verifier_exists, v_verifier_active, v_verifier_scope, v_tenant_id
    FROM verifier_registry
    WHERE verifier_id = p_verifier_id;
    
    IF NOT v_verifier_exists THEN
        RAISE EXCEPTION 'GF007', 'Verifier not found';
    END IF;
    
    IF NOT v_verifier_active THEN
        RAISE EXCEPTION 'GF008', 'Verifier is not active';
    END IF;
    
    -- Check if project exists and get methodology
    SELECT EXISTS (
        SELECT 1 FROM projects
        WHERE project_id = p_project_id
    ), methodology_version_id
    INTO v_project_exists, v_project_methodology
    FROM projects
    WHERE project_id = p_project_id;
    
    IF NOT v_project_exists THEN
        RAISE EXCEPTION 'GF009', 'Project not found';
    END IF;
    
    -- Check if verifier's methodology scope includes the project's methodology
    IF NOT (v_verifier_scope @> jsonb_build_array(v_project_methodology)) THEN
        RAISE EXCEPTION 'GF010', 'Verifier methodology scope does not include project methodology';
    END IF;
    
    -- CRITICAL: Check Regulation 26 separation-of-duties
    PERFORM check_reg26_separation(p_verifier_id, p_project_id, 'VERIFIER');
    
    -- Generate cryptographically random token secret
    v_token_secret := encode(gen_random_bytes(32), 'base64');
    
    -- Hash the token for storage
    v_token_hash := crypt(v_token_secret, gen_salt('bf', 12));
    
    -- Define scoped tables (Phase 1 scope)
    INSERT INTO gf_verifier_read_tokens (
        verifier_id,
        project_id,
        tenant_id,
        token_hash,
        scoped_tables,
        expires_at,
        issued_by
    ) VALUES (
        p_verifier_id,
        p_project_id,
        v_tenant_id,
        v_token_hash,
        '["evidence_nodes","monitoring_records","asset_batches","verification_cases"]'::jsonb,
        now() + (p_ttl_hours || ' hours')::interval,
        current_user
    ) RETURNING token_id INTO v_token_id;
    
    -- Return the raw token secret (shown once, never stored)
    RETURN v_token_secret;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to revoke verifier read token
CREATE OR REPLACE FUNCTION revoke_verifier_read_token(
    p_token_hash TEXT
)
RETURNS void AS $$
DECLARE
    v_token_exists BOOLEAN;
    v_already_revoked BOOLEAN;
BEGIN
    -- Validate input
    IF p_token_hash IS NULL OR trim(p_token_hash) = '' THEN
        RAISE EXCEPTION 'GF011', 'Token hash is required';
    END IF;
    
    -- Check if token exists and get revocation status
    SELECT EXISTS (
        SELECT 1 FROM gf_verifier_read_tokens
        WHERE token_hash = p_token_hash
    ), EXISTS (
        SELECT 1 FROM gf_verifier_read_tokens
        WHERE token_hash = p_token_hash
        AND revoked_at IS NOT NULL
    ) INTO v_token_exists, v_already_revoked;
    
    IF NOT v_token_exists THEN
        RAISE EXCEPTION 'GF012', 'Token not found';
    END IF;
    
    IF v_already_revoked THEN
        RAISE EXCEPTION 'GF013', 'Token already revoked';
    END IF;
    
    -- Revoke the token (append-only update)
    UPDATE gf_verifier_read_tokens
    SET revoked_at = now()
    WHERE token_hash = p_token_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to verify token (for Phase 2 API layer)
CREATE OR REPLACE FUNCTION verify_verifier_read_token(
    p_token_secret TEXT
)
RETURNS TABLE (
    token_id UUID,
    verifier_id UUID,
    project_id UUID,
    tenant_id UUID,
    scoped_tables JSONB,
    issued_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    is_valid BOOLEAN
) AS $$
DECLARE
    v_token_found BOOLEAN;
BEGIN
    -- Validate input
    IF p_token_secret IS NULL OR trim(p_token_secret) = '' THEN
        RETURN QUERY SELECT NULL::UUID, NULL::UUID, NULL::UUID, NULL::UUID, NULL::jsonb, NULL::timestamptz, NULL::timestamptz, false;
        RETURN;
    END IF;
    
    -- Try to find token by checking hash against all stored hashes
    RETURN QUERY
    SELECT 
        token_id,
        verifier_id,
        project_id,
        tenant_id,
        scoped_tables,
        issued_at,
        expires_at,
        CASE 
            WHEN revoked_at IS NOT NULL THEN false
            WHEN expires_at < now() THEN false
            ELSE true
        END as is_valid
    FROM gf_verifier_read_tokens
    WHERE token_hash = crypt(p_token_secret, token_hash)
    AND revoked_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to list verifier tokens (admin function)
CREATE OR REPLACE FUNCTION list_verifier_tokens(
    p_verifier_id UUID DEFAULT NULL,
    p_project_id UUID DEFAULT NULL,
    p_include_revoked BOOLEAN DEFAULT false,
    p_limit INT DEFAULT 100,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    token_id UUID,
    verifier_id UUID,
    project_id UUID,
    tenant_id UUID,
    issued_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    issued_by TEXT,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        token_id,
        verifier_id,
        project_id,
        tenant_id,
        issued_at,
        expires_at,
        revoked_at,
        issued_by,
        CASE 
            WHEN revoked_at IS NOT NULL THEN false
            WHEN expires_at < now() THEN false
            ELSE true
        END as is_active
    FROM gf_verifier_read_tokens
    WHERE (p_verifier_id IS NULL OR verifier_id = p_verifier_id)
    AND (p_project_id IS NULL OR project_id = p_project_id)
    AND (p_include_revoked = true OR revoked_at IS NULL)
    ORDER BY issued_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function to clean up expired tokens
CREATE OR REPLACE FUNCTION cleanup_expired_verifier_tokens()
RETURNS INT AS $$
DECLARE
    v_deleted_count INT;
BEGIN
    -- Soft-delete expired tokens by setting revoked_at
    UPDATE gf_verifier_read_tokens
    SET revoked_at = now(),
        issued_by = 'system_cleanup'
    WHERE expires_at < now()
    AND revoked_at IS NULL;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Revoke-first privilege posture
REVOKE ALL ON TABLE gf_verifier_read_tokens FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE ON TABLE gf_verifier_read_tokens TO authenticated_role;
GRANT ALL ON TABLE gf_verifier_read_tokens TO system_role;
GRANT EXECUTE ON FUNCTION issue_verifier_read_token TO authenticated_role;
GRANT EXECUTE ON FUNCTION issue_verifier_read_token TO system_role;
GRANT EXECUTE ON FUNCTION revoke_verifier_read_token TO authenticated_role;
GRANT EXECUTE ON FUNCTION revoke_verifier_read_token TO system_role;
GRANT EXECUTE ON FUNCTION verify_verifier_read_token TO authenticated_role;
GRANT EXECUTE ON FUNCTION verify_verifier_read_token TO system_role;
GRANT EXECUTE ON FUNCTION list_verifier_tokens TO authenticated_role;
GRANT EXECUTE ON FUNCTION list_verifier_tokens TO system_role;
GRANT EXECUTE ON FUNCTION cleanup_expired_verifier_tokens TO system_role;
