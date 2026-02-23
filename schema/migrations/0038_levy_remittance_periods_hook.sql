-- TSK-P0-LEVY-004
-- Phase-0 structural hook. ZRA monthly levy return period registry.
-- Runtime reads/writes are prohibited until Phase-2.

CREATE TABLE IF NOT EXISTS public.levy_remittance_periods (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    period_code         CHAR(7)     NOT NULL CHECK (period_code ~ '^\\d{4}-\\d{2}$'),
    jurisdiction_code   CHAR(2)     NOT NULL,
    period_start        DATE        NOT NULL,
    period_end          DATE        NOT NULL CHECK (period_end >= period_start),
    filing_deadline     DATE        CHECK (filing_deadline IS NULL OR filing_deadline >= period_end),
    period_status       TEXT,
    filed_at            TIMESTAMPTZ,
    zra_reference       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT levy_periods_unique_period_jurisdiction UNIQUE (period_code, jurisdiction_code)
);

CREATE INDEX IF NOT EXISTS levy_periods_jurisdiction_idx
    ON public.levy_remittance_periods (jurisdiction_code, period_start DESC);

CREATE INDEX IF NOT EXISTS levy_periods_status_idx
    ON public.levy_remittance_periods (period_status)
    WHERE period_status IS NOT NULL;

COMMENT ON TABLE public.levy_remittance_periods IS
    'Phase-0 structural hook. ZRA monthly MMO levy return period registry. '
    'Empty in Phase-0 and Phase-1. Phase-2 populates rows and links '
    'levy_calculation_records to periods via reporting_period = period_code. '
    'DO NOT create period rows or file returns until Phase-2 ZRA integration is gated.';

COMMENT ON COLUMN public.levy_remittance_periods.filing_deadline IS
    'Phase-0 hook: nullable. ZRA statutory deadline for monthly levy returns is '
    'expected to be the last working day of the following month. '
    'Confirm exact rule with Compliance Counsel before Phase-2 population.';

COMMENT ON COLUMN public.levy_remittance_periods.period_status IS
    'Phase-0 hook: TEXT with no constraint. Phase-2 will add CHECK enforcing '
    'lifecycle values: OPEN, CALCULATING, FILED, ACCEPTED, DISPUTED.';
