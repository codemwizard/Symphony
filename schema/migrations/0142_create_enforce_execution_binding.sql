-- Migration 0142: Create enforce_execution_binding() trigger function
-- This trigger enforces that transitions are bound to executions
-- Part of Wave 5 Phase 1 implementation
-- Remediations applied: REM-08
-- REM-08: Added JOIN logic to execution_records table for actual execution binding validation

CREATE OR REPLACE FUNCTION enforce_execution_binding()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure execution_id is present for execution binding
    IF NEW.execution_id IS NULL THEN
        RAISE EXCEPTION 'Transition without execution binding for entity %/%', NEW.entity_type, NEW.entity_id;
    END IF;
    
    -- Validate execution binding by checking execution_records table
    -- This ensures the execution exists and has interpretation_version_id
    IF NOT EXISTS (
        SELECT 1 FROM execution_records
        WHERE execution_id = NEW.execution_id
        AND interpretation_version_id IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Invalid execution binding: execution % does not have interpretation_version_id', 
            NEW.execution_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on state_transitions table
CREATE TRIGGER trg_enforce_execution_binding
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION enforce_execution_binding();
