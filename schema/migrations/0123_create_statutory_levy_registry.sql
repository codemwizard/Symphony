-- Migration 0123: Create statutory_levy_registry table
-- This table tracks statutory levy rates over time with temporal uniqueness constraints

CREATE TABLE IF NOT EXISTS public.statutory_levy_registry (
    levy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    levy_code VARCHAR NOT NULL,
    jurisdiction_code VARCHAR NOT NULL,
    effective_from TIMESTAMPTZ NOT NULL,
    effective_to TIMESTAMPTZ,
    rate_value NUMERIC NOT NULL,
    CONSTRAINT statutory_levy_registry_unique_period UNIQUE (levy_code, jurisdiction_code, effective_from)
);

-- Revoke all privileges from PUBLIC
REVOKE ALL ON TABLE public.statutory_levy_registry FROM PUBLIC;

-- Grant SELECT to symphony_command
GRANT SELECT ON TABLE public.statutory_levy_registry TO symphony_command;

-- Grant ALL to symphony_control
GRANT ALL ON TABLE public.statutory_levy_registry TO symphony_control;

COMMENT ON TABLE public.statutory_levy_registry IS 'Stores statutory levy rates with temporal versioning via effective_from/effective_to columns and UNIQUE constraint on (levy_code, jurisdiction_code, effective_from) to prevent overlapping rate periods';

-- Append-only trigger function
CREATE OR REPLACE FUNCTION public.statutory_levy_registry_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'GF050: statutory_levy_registry is append-only, UPDATE/DELETE not allowed' USING ERRCODE = 'GF050';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach trigger as BEFORE UPDATE OR DELETE
CREATE TRIGGER statutory_levy_registry_append_only_trigger
BEFORE UPDATE OR DELETE ON public.statutory_levy_registry
FOR EACH ROW EXECUTE FUNCTION public.statutory_levy_registry_append_only();

