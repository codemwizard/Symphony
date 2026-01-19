-- Phase-7B Option 2A: Replace in-place outbox (hot pending + attempts archive)

-- Remove legacy outbox artifacts
DROP TABLE IF EXISTS payment_outbox CASCADE;
DROP TYPE IF EXISTS outbox_status;

-- Participant sequence allocator
CREATE TABLE IF NOT EXISTS participant_outbox_sequences (
    participant_id TEXT PRIMARY KEY,
    next_sequence_id BIGINT NOT NULL
);

CREATE OR REPLACE FUNCTION bump_participant_outbox_seq(p_participant_id TEXT)
RETURNS BIGINT AS $$
DECLARE
    new_sequence BIGINT;
BEGIN
    INSERT INTO participant_outbox_sequences (participant_id, next_sequence_id)
    VALUES (p_participant_id, 1)
    ON CONFLICT (participant_id)
    DO UPDATE SET next_sequence_id = participant_outbox_sequences.next_sequence_id + 1
    RETURNING next_sequence_id INTO new_sequence;

    RETURN new_sequence;
END;
$$ LANGUAGE plpgsql;

-- Hot pending queue
CREATE TABLE IF NOT EXISTS payment_outbox_pending (
    outbox_id UUID PRIMARY KEY DEFAULT uuidv7(),
    instruction_id TEXT NOT NULL,
    participant_id TEXT NOT NULL,
    sequence_id BIGINT NOT NULL,
    idempotency_key TEXT NOT NULL,
    rail_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    attempt_count INT NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ux_pending_participant_sequence UNIQUE (participant_id, sequence_id),
    CONSTRAINT ux_pending_instruction_idempotency UNIQUE (instruction_id, idempotency_key),
    CONSTRAINT ck_pending_payload_object CHECK (jsonb_typeof(payload) = 'object')
);

CREATE INDEX IF NOT EXISTS ix_pending_due ON payment_outbox_pending (next_attempt_at, created_at);
CREATE INDEX IF NOT EXISTS ix_pending_participant_due ON payment_outbox_pending (participant_id, next_attempt_at);

-- Append-only attempts archive
CREATE TABLE IF NOT EXISTS payment_outbox_attempts (
    attempt_id UUID PRIMARY KEY DEFAULT uuidv7(),
    outbox_id UUID NOT NULL,
    instruction_id TEXT NOT NULL,
    participant_id TEXT NOT NULL,
    sequence_id BIGINT NOT NULL,
    idempotency_key TEXT NOT NULL,
    rail_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    state TEXT NOT NULL,
    attempt_no INT NOT NULL CHECK (attempt_no >= 1),
    claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    rail_reference TEXT,
    rail_code TEXT,
    error_code TEXT,
    error_message TEXT,
    latency_ms INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_attempts_state CHECK (state IN ('DISPATCHING', 'DISPATCHED', 'RETRYABLE', 'FAILED', 'ZOMBIE_REQUEUE')),
    CONSTRAINT ck_attempts_payload_object CHECK (jsonb_typeof(payload) = 'object')
);

CREATE INDEX IF NOT EXISTS ix_attempts_by_outbox ON payment_outbox_attempts (outbox_id, claimed_at DESC);
CREATE INDEX IF NOT EXISTS ix_attempts_dispatching_age ON payment_outbox_attempts (claimed_at) WHERE state = 'DISPATCHING';
CREATE INDEX IF NOT EXISTS ix_attempts_by_instruction ON payment_outbox_attempts (instruction_id, claimed_at DESC);

-- Wakeup trigger
CREATE OR REPLACE FUNCTION notify_outbox_pending()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('outbox_pending', NEW.outbox_id::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payment_outbox_pending_notify ON payment_outbox_pending;
CREATE TRIGGER payment_outbox_pending_notify
    AFTER INSERT ON payment_outbox_pending
    FOR EACH ROW
    EXECUTE FUNCTION notify_outbox_pending();

COMMENT ON TABLE payment_outbox_pending IS 'Phase-7B Option 2A hot pending queue for outbox dispatch.';
COMMENT ON TABLE payment_outbox_attempts IS 'Phase-7B Option 2A append-only outbox attempts archive.';
COMMENT ON TABLE participant_outbox_sequences IS 'Monotonic sequence allocator per participant for outbox sequencing.';
