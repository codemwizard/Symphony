-- Migration 0127: Create project_boundaries table
-- This table stores project boundary polygons with PostGIS geometry for DNSH and K13 compliance checking

CREATE TABLE IF NOT EXISTS public.project_boundaries (
    boundary_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dns_check_version_id UUID NOT NULL,
    spatial_check_execution_id UUID NOT NULL,
    geom geometry(POLYGON, 4326) NOT NULL,
    effective_from TIMESTAMPTZ NOT NULL,
    CONSTRAINT project_boundaries_fk_protected_areas FOREIGN KEY (dns_check_version_id) REFERENCES protected_areas(protected_area_id),
    CONSTRAINT project_boundaries_fk_execution_records FOREIGN KEY (spatial_check_execution_id) REFERENCES execution_records(execution_id)
);

-- Create GIST index on geom column for spatial queries
CREATE INDEX idx_project_boundaries_geom ON public.project_boundaries USING GIST (geom);

-- Revoke all privileges from PUBLIC
REVOKE ALL ON TABLE public.project_boundaries FROM PUBLIC;

-- Grant SELECT to symphony_command
GRANT SELECT ON TABLE public.project_boundaries TO symphony_command;

-- Grant ALL to symphony_control
GRANT ALL ON TABLE public.project_boundaries TO symphony_control;

-- Append-only trigger function
CREATE OR REPLACE FUNCTION public.project_boundaries_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'GF055: project_boundaries is append-only, UPDATE/DELETE not allowed' USING ERRCODE = 'GF055';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach trigger as BEFORE UPDATE OR DELETE
CREATE TRIGGER project_boundaries_append_only_trigger
BEFORE UPDATE OR DELETE ON public.project_boundaries
FOR EACH ROW EXECUTE FUNCTION public.project_boundaries_append_only();

COMMENT ON TABLE public.project_boundaries IS 'Stores project boundary polygons with PostGIS geometry(POLYGON, 4326) for DNSH and K13 compliance checking, with GIST index on geom column, FKs to protected_areas and execution_records, and append-only trigger';
