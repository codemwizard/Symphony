-- 0012_revocation_tables.sql
-- Durable revocation tables (append-only)

CREATE TABLE IF NOT EXISTS public.revoked_client_certs (
  cert_fingerprint_sha256 TEXT PRIMARY KEY,
  revoked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  reason_code TEXT,
  revoked_by TEXT
);

CREATE TABLE IF NOT EXISTS public.revoked_tokens (
  token_jti TEXT PRIMARY KEY,
  revoked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  reason_code TEXT,
  revoked_by TEXT
);

CREATE OR REPLACE FUNCTION deny_revocation_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    RAISE EXCEPTION 'revocation tables are append-only'
      USING ERRCODE = 'P0001';
  END;
$$;

DROP TRIGGER IF EXISTS trg_deny_revoked_client_certs_mutation ON public.revoked_client_certs;
CREATE TRIGGER trg_deny_revoked_client_certs_mutation
BEFORE UPDATE OR DELETE ON public.revoked_client_certs
FOR EACH ROW
EXECUTE FUNCTION deny_revocation_mutation();

DROP TRIGGER IF EXISTS trg_deny_revoked_tokens_mutation ON public.revoked_tokens;
CREATE TRIGGER trg_deny_revoked_tokens_mutation
BEFORE UPDATE OR DELETE ON public.revoked_tokens
FOR EACH ROW
EXECUTE FUNCTION deny_revocation_mutation();
