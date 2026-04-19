-- Migration 0128: Add taxonomy_aligned column to projects table
-- This column is required for K13 taxonomy alignment checking

ALTER TABLE public.projects ADD COLUMN taxonomy_aligned BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.projects.taxonomy_aligned IS 'Flag indicating whether project taxonomy aligns with K13 classification requirements';
