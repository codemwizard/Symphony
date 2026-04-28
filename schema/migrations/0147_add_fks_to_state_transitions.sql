-- Migration 0147: Add FK constraints to state_transitions
-- This migration adds FOREIGN KEY constraints for execution_id and policy_decision_id
-- to enforce referential integrity at the DB level (no soft references)
-- Part of Wave 5 Stabilization (TSK-P2-W5-FIX-03)

-- Precondition: no orphaned rows
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM state_transitions st LEFT JOIN execution_records er
               ON st.execution_id = er.execution_id WHERE er.execution_id IS NULL) THEN
        RAISE EXCEPTION 'PRECONDITION FAILED: orphaned execution_id rows exist';
    END IF;
    IF EXISTS (SELECT 1 FROM state_transitions st LEFT JOIN policy_decisions pd
               ON st.policy_decision_id = pd.policy_decision_id WHERE pd.policy_decision_id IS NULL) THEN
        RAISE EXCEPTION 'PRECONDITION FAILED: orphaned policy_decision_id rows exist';
    END IF;
END $$;

-- Add FK constraint for execution_id (no ON DELETE CASCADE - state_transitions is append-only)
ALTER TABLE state_transitions
    ADD CONSTRAINT fk_st_execution_id
    FOREIGN KEY (execution_id) REFERENCES execution_records(execution_id);

-- Add FK constraint for policy_decision_id (no ON DELETE CASCADE - state_transitions is append-only)
ALTER TABLE state_transitions
    ADD CONSTRAINT fk_st_policy_decision_id
    FOREIGN KEY (policy_decision_id) REFERENCES policy_decisions(policy_decision_id);
