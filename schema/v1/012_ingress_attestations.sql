-- Phase-7R: Ingress Attestation Table with Hash-Chaining (Tamper-Evident)
-- This table implements the "No Ingress → No Execution" principle with cryptographic proof.

-- Ingress Attestation Table (7-day rolling partitions)
CREATE TABLE IF NOT EXISTS ingress_attestations (
    -- PG18: Native UUIDv7 for time-ordered locality
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    
    -- Request Provenance
    request_id UUID NOT NULL,
    idempotency_key TEXT NOT NULL,
    caller_identity TEXT NOT NULL,
    signature TEXT NOT NULL,
    
    -- Hash-Chaining for Tamper-Evidence (Record_n includes Hash(Record_{n-1}))
    prev_hash TEXT NOT NULL DEFAULT '',
    record_hash TEXT GENERATED ALWAYS AS (
        encode(sha256(
            (id::TEXT || request_id::TEXT || idempotency_key || caller_identity || prev_hash)::BYTEA
        ), 'hex')
    ) STORED,
    
    -- Timing
    attested_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Execution tracking
    execution_started BOOLEAN DEFAULT FALSE,
    execution_completed BOOLEAN DEFAULT FALSE,
    terminal_status TEXT,
    
    -- Export Metadata (Phase-7R: Export-Ready, Phase-7B+: Export-Enabled)
    -- Makes future out-of-domain persistence pluggable without schema changes
    exported_at TIMESTAMPTZ,
    export_batch_id UUID
) PARTITION BY RANGE (attested_at);

-- Index for gap detection (unexecuted attestations)
CREATE INDEX IF NOT EXISTS idx_attestation_gaps ON ingress_attestations (attested_at)
WHERE execution_completed = FALSE;

-- Index for hash-chain verification
CREATE INDEX IF NOT EXISTS idx_attestation_hash ON ingress_attestations (record_hash);

-- 7-day rolling partitions for January 2026
CREATE TABLE IF NOT EXISTS ingress_attestations_2026_01_w1 PARTITION OF ingress_attestations
    FOR VALUES FROM ('2026-01-01') TO ('2026-01-08');

CREATE TABLE IF NOT EXISTS ingress_attestations_2026_01_w2 PARTITION OF ingress_attestations
    FOR VALUES FROM ('2026-01-08') TO ('2026-01-15');

CREATE TABLE IF NOT EXISTS ingress_attestations_2026_01_w3 PARTITION OF ingress_attestations
    FOR VALUES FROM ('2026-01-15') TO ('2026-01-22');

CREATE TABLE IF NOT EXISTS ingress_attestations_2026_01_w4 PARTITION OF ingress_attestations
    FOR VALUES FROM ('2026-01-22') TO ('2026-02-01');

COMMENT ON TABLE ingress_attestations IS 'Phase-7R Ingress Attestation Log. Tamper-evident via hash-chaining. 7-day rolling partitions.';
COMMENT ON COLUMN ingress_attestations.prev_hash IS 'Hash of the previous record for chain integrity.';
COMMENT ON COLUMN ingress_attestations.record_hash IS 'Computed hash of this record for verification.';
