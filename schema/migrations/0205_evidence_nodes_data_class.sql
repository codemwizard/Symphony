-- Migration: 0205_evidence_nodes_data_class.sql
-- Task: TSK-P3-W1-DB-007
-- Description: Add constitutional_data_class ENUM and data_class column to evidence_nodes.
--              Implements Gap 1 from SYMPHONY_GROUND_TRUTH_REMEDIATION_REPORT.md.
--              Materialises the six data classes from DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md
--              (Authority-Rank 9) into the schema layer.
--
-- MRV-AMRC References:
--   identity    → Table 2 (TOMBSTONE-ONLY)
--   evidentiary → Table 1 (IMMUTABLE)
--   provenance  → Table 1 (IMMUTABLE)
--   replay      → Table 1 (IMMUTABLE)
--   regulator   → Table 1 (IMMUTABLE, per-regime retention)
--   operational → Table 4 (EXHAUSTIBLE)

-- Step 1: Create the constitutional data class ENUM
CREATE TYPE public.constitutional_data_class AS ENUM (
    'identity',       -- §3.1: Conditionally deletable; tombstoned on erasure after retention floor
    'evidentiary',    -- §3.2: Immutable; no deletion; permanent replay obligation
    'provenance',     -- §3.3: Immutable; chain must remain intact
    'replay',         -- §3.4: Immutable; required for constitutional reconstruction
    'regulator',      -- §3.5: Per-regulator mandatory retention; no Symphony deletion authority
    'operational'     -- §3.6: Permitted deletion after retention floor; no replay obligation
);

-- Step 2: Add data_class column with safe default
-- Default 'operational' ensures existing rows are classified as EXHAUSTIBLE (safe default).
-- Rows that constitute evidentiary or provenance data must be explicitly reclassified
-- by the Phase 3 backfill migration or by application code on creation.
ALTER TABLE public.evidence_nodes
    ADD COLUMN data_class public.constitutional_data_class NOT NULL DEFAULT 'operational';

-- Step 3: Create monotonicity enforcement trigger
-- Once a node is classified as evidentiary or provenance, it cannot be downgraded.
-- This prevents operational convenience from overriding constitutional permanence.
CREATE OR REPLACE FUNCTION public.enforce_data_class_monotonicity()
RETURNS TRIGGER LANGUAGE plpgsql
SECURITY DEFINER SET search_path = pg_catalog, public AS $$
BEGIN
    -- Evidentiary is the highest classification; cannot be downgraded to anything
    IF OLD.data_class = 'evidentiary' AND NEW.data_class <> 'evidentiary' THEN
        RAISE EXCEPTION 'Evidentiary data class cannot be downgraded (evidence_node_id=%)',
            OLD.evidence_node_id
            USING ERRCODE = 'P3101';
    END IF;

    -- Provenance can only be upgraded to evidentiary, not downgraded
    IF OLD.data_class = 'provenance' AND NEW.data_class NOT IN ('evidentiary', 'provenance') THEN
        RAISE EXCEPTION 'Provenance data class cannot be downgraded below provenance (evidence_node_id=%)',
            OLD.evidence_node_id
            USING ERRCODE = 'P3101';
    END IF;

    -- Replay can be upgraded to provenance or evidentiary, not downgraded
    IF OLD.data_class = 'replay' AND NEW.data_class NOT IN ('evidentiary', 'provenance', 'replay') THEN
        RAISE EXCEPTION 'Replay data class cannot be downgraded below replay (evidence_node_id=%)',
            OLD.evidence_node_id
            USING ERRCODE = 'P3101';
    END IF;

    -- Regulator can be upgraded to evidentiary/provenance/replay, not downgraded to operational
    IF OLD.data_class = 'regulator' AND NEW.data_class = 'operational' THEN
        RAISE EXCEPTION 'Regulator data class cannot be downgraded to operational (evidence_node_id=%)',
            OLD.evidence_node_id
            USING ERRCODE = 'P3101';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_enforce_data_class_monotonicity
    BEFORE UPDATE ON public.evidence_nodes
    FOR EACH ROW EXECUTE FUNCTION public.enforce_data_class_monotonicity();

-- Step 4: Index for filtering by data_class (CI verifiers scope to non-operational nodes)
CREATE INDEX idx_evidence_nodes_data_class ON public.evidence_nodes(data_class);

-- Step 5: Comment documenting the constitutional basis
COMMENT ON COLUMN public.evidence_nodes.data_class IS
    'Constitutional data classification per DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md §3. '
    'Monotonicity enforced: classifications cannot be downgraded. '
    'MRV-AMRC cross-reference: identity=Table2, evidentiary/provenance/replay/regulator=Table1, operational=Table4.';
