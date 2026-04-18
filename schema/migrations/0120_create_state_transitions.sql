-- Migration 0120: Create state_transitions table, state_current table, and trigger functions
-- Task: TSK-P2-PREAUTH-005-01, TSK-P2-PREAUTH-005-02, TSK-P2-PREAUTH-005-03 through 005-08
-- These tables and triggers track state transitions with execution binding and current state

CREATE TABLE IF NOT EXISTS state_transitions (
    transition_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    from_state VARCHAR NOT NULL,
    to_state VARCHAR NOT NULL,
    transition_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    execution_id UUID,
    policy_decision_id UUID,
    signature TEXT
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_state_transitions_project_id ON state_transitions(project_id);
CREATE INDEX IF NOT EXISTS idx_state_transitions_transition_timestamp ON state_transitions(transition_timestamp);

-- Create state_current table to track current state for each project
CREATE TABLE IF NOT EXISTS state_current (
    project_id UUID PRIMARY KEY,
    current_state VARCHAR NOT NULL,
    state_since TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create enforce_transition_state_rules() function
-- Task: TSK-P2-PREAUTH-005-03
CREATE OR REPLACE FUNCTION enforce_transition_state_rules()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if state_rules table exists and has valid (from_state, to_state) pair
    -- This is a placeholder for the actual rule checking logic
    -- In a full implementation, this would query state_rules table
    -- For now, we'll allow the transition and raise GF032 if needed
    RAISE NOTICE 'Transition state rules check: % -> %', NEW.from_state, NEW.to_state;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach enforce_transition_state_rules() as BEFORE INSERT OR UPDATE trigger
CREATE TRIGGER tr_enforce_transition_state_rules
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW EXECUTE FUNCTION enforce_transition_state_rules();

-- Create enforce_transition_authority() function
-- Task: TSK-P2-PREAUTH-005-04
CREATE OR REPLACE FUNCTION enforce_transition_authority()
RETURNS TRIGGER AS $$
BEGIN
    -- Verify policy_decision_id is present for authoritative transitions
    -- This is a placeholder for the actual authority checking logic
    -- In a full implementation, this would verify policy_decision_id references valid decisions
    -- For now, we'll allow the transition and raise GF033 if needed
    IF NEW.policy_decision_id IS NULL THEN
        RAISE NOTICE 'Transition authority check: policy_decision_id is NULL';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach enforce_transition_authority() as BEFORE INSERT OR UPDATE trigger
CREATE TRIGGER tr_enforce_transition_authority
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW EXECUTE FUNCTION enforce_transition_authority();

-- Create enforce_transition_signature() function
-- Task: TSK-P2-PREAUTH-005-05
CREATE OR REPLACE FUNCTION enforce_transition_signature()
RETURNS TRIGGER AS $$
BEGIN
    -- Verify signature is present for signed transitions
    -- This is a placeholder for the actual signature checking logic
    -- In a full implementation, this would verify cryptographic signature
    -- For now, we'll allow the transition and raise GF034 if needed
    IF NEW.signature IS NULL THEN
        RAISE NOTICE 'Transition signature check: signature is NULL';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach enforce_transition_signature() as BEFORE INSERT OR UPDATE trigger
CREATE TRIGGER tr_enforce_transition_signature
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW EXECUTE FUNCTION enforce_transition_signature();

-- Create enforce_execution_binding() function
-- Task: TSK-P2-PREAUTH-005-06
CREATE OR REPLACE FUNCTION enforce_execution_binding()
RETURNS TRIGGER AS $$
BEGIN
    -- Verify execution_id is present for reproducible transitions
    -- This is a placeholder for the actual execution binding checking logic
    -- In a full implementation, this would verify execution_id references valid execution records
    -- For now, we'll allow the transition and raise GF035 if needed
    IF NEW.execution_id IS NULL THEN
        RAISE NOTICE 'Transition execution binding check: execution_id is NULL';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach enforce_execution_binding() as BEFORE INSERT OR UPDATE trigger
CREATE TRIGGER tr_enforce_execution_binding
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW EXECUTE FUNCTION enforce_execution_binding();

-- Create deny_state_transitions_mutation() function
-- Task: TSK-P2-PREAUTH-005-07
CREATE OR REPLACE FUNCTION deny_state_transitions_mutation()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent UPDATE and DELETE on state_transitions table (append-only)
    -- This ensures state transitions cannot be modified after insertion
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'GF036: state_transitions table is append-only, UPDATE not allowed';
    END IF;
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'GF036: state_transitions table is append-only, DELETE not allowed';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach deny_state_transitions_mutation() as BEFORE UPDATE OR DELETE trigger
CREATE TRIGGER tr_deny_state_transitions_mutation
BEFORE UPDATE OR DELETE ON state_transitions
FOR EACH ROW EXECUTE FUNCTION deny_state_transitions_mutation();

-- Create update_current_state() function
-- Task: TSK-P2-PREAUTH-005-08
CREATE OR REPLACE FUNCTION update_current_state()
RETURNS TRIGGER AS $$
BEGIN
    -- Update state_current table with the new state for the project
    -- This ensures state_current table stays in sync with state_transitions
    INSERT INTO state_current (project_id, current_state, state_since)
    VALUES (NEW.project_id, NEW.to_state, NEW.transition_timestamp)
    ON CONFLICT (project_id) DO UPDATE SET
        current_state = EXCLUDED.current_state,
        state_since = EXCLUDED.state_since;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach update_current_state() as AFTER INSERT trigger
CREATE TRIGGER tr_update_current_state
AFTER INSERT ON state_transitions
FOR EACH ROW EXECUTE FUNCTION update_current_state();
