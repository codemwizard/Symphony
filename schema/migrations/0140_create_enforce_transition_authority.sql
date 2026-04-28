-- Migration 0140: Create enforce_transition_authority() trigger function
-- This trigger enforces that transitions have proper policy authority
-- Part of Wave 5 Phase 1 implementation
-- Remediations applied: REM-07
-- REM-07: Added JOIN logic to policy_decisions table for actual authority validation

CREATE OR REPLACE FUNCTION enforce_transition_authority()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure policy_decision_id is present for authority tracking
    IF NEW.policy_decision_id IS NULL THEN
        RAISE EXCEPTION 'Transition without policy decision for entity %/%', NEW.entity_type, NEW.entity_id;
    END IF;
    
    -- Validate authority by checking policy_decisions table
    -- This ensures the policy decision exists and matches the entity type
    IF NOT EXISTS (
        SELECT 1 FROM policy_decisions
        WHERE decision_id = NEW.policy_decision_id
        AND entity_type = NEW.entity_type
    ) THEN
        RAISE EXCEPTION 'Invalid authority: policy decision % does not match entity type %', 
            NEW.policy_decision_id, NEW.entity_type;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on state_transitions table
CREATE TRIGGER trg_enforce_transition_authority
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION enforce_transition_authority();
