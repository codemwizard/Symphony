-- scripts/db/backfill_execution_records_determinism.sql
-- Task: TSK-P2-PREAUTH-003-REM-02 (work_item_01)
-- Casefile: REM-2026-04-20_execution-truth-anchor
--
-- Idempotent backfill/precondition script for execution_records determinism
-- columns. The expected state at 0131 HEAD is that execution_records has no
-- real rows (0118 shipped without determinism columns and no production data
-- has landed on it yet). This script therefore runs a precondition assertion
-- and no row-level backfill; if the precondition fails twice, the two-strike
-- DRD lockout applies and work forks to REM-02b.
--
-- NOTE: This file is a convenience for manual runs. Migration 0132 INLINES
-- the same DO block; do NOT use \i inside 0132 (B6 constraint — migrate.sh
-- checksums only the migration file itself, external includes would bypass
-- the immutability gate).

DO $$
DECLARE
    null_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO null_count
    FROM public.execution_records
    WHERE input_hash                IS NULL
       OR output_hash               IS NULL
       OR runtime_version           IS NULL
       OR tenant_id                 IS NULL
       OR interpretation_version_id IS NULL;

    IF null_count > 0 THEN
        RAISE EXCEPTION 'GF059: execution_records determinism backfill precondition failed — % NULL rows present', null_count
            USING ERRCODE = 'GF059';
    END IF;
END $$;
