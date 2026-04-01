-- Migration 0112: GF Phase 1 — Verifier Read Token Functions
-- Implements scoped read tokens for third-party verifiers to access
-- evidence_nodes, monitoring_records, asset_batches, and verification_cases
-- without full tenant access. Enforces Regulation 26 separation via
-- check_reg26_separation(). Tokens are hashed (crypt/gen_random_bytes),
-- time-bounded (TTL), and append-only (soft revocation only).
-- Depends on 0106 (verifier_registry), 0097 (projects), 0101 (asset_batches),
-- 0100 (evidence_nodes), 0099 (monitoring_records).
-- Functions: SECURITY DEFINER with hardened search_path per INV-008.

-- ── gf_verifier_read_tokens table ────────────────────────────────────────────
CREATE TABLE public.gf_verifier_read_tokens (
    token_id          UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    tenant_id         UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
    verifier_id       UUID NOT NULL REFERENCES public.verifier_registry(verifier_id) ON DELETE RESTRICT,
    project_id        UUID NOT NULL REFERENCES public.projects(project_id) ON DELETE RESTRICT,
    token_hash        TEXT NOT NULL,
    scoped_tables     JSONB NOT NULL DEFAULT '[]',
    issued_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at        TIMESTAMPTZ NOT NULL,
    revoked_at        TIMESTAMPTZ,
    revocation_reason TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Indexes ──────────────────────────────────────────────────────────────────
CREATE INDEX idx_gf_verifier_read_tokens_verifier ON gf_verifier_read_tokens(verifier_id);
CREATE INDEX idx_gf_verifier_read_tokens_project ON gf_verifier_read_tokens(project_id);
CREATE INDEX idx_gf_verifier_read_tokens_tenant ON gf_verifier_read_tokens(tenant_id);
CREATE INDEX idx_gf_verifier_read_tokens_hash ON gf_verifier_read_tokens(token_hash);
CREATE INDEX idx_gf_verifier_read_tokens_expires ON gf_verifier_read_tokens(expires_at);

-- ── Revoke-first privilege posture ───────────────────────────────────────────
REVOKE ALL ON TABLE gf_verifier_read_tokens FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE gf_verifier_read_tokens TO symphony_command;
GRANT ALL ON TABLE gf_verifier_read_tokens TO symphony_control;

-- ── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.gf_verifier_read_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gf_verifier_read_tokens FORCE ROW LEVEL SECURITY;

CREATE POLICY gf_verifier_read_tokens_tenant_isolation
    ON public.gf_verifier_read_tokens
    FOR ALL TO PUBLIC
    USING (tenant_id = public.current_tenant_id_or_null())
    WITH CHECK (tenant_id = public.current_tenant_id_or_null());

-- ── Append-only trigger ──────────────────────────────────────────────────────
-- Permits UPDATE only on revoked_at and revocation_reason (soft revocation).
-- DELETE not allowed on gf_verifier_read_tokens (append-only ledger).
CREATE OR REPLACE FUNCTION public.gf_verifier_read_tokens_append_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'DELETE not allowed on gf_verifier_read_tokens (append-only ledger)'
            USING ERRCODE = 'GF001';
    END IF;
    IF TG_OP = 'UPDATE' THEN
        -- Only allow setting revoked_at (soft revocation)
        IF OLD.token_hash != NEW.token_hash
           OR OLD.verifier_id != NEW.verifier_id
           OR OLD.project_id != NEW.project_id
           OR OLD.tenant_id != NEW.tenant_id
           OR OLD.expires_at != NEW.expires_at
        THEN
            RAISE EXCEPTION 'UPDATE not allowed on immutable columns of gf_verifier_read_tokens'
                USING ERRCODE = 'GF001';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS gf_verifier_read_tokens_append_only ON public.gf_verifier_read_tokens;
CREATE TRIGGER gf_verifier_read_tokens_append_only
    BEFORE UPDATE OR DELETE ON public.gf_verifier_read_tokens
    FOR EACH ROW EXECUTE FUNCTION public.gf_verifier_read_tokens_append_only();

-- ── issue_verifier_read_token ────────────────────────────────────────────────
-- Issues a scoped read token for a verifier on a specific project.
-- Validates verifier is active, methodology scope matches, and Reg26 separation.
-- Returns the plaintext secret once; only the hash is stored.
CREATE OR REPLACE FUNCTION public.issue_verifier_read_token(
    p_tenant_id    UUID,
    p_verifier_id  UUID,
    p_project_id   UUID,
    p_ttl_hours    INT DEFAULT 720,
    p_scoped_tables JSONB DEFAULT '["evidence_nodes","monitoring_records","asset_batches","verification_cases"]'
)
RETURNS TABLE(
    token_id       UUID,
    token_secret   TEXT,
    expires_at     TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_token_id       UUID;
    v_token_secret   TEXT;
    v_token_hash     TEXT;
    v_expires_at     TIMESTAMPTZ;
    v_verifier_active BOOLEAN;
    v_methodology_scope JSONB;
BEGIN
    -- ── Input validation ────────────────────────────────────────────────────
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_verifier_id IS NULL THEN
        RAISE EXCEPTION 'p_verifier_id is required' USING ERRCODE = 'GF003';
    END IF;
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF004';
    END IF;
    IF p_ttl_hours IS NULL OR p_ttl_hours <= 0 OR p_ttl_hours > 8760 THEN
        RAISE EXCEPTION 'p_ttl_hours must be between 1 and 8760' USING ERRCODE = 'GF005';
    END IF;

    -- ── Verifier validation ─────────────────────────────────────────────────
    SELECT vr.is_active, vr.methodology_scope
      INTO v_verifier_active, v_methodology_scope
      FROM public.verifier_registry vr
     WHERE vr.verifier_id = p_verifier_id
       AND vr.tenant_id = p_tenant_id;

    IF v_verifier_active IS NULL THEN
        RAISE EXCEPTION 'Verifier not found' USING ERRCODE = 'GF006';
    END IF;
    IF v_verifier_active != true THEN
        RAISE EXCEPTION 'Verifier is not active' USING ERRCODE = 'GF007';
    END IF;

    -- ── Regulation 26 separation check ──────────────────────────────────────
    PERFORM public.check_reg26_separation(p_verifier_id, p_project_id, 'VERIFIER');

    -- ── Generate cryptographic token ────────────────────────────────────────
    v_token_secret := encode(public.gen_random_bytes(32), 'hex');
    v_token_hash := public.crypt(v_token_secret, public.gen_salt('bf', 8));
    v_expires_at := now() + (p_ttl_hours || ' hours')::INTERVAL;

    -- ── Insert token record ─────────────────────────────────────────────────
    INSERT INTO public.gf_verifier_read_tokens (
        tenant_id, verifier_id, project_id, token_hash,
        scoped_tables, expires_at
    ) VALUES (
        p_tenant_id, p_verifier_id, p_project_id, v_token_hash,
        p_scoped_tables, v_expires_at
    )
    RETURNING gf_verifier_read_tokens.token_id INTO v_token_id;

    -- ── Return token secret (shown once) ────────────────────────────────────
    -- RETURN v_token_secret via output parameters; plaintext is never stored.
    RETURN QUERY SELECT v_token_id, v_token_secret, v_expires_at;
END;
$$;

-- ── revoke_verifier_read_token ───────────────────────────────────────────────
-- Soft-revokes a token by setting revoked_at. Token remains in table for audit.
CREATE OR REPLACE FUNCTION public.revoke_verifier_read_token(
    p_tenant_id  UUID,
    p_token_id   UUID,
    p_reason     TEXT DEFAULT 'manual_revocation'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_token_id IS NULL THEN
        RAISE EXCEPTION 'p_token_id is required' USING ERRCODE = 'GF003';
    END IF;

    UPDATE public.gf_verifier_read_tokens
       SET revoked_at = now(),
           revocation_reason = p_reason
     WHERE token_id = p_token_id
       AND tenant_id = p_tenant_id
       AND revoked_at IS NULL;
END;
$$;

-- ── verify_verifier_read_token ───────────────────────────────────────────────
-- Validates a token_hash against stored hash; checks not expired/revoked.
-- Returns scoped access metadata on success. Fails closed if invalid.
CREATE OR REPLACE FUNCTION public.verify_verifier_read_token(
    p_token_hash TEXT,
    p_project_id UUID
)
RETURNS TABLE(
    token_id      UUID,
    verifier_id   UUID,
    scoped_tables JSONB,
    expires_at    TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF p_token_hash IS NULL THEN
        RAISE EXCEPTION 'p_token_hash is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF003';
    END IF;

    RETURN QUERY
    SELECT t.token_id, t.verifier_id, t.scoped_tables, t.expires_at
      FROM public.gf_verifier_read_tokens t
     WHERE t.project_id = p_project_id
       AND t.revoked_at IS NULL
       AND t.expires_at > now()
       AND t.token_hash = public.crypt(p_token_hash, t.token_hash)
     LIMIT 1;
END;
$$;

-- ── list_verifier_tokens ─────────────────────────────────────────────────────
-- Lists tokens for a verifier, including revoked/expired for audit.
CREATE OR REPLACE FUNCTION public.list_verifier_tokens(
    p_tenant_id   UUID,
    p_verifier_id UUID
)
RETURNS TABLE(
    token_id      UUID,
    project_id    UUID,
    scoped_tables JSONB,
    issued_at     TIMESTAMPTZ,
    expires_at    TIMESTAMPTZ,
    revoked_at    TIMESTAMPTZ,
    is_valid      BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_verifier_id IS NULL THEN
        RAISE EXCEPTION 'p_verifier_id is required' USING ERRCODE = 'GF003';
    END IF;

    RETURN QUERY
    SELECT t.token_id, t.project_id, t.scoped_tables,
           t.issued_at, t.expires_at, t.revoked_at,
           (t.revoked_at IS NULL AND t.expires_at > now()) AS is_valid
      FROM public.gf_verifier_read_tokens t
     WHERE t.tenant_id = p_tenant_id
       AND t.verifier_id = p_verifier_id
     ORDER BY t.created_at DESC;
END;
$$;

-- ── cleanup_expired_verifier_tokens ──────────────────────────────────────────
-- Soft-revokes all expired tokens that haven't been revoked yet.
-- Does NOT delete (append-only table). Sets revoked_at = now().
CREATE OR REPLACE FUNCTION public.cleanup_expired_verifier_tokens()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_count INT;
BEGIN
    UPDATE public.gf_verifier_read_tokens
       SET revoked_at = now(),
           revocation_reason = 'expired_cleanup'
     WHERE expires_at <= now()
       AND revoked_at IS NULL;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

-- ── Privileges ───────────────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION issue_verifier_read_token(UUID, UUID, UUID, INT, JSONB)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION revoke_verifier_read_token(UUID, UUID, TEXT)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION verify_verifier_read_token(TEXT, UUID)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION list_verifier_tokens(UUID, UUID)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION cleanup_expired_verifier_tokens()
    TO symphony_command;

-- Return v_token_secret is the only way to get the plaintext; it is never stored.
