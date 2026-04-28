-- Migration 0155: Reassign K13 SQLSTATE from GF060 to GF061
-- Phase 2: Wave 6 Remediation (TSK-P2-W6-REM-15)

CREATE OR REPLACE FUNCTION public.enforce_k13_taxonomy_alignment()
RETURNS TRIGGER AS $$
BEGIN
    -- If taxonomy_aligned is true, it requires spatial_check_execution_id.
    -- Since the column does not exist on the projects table yet, this is always a violation.
    IF NEW.taxonomy_aligned = true THEN
        RAISE EXCEPTION 'GF061: K13 violation: taxonomy_aligned=true requires spatial_check_execution_id' USING ERRCODE = 'GF061';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

COMMENT ON FUNCTION public.enforce_k13_taxonomy_alignment() IS 'Ensures taxonomy_aligned flag requires spatial_check_execution_id, enforcing EU Taxonomy K13 compliance (GF061)';
