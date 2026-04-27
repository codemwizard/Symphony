-- Migration 0149: Rename triggers for deterministic execution order
-- PostgreSQL fires same-event triggers in alphabetical order by name
-- This migration renames all triggers to use bi_XX_ (BEFORE INSERT), bd_XX_ (BEFORE DELETE),
-- and ai_XX_ (AFTER INSERT) prefixes to guarantee deterministic execution order
-- Part of Wave 5 Stabilization (TSK-P2-W5-FIX-05)

-- Drop old triggers (BEFORE INSERT/UPDATE triggers)
DROP TRIGGER IF EXISTS trg_enforce_state_transition_authority ON state_transitions;
DROP TRIGGER IF EXISTS trg_upgrade_authority_on_execution_binding ON state_transitions;
DROP TRIGGER IF EXISTS trg_enforce_transition_state_rules ON state_transitions;
DROP TRIGGER IF EXISTS trg_enforce_transition_authority ON state_transitions;
DROP TRIGGER IF EXISTS trg_enforce_transition_signature ON state_transitions;
DROP TRIGGER IF EXISTS trg_enforce_execution_binding ON state_transitions;

-- Drop old trigger (BEFORE UPDATE/DELETE)
DROP TRIGGER IF EXISTS trg_deny_state_transitions_mutation ON state_transitions;

-- Drop old trigger (AFTER INSERT)
DROP TRIGGER IF EXISTS trg_06_update_current ON state_transitions;

-- Create new triggers with deterministic naming (bi_XX_ for BEFORE INSERT)
-- bi_01_enforce_transition_authority — validate policy authority
CREATE TRIGGER bi_01_enforce_transition_authority
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION enforce_transition_authority();

-- bi_02_enforce_execution_binding — validate execution exists
CREATE TRIGGER bi_02_enforce_execution_binding
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION enforce_execution_binding();

-- bi_03_enforce_transition_state_rules — validate state rules
CREATE TRIGGER bi_03_enforce_transition_state_rules
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION enforce_transition_state_rules();

-- bi_04_enforce_transition_signature — validate signature
CREATE TRIGGER bi_04_enforce_transition_signature
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION enforce_transition_signature();

-- bi_05_enforce_state_transition_authority — validate data_authority transitions
CREATE TRIGGER bi_05_enforce_state_transition_authority
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION enforce_state_transition_authority();

-- bi_06_upgrade_authority_on_execution_binding — auto-upgrade authority
CREATE TRIGGER bi_06_upgrade_authority_on_execution_binding
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION upgrade_authority_on_execution_binding();

-- bd_01_deny_state_transitions_mutation — BEFORE DELETE/UPDATE deny
CREATE TRIGGER bd_01_deny_state_transitions_mutation
BEFORE UPDATE OR DELETE ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION deny_state_transitions_mutation();

-- ai_01_update_current_state — AFTER INSERT update state_current
CREATE TRIGGER ai_01_update_current_state
AFTER INSERT ON state_transitions
FOR EACH ROW
EXECUTE FUNCTION update_current_state();
