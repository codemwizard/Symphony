-- Migration 0177: Create entity coherence trigger between policy_decisions and execution_records
-- Task: TSK-P2-W5-REM-01
-- Trigger step of the 4-step sequence

CREATE OR REPLACE FUNCTION public.enforce_policy_decisions_entity_coherence()
RETURNS TRIGGER AS $$
DECLARE
    v_exec_entity_type TEXT;
    v_exec_entity_id UUID;
BEGIN
    -- Fetch the entity binding from the parent execution record
    SELECT entity_type, entity_id
    INTO v_exec_entity_type, v_exec_entity_id
    FROM public.execution_records
    WHERE execution_id = NEW.execution_id;

    -- Strict mismatch check
    IF v_exec_entity_type IS DISTINCT FROM NEW.entity_type OR
       v_exec_entity_id IS DISTINCT FROM NEW.entity_id THEN
        RAISE EXCEPTION 'GF062: policy_decisions entity mismatch with execution_records (expected %/%, got %/%)',
            v_exec_entity_type, v_exec_entity_id, NEW.entity_type, NEW.entity_id
            USING ERRCODE = 'GF062';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER enforce_policy_decisions_entity_coherence
BEFORE INSERT ON public.policy_decisions
FOR EACH ROW EXECUTE FUNCTION public.enforce_policy_decisions_entity_coherence();

REVOKE ALL ON FUNCTION public.enforce_policy_decisions_entity_coherence() FROM PUBLIC;

COMMENT ON FUNCTION public.enforce_policy_decisions_entity_coherence() IS
    'TSK-P2-W5-REM-01: Ensures policy_decisions entity binding matches the parent execution_record. Raises GF062 on mismatch.';
