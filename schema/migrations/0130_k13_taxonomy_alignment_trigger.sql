-- Migration 0130: Implement enforce_k13_taxonomy_alignment() trigger
-- This trigger ensures taxonomy_aligned flag requires spatial_check_execution_id, enforcing EU Taxonomy K13 compliance

CREATE OR REPLACE FUNCTION public.enforce_k13_taxonomy_alignment()
RETURNS TRIGGER AS $$
BEGIN
    -- If taxonomy_aligned is true, spatial_check_execution_id must not be null
    IF NEW.taxonomy_aligned = true AND NEW.spatial_check_execution_id IS NULL THEN
        RAISE EXCEPTION 'GF060: K13 violation: taxonomy_aligned=true requires spatial_check_execution_id' USING ERRCODE = 'GF060';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach trigger as BEFORE INSERT OR UPDATE on projects
CREATE TRIGGER enforce_k13_taxonomy_alignment_trigger
BEFORE INSERT OR UPDATE ON public.projects
FOR EACH ROW EXECUTE FUNCTION public.enforce_k13_taxonomy_alignment();

COMMENT ON FUNCTION public.enforce_k13_taxonomy_alignment() IS 'Ensures taxonomy_aligned flag requires spatial_check_execution_id, enforcing EU Taxonomy K13 compliance';
