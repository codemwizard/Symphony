-- Migration 0144: Create update_current_state() trigger function
-- This trigger automatically updates state_current table after state_transitions insert
-- Part of Wave 5 Phase 1 implementation
-- REM-11: Updated to use (entity_type, entity_id) PK and renamed trigger to trg_06_update_current

CREATE OR REPLACE FUNCTION update_current_state()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert or update state_current with the latest transition
    INSERT INTO state_current (entity_type, entity_id, current_state, last_transition_id, updated_at)
    VALUES (NEW.entity_type, NEW.entity_id, NEW.to_state, NEW.transition_id, NOW())
    ON CONFLICT (entity_type, entity_id) DO UPDATE SET
        current_state = EXCLUDED.current_state,
        last_transition_id = EXCLUDED.last_transition_id,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists for idempotency
DROP TRIGGER IF EXISTS trg_update_current_state ON state_transitions;
DROP TRIGGER IF EXISTS trg_06_update_current ON state_transitions;

-- Create trigger on state_transitions table with explicit ordering name
CREATE TRIGGER trg_06_update_current
AFTER INSERT ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION update_current_state();
