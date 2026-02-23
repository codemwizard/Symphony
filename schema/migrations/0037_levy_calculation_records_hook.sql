-- TSK-P0-LEVY-003
-- Phase-0 structural hook. Phase-2 calculation logic writes to this table.
-- Runtime reads/writes are prohibited until Phase-2.

CREATE TABLE IF NOT EXISTS public.levy_calculation_records (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    instruction_id          UUID        NOT NULL
                                REFERENCES public.ingress_attestations(attestation_id)
                                ON DELETE RESTRICT,
    levy_rate_id            UUID        REFERENCES public.levy_rates(id)
                                ON DELETE RESTRICT,
    jurisdiction_code       CHAR(2),
    taxable_amount_minor    BIGINT      CHECK (taxable_amount_minor IS NULL OR taxable_amount_minor >= 0),
    levy_amount_pre_cap     BIGINT      CHECK (levy_amount_pre_cap IS NULL OR levy_amount_pre_cap >= 0),
    cap_applied_minor       BIGINT      CHECK (cap_applied_minor IS NULL OR cap_applied_minor >= 0),
    levy_amount_final       BIGINT      CHECK (levy_amount_final IS NULL OR levy_amount_final >= 0),
    currency_code           CHAR(3),
    reporting_period        CHAR(7)     CHECK (reporting_period IS NULL OR reporting_period ~ '^\\d{4}-\\d{2}$'),
    levy_status             TEXT,
    calculated_at           TIMESTAMPTZ,
    calculated_by_version   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT levy_calculation_one_per_instruction UNIQUE (instruction_id)
);

CREATE INDEX IF NOT EXISTS levy_calc_reporting_period_idx
    ON public.levy_calculation_records (reporting_period, jurisdiction_code)
    WHERE reporting_period IS NOT NULL;

CREATE INDEX IF NOT EXISTS levy_calc_status_idx
    ON public.levy_calculation_records (levy_status)
    WHERE levy_status IS NOT NULL;

COMMENT ON TABLE public.levy_calculation_records IS
    'Phase-0 structural hook. Phase-2 MMO Levy calculation engine writes one row '
    'per levy-applicable instruction. Empty in Phase-0 and Phase-1. '
    'DO NOT write to this table until Phase-2 calculation logic is gated.';

COMMENT ON COLUMN public.levy_calculation_records.levy_status IS
    'Phase-0 hook: TEXT with no constraint. Phase-2 will add CHECK constraint '
    'enforcing valid lifecycle values: CALCULATED, BATCHED, REMITTED, DISPUTED.';
