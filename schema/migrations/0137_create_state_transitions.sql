-- Migration 0137: Create state_transitions table
-- This table tracks all state transitions with execution binding
-- Part of Wave 5 Phase 1 implementation
-- Remediations applied: REM-01, REM-02, REM-03, REM-09, REM-11
-- REM-03: Replaced weak constraint with strong hash-based idempotency constraint

-- Create data_authority_level ENUM type if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'data_authority_level') THEN
        CREATE TYPE public.data_authority_level AS ENUM (
            'phase1_indicative_only',
            'non_reproducible',
            'derived_unverified',
            'policy_bound_unsigned',
            'authoritative_signed',
            'superseded',
            'invalidated'
        );
    END IF;
END $$;

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
    data_authority public.data_authority_level NOT NULL DEFAULT 'non_reproducible',
    audit_grade BOOLEAN NOT NULL DEFAULT false,
    authority_explanation TEXT NOT NULL DEFAULT 'No execution context recorded',
    CONSTRAINT unique_entity_hash UNIQUE (entity_type, entity_id, transition_hash)
);

-- Create indexes for efficient querying
CREATE INDEX idx_state_transitions_project_id ON state_transitions(project_id);
CREATE INDEX idx_state_transitions_timestamp ON state_transitions(transition_timestamp);
CREATE INDEX idx_state_transitions_entity ON state_transitions(entity_type, entity_id);
