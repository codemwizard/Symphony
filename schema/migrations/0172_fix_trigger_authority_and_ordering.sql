-- Migration 0172: Fix P1/P2 trigger authority and ordering issues
-- Task: TSK-P2-PREAUTH-007-14 (security fixes)
-- Wave: 5 — State Machine + Trigger Layer
--
-- P1 Fix 1: Add execution_id check in enforce_transition_authority
-- - Validates that policy_decision_id belongs to the same execution_id
-- - Prevents pairing execution A with policy decision from execution B
-- - Raises GF081 for execution-decision binding violations
--
-- P1 Fix 2: Add allowed and decision_type checks in enforce_transition_state_rules
-- - Filter on allowed=true to respect explicit deny rules
-- - Enforce required_decision_type against attached policy decision
-- - Raises GF080 for decision type mismatches
--
-- P2 Fix: Adjust trigger ordering for signature gate
-- - Move bi_04_enforce_transition_signature to bi_07
-- - Runs AFTER bi_06_upgrade_authority_on_execution_binding
-- - Allows unsigned authority classification before signature validation

-- ─── Fix enforce_transition_state_rules() ─────────────────────────────
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

    -- Check if the specific transition is allowed and not explicitly denied
    IF NOT EXISTS (
        SELECT 1 FROM state_rules
        WHERE entity_type = NEW.entity_type
        AND from_state = NEW.from_state
        AND to_state = NEW.to_state
        AND allowed = true
    ) THEN
        RAISE EXCEPTION 'Invalid state transition from % to % for entity type %: transition not allowed or explicitly denied',
            NEW.from_state, NEW.to_state, NEW.entity_type
        USING ERRCODE = 'GF003';
    END IF;

    -- Enforce required decision type if specified
    IF EXISTS (
        SELECT 1 FROM state_rules
        WHERE entity_type = NEW.entity_type
        AND from_state = NEW.from_state
        AND to_state = NEW.to_state
        AND required_decision_type IS NOT NULL
    ) THEN
        DECLARE
            req_type VARCHAR(50);
        BEGIN
            SELECT required_decision_type INTO req_type
            FROM state_rules
            WHERE entity_type = NEW.entity_type
            AND from_state = NEW.from_state
            AND to_state = NEW.to_state
            AND required_decision_type IS NOT NULL
            LIMIT 1;

            IF NOT EXISTS (
                SELECT 1 FROM policy_decisions
                WHERE policy_decision_id = NEW.policy_decision_id
                AND decision_type = req_type
            ) THEN
                RAISE EXCEPTION 'Invalid state transition: required decision type % not found in policy decision %',
                    req_type, NEW.policy_decision_id
                USING ERRCODE = 'GF080';
            END IF;
        END;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- ─── Fix enforce_transition_authority() ───────────────────────────────
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

    -- Validate execution-decision binding: ensure policy decision belongs to the same execution
    -- This prevents pairing execution A with a policy decision from execution B
    IF NOT EXISTS (
        SELECT 1 FROM policy_decisions
        WHERE policy_decision_id = NEW.policy_decision_id
        AND execution_id = NEW.execution_id
    ) THEN
        RAISE EXCEPTION 'Invalid authority: policy decision % does not belong to execution % (execution-decision binding violation)',
            NEW.policy_decision_id, NEW.execution_id
        USING ERRCODE = 'GF081';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- ─── Fix trigger ordering: move signature gate to bi_07 ───────────────
DROP TRIGGER IF EXISTS bi_04_enforce_transition_signature ON state_transitions;
DROP TRIGGER IF EXISTS bi_07_enforce_transition_signature ON state_transitions;

CREATE TRIGGER bi_07_enforce_transition_signature
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION enforce_transition_signature();
