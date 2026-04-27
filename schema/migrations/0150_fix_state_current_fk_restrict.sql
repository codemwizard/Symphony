-- Migration 0150: Change state_current FK to ON DELETE RESTRICT
-- Migration 0138 created fk_last_transition with ON DELETE CASCADE, which violates
-- the append-only guarantee by silently cascade-deleting current state when a
-- state_transitions row is deleted. This migration changes it to ON DELETE RESTRICT.
-- Part of Wave 5 Stabilization (TSK-P2-W5-FIX-06)

-- Drop the CASCADE FK constraint
ALTER TABLE state_current DROP CONSTRAINT fk_last_transition;

-- Add the FK constraint with ON DELETE RESTRICT
ALTER TABLE state_current ADD CONSTRAINT fk_last_transition
    FOREIGN KEY (last_transition_id)
    REFERENCES state_transitions(transition_id) ON DELETE RESTRICT;
