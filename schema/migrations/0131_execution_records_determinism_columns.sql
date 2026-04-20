-- Migration 0131: execution_records determinism columns (expand phase)
-- Task: TSK-P2-PREAUTH-003-REM-01
-- Casefile: REM-2026-04-20_execution-truth-anchor
-- Invariant: INV-EXEC-TRUTH-001 (enforced by REM-02 + REM-03; declared by REM-04)
--
-- Expand phase of the expand/contract pair: adds four nullable determinism
-- columns so backfill (if needed) and SET NOT NULL (REM-02) can run safely.
-- 0118 created execution_records without these columns; forward-only discipline
-- (AGENTS.md hard constraint) prohibits editing 0118 in place.
--
-- NOTE: do NOT add top-level BEGIN/COMMIT. scripts/db/migrate.sh wraps every
-- migration in its own transaction; a top-level COMMIT here would prematurely
-- close the outer transaction and leave the schema_migrations INSERT unprotected.

ALTER TABLE public.execution_records ADD COLUMN IF NOT EXISTS input_hash      TEXT;
ALTER TABLE public.execution_records ADD COLUMN IF NOT EXISTS output_hash     TEXT;
ALTER TABLE public.execution_records ADD COLUMN IF NOT EXISTS runtime_version TEXT;
ALTER TABLE public.execution_records ADD COLUMN IF NOT EXISTS tenant_id       UUID;

COMMENT ON COLUMN public.execution_records.input_hash      IS 'Canonicalised input payload SHA-256. Tightened to NOT NULL by REM-02.';
COMMENT ON COLUMN public.execution_records.output_hash     IS 'Canonicalised output payload SHA-256. Tightened to NOT NULL by REM-02.';
COMMENT ON COLUMN public.execution_records.runtime_version IS 'Adapter runtime version string. Tightened to NOT NULL by REM-02.';
COMMENT ON COLUMN public.execution_records.tenant_id       IS 'Tenant scope for multi-tenant audit isolation. Tightened to NOT NULL by REM-02.';
