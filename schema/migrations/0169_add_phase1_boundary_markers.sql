-- Migration: 0169_add_phase1_boundary_markers.sql
-- Task: TSK-P2-PREAUTH-007-11
-- Description: Add phase and data_authority columns to monitoring_records with BEFORE INSERT trigger enforcing Phase 1 boundary rules
-- Work Item: tsk_p2_preauth_007_11_work_item_01, tsk_p2_preauth_007_11_work_item_02
-- Depends on: 0108 (monitoring_records table), 0121 (data_authority_level enum)

BEGIN;

-- Add phase column to monitoring_records
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'monitoring_records'
          AND column_name = 'phase'
    ) THEN
        ALTER TABLE public.monitoring_records
            ADD COLUMN phase VARCHAR NOT NULL DEFAULT 'phase1';
    END IF;
END
$$;

-- Add data_authority column to monitoring_records
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'monitoring_records'
          AND column_name = 'data_authority'
    ) THEN
        ALTER TABLE public.monitoring_records
            ADD COLUMN data_authority data_authority_level NOT NULL DEFAULT 'phase1_indicative_only';
    END IF;
END
$$;

-- Backfill legacy rows (if any inserted before default was set)
UPDATE public.monitoring_records
SET phase = 'phase1', data_authority = 'phase1_indicative_only'
WHERE phase IS NULL OR data_authority IS NULL;

-- Create enforcement trigger function
CREATE OR REPLACE FUNCTION enforce_phase1_boundary()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NEW.phase = 'phase1' THEN
    IF NEW.data_authority <> 'phase1_indicative_only' THEN
      RAISE EXCEPTION 'Phase 1 boundary violation: phase1 rows must have data_authority = phase1_indicative_only, got %', NEW.data_authority
      USING ERRCODE = 'GF071';
    END IF;
    IF NEW.audit_grade <> false THEN
      RAISE EXCEPTION 'Phase 1 boundary violation: phase1 rows must have audit_grade = false, got %', NEW.audit_grade
      USING ERRCODE = 'GF072';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- Bind trigger
DROP TRIGGER IF EXISTS trg_enforce_phase1_boundary ON public.monitoring_records;
CREATE TRIGGER trg_enforce_phase1_boundary
  BEFORE INSERT OR UPDATE ON public.monitoring_records
  FOR EACH ROW
  EXECUTE FUNCTION enforce_phase1_boundary();

-- Add comments
COMMENT ON COLUMN public.monitoring_records.phase IS
    'Phase marker: phase1 or phase2. Phase 1 rows are constrained to phase1_indicative_only data authority and audit_grade=false';
COMMENT ON COLUMN public.monitoring_records.data_authority IS
    'Data authority level using data_authority_level enum. Phase 1 rows must be phase1_indicative_only';
COMMENT ON FUNCTION public.enforce_phase1_boundary() IS
    'SECURITY DEFINER trigger function enforcing Phase 1 boundary rules: phase1 rows require data_authority=phase1_indicative_only and audit_grade=false';

COMMIT;
