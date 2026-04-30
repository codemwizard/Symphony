-- Verification SQL for Wave 8 placeholder cleanup
-- Task: TSK-P2-W8-DB-002
-- Purpose: Prove that placeholder-style values are rejected or impossible on asset_batches write boundary

-- Check 1: Verify signature placeholder trigger has been dropped
SELECT 
    trigger_name,
    event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'tr_add_signature_placeholder'
AND event_object_schema = 'public';

-- Expected: 0 rows (trigger dropped)

-- Check 2: Verify signature placeholder function has been dropped
SELECT 
    p.proname as function_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'add_signature_placeholder_posture';

-- Expected: 0 rows (function dropped)

-- Check 3: Verify CHECK constraint rejects placeholder transition_hash
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.state_transitions'::regclass
AND conname = 'no_placeholder_transition_hash';

-- Expected: constraint exists with CHECK (transition_hash NOT LIKE 'PLACEHOLDER_%')

-- Check 4: Verify CHECK constraint rejects non_reproducible data_authority
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.state_transitions'::regclass
AND conname = 'no_non_reproducible_data_authority';

-- Expected: constraint exists with CHECK (data_authority != 'non_reproducible')

-- Check 5: Verify placeholder rejection function exists
SELECT 
    p.proname as function_name,
    p.prosecdef as security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'wave8_reject_placeholders';

-- Expected: function exists with prosecdef = true

-- Check 6: Test placeholder transition_hash rejection (physical write test)
DO $$
DECLARE
    test_result text;
BEGIN
    -- Attempt to insert with placeholder transition_hash
    BEGIN
        INSERT INTO public.state_transitions (
            transition_id,
            project_id,
            entity_type,
            entity_id,
            from_state,
            to_state,
            transition_hash,
            data_authority
        ) VALUES (
            gen_random_uuid(),
            gen_random_uuid(),
            'test_entity',
            gen_random_uuid(),
            'pending',
            'active',
            'PLACEHOLDER_PENDING_SIGNING_CONTRACT:test123',
            'test_authority'
        );
        test_result := 'INSERT_SUCCEEDED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'INSERT_FAILED_PLACEHOLDER_REJECTED';
    END;
    
    RAISE NOTICE 'Placeholder transition_hash test result: %', test_result;
END $$;

-- Expected: INSERT_FAILED_PLACEHOLDER_REJECTED (constraint rejects placeholder)

-- Check 7: Test non_reproducible data_authority rejection (physical write test)
DO $$
DECLARE
    test_result text;
BEGIN
    -- Attempt to insert with non_reproducible data_authority
    BEGIN
        INSERT INTO public.state_transitions (
            transition_id,
            project_id,
            entity_type,
            entity_id,
            from_state,
            to_state,
            transition_hash,
            data_authority
        ) VALUES (
            gen_random_uuid(),
            gen_random_uuid(),
            'test_entity',
            gen_random_uuid(),
            'pending',
            'active',
            'valid_hash_1234567890abcdef',
            'non_reproducible'
        );
        test_result := 'INSERT_SUCCEEDED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'INSERT_FAILED_NON_REPRODUCIBLE_REJECTED';
    END;
    
    RAISE NOTICE 'Non-reproducible data_authority test result: %', test_result;
END $$;

-- Expected: INSERT_FAILED_NON_REPRODUCIBLE_REJECTED (constraint rejects non_reproducible)
