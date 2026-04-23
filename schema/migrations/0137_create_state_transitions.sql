-- Migration 0137: Create state_transitions table
-- This table tracks all state transitions with execution binding
-- Part of Wave 5 Phase 1 implementation
-- Remediations applied: REM-01, REM-02, REM-03, REM-09, REM-11
-- REM-03: Replaced weak constraint with strong hash-based idempotency constraint

CREATE TABLE state_transitions (
    transition_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    entity_type VARCHAR NOT NULL,
    entity_id UUID NOT NULL,
    from_state VARCHAR NOT NULL,
    to_state VARCHAR NOT NULL,
    transition_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    execution_id UUID NOT NULL,
    policy_decision_id UUID NOT NULL,
    signature TEXT,
    transition_hash TEXT NOT NULL,
    CONSTRAINT unique_entity_hash UNIQUE (entity_type, entity_id, transition_hash)
);

-- Create indexes for efficient querying
CREATE INDEX idx_state_transitions_project_id ON state_transitions(project_id);
CREATE INDEX idx_state_transitions_timestamp ON state_transitions(transition_timestamp);
CREATE INDEX idx_state_transitions_entity ON state_transitions(entity_type, entity_id);
