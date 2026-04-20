-- Migration 0131: Add determinism columns to execution_records (expand phase)
-- Task: TSK-P2-PREAUTH-003-REM-01
-- Casefile: REM-2026-04-20_execution-truth-anchor
-- Invariant (declared, not-yet-implemented until REM-05 emits evidence): INV-EXEC-TRUTH-001
--
-- This migration is the EXPAND half of an expand/contract pair (INV-097).
-- It adds four nullable columns so that existing rows (if any) remain valid
-- and subsequent migration 0132 can perform backfill + SET NOT NULL + UNIQUE.
--
-- Forward-only: no edit to migration 0118 is permitted. No runtime DDL.

ALTER TABLE public.execution_records
    ADD COLUMN IF NOT EXISTS input_hash       TEXT;

ALTER TABLE public.execution_records
    ADD COLUMN IF NOT EXISTS output_hash      TEXT;

ALTER TABLE public.execution_records
    ADD COLUMN IF NOT EXISTS runtime_version  TEXT;

ALTER TABLE public.execution_records
    ADD COLUMN IF NOT EXISTS tenant_id        UUID;

COMMENT ON COLUMN public.execution_records.input_hash IS
    'SHA-256 hex digest of the canonicalised input payload that drove this execution. Set NOT NULL in migration 0132.';

COMMENT ON COLUMN public.execution_records.output_hash IS
    'SHA-256 hex digest of the canonicalised output payload produced by this execution. Set NOT NULL in migration 0132.';

COMMENT ON COLUMN public.execution_records.runtime_version IS
    'Adapter / executor runtime version string. Set NOT NULL in migration 0132.';

COMMENT ON COLUMN public.execution_records.tenant_id IS
    'Owning tenant. Set NOT NULL in migration 0132; the three-layer separation model keeps this on the truth anchor so determinism and tenancy are co-anchored.';
