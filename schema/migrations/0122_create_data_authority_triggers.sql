-- Migration 0122: Create data authority trigger functions
-- Tasks: TSK-P2-PREAUTH-006B-01, TSK-P2-PREAUTH-006B-02, TSK-P2-PREAUTH-006B-03, TSK-P2-PREAUTH-006B-04
-- Phase: PRE-PHASE2

-- enforce_monitoring_authority() trigger function
CREATE OR REPLACE FUNCTION enforce_monitoring_authority()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate data_authority transitions
    IF TG_OP = 'UPDATE' AND OLD.data_authority IS DISTINCT FROM NEW.data_authority THEN
        -- Only allow specific transitions
        IF NOT (
            -- Allow upgrade from lower to higher authority
            (OLD.data_authority = 'phase1_indicative_only' AND NEW.data_authority IN ('derived_unverified', 'policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'non_reproducible' AND NEW.data_authority IN ('derived_unverified', 'policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'derived_unverified' AND NEW.data_authority IN ('policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'policy_bound_unsigned' AND NEW.data_authority = 'authoritative_signed') OR
            -- Allow downgrade for supersession
            (OLD.data_authority = 'authoritative_signed' AND NEW.data_authority = 'superseded') OR
            -- Allow invalidation
            (NEW.data_authority = 'invalidated')
        ) THEN
            RAISE EXCEPTION 'GF037: Invalid data_authority transition from % to %', OLD.data_authority, NEW.data_authority;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach trigger to monitoring_records
DROP TRIGGER IF EXISTS trg_enforce_monitoring_authority ON monitoring_records;
CREATE TRIGGER trg_enforce_monitoring_authority
BEFORE INSERT OR UPDATE ON monitoring_records
FOR EACH ROW EXECUTE FUNCTION enforce_monitoring_authority();

-- enforce_asset_batch_authority() trigger function
CREATE OR REPLACE FUNCTION enforce_asset_batch_authority()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate data_authority transitions
    IF TG_OP = 'UPDATE' AND OLD.data_authority IS DISTINCT FROM NEW.data_authority THEN
        -- Only allow specific transitions
        IF NOT (
            -- Allow upgrade from lower to higher authority
            (OLD.data_authority = 'phase1_indicative_only' AND NEW.data_authority IN ('derived_unverified', 'policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'non_reproducible' AND NEW.data_authority IN ('derived_unverified', 'policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'derived_unverified' AND NEW.data_authority IN ('policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'policy_bound_unsigned' AND NEW.data_authority = 'authoritative_signed') OR
            -- Allow downgrade for supersession
            (OLD.data_authority = 'authoritative_signed' AND NEW.data_authority = 'superseded') OR
            -- Allow invalidation
            (NEW.data_authority = 'invalidated')
        ) THEN
            RAISE EXCEPTION 'GF037: Invalid data_authority transition from % to %', OLD.data_authority, NEW.data_authority;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach trigger to asset_batches
DROP TRIGGER IF EXISTS trg_enforce_asset_batch_authority ON asset_batches;
CREATE TRIGGER trg_enforce_asset_batch_authority
BEFORE INSERT OR UPDATE ON asset_batches
FOR EACH ROW EXECUTE FUNCTION enforce_asset_batch_authority();

-- enforce_state_transition_authority() trigger function
CREATE OR REPLACE FUNCTION enforce_state_transition_authority()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate data_authority transitions
    IF TG_OP = 'UPDATE' AND OLD.data_authority IS DISTINCT FROM NEW.data_authority THEN
        -- Only allow specific transitions
        IF NOT (
            -- Allow upgrade from lower to higher authority
            (OLD.data_authority = 'non_reproducible' AND NEW.data_authority IN ('derived_unverified', 'policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'derived_unverified' AND NEW.data_authority IN ('policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'policy_bound_unsigned' AND NEW.data_authority = 'authoritative_signed') OR
            -- Allow downgrade for supersession
            (OLD.data_authority = 'authoritative_signed' AND NEW.data_authority = 'superseded') OR
            -- Allow invalidation
            (NEW.data_authority = 'invalidated')
        ) THEN
            RAISE EXCEPTION 'GF037: Invalid data_authority transition from % to %', OLD.data_authority, NEW.data_authority;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach trigger to state_transitions
DROP TRIGGER IF EXISTS trg_enforce_state_transition_authority ON state_transitions;
CREATE TRIGGER trg_enforce_state_transition_authority
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW EXECUTE FUNCTION enforce_state_transition_authority();

-- upgrade_authority_on_execution_binding() trigger function
CREATE OR REPLACE FUNCTION upgrade_authority_on_execution_binding()
RETURNS TRIGGER AS $$
BEGIN
    -- Upgrade data_authority when execution_id is present
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND (OLD.execution_id IS DISTINCT FROM NEW.execution_id OR OLD.signature IS DISTINCT FROM NEW.signature)) THEN
        IF NEW.execution_id IS NOT NULL THEN
            IF NEW.signature IS NOT NULL THEN
                NEW.data_authority := 'authoritative_signed';
                NEW.audit_grade := true;
                NEW.authority_explanation := 'Execution binding with signature';
            ELSE
                NEW.data_authority := 'policy_bound_unsigned';
                NEW.authority_explanation := 'Execution binding without signature';
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Attach trigger to state_transitions (BEFORE to allow modification of NEW)
DROP TRIGGER IF EXISTS trg_upgrade_authority_on_execution_binding ON state_transitions;
CREATE TRIGGER trg_upgrade_authority_on_execution_binding
BEFORE INSERT OR UPDATE ON state_transitions
FOR EACH ROW EXECUTE FUNCTION upgrade_authority_on_execution_binding();
