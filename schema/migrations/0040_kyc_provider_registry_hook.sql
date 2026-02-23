-- TSK-P0-KYC-001
-- Phase-0 structural hook. No runtime reads permitted until Phase-2.

CREATE TABLE IF NOT EXISTS public.kyc_provider_registry (
    id                                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_code                       TEXT        NOT NULL,
    provider_name                       TEXT        NOT NULL,
    jurisdiction_code                   CHAR(2)     NOT NULL,
    public_key_pem                      TEXT,
    signing_algorithm                   TEXT,
    boz_licence_reference               TEXT,
    is_active                           BOOLEAN     DEFAULT NULL,
    active_from                         DATE,
    active_to                           DATE        CHECK (active_to IS NULL OR active_from IS NULL OR active_to >= active_from),
    created_at                          TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by                          TEXT        NOT NULL DEFAULT current_user,
    updated_at                          TIMESTAMPTZ,
    CONSTRAINT kyc_provider_unique_code UNIQUE (provider_code),
    CONSTRAINT kyc_provider_unique_active_per_jurisdiction UNIQUE (jurisdiction_code, provider_code)
);

CREATE UNIQUE INDEX IF NOT EXISTS kyc_provider_active_idx
    ON public.kyc_provider_registry (jurisdiction_code, provider_code)
    WHERE active_to IS NULL AND is_active IS NOT FALSE;

CREATE INDEX IF NOT EXISTS kyc_provider_jurisdiction_idx
    ON public.kyc_provider_registry (jurisdiction_code, active_from DESC);

COMMENT ON TABLE public.kyc_provider_registry IS
    'Phase-0 structural hook. Registry of licensed external KYC providers whose '
    'verification hashes Symphony accepts. Symphony never calls providers directly. '
    'Phase-2 populates rows once Compliance confirms which providers are '
    'BoZ-recognised. DO NOT read this table in application runtime until Phase-2.';

COMMENT ON COLUMN public.kyc_provider_registry.public_key_pem IS
    'Phase-0 hook: nullable. Provider public key for verifying hash signatures. '
    'Phase-2 will enforce NOT NULL and validate key format on insert. '
    'Confirm exact key format (Ed25519 vs ECDSA) with provider before Phase-2 population.';

COMMENT ON COLUMN public.kyc_provider_registry.signing_algorithm IS
    'Phase-0 hook: TEXT, no constraint. Phase-2 will add CHECK enforcing '
    'accepted values: Ed25519, ECDSA-P256, HMAC-SHA256.';
