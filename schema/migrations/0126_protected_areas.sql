-- Migration 0126: Create protected_areas table
-- This table stores protected area polygons with PostGIS geometry for DNSH compliance checking

CREATE TABLE IF NOT EXISTS public.protected_areas (
    protected_area_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_version_id UUID NOT NULL,
    geom geometry(POLYGON, 4326) NOT NULL,
    effective_from TIMESTAMPTZ NOT NULL,
    CONSTRAINT protected_areas_fk_source_version FOREIGN KEY (source_version_id) REFERENCES factor_registry(factor_id)
);

-- Create GIST index on geom column for spatial queries
CREATE INDEX idx_protected_areas_geom ON public.protected_areas USING GIST (geom);

-- Revoke all privileges from PUBLIC
REVOKE ALL ON TABLE public.protected_areas FROM PUBLIC;

-- Grant SELECT to symphony_command
GRANT SELECT ON TABLE public.protected_areas TO symphony_command;

-- Grant ALL to symphony_control
GRANT ALL ON TABLE public.protected_areas TO symphony_control;

-- Append-only trigger function
CREATE OR REPLACE FUNCTION public.protected_areas_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'GF055: protected_areas is append-only, UPDATE/DELETE not allowed' USING ERRCODE = 'GF055';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach trigger as BEFORE UPDATE OR DELETE
CREATE TRIGGER protected_areas_append_only_trigger
BEFORE UPDATE OR DELETE ON public.protected_areas
FOR EACH ROW EXECUTE FUNCTION public.protected_areas_append_only();

COMMENT ON TABLE public.protected_areas IS 'Stores protected area polygons with PostGIS geometry(POLYGON, 4326) for DNSH compliance checking, with GIST index on geom column and append-only trigger';
