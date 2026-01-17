-- Phase-7B: High-Water Mark Queries
-- Deterministic batch boundaries using monotonic IDs
-- 
-- These queries define the export cursor for evidence batches.
-- Supervisors can verify continuity across exports using these marks.

-- -----------------------------------------------------------------------------
-- Query 1: Current High-Water Marks
-- Returns the maximum ID from each source table.
-- Used to define the upper bound of an export batch.
-- -----------------------------------------------------------------------------
-- SELECT
--     (SELECT COALESCE(MAX(id)::text, '0') FROM ingress_attestations) AS max_ingress_id,
--     (SELECT COALESCE(MAX(id)::text, '0') FROM payment_outbox) AS max_outbox_id,
--     (SELECT COALESCE(MAX(id)::text, '0') FROM ledger_entries) AS max_ledger_id;


-- -----------------------------------------------------------------------------
-- Query 2: Export Batch Range
-- Fetches records between two high-water marks (exclusive lower, inclusive upper).
-- This ensures no overlapping or missing records between batches.
-- -----------------------------------------------------------------------------

-- Ingress Attestations
-- SELECT id, request_id, caller_id, created_at, execution_started, 
--        execution_completed, terminal_status, prev_hash
-- FROM ingress_attestations
-- WHERE id > $1 AND id <= $2
-- ORDER BY id ASC
-- LIMIT $3;

-- Payment Outbox
-- SELECT id, idempotency_key, status, retry_count, created_at, updated_at
-- FROM payment_outbox
-- WHERE id > $1 AND id <= $2
-- ORDER BY id ASC
-- LIMIT $3;

-- Ledger Entries
-- SELECT id, account_id, amount, currency, entry_type, created_at
-- FROM ledger_entries
-- WHERE id > $1 AND id <= $2
-- ORDER BY id ASC
-- LIMIT $3;


-- -----------------------------------------------------------------------------
-- Table: evidence_export_log
-- Tracks all evidence exports with their high-water marks.
-- Used to determine the starting point for the next batch.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS evidence_export_log (
    id BIGSERIAL PRIMARY KEY,
    batch_id TEXT NOT NULL UNIQUE,
    schema_version TEXT NOT NULL,
    exported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- High-water marks at time of export
    max_ingress_id TEXT NOT NULL,
    max_outbox_id TEXT NOT NULL,
    max_ledger_id TEXT NOT NULL,
    
    -- Record counts for verification
    ingress_count INTEGER NOT NULL,
    outbox_count INTEGER NOT NULL,
    ledger_count INTEGER NOT NULL,
    
    -- Integrity
    batch_hash TEXT NOT NULL,
    previous_batch_id TEXT REFERENCES evidence_export_log(batch_id),
    
    -- Metadata
    view_version TEXT DEFAULT '7B.1.0',
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for efficient batch chain traversal
CREATE INDEX IF NOT EXISTS idx_evidence_export_log_exported_at 
    ON evidence_export_log(exported_at DESC);

-- Index for batch chain continuity verification
CREATE INDEX IF NOT EXISTS idx_evidence_export_log_previous_batch 
    ON evidence_export_log(previous_batch_id);

COMMENT ON TABLE evidence_export_log IS 
    'Phase-7B: Evidence export audit log with high-water marks for batch continuity verification.';
