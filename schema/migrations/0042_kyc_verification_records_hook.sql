-- TSK-P0-KYC-002
-- Phase-0 structural hook. No runtime writes until Phase-2.

CREATE TABLE IF NOT EXISTS public.kyc_verification_records (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id               UUID        NOT NULL
                                REFERENCES public.tenant_members(member_id)
                                ON DELETE RESTRICT,
    provider_id             UUID
                                REFERENCES public.kyc_provider_registry(id)
                                ON DELETE RESTRICT,
    provider_code           TEXT,
    outcome                 TEXT,
    verification_method     TEXT,
    verification_hash       TEXT,
    hash_algorithm          TEXT,
    provider_signature      TEXT,
    provider_key_version    TEXT,
    provider_reference      TEXT,
    jurisdiction_code       CHAR(2),
    document_type           TEXT,
    verified_at_provider    TIMESTAMPTZ,
    anchored_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    retention_class         TEXT        NOT NULL
                                DEFAULT 'FIC_AML_CUSTOMER_ID'
                                CHECK (retention_class = 'FIC_AML_CUSTOMER_ID'),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by              TEXT        NOT NULL DEFAULT current_user
);

CREATE INDEX IF NOT EXISTS kyc_verification_member_idx
    ON public.kyc_verification_records (member_id, anchored_at DESC);

CREATE INDEX IF NOT EXISTS kyc_verification_provider_idx
    ON public.kyc_verification_records (provider_id)
    WHERE provider_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS kyc_verification_jurisdiction_outcome_idx
    ON public.kyc_verification_records (jurisdiction_code, outcome)
    WHERE outcome IS NOT NULL;

COMMENT ON TABLE public.kyc_verification_records IS
    'Phase-0 structural hook. Anchors cryptographic evidence that an external '
    'KYC provider verified a Symphony member identity. Symphony never holds raw '
    'identity documents. Retention class: FIC_AML_CUSTOMER_ID (10 years). '
    'Phase-2 KYC hash bridge endpoint writes to this table.';

COMMENT ON COLUMN public.kyc_verification_records.verification_hash IS
    'Provider-signed hash of the verification outcome. Symphony stores the hash '
    'as evidence, not identity documents.';

COMMENT ON COLUMN public.kyc_verification_records.retention_class IS
    'Retention class enforced at schema level. Must be FIC_AML_CUSTOMER_ID.';
