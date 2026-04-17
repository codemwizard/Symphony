-- Migration 0116: Extend interpretation_packs with temporal uniqueness columns
-- Task: TSK-P2-PREAUTH-001-01
-- Depends on: 0102 (gf_regulatory_plane — creates interpretation_packs)
--
-- This migration adds project-level temporal resolution columns to the existing
-- interpretation_packs table (created in 0102) and creates a SECURITY DEFINER
-- function to resolve the active pack at a point in time.
--
-- DRD: TSK-OPS-DRD-008 — original version lacked IF NOT EXISTS and compliance
-- guards. Remediated 2026-04-17.

-- ─── Extend interpretation_packs with temporal columns ─────────────
-- Add columns only if they don't already exist (idempotent).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'interpretation_packs'
          AND column_name = 'project_id'
    ) THEN
        ALTER TABLE public.interpretation_packs
            ADD COLUMN project_id UUID,
            ADD COLUMN interpretation_pack_code UUID,
            ADD COLUMN effective_from TIMESTAMPTZ,
            ADD COLUMN effective_to TIMESTAMPTZ;
    END IF;
END
$$;

-- ─── Temporal uniqueness constraint ───────────────────────────────
-- Ensures no overlapping interpretation pack versions for the same project.
-- Uses DO block for idempotent constraint creation.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'unique_interpretation_per_project_time'
    ) THEN
        ALTER TABLE public.interpretation_packs
            ADD CONSTRAINT unique_interpretation_per_project_time
            UNIQUE (project_id, interpretation_pack_code, effective_from);
    END IF;
END
$$;

-- ─── Indexes for temporal query paths ─────────────────────────────
CREATE INDEX IF NOT EXISTS idx_interpretation_packs_project_time
    ON public.interpretation_packs (project_id, effective_from DESC, effective_to);

CREATE INDEX IF NOT EXISTS idx_interpretation_packs_code
    ON public.interpretation_packs (interpretation_pack_code);

-- ─── SECURITY DEFINER function: resolve_interpretation_pack ───────
-- Resolves the active interpretation pack for a project at a given timestamp.
-- Hardened per AGENTS.md: SET search_path = pg_catalog, public.
CREATE OR REPLACE FUNCTION public.resolve_interpretation_pack(
    p_project_id UUID,
    p_effective_at TIMESTAMPTZ
)
RETURNS UUID
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    v_interpretation_pack_id UUID;
BEGIN
    SELECT interpretation_pack_id INTO v_interpretation_pack_id
    FROM public.interpretation_packs
    WHERE project_id = p_project_id
      AND effective_from <= p_effective_at
      AND (effective_to IS NULL OR effective_to > p_effective_at)
    ORDER BY effective_from DESC
    LIMIT 1;

    RETURN v_interpretation_pack_id;
END;
$$;

-- ─── Revoke-first privilege posture for SECURITY DEFINER function ─
REVOKE ALL ON FUNCTION public.resolve_interpretation_pack(UUID, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_interpretation_pack(UUID, TIMESTAMPTZ) TO symphony_command;
GRANT EXECUTE ON FUNCTION public.resolve_interpretation_pack(UUID, TIMESTAMPTZ) TO symphony_control;

-- ─── Comments ─────────────────────────────────────────────────────
COMMENT ON FUNCTION public.resolve_interpretation_pack IS
    'Resolves the active interpretation pack for a project at a given effective timestamp using temporal logic';
