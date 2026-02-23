-- TSK-P0-KYC-004: Phase-0 governance declaration hook for KYC retention policy.

CREATE TABLE IF NOT EXISTS public.kyc_retention_policy (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    jurisdiction_code CHAR(2) NOT NULL,
    retention_class TEXT NOT NULL,
    statutory_reference TEXT NOT NULL,
    retention_years INTEGER NOT NULL CHECK (retention_years > 0),
    description TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT kyc_retention_unique_active_class UNIQUE (jurisdiction_code, retention_class)
);

CREATE OR REPLACE RULE kyc_retention_policy_no_update AS
    ON UPDATE TO public.kyc_retention_policy DO INSTEAD NOTHING;

CREATE OR REPLACE RULE kyc_retention_policy_no_delete AS
    ON DELETE TO public.kyc_retention_policy DO INSTEAD NOTHING;

COMMENT ON TABLE public.kyc_retention_policy IS
    'Phase-0 governance declaration. Immutable registry of KYC evidence retention '
    'policies by jurisdiction and retention class. Append-only: UPDATE and DELETE '
    'are rejected by rules. The Zambia FIC Act row is seeded in Phase-0 because '
    'the 10-year obligation is a confirmed statutory fact.';

COMMENT ON RULE kyc_retention_policy_no_update ON public.kyc_retention_policy IS
    'Immutability enforcement. KYC retention policies are statutory facts. '
    'To supersede a policy, add a new row with updated parameters.';

INSERT INTO public.kyc_retention_policy (
    jurisdiction_code,
    retention_class,
    statutory_reference,
    retention_years,
    description
)
SELECT
    'ZM',
    'FIC_AML_CUSTOMER_ID',
    'Financial Intelligence Centre Act, Chapter 87 of the Laws of Zambia, Section 21 — Customer Identification Records',
    10,
    'KYC verification evidence for Zambian members under FIC Act AML obligations. '
    'Includes verification hash, outcome code, provider reference, and signing '
    'metadata. Does not include raw identity documents (held by licensed provider). '
    'Retention period: 10 years from date of verification.'
WHERE NOT EXISTS (
    SELECT 1
    FROM public.kyc_retention_policy
    WHERE jurisdiction_code = 'ZM'
      AND retention_class = 'FIC_AML_CUSTOMER_ID'
);
