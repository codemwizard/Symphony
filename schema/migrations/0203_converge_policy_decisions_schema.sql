-- Migration 0203: Converge policy_decisions schema between main DB and fresh DBs
-- Fixes migration non-convergence issues that cause baseline drift
-- Task: Migration Convergence Fix
-- symphony:no_tx

DO $$
BEGIN
    -- Fix primary key constraint name
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'policy_decisions' 
        AND constraint_name = 'policy_decisions_pkey'
        AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE policy_decisions RENAME CONSTRAINT policy_decisions_pkey TO policy_decisions_pk;
    END IF;
    
    -- Fix foreign key constraint name
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'policy_decisions' 
        AND constraint_name = 'policy_decisions_execution_id_fkey'
        AND constraint_type = 'FOREIGN KEY'
    ) THEN
        ALTER TABLE policy_decisions RENAME CONSTRAINT policy_decisions_execution_id_fkey TO policy_decisions_fk_execution;
    END IF;
    
    -- Fix unique constraint name
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'policy_decisions' 
        AND constraint_name = 'policy_decisions_execution_id_decision_type_key'
        AND constraint_type = 'UNIQUE'
    ) THEN
        ALTER TABLE policy_decisions RENAME CONSTRAINT policy_decisions_execution_id_decision_type_key TO policy_decisions_unique_exec_type;
    END IF;
    
    -- Fix hash check constraint name
    IF EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'policy_decisions_decision_hash_check'
    ) THEN
        ALTER TABLE policy_decisions RENAME CONSTRAINT policy_decisions_decision_hash_check TO policy_decisions_hash_hex_64;
    END IF;
    
    -- Fix signature check constraint name
    IF EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'policy_decisions_signature_check'
    ) THEN
        ALTER TABLE policy_decisions RENAME CONSTRAINT policy_decisions_signature_check TO policy_decisions_sig_hex_128;
    END IF;
    
    -- Add missing DEFAULT on policy_decision_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'policy_decisions' 
        AND column_name = 'policy_decision_id' 
        AND column_default IS NOT NULL
    ) THEN
        ALTER TABLE policy_decisions ALTER COLUMN policy_decision_id SET DEFAULT gen_random_uuid();
    END IF;
    
    -- Add missing ON DELETE RESTRICT to foreign key
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'policy_decisions' 
        AND constraint_name = 'policy_decisions_fk_execution'
        AND constraint_type = 'FOREIGN KEY'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.referential_constraints 
        WHERE constraint_name = 'policy_decisions_fk_execution'
        AND delete_rule = 'RESTRICT'
    ) THEN
        -- Drop and recreate the FK with ON DELETE RESTRICT
        ALTER TABLE policy_decisions DROP CONSTRAINT policy_decisions_fk_execution;
        ALTER TABLE policy_decisions 
        ADD CONSTRAINT policy_decisions_fk_execution 
        FOREIGN KEY (execution_id) REFERENCES execution_records(execution_id) 
        ON DELETE RESTRICT;
    END IF;
END $$;

-- Fix append-only trigger name and ERRCODE
-- Drop the old trigger if it exists with wrong name
DROP TRIGGER IF EXISTS enforce_policy_decisions_append_only ON policy_decisions;

-- Drop the old function if it exists
DROP FUNCTION IF EXISTS enforce_policy_decisions_append_only();

-- Create the correct trigger function with GF060 ERRCODE
CREATE OR REPLACE FUNCTION enforce_policy_decisions_append_only()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'GF060: policy_decisions table is append-only' 
        USING ERRCODE = 'GF060';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Create the trigger with correct name
CREATE TRIGGER policy_decisions_append_only_trigger
BEFORE DELETE ON policy_decisions
FOR EACH ROW EXECUTE FUNCTION enforce_policy_decisions_append_only();

-- Revoke permissions on the function
REVOKE ALL ON FUNCTION enforce_policy_decisions_append_only() FROM PUBLIC;

-- Create missing check_invariant_gate function if it doesn't exist
CREATE OR REPLACE FUNCTION check_invariant_gate()
RETURNS TRIGGER AS $$
DECLARE
    failing_count INTEGER;
    registry_exists BOOLEAN;
BEGIN
    -- Check if invariant registry exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'invariant_registry'
    ) INTO registry_exists;
    
    IF registry_exists THEN
        -- Check for failing invariants
        SELECT COUNT(*) INTO failing_count
        FROM invariant_registry 
        WHERE status = 'FAIL' AND enabled = true;
        
        IF failing_count > 0 THEN
            RAISE EXCEPTION 'GF063: % invariants are failing, operation blocked', failing_count
            USING ERRCODE = 'GF063';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Revoke permissions on the function
REVOKE ALL ON FUNCTION check_invariant_gate() FROM PUBLIC;
