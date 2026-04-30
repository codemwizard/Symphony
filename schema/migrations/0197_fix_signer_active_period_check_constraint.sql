-- Migration: 0197_fix_signer_active_period_check_constraint.sql
-- Task: Devin Review remediation
-- Purpose: Replace CHECK constraint using now() with a BEFORE INSERT/UPDATE trigger
-- Dependencies: 0176_wave8_signer_resolution_surface.sql
-- Type: Forward-only migration
--
-- Bug: The wave8_signer_active_period CHECK constraint uses now() to validate
-- valid_until > now(). PostgreSQL evaluates CHECK constraints at INSERT/UPDATE
-- time, meaning once valid_until passes, any UPDATE to the row (even unrelated
-- columns) will fail the CHECK. This creates a time-bomb where expired rows
-- become permanently un-updateable. Additionally, now() returns the transaction
-- start time which can surprise in long transactions.
--
-- Fix: Drop the CHECK constraint and replace with a BEFORE INSERT OR UPDATE
-- trigger that enforces the same logic only when is_active = true. Expired
-- rows can still be updated (e.g., to set is_active = false for deactivation).

-- Drop the problematic CHECK constraint
ALTER TABLE public.wave8_signer_resolution
    DROP CONSTRAINT IF EXISTS wave8_signer_active_period;

-- Create a trigger function that enforces valid_from is set when active,
-- but only rejects if valid_until is set AND in the past AND the row is
-- being inserted or activated (not when updating an already-expired row).
CREATE OR REPLACE FUNCTION public.wave8_enforce_signer_active_period()
RETURNS trigger
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only enforce on active signers
    IF NEW.is_active = true THEN
        -- valid_from is required for active signers
        IF NEW.valid_from IS NULL THEN
            RAISE EXCEPTION 'Active signer must have valid_from set'
            USING ERRCODE = '23514'; -- check_violation
        END IF;
        
        -- On INSERT: reject if valid_until is already in the past
        IF TG_OP = 'INSERT' AND NEW.valid_until IS NOT NULL AND NEW.valid_until <= clock_timestamp() THEN
            RAISE EXCEPTION 'Cannot insert active signer with valid_until in the past'
            USING ERRCODE = '23514';
        END IF;
        
        -- On UPDATE: reject only if is_active is being changed from false to true
        -- with an already-expired valid_until (reactivation of expired key)
        IF TG_OP = 'UPDATE' AND OLD.is_active = false AND NEW.is_active = true THEN
            IF NEW.valid_until IS NOT NULL AND NEW.valid_until <= clock_timestamp() THEN
                RAISE EXCEPTION 'Cannot reactivate signer with valid_until in the past'
                USING ERRCODE = '23514';
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_wave8_signer_active_period
    BEFORE INSERT OR UPDATE ON public.wave8_signer_resolution
    FOR EACH ROW
    EXECUTE FUNCTION public.wave8_enforce_signer_active_period();

COMMENT ON FUNCTION public.wave8_enforce_signer_active_period() IS
    'Replaces the wave8_signer_active_period CHECK constraint (which used now() and caused expired rows to become un-updateable). Enforces valid_from on active signers and prevents inserting or reactivating signers with already-expired valid_until.';
