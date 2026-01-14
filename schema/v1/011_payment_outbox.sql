-- Phase-7R: Transactional Outbox Schema (PostgreSQL 18+ Native)
-- This schema implements the crash-consistent outbox pattern for external rail dispatch.

-- Outbox Status Enum
CREATE TYPE outbox_status AS ENUM ('PENDING', 'IN_FLIGHT', 'SUCCESS', 'FAILED', 'RECOVERING');

-- Main Outbox Table (Partitioned by created_at for efficient cleanup)
CREATE TABLE IF NOT EXISTS payment_outbox (
    -- PG18: Native UUIDv7 for time-ordered locality
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    
    -- Symphony Core Invariants
    participant_id UUID NOT NULL,
    sequence_id BIGINT NOT NULL,
    idempotency_key TEXT UNIQUE NOT NULL,
    
    -- Transaction Data
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    
    -- Reliability Tracking
    status outbox_status DEFAULT 'PENDING',
    retry_count INT DEFAULT 0 CHECK (retry_count >= 0 AND retry_count <= 10),
    last_error TEXT,
    
    -- Timing
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_attempt_at TIMESTAMPTZ,
    processed_at TIMESTAMPTZ,
    
    -- Composite unique constraint for sequence continuity proof
    CONSTRAINT uq_participant_sequence UNIQUE (participant_id, sequence_id)
) PARTITION BY RANGE (created_at);

-- Index for Relayer Poller (SKIP LOCKED pattern)
CREATE INDEX IF NOT EXISTS idx_outbox_poller ON payment_outbox (status, created_at)
WHERE status IN ('PENDING', 'RECOVERING');

-- Create initial partition for Phase-7R (January 2026)
CREATE TABLE IF NOT EXISTS payment_outbox_2026_01 PARTITION OF payment_outbox
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

-- Create next month partition (February 2026)
CREATE TABLE IF NOT EXISTS payment_outbox_2026_02 PARTITION OF payment_outbox
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

COMMENT ON TABLE payment_outbox IS 'Phase-7R Transactional Outbox for crash-consistent rail dispatch. Partitioned by created_at.';
COMMENT ON COLUMN payment_outbox.sequence_id IS 'Monotonic sequence ID per participant for gap detection.';
COMMENT ON COLUMN payment_outbox.idempotency_key IS 'Client-provided key used for external rail idempotency.';
