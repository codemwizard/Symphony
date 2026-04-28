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

-- enforce_state_transition_authority() trigger function
-- Moved from migration 0122 which runs before state_transitions exists
CREATE OR REPLACE FUNCTION enforce_state_transition_authority()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate data_authority transitions
    IF TG_OP = 'UPDATE' AND OLD.data_authority IS DISTINCT FROM NEW.data_authority THEN
        -- Only allow specific transitions
        IF NOT (
            -- Allow upgrade from lower to higher authority
            (OLD.data_authority = 'non_reproducible' AND NEW.data_authority IN ('derived_unverified', 'policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'derived_unverified' AND NEW.data_authority IN ('policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'policy_bound_unsigned' AND NEW.data_authority = 'authoritative_signed') OR
            -- Allow downgrade for supersession
            (OLD.data_authority = 'authoritative_signed' AND NEW.data_authority = 'superseded') OR
            -- Allow invalidation
            (NEW.data_authority = 'invalidated')
        ) THEN
            RAISE EXCEPTION 'GF037: Invalid data_authority transition from % to %', OLD.data_authority, NEW.data_authority;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach trigger to state_transitions
DROP TRIGGER IF EXISTS trg_enforce_state_transition_authority ON state_transitions;
CREATE TRIGGER trg_enforce_state_transition_authority
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW EXECUTE FUNCTION enforce_state_transition_authority();

-- upgrade_authority_on_execution_binding() trigger function
-- Moved from migration 0122 which runs before state_transitions exists
CREATE OR REPLACE FUNCTION upgrade_authority_on_execution_binding()
RETURNS TRIGGER AS $$
BEGIN
    -- Upgrade data_authority when execution_id is present
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND (OLD.execution_id IS DISTINCT FROM NEW.execution_id OR OLD.signature IS DISTINCT FROM NEW.signature)) THEN
        IF NEW.execution_id IS NOT NULL THEN
            IF NEW.signature IS NOT NULL THEN
                NEW.data_authority := 'authoritative_signed';
                NEW.audit_grade := true;
                NEW.authority_explanation := 'Execution binding with signature';
            ELSE
                NEW.data_authority := 'policy_bound_unsigned';
                NEW.authority_explanation := 'Execution binding without signature';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach trigger to state_transitions (BEFORE to allow modification of NEW)
DROP TRIGGER IF EXISTS trg_upgrade_authority_on_execution_binding ON state_transitions;
CREATE TRIGGER trg_upgrade_authority_on_execution_binding
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW EXECUTE FUNCTION upgrade_authority_on_execution_binding();
