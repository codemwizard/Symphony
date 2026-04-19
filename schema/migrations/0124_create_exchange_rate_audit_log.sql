-- Migration 0124: Create exchange_rate_audit_log table
-- This table tracks exchange rates with high precision for financial audit compliance

CREATE TABLE IF NOT EXISTS public.exchange_rate_audit_log (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_currency VARCHAR NOT NULL,
    to_currency VARCHAR NOT NULL,
    rate_value NUMERIC(18,8) NOT NULL,
    effective_from TIMESTAMPTZ NOT NULL,
    CONSTRAINT exchange_rate_audit_log_unique_period UNIQUE (from_currency, to_currency, effective_from)
);

-- Revoke all privileges from PUBLIC
REVOKE ALL ON TABLE public.exchange_rate_audit_log FROM PUBLIC;

-- Grant SELECT to symphony_command
GRANT SELECT ON TABLE public.exchange_rate_audit_log TO symphony_command;

-- Grant ALL to symphony_control
GRANT ALL ON TABLE public.exchange_rate_audit_log TO symphony_control;

COMMENT ON TABLE public.exchange_rate_audit_log IS 'Stores exchange rates with NUMERIC(18,8) precision for financial audit compliance, with UNIQUE constraint on (from_currency, to_currency, effective_from) to prevent overlapping rate periods';

-- Append-only trigger function
CREATE OR REPLACE FUNCTION public.exchange_rate_audit_log_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'GF051: exchange_rate_audit_log is append-only, UPDATE/DELETE not allowed' USING ERRCODE = 'GF051';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach trigger as BEFORE UPDATE OR DELETE
CREATE TRIGGER exchange_rate_audit_log_append_only_trigger
BEFORE UPDATE OR DELETE ON public.exchange_rate_audit_log
FOR EACH ROW EXECUTE FUNCTION public.exchange_rate_audit_log_append_only();

