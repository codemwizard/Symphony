-- Migration 0153: Set signature placeholder posture in transition_hash
-- The transition_hash column currently has no distinguishing marker to indicate
-- whether it is a real cryptographic hash or a placeholder. This migration adds
-- a BEFORE INSERT trigger that prefixes transition_hash with
-- PLACEHOLDER_PENDING_SIGNING_CONTRACT: when the provided hash doesn't already
-- have this prefix. This prevents mistaking placeholder hashes for real ones.
-- Part of Wave 5 Stabilization (TSK-P2-W5-FIX-09)

-- Function to add placeholder prefix to transition_hash
CREATE OR REPLACE FUNCTION add_signature_placeholder_posture()
RETURNS TRIGGER AS $$
BEGIN
    -- If transition_hash doesn't start with the placeholder prefix, add it
    IF NEW.transition_hash IS NOT NULL AND NEW.transition_hash NOT LIKE 'PLACEHOLDER_PENDING_SIGNING_CONTRACT:%' THEN
        NEW.transition_hash := 'PLACEHOLDER_PENDING_SIGNING_CONTRACT:' || NEW.transition_hash;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Create trigger to call the function before INSERT
DROP TRIGGER IF EXISTS tr_add_signature_placeholder ON state_transitions;
CREATE TRIGGER tr_add_signature_placeholder
    BEFORE INSERT ON state_transitions
    FOR EACH ROW
    EXECUTE FUNCTION add_signature_placeholder_posture();
