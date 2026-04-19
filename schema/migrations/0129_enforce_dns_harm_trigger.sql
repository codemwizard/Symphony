-- Migration 0129: Implement enforce_dns_harm() trigger
-- This trigger prevents project boundaries from overlapping protected areas, enforcing DNSH compliance

CREATE OR REPLACE FUNCTION public.enforce_dns_harm()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the new or updated project boundary intersects any protected area
    IF EXISTS (
        SELECT 1
        FROM public.protected_areas pa
        WHERE ST_Intersects(NEW.geom, pa.geom)
    ) THEN
        RAISE EXCEPTION 'GF057: DNSH violation: project boundary intersects protected area' USING ERRCODE = 'GF057';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach trigger as BEFORE INSERT OR UPDATE on project_boundaries
CREATE TRIGGER enforce_dns_harm_trigger
BEFORE INSERT OR UPDATE ON public.project_boundaries
FOR EACH ROW EXECUTE FUNCTION public.enforce_dns_harm();

COMMENT ON FUNCTION public.enforce_dns_harm() IS 'Prevents project boundaries from intersecting protected areas, enforcing DNSH (Do No Significant Harm) compliance';
