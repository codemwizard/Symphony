-- TSK-P0-LEVY-001
-- Phase-0 structural hook. No runtime reads permitted until Phase-2.

CREATE TABLE IF NOT EXISTS public.levy_rates (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Jurisdiction this rate applies to. Initially 'ZM' only.
    jurisdiction_code   CHAR(2)     NOT NULL,
    -- Finance Act or statutory instrument that introduced this rate.
    -- Nullable in Phase-0: Phase-2 will enforce NOT NULL once ingestion exists.
    statutory_reference TEXT,
    -- Rate expressed in basis points (bps). 20 bps = 0.20%.
    -- Zambia Mobile Money Transaction Levy 2023: 20 bps, capped per transaction.
    rate_bps            INTEGER     NOT NULL CHECK (rate_bps >= 0 AND rate_bps <= 10000),
    -- Per-transaction cap in the smallest currency unit (ngwee for ZMW).
    -- NULL means no cap applies. Zambia 2023: cap exists, value to be confirmed
    -- with Compliance before Phase-2 population.
    cap_amount_minor    BIGINT      CHECK (cap_amount_minor IS NULL OR cap_amount_minor > 0),
    -- Currency this cap is denominated in.
    cap_currency_code   CHAR(3),
    -- Inclusive start of validity window (Finance Act effective date).
    effective_from      DATE        NOT NULL,
    -- Inclusive end of validity window. NULL = currently in force.
    effective_to        DATE        CHECK (effective_to IS NULL OR effective_to >= effective_from),
    -- Audit fields.
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by          TEXT        NOT NULL DEFAULT current_user,
    CONSTRAINT levy_rates_cap_currency_required
        CHECK (cap_amount_minor IS NULL OR cap_currency_code IS NOT NULL)
);

-- Only one currently-in-force rate per jurisdiction (effective_to IS NULL).
CREATE UNIQUE INDEX IF NOT EXISTS levy_rates_one_active_per_jurisdiction
    ON public.levy_rates (jurisdiction_code)
    WHERE effective_to IS NULL;

-- Standard lookup index.
CREATE INDEX IF NOT EXISTS levy_rates_jurisdiction_date_idx
    ON public.levy_rates (jurisdiction_code, effective_from DESC);

COMMENT ON TABLE public.levy_rates IS
    'Phase-0 structural hook. Versioned registry of statutory MMO levy rates by '
    'jurisdiction. Populated in Phase-2 once Compliance confirms exact statutory '
    'values. DO NOT read this table in application runtime until Phase-2.';

COMMENT ON COLUMN public.levy_rates.rate_bps IS
    'Rate in basis points. 20 = 0.20%. Zambia MMO Levy 2023 = 20 bps.';

COMMENT ON COLUMN public.levy_rates.cap_amount_minor IS
    'Per-transaction cap in smallest currency unit (e.g. ngwee). '
    'NULL = no cap. Confirm exact ZMW cap with Compliance Counsel before Phase-2 population.';
