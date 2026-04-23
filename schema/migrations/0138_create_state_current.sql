-- Migration 0138: Create state_current table
-- This table tracks the current state for each entity
-- Part of Wave 5 Phase 1 implementation
-- Remediations applied: REM-04, REM-05
-- REM-11: Changed PK from project_id to (entity_type, entity_id) for generic entity model

CREATE TABLE state_current (
    entity_type VARCHAR NOT NULL,
    entity_id UUID NOT NULL,
    current_state VARCHAR NOT NULL,
    last_transition_id UUID,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (entity_type, entity_id),
    CONSTRAINT fk_last_transition FOREIGN KEY (last_transition_id) 
        REFERENCES state_transitions(transition_id) ON DELETE CASCADE
);

-- Create index for efficient querying
CREATE INDEX idx_state_current_last_transition ON state_current(last_transition_id);
