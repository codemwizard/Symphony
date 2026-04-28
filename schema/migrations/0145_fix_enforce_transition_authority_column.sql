-- Migration 0145: Fix column name mismatch in enforce_transition_authority()
-- This migration fixes the column reference from decision_id to policy_decision_id
-- The policy_decisions table PK is policy_decision_id, not decision_id
-- Part of Wave 5 Stabilization (TSK-P2-W5-FIX-01)

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
        WHERE policy_decision_id = NEW.policy_decision_id
        AND entity_type = NEW.entity_type
    ) THEN
        RAISE EXCEPTION 'Invalid authority: policy decision % does not match entity type %', 
            NEW.policy_decision_id, NEW.entity_type;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
