-- Migration 0128: Add taxonomy_aligned column to projects table
-- This column is required for K13 taxonomy alignment checking
-- Expand phase: Add column as nullable

ALTER TABLE public.projects ADD COLUMN taxonomy_aligned BOOLEAN;

COMMENT ON COLUMN public.projects.taxonomy_aligned IS 'Flag indicating whether project taxonomy aligns with K13 classification requirements';

-- Backfill existing rows with default value
UPDATE public.projects SET taxonomy_aligned = false WHERE taxonomy_aligned IS NULL;

-- Contract phase: Add NOT NULL constraint after backfill
ALTER TABLE public.projects ALTER COLUMN taxonomy_aligned SET NOT NULL;
