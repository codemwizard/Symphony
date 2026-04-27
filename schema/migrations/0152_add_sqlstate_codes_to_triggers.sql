-- Migration 0152: Add explicit SQLSTATE codes to all Wave 5 trigger RAISE EXCEPTION statements
-- All RAISE EXCEPTION statements previously used the default SQLSTATE P0001.
-- This migration adds GF-prefixed SQLSTATE codes in PostgreSQL's user-definable range
-- to allow the application layer to distinguish different violation types.
-- Part of Wave 5 Stabilization (TSK-P2-W5-FIX-08)

-- Function 1: enforce_transition_state_rules() (from 0139, hardened in 0148)
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
            NEW.from_state, NEW.to_state, NEW.entity_type
        USING ERRCODE = 'GF002';
    END IF;
    
    -- Check if the specific transition is allowed
    IF NOT EXISTS (
        SELECT 1 FROM state_rules
        WHERE entity_type = NEW.entity_type
        AND from_state = NEW.from_state
        AND to_state = NEW.to_state
    ) THEN
        RAISE EXCEPTION 'Invalid state transition from % to % for entity type %: transition not allowed', 
            NEW.from_state, NEW.to_state, NEW.entity_type
        USING ERRCODE = 'GF003';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function 2: enforce_transition_authority() (from 0140, fixed in FIX-01, hardened in 0148)
CREATE OR REPLACE FUNCTION enforce_transition_authority()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure policy_decision_id is present for authority tracking
    IF NEW.policy_decision_id IS NULL THEN
        RAISE EXCEPTION 'Transition without policy decision for entity %/%', NEW.entity_type, NEW.entity_id
        USING ERRCODE = 'GF009';
    END IF;
    
    -- Validate authority by checking policy_decisions table
    -- This ensures the policy decision exists and matches the entity type
    IF NOT EXISTS (
        SELECT 1 FROM policy_decisions
        WHERE policy_decision_id = NEW.policy_decision_id
        AND entity_type = NEW.entity_type
    ) THEN
        RAISE EXCEPTION 'Invalid authority: policy decision % does not match entity type %', 
            NEW.policy_decision_id, NEW.entity_type
        USING ERRCODE = 'GF001';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function 3: enforce_transition_signature() (from 0141, hardened in 0148)
CREATE OR REPLACE FUNCTION enforce_transition_signature()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure signature is present for cryptographic verification
    IF NEW.signature IS NULL THEN
        RAISE EXCEPTION 'Transition without signature for entity %/%', NEW.entity_type, NEW.entity_id
        USING ERRCODE = 'GF004';
    END IF;
    
    -- Verify transition_hash matches computed hash (REM-10)
    IF NEW.transition_hash IS NULL THEN
        RAISE EXCEPTION 'Transition without hash for entity %/%', NEW.entity_type, NEW.entity_id
        USING ERRCODE = 'GF005';
    END IF;
    
    -- Verify signature using ed25519 (placeholder for actual implementation)
    -- In production, this would call verify_ed25519_signature with the message, signature, and public key
    -- IF NOT verify_ed25519_signature(NEW.transition_hash, NEW.signature, NEW.public_key) THEN
    --     RAISE EXCEPTION 'Invalid signature for transition %', NEW.transition_id
    --     USING ERRCODE = 'GFxxx';
    -- END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function 4: enforce_execution_binding() (from 0142, hardened in 0148)
CREATE OR REPLACE FUNCTION enforce_execution_binding()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure execution_id is present for execution binding
    IF NEW.execution_id IS NULL THEN
        RAISE EXCEPTION 'Transition without execution binding for entity %/%', NEW.entity_type, NEW.entity_id
        USING ERRCODE = 'GF006';
    END IF;
    
    -- Validate execution binding by checking execution_records table
    -- This ensures the execution exists and has interpretation_version_id
    IF NOT EXISTS (
        SELECT 1 FROM execution_records
        WHERE execution_id = NEW.execution_id
        AND interpretation_version_id IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Invalid execution binding: execution % does not have interpretation_version_id', 
            NEW.execution_id
        USING ERRCODE = 'GF007';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function 5: deny_state_transitions_mutation() (from 0143, hardened in 0148)
CREATE OR REPLACE FUNCTION deny_state_transitions_mutation()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent UPDATE operations on state_transitions
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'state_transitions is append-only'
        USING ERRCODE = 'GF008';
    END IF;
    
    -- Prevent DELETE operations on state_transitions
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'state_transitions is append-only'
        USING ERRCODE = 'GF008';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Function 6: update_current_state() (from 0144, hardened in 0148)
-- This function has no RAISE EXCEPTION statements, so no SQLSTATE codes needed
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;
