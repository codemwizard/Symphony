-- Symphony Phase 7.2: Execution Attempts
-- Phase Key: SYS-7-2
-- System of Record: Platform Orchestration Layer (Node.js)
--
-- Attempt tracking is diagnostic and non-authoritative.
-- No execution decision may be derived solely from attempt state.
--
-- Attempts are append-only: state transitions are forward-only,
-- and resolved_at is set exactly once.

CREATE TABLE execution_attempts (
    -- Identity
    attempt_id TEXT PRIMARY KEY DEFAULT generate_ulid(),
    instruction_id TEXT NOT NULL,
    sequence_number INTEGER NOT NULL,
    
    -- State (forward-only transitions)
    state TEXT NOT NULL DEFAULT 'CREATED'
        CHECK (state IN ('CREATED', 'SENT', 'ACKED', 'NACKED', 'TIMEOUT')),
    
    -- External response (if received)
    rail_response JSONB,
    
    -- Failure classification (if failed)
    failure_class TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    
    -- Correlation (INV SYS-7-1-A)
    ingress_sequence_id TEXT NOT NULL,
    request_id TEXT NOT NULL,
    
    -- Constraints
    CONSTRAINT unique_attempt_sequence UNIQUE (instruction_id, sequence_number),
    CONSTRAINT valid_rail_response CHECK (
        rail_response IS NULL OR jsonb_typeof(rail_response) = 'object'
    )
);

-- Indexes
CREATE INDEX idx_attempts_instruction ON execution_attempts(instruction_id);
CREATE INDEX idx_attempts_state ON execution_attempts(state) WHERE state = 'SENT';
CREATE INDEX idx_attempts_request ON execution_attempts(request_id);

-- Documentation
COMMENT ON TABLE execution_attempts IS 'Diagnostic attempt tracking. Non-authoritative. Append-only semantics. Phase 7.2.';
COMMENT ON COLUMN execution_attempts.state IS 'Attempt state. Forward-only transitions. Does not determine instruction success.';
COMMENT ON COLUMN execution_attempts.rail_response IS 'External rail response. For diagnostics only.';
COMMENT ON COLUMN execution_attempts.failure_class IS 'Classified failure type per Phase 7.2 taxonomy.';
