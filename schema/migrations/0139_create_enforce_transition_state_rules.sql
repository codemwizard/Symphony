-- Migration 0139: Create enforce_transition_state_rules() trigger function
-- This trigger enforces state transition rules
-- Part of Wave 5 Phase 1 implementation
-- Remediations applied: REM-06
-- REM-06: Added JOIN logic to state_rules table for actual validation

CREATE OR REPLACE FUNCTION enforce_transition_state_rules()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate state transition against state_rules table
    -- This ensures only valid transitions are allowed per business logic
    IF NOT EXISTS (
        SELECT 1 FROM state_rules
        WHERE entity_type = NEW.entity_type
        AND from_state = NEW.from_state
    ) THEN
        RAISE EXCEPTION 'Invalid state transition from % to % for entity type %: no rule defined', 
            NEW.from_state, NEW.to_state, NEW.entity_type;
    END IF;
    
    -- Check if the specific transition is allowed
    IF NOT EXISTS (
        SELECT 1 FROM state_rules
        WHERE entity_type = NEW.entity_type
        AND from_state = NEW.from_state
        AND to_state = NEW.to_state
    ) THEN
        RAISE EXCEPTION 'Invalid state transition from % to % for entity type %: transition not allowed', 
            NEW.from_state, NEW.to_state, NEW.entity_type;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on state_transitions table
CREATE TRIGGER trg_enforce_transition_state_rules
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION enforce_transition_state_rules();
