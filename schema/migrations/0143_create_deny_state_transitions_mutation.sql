-- Migration 0143: Create deny_state_transitions_mutation() trigger function
-- This trigger prevents direct mutation of state_transitions table
-- Part of Wave 5 Phase 1 implementation
-- REM-12: Changed error string to exact "state_transitions is append-only" for verifier requirement

CREATE OR REPLACE FUNCTION deny_state_transitions_mutation()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent UPDATE operations on state_transitions
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'state_transitions is append-only';
    END IF;
    
    -- Prevent DELETE operations on state_transitions
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'state_transitions is append-only';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on state_transitions table
CREATE TRIGGER trg_deny_state_transitions_mutation
BEFORE UPDATE OR DELETE ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION deny_state_transitions_mutation();
