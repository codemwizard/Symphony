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

-- Note: enforce_state_transition_authority() and upgrade_authority_on_execution_binding()
-- triggers are created in migration 0137 where state_transitions table is defined.
-- This migration (0122) runs before state_transitions exists, so these triggers
-- cannot be attached here.
